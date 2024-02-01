###########################################################################
#
# NAME: Unlock Suspended Accounts
#
# AUTHOR:  Josh Mena InfoSec Team
#
# COMMENT: 
# This script will check if the login account is suspended due to 5 bad attempts. 
# If the account is locked it will unlock it. 
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

# ------Define Functions ------ >

#Rerun The Script Function
    Function Rerun 
    {
        $a = new-object -comobject wscript.shell 
        $intAnswer = $a.popup("Do you want to check another account?", ` 
        0,"Check Accounts",4) 
        If ($intAnswer -eq 6) {  CheckUserAccount
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

#Check locked account Function
Function CheckUserAccount
{
cls

#type suspended account
$lUser = Read-Host -Prompt 'Type username to check status and unlock (samaccountname e.g. jdoe)'
    while ([string]::IsNullOrEmpty($lUser)){
    
    write-host -f Yellow  "Please type user name "
    $lUser = Read-Host -Prompt 'Type username to check status and unlock (samaccountname e.g. jdoe)'

    }

Try
     { $var1 = Get-PASUser -UserName $lUser -ExtendedDetails $true
       $var2 = $var1 | Select-Object -ExpandProperty Suspended
       $var3 = $var1 | Select-Object -ExpandProperty UserName
       $v_ID = $var1 | Select-Object -ExpandProperty ID
     if ($var2 -eq $True){ 
            Write-Warning "Account $var3 is suspended"
            Write-Host -f Yellow "Check if user is typing correct password and that their trad account is not locked out in AD" 
            Write-Host -f red "Unlocking Account $var3 ..." 
            Start-Sleep -s 5
            
            Unblock-PASUser -ID $v_ID 
            $var4 = Get-PASUser -UserName $lUser -ExtendedDetails $true | Select-Object -ExpandProperty suspended
                if ($var4 -eq $False){
                    Write-Host -f Green "Account $var3 has been unlocked"
                    Write-Host -f Magenta "Please confirm that $var3 trad account is not expired in AD. If problem persists, make sure MFA Token is not locked out!"
                }
     }
    else {
       Write-Host -ForegroundColor Green "Account $var3 is not locked" 
           }
        
    }
    Catch
    {
     $errormessage = $Error[0].Exception.Message
     $errorposition = $Error[0].invocationinfo.PositionMessage
     Write-Warning "User $luser was not found."
     Write-Host -ForegroundColor Yellow "Please make sure user name is correct, and is vaulted!"
           
    }
    
}

# Get Credentials to Login
# ------------------------
$caption = "Check Account Status"
$msg = "Enter your PROD User name and Password"; 
$creds = $Host.UI.PromptForCredential($caption,$msg,"","")
if (!$creds){ 
    Write-Warning "User canceled. " 
    Stop-Transcript | Out-Null 
    exit    } 

#Open Session
New-PASSession -Credential $creds -BaseURI https://pam.constoso.com -SkipCertificateCheck -type RADIUS -Verbose # 

CheckUserAccount

while($true){
Rerun
}

Get-ChildItem "L:\EUC\PAM\Scripts\logs\"  | Where CreationTime -lt  (Get-Date).AddDays(-15)  | Remove-Item  
