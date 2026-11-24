#!/usr/bin/env pwsh
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT
#Requires -Version 7.4

<#
.SYNOPSIS
    Installs and imports PowerShell modules at the exact versions pinned in a manifest.

.DESCRIPTION
    Reads ps-module-versions.json and, for each requested module, installs the pinned
    version from PowerShell Gallery when it is not already available, retrying failed
    installs with increasing delays. Each module is then imported with -RequiredVersion;
    the script fails when the pinned version cannot be loaded, so a restored cache
    holding a different version never passes silently.

.PARAMETER Name
    Module names to install. Every name must exist in the manifest. When omitted or
    empty, every manifest module is installed.

.PARAMETER ManifestPath
    Path to the module version manifest.

.PARAMETER MaxAttempts
    Maximum install attempts per module.

.PARAMETER InitialDelaySeconds
    Delay before the second attempt; each later delay doubles.

.EXAMPLE
    ./scripts/security/Install-PSModules.ps1

.EXAMPLE
    ./scripts/security/Install-PSModules.ps1 -Name powershell-yaml

.NOTES
    Used by the .github/actions/setup-ps-modules composite action.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [AllowEmptyCollection()]
    [string[]]$Name = @(),

    [Parameter(Mandatory = $false)]
    [string]$ManifestPath = (Join-Path $PSScriptRoot 'ps-module-versions.json'),

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 10)]
    [int]$MaxAttempts = 3,

    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 300)]
    [int]$InitialDelaySeconds = 10
)

$ErrorActionPreference = 'Stop'

#region Functions

function Get-PinnedModuleSet {
    <#
    .SYNOPSIS
        Returns the requested manifest entries as name and version pairs.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath,

        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [string[]]$Name = @()
    )

    if (-not (Test-Path -Path $ManifestPath -PathType Leaf)) {
        throw "Module manifest not found: $ManifestPath"
    }

    $manifest = Get-Content -Path $ManifestPath -Raw | ConvertFrom-Json
    if ($null -eq $manifest.modules) {
        throw "Module manifest has no 'modules' object: $ManifestPath"
    }

    $entries = foreach ($property in $manifest.modules.PSObject.Properties) {
        $version = [string]$property.Value.version
        if ([string]::IsNullOrWhiteSpace($version)) {
            throw "Module '$($property.Name)' has no version in $ManifestPath"
        }
        [pscustomobject]@{ Name = $property.Name; Version = $version }
    }

    $requested = @($Name | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    if ($requested.Count -eq 0) {
        return @($entries)
    }

    $unknown = @($requested | Where-Object { $_ -notin $entries.Name })
    if ($unknown.Count -gt 0) {
        throw "Modules not in manifest: $($unknown -join ', ')"
    }

    return @($entries | Where-Object { $_.Name -in $requested })
}

function Install-PinnedModule {
    <#
    .SYNOPSIS
        Installs one module at an exact version with retries, then imports that version.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Version,

        [Parameter(Mandatory = $true)]
        [int]$MaxAttempts,

        [Parameter(Mandatory = $true)]
        [int]$InitialDelaySeconds
    )

    $available = Get-Module -ListAvailable -Name $Name |
        Where-Object { $_.Version -eq [version]$Version }

    if ($available) {
        Write-Host "$Name $Version already installed"
    }
    else {
        $delay = $InitialDelaySeconds
        for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
            try {
                Install-PSResource -Name $Name -Version $Version -Repository PSGallery -Scope CurrentUser -TrustRepository -ErrorAction Stop
                Write-Host "Installed $Name $Version"
                break
            }
            catch {
                if ($attempt -ge $MaxAttempts) {
                    throw "Failed to install $Name $Version after $MaxAttempts attempts: $($_.Exception.Message)"
                }
                Write-Warning "Install of $Name $Version failed (attempt $attempt/$MaxAttempts): $($_.Exception.Message). Retrying in $delay seconds."
                Start-Sleep -Seconds $delay
                $delay *= 2
            }
        }
    }

    try {
        Import-Module -Name $Name -RequiredVersion $Version -Force -ErrorAction Stop
    }
    catch {
        throw "Failed to import $Name $Version`: $($_.Exception.Message)"
    }
    Write-Host "Imported $Name $Version"
}

function Invoke-PSModuleInstall {
    <#
    .SYNOPSIS
        Installs and imports every requested manifest module.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ManifestPath,

        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [string[]]$Name = @(),

        [Parameter(Mandatory = $true)]
        [int]$MaxAttempts,

        [Parameter(Mandatory = $true)]
        [int]$InitialDelaySeconds
    )

    foreach ($module in Get-PinnedModuleSet -ManifestPath $ManifestPath -Name $Name) {
        Install-PinnedModule -Name $module.Name -Version $module.Version -MaxAttempts $MaxAttempts -InitialDelaySeconds $InitialDelaySeconds
    }
}

#endregion Functions

#region Main Execution

if ($MyInvocation.InvocationName -ne '.') {
    try {
        Invoke-PSModuleInstall -ManifestPath $ManifestPath -Name $Name -MaxAttempts $MaxAttempts -InitialDelaySeconds $InitialDelaySeconds
        exit 0
    }
    catch {
        Write-Error -ErrorAction Continue "Install-PSModules failed: $($_.Exception.Message)"
        exit 1
    }
}

#endregion Main Execution
