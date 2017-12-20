$sfm_deploy_code = "https://raw.githubusercontent.com/iaasteamtemplates/XgOnAzureHAPoC/master/sfm_azure_deploy.ps1"
$sfm_deploy_code_path = "C:\sfm_azure_deploy.ps1"
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($sfm_deploy_code, $sfm_deploy_code_path)

$action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-NoProfile -WindowStyle Hidden -Command .\sfm_azure_deploy.ps1' -WorkingDirectory C:\ 
$trigger =  New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -TaskName "sfm_deploy" -Description "Deploy Sophos SFM" 

# Check if Hyper-V is installed, if not install Hyper-V and management tools
$hypervCheck = Get-WindowsFeature -name Hyper-V -ErrorAction SilentlyContinue

if ($hypervCheck.Installed -ne 'True') {
Install-WindowsFeature -Name Hyper-V -IncludeAllSubFeature -IncludeManagementTools -Restart -ErrorAction SilentlyContinue
}