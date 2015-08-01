# PSTools
A collection of Powershell tools I have developed. The plan is to continually update these tools and add more as I build them.

# HandleTools.psm1
Contains three functions, <b>New-Handle</b>, <b>Get-Handle</b>, and <b>Close-Handle</b> which utilize the output and 
capabilities of SysInternal's Handle.exe to search for open file handles and close them. These functions were created 
to deal with the pesky stuck file handles I come across in my server environment. Although useful from the command line 
they really shine when used in scripts combined with other functions I commonly use.

# ServerToolsV1.psm1
Contains three functions, <b>Search-ForItem</b>, <b>Get-ServerBootTime</b>, and <b>Get-CurrentUsers</b> which are short 
but useful tools for easily grabbing important information.

# Function List
* New-Handle
* Get-Handle
* Close-Handle
* Search-ForItem
* Get-ServerBootTime
* Get-CurrentUsers
