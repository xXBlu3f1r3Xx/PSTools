# ServerToolsV1.psm1 is a set of Powershell tools to simplify some repetitive checks or tasks in scripts.
#
# Function list:
#
# Search-ForItem
# Get-ServerBootTime
# Get-CurrentUsers
# 
# @Author:	xXBlu3f1r3Xx
# @Date:	July 25th, 2015
# @PSVers:	2.0+
#
# @About:	These functions have been trimmed down to generalize them for different environments. I originally
# created the tools to work within my company's Citrix server environment. Although fairly simple, I have 
# found them rather useful in making short scripts or when I just need to gather a few pieces of information. 
# I highly recommend making another function to populate a list of servers, or other remote machines, to use 
# in conjunction with these tools.

<#
.SYNOPSIS
   Searches for folders or files in all subdirectories of a provided path.
.DESCRIPTION
   Provide a folder or file name and a parent path to search from, to search
   for all instances found similar to this name. You can specify the -file
   switch to search for files (searching for folders is default). Returns
   the full names.
.EXAMPLE
   Search-ForItem -path "C:\" -name credentials
   This command will return the full path names of all folders named "credentials" within
   the C drive.
.EXAMPLE
   Search-ForItem -path "C:\users\test\" -name test.xml -file
   This command will return the full path names of all files named "test.xml" within the 
   test users profile.
.INPUTS
   Two required <String> inputs, one for the parent path and one for the item's name.
   You can also specify the -file switch to change the search paramater from directories to files.
.LINK
.NOTES
   This function is intended to make scripting file deletions, creations, or checks quicker and easier.
   
   @Author: xXBlu3f1r3Xx
   @LEDate: July 25th, 2015
   @PSVers: 2.0+
#>
function Search-ForItem {
    [CmdletBinding()]
    Param (
        # Path of parent folder to search from
        [Parameter(Mandatory=$true,
                   HelpMessage="Enter the path of a parent folder to search from")]
        [alias("p")]
        [string]
        $path,

        # Name to find in a folder or file name
        [Parameter(Mandatory=$true,
                   HelpMessage="Enter a name of folder or file (if using -file switch)")]
        [alias("n")]
        [string]
        $name,

        # Switch to search for files instead of folders
        [Parameter()]
        [alias("f")]
        [switch]
        $file
    )

    $found = Get-ChildItem -Recurse -Force -Path $path -ErrorAction SilentlyContinue | 
	    Where-Object { ($_.PSIsContainer -ne $file) -and  ( $_.Name -like "*$name*") }
    Write-Host $found | Select-Object Name, FullName | Format-Table -AutoSize

    $found | Select-Object -Property FullName
}

<#
.SYNOPSIS
   Retrieves the last boot time for a server or array of servers.
.DESCRIPTION
   Provide a server or array of servers to retrieve the last reboot time of.
.EXAMPLE
   Get-ServerBootTime -server remoteMachine
   This command will return the last reboot time of the server named "remoteMachine" in the network
.INPUTS
   You can specify an array of computer names, <String[]>, to find the last reboot time of.
   If no paramaters are specified the machine running this function will be used.
.LINK
.NOTES
   This function will very quickly return the time a machine or group of machines last rebooted.
   It is made much more useful if you incorporate another function to populate the list of servers
   or computers in your environment. 
   
   @Author: xXBlu3f1r3Xx
   @LEDate: July 25th, 2015
   @PSVers: 2.0+
#>
function Get-ServerBootTime {
    [CmdletBinding()]
    Param (
        # Server name or array of server names
        [Parameter()]
		[alias("s")]
        [string[]]
        $servers
    )
	
	# Default to checking the current machine if no servers are provided.
	$serverList = @()
	if (!($servers)) {
		$serverList = "$env:computername"
	}
	else {
		$serverList = $servers
	}
	
	# Retrieve the last boot time for all servers passed
	$bootTime = Get-WmiObject -ComputerName $serverList win32_operatingsystem |
		Select-Object csname, @{LABEL='LastBootUpTime';EXPRESSION={$_.ConvertToDateTime($_.lastbootuptime)}}
		
	$bootTime | Format-Table -AutoSize
}

