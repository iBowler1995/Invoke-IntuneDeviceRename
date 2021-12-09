<#	
  .NOTES
  ===========================================================================
   Created by:   	iBowler1995
   Filename:     	Invoke-IntuneDeviceRename.ps1
  ===========================================================================
  .DESCRIPTION
    This script uses the Graph API to bulk rename Windows devices. It can for 
    example be used in a scenario where autopilot default naming has been used
    and a new standardised naming convention has been agreed upon.


  .EXAMPLE
    Invoke-IntuneDeviceRename.ps1 -MachineType "Desktop" 

#>
param
(
[parameter(Mandatory = $true)]
[ValidateSet('Desktop', 'Laptop','VSI')]   [string]$MachineType    
 ) 

TRY {
  
  # Checking for Graph API
  if ((Get-Module Microsoft.Graph.Intune) -eq $null) {
    # Install Graph API PowerShell cmdlets
    Install-Module -Name Microsoft.Graph.Intune
  }
  
  # Connect to Graph API
  Write-Host "Connecting to Graph API" 
  $GraphConnection = Connect-MSGraph
  
  if (-not ([string]::IsNullOrEmpty($GraphConnection.TenantID))) {
    # Set computer naming convention
    switch ($MachineType) {
      "Desktop" {
        $NewDeviceName = "VSI-{{rand:4}}"
      }
      "Laptop" {
        $NewDeviceName = "VSI-{{rand:4}}"
      }
      "VSI"{
          $NewDeviceName = "VSI-{{rand:4}}"
      }
    }
    
    # Get list of devices to rename from Graph
    Write-Host "Obtaining list of devices to rename"
    if ($MachineType -eq "Desktop" -or $MachineType -eq "Laptop"){
        $DevicesToRename = Get-IntuneManagedDevice -filter "(Contains(deviceName, '$MachineType'))"
    }
    elseif ($MachineType -eq "VSI"){
        $DevicesToRename = Get-IntuneManagedDevice | where {$_.deviceName -like "vsi*" -and $_.deviceName.length -eq 7}
    }
    Write-Host "Found $($DevicesToRename.Count) devices beginning with $MachineType" -Foregroundcolor Green
    
    if ($DevicesToRename.Count -gt 0) {
      # Loop through devices
      Foreach ($Device in $DevicesToRename) {
        # Set graph URI to post data to
        $DeviceID = $Device.ID
        $Resource = "deviceManagement/managedDevices('$DeviceID')/setDeviceName"
        $GraphApiVersion = "Beta"
        $URI = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
        
        Write-Host "Applying new naming convention logic for $($Device.DeviceName)" -Foregroundcolor Cyan
        
          $JSONPayload = @"
{
deviceName:"$NewDeviceName"
}
"@
        
        # Post updated computer name via Graph API	
        if (-not ([string]::IsNullOrEmpty($NewDeviceName))) {
          Write-Host "Updating machine name $($Device.DeviceName) with device ID $DeviceID" -Foregroundcolor Cyan
          Write-Host "Device primary user listed as $($Device.userDisplayName)"
          Write-Host "New computer name will use the format $NewDeviceName" -Foregroundcolor Green
          Write-Host "Posting data to $URI" -Foregroundcolor Cyan
          
          Invoke-MSGraphRequest -HttpMethod POST -Url $uri -Content $JSONPayload -Verbose -ErrorAction SilentlyContinue
        } else {
          Write-Host "Device $($Device.DeviceName) did not meeting matching criteria" -Foregroundcolor Red
          Write-Host "Device $($Device.DeviceName) did not meeting matching criteria" -Foregroundcolor Red
        }
        
        # Clear payload information
        $URI = $null
        $JSONPayload = $null
      }
    }
  }else {
    Write-Host "Unable to connect to MS Graph service. Aborting." -Foregroundcolor Red
  }
} catch [System.Exception] {
  Write-Host "$($_.Exception.Message)" -Foregroundcolor Red
}
