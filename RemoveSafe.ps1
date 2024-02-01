###########################################################################
#
# NAME: Remove Safe 
#
# AUTHOR:  Josh Mena InfoSec Team
#
# COMMENT: 
# This script will remove the safe for the selected user. 
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
	$account = $account.substring(0,2).ToUpper()+$account.Substring(2)



 # Get Credentials to Login
    # ------------------------
    $caption = "Remove Safe"
    $msg = "Enter your PROD User name and Password"; 
    $creds = $Host.UI.PromptForCredential($caption,$msg,"","")
    if (!$creds){ 
        Write-Warning "User canceled. " 
        Stop-Transcript | Out-Null 
        exit    }
         
    #Open Session
    New-PASSession -Credential $creds -BaseURI https://pam.contoso.com -SkipCertificateCheck -type RADIUS -Verbose

 #Find user's safe and delete it
    $Pname = $account + "_IND"
	$Pname = $Pname.ToUpper()

  if (Find-PASSafe -search $Pname)
    {
     Write-Host -f Yellow "Removing safe: $account"
	 Remove-PASSafe -SafeName $Pname
    

    }
    else
    {
      
      Write-Host -f Green "Safe: $account does not exist"
    }

    	

Close-PASSession

Stop-Transcript

Get-ChildItem "$path\logs\"  | Where CreationTime -lt  (Get-Date).AddDays(-15)  | Remove-Item      
