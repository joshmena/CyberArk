###########################################################################
#
# NAME: Create Safe Only
#
# AUTHOR:  InfoSec
#
# COMMENT: 
# This script will Create a new safe. 
# If the safe already exist it will stop. 
#
# SUPPORTED VERSIONS:
# CyberArk PVWA v12.6 and above
# 
# Script Version = "2"
#
<###########################################################################>
#dir $env:USERPROFILE\Documents\WindowsPowerShell\Modules\* | Unblock-File
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
$account = Read-Host 'Please type SamAccountName of the new user' 
    while ([string]::IsNullOrEmpty($account)){

    $account = Read-Host 'Please type SamAccountName of the new user' 
    }

    try 
    {
    $checkUser = get-aduser $account -ErrorAction Stop 
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
    Write-Warning -Message "User $account could not be found."  
    write-host -f Yellow "Please make sure user exist in the TRAD domain and run script again!"
    Stop-Transcript | Out-Null
    exit
    }
    finally {
        $Error.Clear()
    }

if (-not(Get-ADPrincipalGroupMembership -Server trad.tradestation.com -Identity $account -ErrorAction Stop | where name -eq "CYBERARK_USER" | select-object -expandproperty name))
   {
       Write-Warning -Message "User $account is not a member of CYBERARK_USER AD group."
       Write-Host "Please add trad\$account account to the AD group before running the script again!" -f Yellow
       stop-transcript
       exit
   }
   else
   {   }
   
  # Get Credentials to Login
    # ------------------------
    $caption = "Create New Safe"
    $msg = "Enter your PROD User name and Password"; 
    $creds = $Host.UI.PromptForCredential($caption,$msg,"","")
    if (!$creds){ 
        Write-Warning "User canceled. " 
        Stop-Transcript | Out-Null 
        exit    }
         
    #Open Session
    New-PASSession -Credential $creds -BaseURI https://ny04pvwa02.nydc.tradestation.com -SkipCertificateCheck -type RADIUS -Verbose  

   
 #Create variables for user and get AD attributes for description
	$Pname = $account + "_IND"
	$Pname = $Pname.ToUpper()
    $desc = ''
     
function Remove-Diacritics 
            {
         param ([String]$src = [String]::Empty)
         $normalized = $src.Normalize( [Text.NormalizationForm]::FormD )
         ($normalized -replace '\p{M}', '')
            }

 #Get descriptions from AD 
  $description = get-aduser $account -Properties * | select EmailAddress,Name,Title, @{label='Manager';expression={$_.manager -replace '^CN=|,.*$'}}
  $descLen =$description.Name.Length + $description.Title.Length  + $description.Manager.Length + $description.EmailAddress.Length + 19
     if($descLen -ge 100)
      {
	$diff = $descLen - 100
	 $title = $description.Title.Substring(0, $description.Title.Length-$diff)
	 } else 
        {
		$title = $description.Title
		}
     $name = $description.name
     $email = "Email: " + $description.EmailAddress
	 $desc = $name + "`r`n" +  $title + "`r`n" +  "Mngr: "  + $description.Manager + "`r`n" + $email
	 $desc = Remove-Diacritics ($desc)

