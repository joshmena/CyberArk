###########################################################################
#
# NAME: Add PAM Account
#
# AUTHOR:  InfoSec
#
# COMMENT: 
# This script will create new pam account in an existing safe 
# If the safe does not exist it will not continue  
#
# SUPPORTED VERSIONS:
# CyberArk PVWA v12.6 and above
# 
# Script Version = "2"
#
###########################################################################
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Update psPAS Module 
  & "L:\EUC\PAM\Scripts\PsPAS_CopyModule.ps1" | Out-Null 


# Get Script Location 
$path = Get-Location
# only works when not using ISE // $scriptName = $MyInvocation.MyCommand.Name
$scriptName = $MyInvocation.MyCommand.Name
#$scriptName = $psISE.CurrentFile.DisplayName
$scriptLog = ($scriptName).Replace(".ps1","_")

# Start Transcript
Start-Transcript -Path "$path\logs\$scriptLog$((Get-Date).ToString('yyyyMMdd_hhmm'))_$((Get-ChildItem Env:\USERNAME).Value).log" -IncludeInvocationHeader

cls

#Reading Contents and Parsing
#$accounts = Get-content "$Path\Accounts.txt" #| select -First 5

#get user account 
$account = Read-Host 'Please type SamAccountName of the user e.g. prod_account ' 
    while ([string]::IsNullOrEmpty($account))
           {
            write-host -f Yellow  "Please type user name "
            $account = Read-Host 'Please type SamAccountName of the user' 
           }
$account = $account.ToUpper()

try 
    {
    $checkUser = get-aduser $account -ErrorAction Stop
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
    Write-Warning -Message "User $account could not be found."  
    write-host -f Yellow "Please make sure user exist in the domain and run script again!"
    Stop-Transcript | Out-Null
    exit
    }
    finally {
        $Error.Clear()
    }

#select domain to create pam account
$varDomain = Read-Host -Prompt 'Type domain to create account (qa,eng,trad,nydc,ildc,tydc)'
while("qa","eng","trad","nydc","ildc","tydc" -notcontains $varDomain)
{
 $varDomain = Read-Host -Prompt 'Please type the correct domain to create pam_account (qa,eng,trad,nydc,ildc,tydc)'
}
$trad = ".tradestation.com"
$domain = ''
$domain = $varDomain+$trad

# Get Credentials to Login
# ------------------------
$caption = "Add Accounts"
$msg = "Enter your PROD User name and Password"; 
$creds = $Host.UI.PromptForCredential($caption,$msg,"","")
if (!$creds){ 
    Write-Warning "User canceled. " 
    Stop-Transcript | Out-Null 
    exit    } 

#Open Session
New-PASSession -Credential $creds -BaseURI https://ny04pam.trad.tradestation.com -SkipCertificateCheck -type RADIUS 

#Convert Password to SecureString
$Password = ConvertTo-SecureString -String "Cyber@rk123!" -AsPlainText -Force

$cleanvar = $account
$account = $account + "_IND"

if ($account -like "*PROD_*")
	{
		$account = $account.replace("PROD_","") 
        $cleanvar = $account
        $account = $account + "_IND"		    
    }
   

  if (!($pamAcct = Get-PASAccount -safeName $account -search $domain))
    {
        
    
       
    #Additional account details
    $platformAccountProperties = @{
    "LOGONDOMAIN"="$domain"
    }
    
    
    #Add PAM Accounts
    $response = Add-PASAccount -secretType Password -secret $Password -SafeName $account -PlatformID "WindowsDomainAccounts-AutoManage" -Address $domain -Username $cleanvar -platformAccountProperties $platformAccountProperties
    $pamAcct = $pamAcct.username + "." + $pamAcct.address
    $response

    Write-Host -f Green "Account $pamAcct has been created." 
    Write-Host -f Red "Please login to PVWA Portal to associate reconcile svc_pwdrecon.$domain account under Additional details.. "
    Write-Host -f Yellow "Procedures can be found on SOP-ITSC-0035"
    
    }
    else
    {
      $pamAcct = $pamAcct.username + "." + $pamAcct.address
      Write-Host -f Yellow "ACCOUNT: $pamAcct ALREADY EXIST!"
    }

    	

Close-PASSession

Stop-Transcript

Get-ChildItem "L:\EUC\PAM\Scripts\logs\"  | Where CreationTime -lt  (Get-Date).AddDays(-15)  | Remove-Item  