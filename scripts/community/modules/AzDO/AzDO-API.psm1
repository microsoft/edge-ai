# AzDO-API.psm1
# Azure DevOps API helper functions

function Invoke-AzureDevOpsApi {
    <#
    .SYNOPSIS
    Makes a REST API call to Azure DevOps.

    .DESCRIPTION
    Helper function to make REST API calls to Azure DevOps with proper error handling.

    .PARAMETER Uri
    The full URI for the API endpoint.

    .PARAMETER Method
    The HTTP method to use (GET, POST, PATCH, DELETE).

    .PARAMETER Headers
    Authentication headers to include in the request.

    .PARAMETER Body
    Optional. The request body for POST/PATCH operations (as a hashtable).

    .OUTPUTS
    PSObject. Returns the deserialized JSON response from the API call.

    .EXAMPLE
    $response = Invoke-AzureDevOpsApi -Uri "https://dev.azure.com/org/project/_apis/git/repositories" -Method "GET" -Headers $authHeaders

    .NOTES
    This function handles common error patterns and provides more detailed error messages.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [Parameter(Mandatory = $true)]
        [ValidateSet("GET", "POST", "PATCH", "DELETE")]
        [string]$Method,

        [Parameter(Mandatory = $true)]
        [hashtable]$Headers,

        [Parameter(Mandatory = $false)]
        [hashtable]$Body = $null
    )

    try {
        Write-Verbose "Making API call to: $Uri with method: $Method"
        $params = @{
            Uri     = $Uri
            Method  = $Method
            Headers = $Headers
            ContentType = "application/json"
            ErrorAction = "Stop"
        }

        # Add body for POST/PATCH requests if provided, POST is required for some API calls
        if ($Body -and ($Method -eq "POST" -or $Method -eq "PATCH")) {
            $jsonBody = $Body | ConvertTo-Json -Depth 10
            $params.Add("Body", $jsonBody)
        }

        # Make the API call
        $response = Invoke-RestMethod @params
        return $response
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $message = $_.Exception.Message

        # Throw a custom error with more information
        throw "Azure DevOps API call failed (Status code: $statusCode): $message. Details: $detailedMessage"
    }
}

function Get-AzureDevOpsItem {
    <#
    .SYNOPSIS
    Makes repeated API calls to get all items when the API returns paginated results.

    .DESCRIPTION
    Helper function that makes repeated API calls to fetch all results from a paginated API.
    It will continue making calls until a page returns fewer items than the page size.

    .PARAMETER Uri
    The base URI for the API endpoint with initial query parameters.

    .PARAMETER Headers
    Authentication headers to include in the request.

    .PARAMETER PageSize
    Number of items to request per page. Default is 100.

    .PARAMETER MaxResults
    Maximum number of results to return. Default is 0 (all).

    .OUTPUTS
    Array. Returns an array of items retrieved from the API.

    .EXAMPLE
    $allPRs = Get-AzureDevOpsItem -Uri "https://dev.azure.com/org/project/_apis/git/pullrequests?api-version=7.0" -Headers $authHeaders

    .NOTES
    This function uses a simple approach of continuing to make calls until we get fewer results than the page size.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [Parameter(Mandatory = $true)]
        [hashtable]$Headers,

        [Parameter(Mandatory = $false)]
        [int]$PageSize = 100,

        [Parameter(Mandatory = $false)]
        [int]$MaxResults = 0
    )

    # Add page size parameter if not already present
    if (-not $Uri.Contains("`$top=")) {
        $delimiter = if ($Uri.Contains("?")) { "&" } else { "?" }
        $Uri = "$Uri$delimiter`$top=$PageSize"
    }

    Write-Verbose "Starting to fetch items from $Uri"

    $allItems = @()
    $hasMoreItems = $true
    $skip = 0
    $apiCallCounter = 0
    $maxApiCalls = 100 # Safety limit

    while ($hasMoreItems -and $apiCallCounter -lt $maxApiCalls) {
        $apiCallCounter++

        # Build URI with current skip value
        $currentUri = $Uri
        if ($currentUri.Contains("`$skip=")) {
            $currentUri = $currentUri -replace "`\$skip=\d+", "`$skip=$skip"
        } else {
            $delimiter = if ($currentUri.Contains("?")) { "&" } else { "?" }
            $currentUri = "$currentUri$delimiter`$skip=$skip"
        }

        Write-Verbose "API call #$($apiCallCounter): Fetching items with skip=$skip from $currentUri"

        try {
            $response = Invoke-AzureDevOpsApi -Uri $currentUri -Method "GET" -Headers $Headers

            if ($response.value -and $response.value.Count -gt 0) {
                $currentPageCount = $response.value.Count
                Write-Verbose "Retrieved $currentPageCount items"

                $allItems += $response.value

                # Continue only if we received a full page of results
                $hasMoreItems = $currentPageCount -eq $PageSize
                $skip += $PageSize

                # Check if we've reached the desired max results
                if ($MaxResults -gt 0 -and $allItems.Count -ge $MaxResults) {
                    Write-Verbose "Reached max results limit ($MaxResults items)"
                    $allItems = $allItems[0..($MaxResults-1)]
                    $hasMoreItems = $false
                }
            } else {
                $hasMoreItems = $false
                Write-Verbose "No more items returned from API, ending loop"
            }
        } catch {
            Write-Error "Error fetching items: $($_)"
            $hasMoreItems = $false
        }
    }

    if ($apiCallCounter -ge $maxApiCalls) {
        Write-Warning "Reached maximum number of API calls ($maxApiCalls). There might be more items available."
    }

    Write-Verbose "Total items retrieved: $($allItems.Count)"
    return $allItems
}

# Export the functions
Export-ModuleMember -Function @(
    'Get-AzureDevOpsItem',
    'Invoke-AzureDevOpsApi'
)
