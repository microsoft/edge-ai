# AzDO-Auth.psm1
# Authentication functions for Azure DevOps

function Get-AzureDevOpsPAT {
    <#
    .SYNOPSIS
    Retrieves a Personal Access Token (PAT) for Azure DevOps authentication.

    .DESCRIPTION
    Gets a Personal Access Token for Azure DevOps either from the provided parameter or
    from the AZURE_DEVOPS_PAT environment variable.

    .PARAMETER PersonalAccessToken
    Optional. The PAT token to use. If not provided, the function will look for the
    AZURE_DEVOPS_PAT environment variable.

    .OUTPUTS
    System.String. Returns the Personal Access Token as a string.

    .EXAMPLE
    $pat = Get-AzureDevOpsPAT
    $pat = Get-AzureDevOpsPAT -PersonalAccessToken "your-pat-token"

    .NOTES
    For security best practices, it's recommended to use environment variables rather
    than passing tokens directly in scripts.
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $false)]
        [string]$PersonalAccessToken = ""
    )

    # If PAT is provided directly, use it
    if ($PersonalAccessToken -and $PersonalAccessToken -ne "") {
        return $PersonalAccessToken
    }

    # Otherwise, try to get it from environment variables
    $pat = [System.Environment]::GetEnvironmentVariable("AZURE_DEVOPS_PAT")

    if (-not $pat -or $pat -eq "") {
        throw "Personal Access Token not provided and AZURE_DEVOPS_PAT environment variable not set."
    }

    return $pat
}

function Get-AzureDevOpsAuthHeader {
    <#
    .SYNOPSIS
    Creates an authentication header for Azure DevOps REST API calls.

    .DESCRIPTION
    Creates a hashtable containing the authorization header required for
    Azure DevOps REST API calls using Basic Authentication with a PAT.

    .PARAMETER Token
    The Personal Access Token for Azure DevOps.

    .EXAMPLE
    $headers = Get-AzureDevOpsAuthHeader -Token $patToken

    .NOTES
    Azure DevOps REST API uses Basic Authentication with the PAT as the password
    and an empty username.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Token
    )

    if ($PSCmdlet.ShouldProcess("Creating Azure DevOps Auth Header")) {
        # Basic authentication with PAT requires using empty username and PAT as password
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$Token"))

        # Return a hashtable with the authorization header
        return @{
            Authorization = "Basic $base64AuthInfo"
        }
    }
}

# Export the functions
Export-ModuleMember -Function @(
    'Get-AzureDevOpsPAT',
    'Get-AzureDevOpsAuthHeader'
)
