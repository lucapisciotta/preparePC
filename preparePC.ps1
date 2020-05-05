#Requires -Version 5.0
#Requires -RunAsAdministrator
<#
.SYNOPSIS
  <Overview of script>
.DESCRIPTION
  <Brief description of script>
.PARAMETER <Parameter_Name>
    <Brief description of parameter input required. Repeat this attribute if required>
.NOTES
  Version:        1.0
  Author:         Luca Pisciotta
  Creation Date:  2020-05-04
  Purpose/Change: Initial script development
#>

# Enable Insecure script
$PolicyStatus = Get-ExecutionPolicy
if ($PolicyStatus -eq 'RemoteSigned') {
  try {
    Write-Host '!!! WARNING !!! - I''m trying to change your Execution Policy to permit to use choco correctly and run scripts ' -ForegroundColor red
    Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force -ErrorAction Stop
  }
  catch {
    Write-Host 'Seems something doesn''t work, try again manually' -ForegroundColor red
    Write-Host $_
    exit 1
  }
} else {
  Write-Host 'You''re Execution Policy is already setted to'$PolicyStatus -Foreground green
}

# Install choco, an utility to manage some software
$chocoCheck = powershell choco -v
if (-not($chocoCheck)) {
  Write-Host 'Seems Chocolatey is not installed, installing now' -ForegroundColor yellow
  [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression
} else {
  Write-Host 'Chocolotey Version'$chocoCheck 'is already installed' -Foreground green
}

# Reload PROFILE
Write-Host 'Reloading your profile...' -ForegroundColor yellow
RefreshEnv.cmd

# Configure choco
$FeaturesDisabled = @(
  'showDownloadProgress'
)

$FeaturesDisabled | ForEach-Object {
  $FeatureStatus = choco feature list | Select-String -Pattern $_ | Where-Object {$_ -eq '[ ]'}
  if (-not($FeatureStatus)) {
    choco feature disable -n $_
  }
}

$FeaturesEnabled = @(
  'allowGlobalConfirmation',
  'useRememberedArgumentsForUpgrades',
  'removePackageInformationOnUninstall'
)

$FeaturesEnabled | ForEach-Object {
  $FeatureStatus = choco feature list | Select-String -Pattern $_ | Where-Object {$_ -eq '[ ]'}
  if (-not($FeatureStatus)) {
    choco feature enable -n $_
  }
}

# Install software with choco
$SoftwareList = @(
  '7zip',
  'adobereader',
  'awscli',
  'calibre',
  'ccleaner',
  'chocolatey',
  'chocolatey-core.extension',
  'curl',
  'eartrumpet',
  'flashplayerplugin',
  'git',
  'git-credential-winstore',
  'java-runtime',
  'lastpass',
  'microsoft-edge',
  'openvpn',
  'poshgit',
  'powershell-core',
  'quicklook',
  'skype',
  'steam',
  'sysinternals',
  'tixati',
  'vlc',
  'vnc-viewer',
  'vscode'
  )

$SoftwareList | ForEach-Object {
  $SoftwareStatus =  choco list --localonly | Select-String -Pattern $_
  if (-not($SoftwareStatus)) {
    try {
      Write-Host 'Installing'$_ -ForegroundColor cyan 
      choco install $_  -ErrorAction stop
      Write-Host $_ 'installed' -ForegroundColor green -ErrorAction stop
    }
    catch {
      Write-Host 'There are some problems with'$_ -ForegroundColor red
    }
  } else {
      $UpgradeNeed = choco upgrade $_ --noop
      if ($UpgradeNeed -match 'is the latest version') {
        Write-Host $_ 'installed and upgraded'
      } else {
        try {
          Write-Host 'Upgrading'$_
          choco upgrade $_  -ErrorAction stop
        }
        catch {
          Write-Host 'There are some problems with'$_ -ForegroundColor red
        }
      }

  }
}

# Set an hostname to your Wokstation

$ActualWorkstationName = Invoke-Expression hostname
Write-Host 'Actual workstation name is' $ActualWorkstationName', do you want to change it? (Default is No)' -ForegroundColor yellow
$ChangeChoose = Read-Host ' ( y / n )'
switch ($ChangeChoose) {
  y {
    $HOSTNAME = Read-Host -Prompt 'Choose an hostname for this PC:'
    Rename-Computer -Force -NewName $HOSTNAME -Restart
  }
  n {Write-Host 'Ok, nothing to change, bye...'}
  Default {Write-Host 'Ok, nothing to change, bye...'}
}