###########################################################################
#
# NAME: Remove PAM Account
#
# AUTHOR:  Josh Mena InfoSec Team
#
# COMMENT: 
# This script will remove the pam account for the selected domain. 
#  
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


#Reading Contents and Parsing
$account = Read-Host 'Please type SamAccountName of the user' 
    while ([string]::IsNullOrEmpty($account))
           {
            write-host -f Yellow  "Please type user name "
            $account = Read-Host 'Please type SamAccountName of the user' 
           }
$account = $account.ToUpper()



#select domain to create pam account
$varDomain = Read-Host -Prompt 'Type domain for the account to be deleted (qa,eng,trad,nydc,ildc,tydc)'
while("qa","eng","trad","nydc","ildc","tydc" -notcontains $varDomain)
{
 $varDomain = Read-Host -Prompt 'Please type the correct domain to delete account (qa,eng,trad,nydc,ildc,tydc)'
}

$trad = ".contoso.com"
$domain = ''
$domain = $varDomain+$trad




# Get Credentials to Login
    # ------------------------
    $caption = "Add PAM Accounts"
    $msg = "Enter your PROD User name and Password"; 
    $creds = $Host.UI.PromptForCredential($caption,$msg,"","")
    if (!$creds){ 
        Write-Warning "User canceled. " 
        Stop-Transcript | Out-Null 
        exit    }
         
    #Open Session
    New-PASSession -Credential $creds -BaseURI https://pam.contoso.com -SkipCertificateCheck -type RADIUS -Verbose



 $cleanvar = $account
 $account = $account + "_IND"

 $pamAcct = Get-PASAccount -safeName $account -search $domain # | Select-Object -ExpandProperty AccountID

    foreach ($varAcct in $pamAcct){ 
       
    if ($varAcct.userName.ToUpper() -eq $cleanvar.ToUpper()) 
        {
       
        Remove-PASAccount -AccountID $varAcct.id

       Write-Host -f green "Account $varAcct.userName has been removed!"
    
        }
    }
    
         
         
    # immediate change
    #Invoke-PASCPMOperation -AccountID $response.id -ChangeTask

    # immediate verification
    # Invoke-PASCPMOperation -AccountID $response.id -VerifyTask



#Rerun The Script Function
    Function Rerun 
    {
        $a = new-object -comobject wscript.shell 
        $intAnswer = $a.popup("Do you want to remove another account?", ` 
        0,"Check Accounts",4) 
        If ($intAnswer -eq 6) {  GetUserAccount
                                 RemoveUserAccount
                                 
            } 
            else 
            { 
             Brakes 
        } 
    }

Function Brakes 
    {
    Close-PASSession
    Stop-Transcript 
    break
    }




while($true){
Rerun
}

Get-ChildItem "L:\EUC\PAM\Scripts\logs\"  | Where CreationTime -lt  (Get-Date).AddDays(-15)  | Remove-Item  