<#
.SYNOPSIS
   Searches the registry to check which users are currently logged on. Can
   also be used to search for a specific username.
.DESCRIPTION
   Provide a username to search for and servers to search on. When searching for a 
   specific user you can specify a server, or servers, to search on. If no paramaters are passed this
   will default to the current machine and providing all logged in users.
.EXAMPLE
   Get-CurrentUsers -username test_server
   This command will search for user "test_server" on the current machine.
.EXAMPLE
   Get-CurrentUsers -username testUser -servers (remoteMachine1, remoteMachine2)
   This command will search for user "testUser" on machines "remoteMachine1" and "remoteMachine2.
.EXAMPLE
   Get-CurrentUsers -servers remoteMachine
   This command will return all users currently logged in to server "remoteMachine".
.INPUTS
   You can specify a user <String> to search for, otherwise it will return all logged on users.
   You can specify an array of computer names, <String[]>, to search as well. If you don't it will 
   search the current machine.
.LINK
.NOTES
   This function will return all users logged in to all servers specified or you can choose to search
   for a particular user across an array of servers. It will return which server(s) the user is currently
   logged in to.
   
   @Author: xXBlu3f1r3Xx
   @LEDate: July 25th, 2015
   @PSVers: 2.0+
#>
function Get-CurrentUsers {
    [CmdletBinding()]
    Param (
        # Username to check for
        [Parameter()]
        [alias("user")]
        [alias("u")]
        [string]
        $username,
		
		# Server(s) to query. If not specified this function will run on the machine calling it.
		[Parameter()]
		[alias("server")]
		[alias("v")]
		[string[]]
		$servers
    )
	BEGIN {
		$serverList = @()
		if (!($servers)) {
			$serverList = $env:computername		# default to the machine running this
		}
		else {
			$serverList = $servers
		}
		
		$found = @()
		#Write-Host "Beginning search on servers..." -f yellow -b black
	}
	PROCESS {
		$found += Invoke-Command -ComputerName $serverList -ScriptBlock {
			$username = $args[0]
			$userList = New-Object System.Collections.Generic.List[PSCustomObject]
			$userFound = $false
			
			# Find registry keys for users and search the USERNAME value for a match
			$sidFormat = "^@\{Name=(HKEY_USERS\\S-\d{1}-\d{1}-\d{2}-\d{10}-\d{10}-\d{9}-\d{5})\}$"
			$userNodes = Get-ChildItem -Path "Registry::HKEY_USERS\" | Select-Object -Property Name
			$userPaths = @()
			foreach ($u in $userNodes) {
				if ($u -match $sidFormat) {
					$userPaths += "Registry::" + $Matches[1]
				}
			}
			Remove-Variable u
			
			foreach ($u in $userPaths) {
				$t = $u.SubString(21)
				$findVolatile = "^@\{Name=(HKEY_USERS\\$t\\Volatile Environment)\}$"
				$peek = Get-ChildItem $u | Select-Object -Property Name
				foreach ($p in $peek) {
					if ($p -match $findVolatile) {
						$userKey = "Registry::" + $Matches[1]
						$userKey = Get-ItemProperty -Path $userKey
						$newUser = New-Object -TypeName PSObject
						Add-Member -InputObject $newUser -MemberType NoteProperty -Name Username -Value $userKey.USERNAME
						$userList.add($newUser)
					}
				}
			}
			Remove-Variable u
			
			# Print either the list of users logged in or if the username was specified show true or false.
			$marker = -1
			if ($username) {
				foreach ($u in $userList) {
					$marker++
					if ($u.Username -like "*$username*") {
						$userFound = $true
						Break
					}
				}
			}
			elseif ($userList) {
				Return $userList
			}
			
			if ($userFound) {
				Return $userList[$marker]
			}
		} -ArgumentList $username
	}
	END {
		if ($username) {
			$found | Sort-Object -Property PSComputerName | Select-Object -ExpandProperty PSComputerName
		}
		else {
			$found | Sort-Object -Property PSComputerName | Select-Object -Property PSComputerName, Username
		}
	}
}
