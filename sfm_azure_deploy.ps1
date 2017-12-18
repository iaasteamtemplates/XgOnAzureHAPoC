# Check if Hyper-V is installed, if not install Hyper-V and management tools
$hypervCheck = Get-WindowsFeature -name Hyper-V

if ($hypervCheck.Installed -eq 'False') {
Install-WindowsFeature -Name Hyper-V -IncludeAllSubFeature -IncludeManagementTools -Restart
}

# Check if a virtual switch with the proper name exists, if not create it
$sfmSwitchCheck = Get-VMSwitch -SwitchName "SfmNatSwitch"
if !($sfmSwitchCheck) {
# Create an internal Hyper-V VM Switch
New-VMSwitch -SwitchName "SfmNatSwitch" -SwitchType Internal
New-Item -Path C:\ -Name "VMs" -ItemType Directory

# Configure default Virtual Machine path
Set-VMHost -VirtualHardDiskPath C:\VMs -VirtualMachinePath C:\VMs

# Configure the NAT Gateway IP Address
New-NetIPAddress –IPAddress 172.16.16.1 -PrefixLength 24 -InterfaceAlias "vEthernet (NATSwitch)"
 
# Configure the NAT rule
New-NetNat –Name SfmNATnetwork –InternalIPInterfaceAddressPrefix 172.16.16.0/24
 
# Create NAT forwards inside Nested Virtual Machines
# To forward specific ports from the Host to the guest VMs you can use the following commands.
Add-NetNatStaticMapping -NatName "SfmNATnetwork" -Protocol TCP -ExternalIPAddress 0.0.0.0 -InternalIPAddress 172.16.16.16 -InternalPort 80 -ExternalPort 80
Add-NetNatStaticMapping -NatName "SfmNATnetwork" -Protocol TCP -ExternalIPAddress 0.0.0.0 -InternalIPAddress 172.16.16.16 -InternalPort 443 -ExternalPort 443
Add-NetNatStaticMapping -NatName "SfmNATnetwork" -Protocol TCP -ExternalIPAddress 0.0.0.0 -InternalIPAddress 172.16.16.16 -InternalPort 4444 -ExternalPort 4444
Add-NetNatStaticMapping -NatName "SfmNATnetwork" -Protocol TCP -ExternalIPAddress 0.0.0.0 -InternalIPAddress 172.16.16.16 -InternalPort 4422 -ExternalPort 4422
 
# This example creates a mapping between port 82 of the Virtual Machine host to port 80 of a Virtual Machine with an IP address of 172.16.16.16.
# Add-NetNatStaticMapping -NatName "SfmNATnetwork" -Protocol TCP -ExternalIPAddress 0.0.0.0 -InternalIPAddress 172.16.16.16 -InternalPort 80 -ExternalPort 82
# Add-NetNatStaticMapping -NatName "SfmNATnetwork" -Protocol TCP -ExternalIPAddress 0.0.0.0 -InternalIPAddress 172.16.16.16 -InternalPort 80 -ExternalPort 82
 
}


## Check is a VM named "SFM" is installed, if not setup VM

$vm_name = "sfm-azure-01"
$SfmVmCheck = Get-Vm -Name $vm_name
if !($SfmVmCheck) {
 
# Download SFM primary and auxiliary disks
$sfm_pri_uri = "https://sophosinstallers.blob.core.windows.net/files/PRIMARY-DISK.vhd"
$sfm_aux_uri = "https://sophosinstallers.blob.core.windows.net/files/AUXILIARY-DISK.vhd"
$sfm_pri_path = "C:\VMs\sfm-pri.vhd"
$sfm_aux_path = "C:\VMs\sfm-aux.vhd"

$wc = New-Object System.Net.WebClient
$wc.DownloadFile($sfm_pri_uri, $sfm_pri_path)
$wc.DownloadFile($sfm_aux_uri, $sfm_aux_path)
 
# Create Hyper-V VM and attach the disks
New-Vm -Name $vm_name -MemoryStartupBytes 2GB -Generation 1 –VHDPath C:\VMs\sfm-pri.vhd -SwitchName "SfmNatSwitch"
Add-VMHardDiskDrive -VMName $vm_name -Path "C:\VMs\sfm-aux.vhd"
Start-Vm $vm_name
Start-Sleep -Seconds 5
 
}