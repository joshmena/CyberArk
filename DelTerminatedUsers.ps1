###########################################################################
#
# NAME: Delete Terminated User Safes
#
# AUTHOR:  InfoSec Team
#
# COMMENT: 
# "This script will check "Terminated Users" AD group and delete the safes from 
#  users in this group"
#
# SUPPORTED VERSIONS:
# CyberArk PVWA v12.6 and above
# 
# Script Version = "2"
#
##########################################################################
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



# Queries AD for Terminated users and creates a list.
Write-Host -f Green "Retrieving List from Terminated Users" 
Write-Host -f white "Please wait ...." 

$ADList = Get-ADGroupMember -server trad.tradestation.com -Identity "terminated users" -Recursive | Select -expand  SAMAccountName



cls

# Get Credentials to Login
    # ------------------------
    $caption = "Delete Termed Users"
    $msg = "Enter your PROD User name and Password"; 
    $creds = $Host.UI.PromptForCredential($caption,$msg,"","")
    if (!$creds){ 
        Write-Warning "User canceled. " 
        Stop-Transcript | Out-Null 
        exit    }
         
 #Open Session
 New-PASSession -Credential $creds -BaseURI https://ny04pam.trad.tradestation.com -SkipCertificateCheck -type RADIUS 

# Queries CyberArk Vault for all users and creates a list. 
$CAList=Get-PASSafe -FindAll | select safename


$myArray = New-Object System.Collections.Generic.List[System.String]
$myArray.Add("-------------------------------------------------------------------------------------------------------")
foreach ($items in $CAList) {

$value = $items.SafeName
    
 
  if ($value -match "_IND") {
    
   $value = $value.Split("_")

      if ($ADList -match $value[0]){
      
       try{
          Remove-PASSafe -SafeName $items.SafeName # -ErrorAction SilentlyContinue
     
       
        }
        catch{

            $err = $_.Exception.Message
           
            if($err.Contains('non-expired')){ 
             #$errorMain = $err.Split("deleted in ")
             $myArray += $items.SafeName + ": Cannot be deleted for another " + $err.Substring($err.Length - 7)
             
             $items.SafeName + ": Cannot be deleted for another " + $err.Substring($err.Length - 7)
            
             }



           }


       
        
      }
   }

   
}
  
 
 # $toV="jmena@tradestation.com,javilacastillo@tradestation.com"
  $subjectV="Monthly CleanUp: Safe(s) pending deletion from Terminated Users"
 # $bodyV="Safe(s) pending deletion from Terminated Users"
  $bodya = ($myArray | convertto-html -Property @{l='Pending Users Safe For Deletion'; e={$_}} | out-string)

  
  Send-MailMessage -From DO-NOT-REPLY@tradestation.com -To jmena@tradestation.com -Subject $subjectV -SmtpServer 10.138.171.5 -Body $bodya -BodyAsHtml
             




  Get-ChildItem "L:\EUC\PAM\Scripts\logs\"  | Where CreationTime -lt  (Get-Date).AddDays(-15)  | Remove-Item  