try{
  Get-PASSafe -SafeName $pname | Out-Null
  Write-Host -f yellow "$desc `r`n" 
  Write-Host -f red "SAFE: $pname ALREADY EXIST. `r`n" 
     
       
}
catch{

    $err = $_.Exception.Message
   
    if($err.Contains('404')){ 
    

    #Permission set for Safe Admins

    $AdminGroup_Role = [PSCustomObject]@{
	Add							= $True
	AddAccounts					= $true
	AddRenameFolder				= $True
	BackupSafe					= $True
	Delete						= $True
	DeleteFolder				= $True
	ListContent					= $True
	ListAccounts				= $true
	ManageSafe					= $True
	ManageSafeMembers			= $True
	MoveFilesAndFolders			= $True
	Rename						= $True
	RestrictedRetrieve			= $True
	Retrieve					= $False
	RetrieveAccounts			= $False
	Unlock						= $True
	Update						= $True
	UseAccounts					= $False
	UpdateMetadata				= $True
	ValidateSafeContent			= $true
	ViewAudit					= $True
	ViewMembers					= $True
	UpdateAccountContent		= $true
	UpdateAccountProperties		= $true
	InitiateCPMAccountManagementOperations	= $true
	SpecifyNextAccountContent	= $true
	RenameAccounts				= $true
	DeleteAccounts				= $true
	UnlockAccounts				= $true
	ViewAuditLog				= $true
	ViewSafeMembers				= $true
	RequestsAuthorizationLevel	= $true
	AccessWithoutConfirmation	= $true
	CreateFolders				= $true
	DeleteFolders				= $true
	MoveAccountsAndFolders		= $true
    }

    #Permission set for Safe User
    $User_Role = [PSCustomObject]@{
	Add							= $True
	AddRenameFolder				= $True
	BackupSafe					= $False
	Delete						= $True
	DeleteFolder				= $True
	ListContent					= $True
	ListAccounts				= $True
	ManageSafe					= $False
	ManageSafeMembers			= $False
	MoveFilesAndFolders			= $True
	Rename						= $True
	RestrictedRetrieve			= $True
	Retrieve					= $True
	Unlock						= $True
	Update						= $True
	UpdateMetadata				= $True
	ValidateSafeContent			= $False
	ViewAudit					= $True
	ViewAuditLog				= $true
	ViewMembers					= $False
	RequestsAuthorizationLevel	= $False
	AccessWithoutConfirmation	= $False
	CreateFolders				= $true
	DeleteFolders				= $true
	MoveAccountsAndFolders		= $true
    }

    #Permission set for Administrator account
    $Admin_Role = [PSCustomObject]@{
	Add							= $True
	AddAccounts					= $true
	AddRenameFolder				= $True
	BackupSafe					= $True
	Delete						= $True
	DeleteFolder				= $True
	ListContent					= $True
	ListAccounts				= $true
	ManageSafe					= $True
	ManageSafeMembers			= $True
	MoveFilesAndFolders			= $True
	Rename						= $True
	RestrictedRetrieve			= $True
	Retrieve					= $True
	RetrieveAccounts			= $True
	Unlock						= $True
	Update						= $True
	UseAccounts					= $True
	UpdateMetadata				= $True
	ValidateSafeContent			= $true
	ViewAudit					= $True
	ViewMembers					= $True
	UpdateAccountContent		= $true
	UpdateAccountProperties		= $true
	InitiateCPMAccountManagementOperations	= $true
	SpecifyNextAccountContent	= $true
	RenameAccounts				= $true
	DeleteAccounts				= $true
	UnlockAccounts				= $true
	ViewAuditLog				= $true
	ViewSafeMembers				= $true
	RequestsAuthorizationLevel	= $true
	AccessWithoutConfirmation	= $true
	CreateFolders				= $true
	DeleteFolders				= $true
	MoveAccountsAndFolders		= $true
    }
	
	#Permission set for Safe Managers - EUC Team
    $SafeManagerGroup_Role = [PSCustomObject]@{
	Add							= $True
	AddAccounts					= $true
	AddRenameFolder				= $True
	BackupSafe					= $True
	Delete						= $True
	DeleteFolder				= $True
	ListContent					= $True
	ListAccounts				= $true
	ManageSafe					= $True
	ManageSafeMembers			= $True
	MoveFilesAndFolders			= $True
	Rename						= $True
	RestrictedRetrieve			= $False
	Retrieve					= $False
	RetrieveAccounts			= $False
	Unlock						= $True
	Update						= $True
	UseAccounts					= $False
	UpdateMetadata				= $True
	ValidateSafeContent			= $true
	ViewAudit					= $True
	ViewMembers					= $True
	UpdateAccountContent		= $true
	UpdateAccountProperties		= $true
	InitiateCPMAccountManagementOperations	= $true
	SpecifyNextAccountContent	= $true
	RenameAccounts				= $true
	DeleteAccounts				= $true
	UnlockAccounts				= $true
	ViewAuditLog				= $True
	ViewSafeMembers				= $true
	RequestsAuthorizationLevel	= $False
	AccessWithoutConfirmation	= $False
	CreateFolders				= $true
	DeleteFolders				= $true
	MoveAccountsAndFolders		= $true
    }

    Write-Host -f yellow "Please wait ..."
	write-Host -f green "creating Safe for $desc"  
    Start-Sleep -s 5
         
    Add-PASSafe -SafeName $Pname -Description $desc -ManagingCPM CPM_NY04 -NumberOfDaysRetention 1 
      
	$User_Role | Add-PASSafeMember -SafeName $Pname -MemberName $account -SearchIn "TRAD DOMAIN"
	$AdminGroup_Role | Add-PASSafeMember -SafeName $Pname -MemberName CYBERARK_ADMIN
	$SafeManagerGroup_Role | Add-PASSafeMember -SafeName $Pname -MemberName CYBERARK_SAFE_MANAGERS

    #Enable only when running with prod_account##
	$Admin_Role | Add-PASSafeMember -SafeName $Pname -MemberName Administrator
    
    $adminSession = Get-PASSession

    Remove-PASSafeMember -SafeName $Pname -MemberName $adminSession.User
 
    
    
    }
   
}

Close-PASSession

Stop-Transcript

Get-ChildItem "$path\logs\"  | Where CreationTime -lt  (Get-Date).AddDays(-15)  | Remove-Item      