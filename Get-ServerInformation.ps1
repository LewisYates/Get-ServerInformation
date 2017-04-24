############################################################################################
#                                                                                          #
#    Get-ServerInformation Returns A Table of Server Hardware Information including:       #
#                                                                                          #
#  OS - Architecture - CPU(s) - Install Date - Total Drive Space - Free Drive Space - RAM  # 
#                                                                                          #
############################################################################################
    
    
function Get-ServerInformation {

    Param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Online', 'Retail')]
        [string]$Asset,
        [Parameter(Mandatory=$true)]
        [ValidateSet('QA1','QA2','QA3','QA4','FT1', 'FT2', 'UAT1', 'UAT2', 'PROD')]
        [string]$Env
    )

    if ( $Asset -eq 'Online') {

    $Location = 'OnlineServers'
    
    } else {

    $Location = 'RetailServers'

    }

    $username = [Environment]::Username

    $serverList = (@{
    FT1 = @(Get-Content -Path C:\Users\$username\Desktop\ServerScripts\$Location\ft1.txt)
    FT2 = @(Get-Content -Path C:\Users\$username\Desktop\ServerScripts\$Location\ft2.txt)
    UAT1 = @(Get-Content -Path C:\Users\$username\Desktop\ServerScripts\$Location\uat1.txt)
    UAT2 = @(Get-Content -Path C:\Users\$username\Desktop\ServerScripts\$Location\uat2.txt)
    PROD = @(Get-Content -Path C:\Users\$username\Desktop\ServerScripts\$Location\prod.txt)
	QA1 = @(Get-Content -Path C:\Users\$username\Desktop\ServerScripts\$Location\qa1.txt)
	QA2 = @(Get-Content -Path C:\Users\$username\Desktop\ServerScripts\$Location\qa2.txt)
	QA3 = @(Get-Content -Path C:\Users\$username\Desktop\ServerScripts\$Location\qa3.txt)
	QA4 = @(Get-Content -Path C:\Users\$username\Desktop\ServerScripts\$Location\qa4.txt)
    })[$Env]

    #CLS


     ######################################################################################
     #                                                                                    #
     #    Before getting data for servers in the .txt files, get data from own server     #
     #                                                                                    #
     ######################################################################################

    	    #Operating System
  	        $ComputerName = (Get-WmiObject Win32_OperatingSystem).Caption

  	        #Server Host Name
  	        $OSName = (Get-WmiObject Win32_ComputerSystem).Name

  	        #OS Architecture (32/64-Bit)
  	        $Architecture = (Get-WmiObject Win32_OperatingSystem).OSArchitecture

  	        #CPU
  	        $CPU = Get-WmiObject Win32_processor | select -ExpandProperty Name
            
            #For repeating processors, reduce it to one 'unique' CPU
            $CPUReduce = ($CPU | select -Unique)
            #Count the number of CPUs in the server (which are later appended by x'n')
            $CPUNo = ($CPU).count
            
  	        #Date of Installation
  	        $Install = (Get-WmiObject Win32_OperatingSystem).InstallDate
            $InstallDate = ([WMI] '').ConvertToDateTime($Install)

  	        #Total HDD Capacity
  	        $drives  = Get-WmiObject win32_logicaldisk| ?{$_.drivetype -eq 3} | foreach-object {$_.name + "\: " + [math]::Round(($_.Size)/1GB)+"GB"}
        
            #Total Free Space for each drive/disk
  	        $freeSpace  = Get-WmiObject win32_logicaldisk| ?{$_.drivetype -eq 3} | foreach-object {
            if ($_.FreeSpace -le 2GB){

            $_.name + "\: " + [math]::Round(($_.FreeSpace)/1MB)+"MB"

            } else {

            $_.name + "\: " + [math]::Round($_.FreeSpace/1GB)+"GB"

            }}

  	        #Total RAM
	        [long]$memory = 0
	        # Get the WMI class Win32_PhysicalMemory and total the capacity of all installed memory modules
	        Get-WmiObject -Class Win32_PhysicalMemory | ForEach-Object -Process { $memory += $_.Capacity }

	        # Display the output in Gigabyte + Append 'GB'
            $RAM = ($memory/1GB).ToString() + "GB"

	        #Server Status
  	        $Status = (Get-WmiObject Win32_ComputerSystem).Status
  	        #Write-Host "Status: " $Status -ForegroundColor Green
	        Write-Host ""

            ########################################################
            #                                                      #
            #   Create A Table To Display Data For Each Server     #
            #                                                      #
            ########################################################

            Write-Host "====="$OSName “Hardware written to" $Env ".txt file on Desktop=====” -BackgroundColor Blue

            #Create Table object
            $table = New-Object system.Data.DataTable “$tabName”

            #Define Columns
            $col1 = New-Object system.Data.DataColumn HostName,([string])
            $col2 = New-Object system.Data.DataColumn OperatingSystem,([string])
            $col3 = New-Object system.Data.DataColumn OSArchitecture,([string])
            $col4 = New-Object system.Data.DataColumn CPU,([string])
            $col5 = New-Object system.Data.DataColumn InstallDate,([string])
            $col6 = New-Object system.Data.DataColumn LocalDrivesTotalSpace,([string])
            $col7 = New-Object system.Data.DataColumn LocalDrivesFreeSpace,([string])
            $col8 = New-Object system.Data.DataColumn RAM,([string])
            

            #Add the Columns
            $table.columns.add($col1)
            $table.columns.add($col2)
            $table.columns.add($col3)
            $table.columns.add($col4)
            $table.columns.add($col5)
            $table.columns.add($col6)
            $table.columns.add($col7)
            $table.columns.add($col8)


            #Create a row
            $row = $table.NewRow()

            #Enter data in the row
            $row.HostName = $OSName 
            $row.OperatingSystem = $ComputerName 
            $row.OSArchitecture = $Architecture
            
            #If there is more than one of the same CPU, collate them (e.g. Intel(R) Xeon(R) CPU E5-2630 0 @ 2.30GHz x4)
            if ($CPUNo -gt 1){
                $CPUCondensed = $CPUReduce + " x" + $CPUNo
                $row.CPU = [string]$CPUCondensed

            } 
            
            #Otherwise, display the single CPU
            else {
            $row.CPU = [string]$CPU
            }

            $row.InstallDate = $InstallDate
            $row.LocalDrivesTotalSpace = [string]$drives 
            $row.LocalDrivesFreeSpace = [string]$freeSpace
            $row.RAM = $RAM

            #Add the row to the table
            $table.Rows.Add($row)

            #Display the table (interactively and to file)

	        $username = [Environment]::UserName

            $firstOutput = ($table | Format-Table -Wrap) | Out-File -FilePath C:\Users\$username\Desktop\$Env.txt

            #===========END===========#


   $output = ForEach($server in $serverList){

        Invoke-Command -ComputerName $server -ScriptBlock {

  	        #Operating System
  	        $ComputerName = (Get-WmiObject Win32_OperatingSystem).Caption

  	        #Server Host Name
  	        $OSName = (Get-WmiObject Win32_ComputerSystem).Name

  	        #OS Architecture (32/64-Bit)
  	        $Architecture = (Get-WmiObject Win32_OperatingSystem).OSArchitecture

  	        #CPU
  	        $CPU = Get-WmiObject Win32_processor | select -ExpandProperty Name

            $CPUReduce = ($CPU | select -Unique)
            $CPUNo = ($CPU).count
            
  	        #Date of Installation
  	        $Install = (Get-WmiObject Win32_OperatingSystem).InstallDate
            $InstallDate = ([WMI] '').ConvertToDateTime($Install)

  	        #Total HDD Capacity for each drive/disk
  	        $drives  = Get-WmiObject win32_logicaldisk| ?{$_.drivetype -eq 3} | foreach-object {$_.name + "\: " + [math]::Round(($_.Size)/1GB)+"GB"}
        
            #Total Free Space for each drive/disk
  	        $freeSpace  = Get-WmiObject win32_logicaldisk| ?{$_.drivetype -eq 3} | foreach-object {
            if ($_.FreeSpace -le 2GB){

            $_.name + "\: " + [math]::Round(($_.FreeSpace)/1MB)+"MB"

            } else {

            $_.name + "\: " + [math]::Round($_.FreeSpace/1GB)+"GB"

            }}

  	        #Total RAM
	        [long]$memory = 0
	        # Get the WMI class Win32_PhysicalMemory and total the capacity of all installed memory modules
	        Get-WmiObject -Class Win32_PhysicalMemory | ForEach-Object -Process { $memory += $_.Capacity }

	        # Display the output in Gigabyte + Append 'GB'
            $RAM = ($memory/1GB).ToString() + "GB"

	        #Server Status
  	        $Status = (Get-WmiObject Win32_ComputerSystem).Status
  	        #Write-Host "Status: " $Status -ForegroundColor Green
	        Write-Host ""


            ########################################################
            #                                                      #
            #   Create A Table To Display Data For Each Server     #
            #                                                      #
            ########################################################

            Write-Host "====="$OSName “Hardware written to .txt file on Desktop=====” -BackgroundColor Blue

            #Create Table object
            $table = New-Object system.Data.DataTable “$tabName”

             #Define Columns
            $col1 = New-Object system.Data.DataColumn HostName,([string])
            $col2 = New-Object system.Data.DataColumn OperatingSystem,([string])
            $col3 = New-Object system.Data.DataColumn OSArchitecture,([string])
            $col4 = New-Object system.Data.DataColumn CPU,([string])
            $col5 = New-Object system.Data.DataColumn InstallDate,([string])
            $col6 = New-Object system.Data.DataColumn LocalDrivesTotalSpace,([string])
            $col7 = New-Object system.Data.DataColumn LocalDrivesFreeSpace,([string])
            $col8 = New-Object system.Data.DataColumn RAM,([string])
            

            #Add the Columns
            $table.columns.add($col1)
            $table.columns.add($col2)
            $table.columns.add($col3)
            $table.columns.add($col4)
            $table.columns.add($col5)
            $table.columns.add($col6)
            $table.columns.add($col7)
            $table.columns.add($col8)


            #Create a row
            $row = $table.NewRow()

            #Enter data in the row
            $row.HostName = $OSName 
            $row.OperatingSystem = $ComputerName 
            $row.OSArchitecture = $Architecture
            
            #If there is more than one of the same CPU, collate them (e.g. Intel(R) Xeon(R) CPU E5-2630 0 @ 2.30GHz x4)
            if ($CPUNo -gt 1){
                $CPUCondensed = $CPUReduce + " x" + $CPUNo
                $row.CPU = [string]$CPUCondensed

            } 
            
            #Otherwise, display the single CPU
            else {
            $row.CPU = [string]$CPU
            }

            $row.InstallDate = $InstallDate
            $row.LocalDrivesTotalSpace = [string]$drives 
            $row.LocalDrivesFreeSpace = [string]$freeSpace
            $row.RAM = $RAM

            #Add the row to the table
            $table.Rows.Add($row)

            #Display the table
            $table | Format-Table -Wrap

        }
    }

    $username = [Environment]::UserName

    $output | Out-File -FilePath C:\Users\$username\Desktop\$Env.txt -Append


}
