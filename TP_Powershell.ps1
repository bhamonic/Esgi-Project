<#	
	.NOTES
	===========================================================================
	 Created on:   	16/07/2019 12:09
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

#Region Environment
Import-Module ActiveDirectory
Add-Type -AssemblyName System.web
Import-Module VMware.VimAutomation.Core
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
Install-Module -Name "VIPerms" -Scope "CurrentUser"
Import-Module -Name "VIPerms"

$esxi_pass = ConvertTo-SecureString -AsPlainText -Force "Espoir15"
$esxi_cred = New-Object System.Management.Automation.PSCredential ('root', $esxi_pass)
$vsphere_pass = ConvertTo-SecureString -AsPlainText -Force "Espoir15"
$vsphere_cred = New-Object System.Management.Automation.PSCredential ('root', $vsphere_pass)

#Endregion Environment

#region function 
function logfile
{
	
	
	
}
#endregion function 

#region Menu
function menu
{
	$menu = "[1] AD
[2] DNS
[3] vCenter
[4] Create VM
[5] Export
[6] Git
[0] Exit
    "
	$answer = Read-Host $menu
	switch ($answer)
	{
		"1" { AD }
		"2" { DNS }
		"3" { vCenter }
		"4" { Create-VM }
		"5" { Export }
		"6" { Github }
		"0" { exit }
		default
		{
			write-host "Invalid option, please retry"
			menu
		}
	}
}


#Endregion Menu 

#Region AD
function AD
{
	
	if (get-aduser -Filter 'Name -like "test-*"')
	{
		$user = get-aduser -Filter 'Name -like "test-*"' | Select-Object -ExpandProperty Name
		Remove-ADUser $user -Confirm:$false
		Remove-ADGroup "Admin-$user" -Confirm:$false
		increment -username $user
		generate_password
		New-ADUser -Name $new_username -AccountPassword $Secure_Pass -enable:$true -Confirm:$false
		New-ADGroup -Name "Admin-$new_username" -groupscope "Global" -Confirm:$false
		Add-ADGroupMember -Identity "Admin-$new_username" -Members $new_username -Confirm:$false
	}
	
	else
	{
		New-ADUser -Name "test-00" -Confirm:$false
		New-ADGroup -Name "Admin-$new_username" -groupscope "Global" -Confirm:$false
		Add-ADGroupMember -Identity "Admin-$new_username" -Members $new_username -Confirm:$false
		
	}
}


function increment
{
	param ($username)
	
	$new_username = $username.Split("-")
	[int]$new_username[1] += 1
	if ([int]$new_username[1] -le 9)
	{
		[string]$script:new_username = $new_username[0] + "-0" + $new_username[1]
	}
	else
	{
		[string]$script:new_username = $new_username[0] + "-" + $new_username[1]
	}
}

function generate_password
{
	[string]$Password = [System.Web.Security.Membership]::GeneratePassword(12, 6)
	$script:Secure_Pass = ConvertTo-SecureString -AsPlainText -Force $Password
}

#Endregion AD 


function GitHub
{
	
	git add . # Take all the file in the current directory to commit
	$message = read-host "Enter the message of the commit"
	git push -m $message
	# add log function
}

function DNS
{
	
	$ESXI_Name = "172.180.0.150"
	if (Get-DnsServerZone ESGI.LAN | Get-DnsServerResourceRecord | Where-Object -Property 'Hostname' -Like $ESXI_Name)
	{
		Remove-DnsServerResourceRecord -ZoneName "0.180.172.in-addr.arpa" -RRType "PTR" -Name "200" -Confirm:$false
		#Remove-DnsServerResourceRecord -ZoneName "ESGI.LAN" -RRType "A" -Name $ESXI_Name -RecordData "192.168.200.200" -Confirm:$false
	}
	Add-DnsServerResourceRecordPtr -Name "200" -ZoneName "0.180.172.in-addr.arpa" -AllowUpdateAny -PtrDomainName "huy.fr"
	#Add-DnsServerResourceRecordA -Name $ESXI_Name -ZoneName "ESGI.LAN" -AllowUpdateAny -IPv4Address "192.168.200.200" 
	if (Get-ADComputer $ESXI_Name)
	{
		Remove-ADComputer $ESXI_Name -confirm:$false
	}
	New-ADComputer $ESXI_Name
}

function vCenter {
	Connect-VIServer -Server "" -Credential $vsphere_cred
	$script:cluster_name = "172.180.0.150"
	$vmhost = "172.180.0.200"
	New-Cluster -name $cluster_name -Location "DC" -DrsAutomationLevel FullyAutomated
	add-vmhost $vmhost -Location "DC" -Credential $esxi_cred -Force
	Move-VMHost $vmhost -Destination $cluster_name
	while (!Get-VMHost | Select parent)
	{
		Start-Sleep -s 2
		Write-Host "Waiting for VMHost to be added to cluster"
	}
	$ports = import-csv "C:\Documents\portgroup.csv" -Delimiter ";"
	foreach ($port in $ports)
	{
		Get-VirtualSwitch -name vswitch0 -vmhost $vmhost | New-VirtualPortGroup -name $port.Portgroups -VLanId $port.ID -ErrorAction Continue
	}
	Disconnect-VIServer * -Confirm:$false
}

function Create-VM
{
	$vm_nb = Read-Host "How many VM :"
	for ($i = 0; $i -lt $vm_nb; $i++)
	{
		$vm_name = "vm-" + $script:cluster_name + "-" + $i
		
		$ports = import-csv "C:\Documents\portgroup.csv" -Delimiter ";"
		Write-Host $ports
		$select_port = Read-Host "Select Portgroup ID"
		
		New-Vm -Name $vm_Name -Datastore "DC" -NumCPU 1 -MemoryMB 256 -CoresPerSocket 1 -portgroup $select_port
		
	}
}
<#Connect-VIServer -Server "vcsa5.esgi.lan" -Credential $vsphere_cred

New-Cluster -name "ESXI_Cluster" -Location "DC" -DrsAutomationLevel FullyAutomated

$ESXiHosts = "esxi.esgi.lan"
$ESXiLocation = "ESXI_Cluster"


Add-VMHost -Name "ESXI" -Server $ESXiHosts -Location $ESXiLocation -Credential $vsphere_cred -RunAsync -force

 

$resourcePool= Get-Folder -NoRecursion | select -First 1 | select -ExpandProperty Name
[string]$vi_user = Get-VIAccount -Domain "ESGI" -User "*toto*" | select -First 1 
[string]$vi_user = "$new_username@ESGI"
New-VIPermission -role "ALL" -principal $vi_user #>