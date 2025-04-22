# Import the AzDO-Types module
using module "./AzDO-Types.psm1"

function Get-RepositoryId {
    <#
    .SYNOPSIS
    Retrieves the Azure DevOps repository ID by name or returns the ID directly.

    .DESCRIPTION
    This function gets a repository ID from Azure DevOps. It can handle both direct repository IDs
    and repository names.

    .PARAMETER Params
    An AzDOApiParameters object containing the required Azure DevOps connection parameters.

    .OUTPUTS
    System.String. The repository ID if found, otherwise returns $null.

    .EXAMPLE
    $params = [AzDOApiParameters]::new("MyOrg", "MyProject", "edge-ai", $authHeaders, "api-version=7.0")
    $repoId = Get-RepositoryId -Params $params
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [AzDOApiParameters]$Params
    )

    # Validate parameters
    if (-not $Params.Validate()) {
        Write-Error "Invalid API parameters provided"
        return $null
    }

    # If the repository is a name, look it up
    Write-Verbose "Looking up repository ID for '$($Params.Repository)'"
    $reposUrl = "$($Params.GetBaseApiUrl())/git/repositories?$($Params.ApiVersion)"

    try {
        $repos = Invoke-AzureDevOpsApi -Uri $reposUrl -Method "GET" -Headers $Params.Headers
        $targetRepo = $repos.value | Where-Object { $_.name -eq $Params.Repository }

        if ($targetRepo) {
            Write-Verbose "Found '$($Params.Repository)' repository with ID: $($targetRepo.id)"
            return $targetRepo.id
        } else {
            Write-Warning "Could not find '$($Params.Repository)' repository."
            return $null
        }
    } catch {
        Write-Warning "Error retrieving repositories: $_"
        return $null
    }
}
function Get-PullRequestList {
    <#
    .SYNOPSIS
    Retrieves a list of pull requests from Azure DevOps.

    .DESCRIPTION
    Gets a list of pull requests for a specific project in an Azure DevOps organization,
    with optional filtering by status.

    .PARAMETER Params
    An AzDOApiParameters object containing the required Azure DevOps connection parameters.

    .PARAMETER Status
    Optional. The status of pull requests to retrieve: 'active', 'completed', 'abandoned', or 'all'. Default is 'all'.

    .PARAMETER MaxPRs
    Optional. Maximum number of pull requests to retrieve. Default is 0 (all).

    .PARAMETER ReturnTypedObjects
    Optional. If set to true, returns AzDOPullRequest objects instead of raw API response. Default is true.

    .EXAMPLE
    $params = [AzDOApiParameters]::new("MyOrg", "MyProject", "edge-ai", $authHeaders, "api-version=7.0")
    $pullRequests = Get-PullRequestList -Params $params -Status "completed" -MaxPRs 100

    .NOTES
    This function uses the Azure DevOps REST API to retrieve pull requests.
    #>
    [CmdletBinding()]
    [OutputType([AzDOPullRequest[]])]
    param(
        [Parameter(Mandatory=$true)]
        [AzDOApiParameters]$Params,

        [Parameter(Mandatory=$false)]
        [ValidateSet("active", "completed", "abandoned", "all")]
        [string]$Status = "all",

        [Parameter(Mandatory=$false)]
        [int]$MaxPRs = 500
    )

    try {
        # Build the query URL
        $apiUrlBase = "$($Params.GetBaseApiUrl())/git/pullrequests"
        $queryUrl = "${apiUrlBase}?$($Params.ApiVersion)"

        # Include the status filter, this defaults to 'all' if not specified
        $queryUrl += "&searchCriteria.status=$Status"

        # Filter to only include PRs that target main branch
        $queryUrl += "&searchCriteria.targetRefName=refs/heads/main"

        $repoId = Get-RepositoryId -Params $Params
        Write-Verbose "Filtering PRs by repository ID: $repoId"
        $queryUrl += "&searchCriteria.repositoryId=$repoId"

        # Get PRs using our loop-based approach
        Write-Verbose "Retrieving pull requests from: $queryUrl"
        $pullRequestsResponse = Get-AzureDevOpsItem -Uri $queryUrl -Headers $Params.Headers -MaxResults $MaxPRs

        if ($null -eq $pullRequestsResponse -or $pullRequestsResponse.Count -eq 0) {
            Write-Warning "No pull requests found with status '$Status'."
            return [AzDOPullRequest[]]@()
        }

        Write-Verbose "Retrieved $($pullRequestsResponse.value.Count) pull requests."

        [AzDOPullRequest[]]$prs = @()

        foreach ($prData in $pullRequestsResponse) {
            $pr = [AzDOPullRequest]::new()

            # Basic properties
            $pr.Id = $prData.pullRequestId
            $pr.PullRequestId = $prData.pullRequestId
            $pr.Title = $prData.title
            $pr.Description = $prData.description
            $pr.Status = $prData.status
            $pr.MergeStatus = $prData.mergeStatus
            $pr.MergeId = $prData.mergeId
            $pr.Url = $prData.url
            $pr.CodeReviewId = $prData.codeReviewId
            $pr.SupportsIterations = $prData.supportsIterations
            $pr.IsDraft = $prData.isDraft

            # Repository information
            $pr.RepositoryId = $prData.repository.id
            $pr.RepositoryName = $prData.repository.name
            $pr.RepositoryUrl = $prData.repository.url

            # Branch information
            $pr.SourceRefName = $prData.sourceRefName
            $pr.TargetRefName = $prData.targetRefName
            $pr.SourceBranch = $prData.sourceRefName -replace "refs/heads/", ""
            $pr.TargetBranch = $prData.targetRefName -replace "refs/heads/", ""

            # Author information
            $pr.CreatedById = $prData.createdBy.id
            $pr.CreatedByName = $prData.createdBy.displayName
            $pr.CreatedByDisplayName = $prData.createdBy.displayName
            $pr.CreatedByEmail = $prData.createdBy.uniqueName
            $pr.CreatedByUniqueName = $prData.createdBy.uniqueName
            $pr.CreatedByImageUrl = $prData.createdBy.imageUrl

            # Commit information
            $pr.LastMergeCommit = if ($prData.lastMergeCommit) { [AzDOPullRequestCommit]::new($prData.lastMergeCommit) } else { $null }
            $pr.LastMergeSourceCommit = if ($prData.lastMergeSourceCommit) { [AzDOPullRequestCommit]::new($prData.lastMergeSourceCommit) } else { $null }
            $pr.LastMergeTargetCommit = if ($prData.lastMergeTargetCommit) { [AzDOPullRequestCommit]::new($prData.lastMergeTargetCommit) } else { $null }

            # Dates - handling potential null values
            if ($prData.creationDate) {
                $pr.CreationDate = [DateTime]::Parse($prData.creationDate)
            }

            if ($prData.closedDate) {
                $pr.ClosedDate = [DateTime]::Parse($prData.closedDate)
            }

            # Add to collection with type checking
            $prs += $pr
        }

        return $prs
    }
    catch {
        Write-Error "Failed to retrieve pull requests: $($_)"
        return [AzDOPullRequest[]]@()
    }
}

function Get-PullRequestCommitList {
    <#
    .SYNOPSIS
    Retrieves the list of commits for a specific pull request.

    .DESCRIPTION
    Gets all commits associated with a pull request from the Azure DevOps API.
    Returns a strongly-typed collection of commit objects.

    .PARAMETER Params
    An AzDOApiParameters object containing the required Azure DevOps connection parameters.

    .PARAMETER PullRequestId
    The ID of the pull request to get commits for.

    .EXAMPLE
    $params = [AzDOApiParameters]::new("MyOrg", "MyProject", "MyRepo", $authHeaders, "api-version=7.0")
    $commits = Get-PullRequestCommitList -Params $params -PullRequestId 123

    .NOTES
    This function retrieves commits in chronological order, with the newest commit first.
    #>
    [CmdletBinding()]
    [OutputType([AzDOPullRequestCommit[]])]
    param(
        [Parameter(Mandatory=$true)]
        [AzDOApiParameters]$Params,

        [Parameter(Mandatory=$true)]
        [int]$PullRequestId
    )

    try {
        # Form the API URL
        $commitsUrl = "$($Params.GetBaseApiUrl())/git/repositories/$($Params.RepositoryId)/pullRequests/$PullRequestId/commits?$($Params.ApiVersion)"

        Write-Verbose "Retrieving commits for PR ID: $PullRequestId from $commitsUrl"

        # Get commits data
        $commitsResponse = Invoke-AzureDevOpsApi -Uri $commitsUrl -Method "GET" -Headers $Params.Headers

        # Create an empty commit list
        $commitList = [AzDOPullRequestCommit[]]@()

        # Iterate through commits and add them to the list
        if ($commitsResponse.value -and $commitsResponse.value.Count -gt 0) {

            foreach ($commitData in $commitsResponse.value) {
                # Create a new commit object for each commit
                $commit = [AzDOPullRequestCommit]::new($commitData)
                $commitList += $commit

                Write-Verbose "Added commit: $($commit.CommitId) by $($commit.Author)"
            }
        }

        Write-Verbose "Retrieved $($commitList.Count) commits for PR ID: $PullRequestId"
        return $commitList
    }
    catch {
        Write-Error "Error retrieving commits for PR ID: $PullRequestId. Used URL: $commitsUrl Error: $_"
        return [AzDOPullRequestCommit[]]@()
    }
}

function Get-PullRequestReviewerList {
    <#
    .SYNOPSIS
    Retrieves the list of reviewers for a specific pull request.

    .DESCRIPTION
    Gets the raw reviewer data for a pull request from the Azure DevOps API.
    Returns the unmodified collection of reviewers as returned by the API.

    .PARAMETER Params
    An AzDOApiParameters object containing the required Azure DevOps connection parameters.

    .PARAMETER PullRequestId
    The ID of the pull request to get reviewers for.

    .EXAMPLE
    $params = [AzDOApiParameters]::new("MyOrg", "MyProject", "MyRepo", $authHeaders, "api-version=7.0")
    $reviewers = Get-PullRequestReviewerList -Params $params -PullRequestId 123

    .NOTES
    Returns the raw reviewer data without any additional calculations or transformations.
    #>
    [CmdletBinding()]
    [OutputType([AzDOPullRequestReviewer[]])]
    param(
        [Parameter(Mandatory=$true)]
        [AzDOApiParameters]$Params,

        [Parameter(Mandatory=$true)]
        [int]$PullRequestId
    )

    try {

        # Form the API URL
        $reviewersUrl = "$($Params.GetBaseApiUrl())/git/repositories/$($Params.RepositoryId)/pullRequests/$PullRequestId/reviewers?$($Params.ApiVersion)"

        Write-Verbose "Retrieving reviewers for PR ID: $PullRequestId from $reviewersUrl"

        # Get reviewer data
        $reviewersResponse = Invoke-AzureDevOpsApi -Uri $reviewersUrl -Method "GET" -Headers $Params.Headers

        # Create a typed collection of reviewer objects
        [AzDOPullRequestReviewer[]]$reviewers = @()

        # Check if we got valid reviewer data
        if ($reviewersResponse -and $reviewersResponse.PSObject.Properties.Name -contains "value") {
            # Translate vote values to readable status
            $voteStatusMap = @{
                10 = "Approved"
                5 = "Approved with suggestions"
                0 = "No vote"
                -5 = "Waiting for author"
                -10 = "Rejected"
            }

            foreach ($reviewerData in $reviewersResponse.value) {
                if ($null -eq $reviewerData) { continue }

                # Create new reviewer object
                $reviewer = [AzDOPullRequestReviewer]::new()
                $reviewer.Id = $reviewerData.id
                $reviewer.DisplayName = $reviewerData.displayName
                $reviewer.UniqueName = $reviewerData.uniqueName

                # Set vote value and status
                $voteValue = if ($null -ne $reviewerData.PSObject.Properties['vote']) { $reviewerData.vote } else { 0 }
                $reviewer.VoteValue = $voteValue

                $reviewer.VoteStatus = $voteStatusMap[0]  # Always use "No vote" from the map for any unknown values

                # Set additional properties
                $reviewer.IsRequired = if ($reviewerData.PSObject.Properties['isRequired']) { $reviewerData.isRequired -eq $true } else { $false }
                $reviewer.HasDeclined = if ($reviewerData.PSObject.Properties['hasDeclined']) { $reviewerData.hasDeclined -eq $true } else { $false }

                # Try to parse vote date if it exists (Azure DevOps doesn't directly provide this)
                if ($reviewerData.PSObject.Properties['votedFor'] -and $reviewerData.votedFor) {
                    try {
                        $reviewer.VoteDate = [DateTime]::Parse($reviewerData.votedFor)
                    } catch {
                        $reviewer.VoteDate = $null
                    }
                }

                # Add to collection with type checking
                $reviewers += $reviewer
            }
        }

        return [AzDOPullRequestReviewer[]]$reviewers
    }
    catch {
        Write-Warning "Error retrieving reviewers for PR ID: $PullRequestId. Error: $_"
    }
}

function Get-AzDOPullRequestThread {
    <#
    .SYNOPSIS
    Retrieves comment threads from a specific pull request.

    .DESCRIPTION
    Gets all comment threads for a pull request from the Azure DevOps API.
    Returns a strongly-typed collection of thread objects with their comments.

    .PARAMETER Params
    An AzDOApiParameters object containing the required Azure DevOps connection parameters.

    .PARAMETER PullRequestId
    The ID of the pull request to get threads for.

    .EXAMPLE
    $params = [AzDOApiParameters]::new("MyOrg", "MyProject", "MyRepo", $authHeaders, "api-version=7.0")
    $threads = Get-AzDOPullRequestThread -Params $params -PullRequestId 123

    .NOTES
    This function retrieves both thread metadata and individual comments within each thread.
    #>
    [CmdletBinding()]
    [OutputType([AzDOPullRequestThread[]])]
    param(
        [Parameter(Mandatory=$true)]
        [AzDOApiParameters]$Params,

        [Parameter(Mandatory=$true)]
        [int]$PullRequestId
    )

    try {

        # Form the API URL
        $threadsUrl = "$($Params.GetBaseApiUrl())/git/repositories/$($Params.RepositoryId)/pullRequests/$PullRequestId/threads?$($Params.ApiVersion)"

        Write-Verbose "Retrieving threads for PR ID: $PullRequestId from $threadsUrl"

        # Get thread data
        $threadsResponse = Invoke-AzureDevOpsApi -Uri $threadsUrl -Method "GET" -Headers $Params.Headers

        # Check if we have valid data
        if ($null -eq $threadsResponse -or $null -eq $threadsResponse.value) {
            Write-Verbose "No threads found for PR ID: $PullRequestId"
            return [AzDOPullRequestThread[]]@()
        }

        # Create thread collection
        $threads = [AzDOPullRequestThread[]]@()

        # Process each thread
        foreach ($threadData in $threadsResponse.value) {
            if ($null -eq $threadData) { continue }

            # Create thread object using constructor instead of manual property setting
            try {
                $thread = [AzDOPullRequestThread]::new($threadData)
                $threads += $thread
            }
            catch {
                Write-Warning "Error creating thread object: $_"
            }
        }

        return $threads
    }
    catch {
        Write-Warning "Error retrieving threads for PR ID: $PullRequestId. Error: $_"
        return [AzDOPullRequestThread[]]@()
    }
}

function Get-MainBranchPRMetric {
    <#
    .SYNOPSIS
    Retrieves pull request metrics from the main branch history when Azure DevOps API fails.

    .DESCRIPTION
    When the Azure DevOps API fails to provide file change data for PRs, this function can
    extract metrics from the Git commit history on the main branch using the squashed commits.

    .PARAMETER PullRequest
    A pull request object with metadata.

    .PARAMETER RepositoryPath
    The path to the local Git repository.

    .PARAMETER MainBranch
    The name of the main branch. Default is 'main'.

    .EXAMPLE
    $updatedPR = Get-MainBranchPRMetric -PullRequest $pr -RepositoryPath "/path/to/repo" -MainBranch "main"

    .NOTES
    This function is designed as a fallback for when Azure DevOps API fails to provide metrics.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]$PullRequestId,

        [Parameter(Mandatory=$true)]
        [object]$PullRequestStatus,

        [Parameter(Mandatory=$true)]
        [object]$PullRequestClosedDate,

        [Parameter(Mandatory=$true)]
        [object]$PullRequestTitle,

        [Parameter(Mandatory=$true)]
        [object]$PullRequestSourceBranch,

        [Parameter(Mandatory=$true)]
        [string]$RepositoryPath,

        [Parameter(Mandatory=$false)]
        [string]$MainBranch = "main"
    )

    # Skip PRs that aren't completed
    if ($PullRequestStatus -ne "completed" -or $null -eq $PullRequestClosedDate) {
        Write-Verbose "PR #$($PullRequestID) is not completed. Skipping."
        return $PullRequest
    }

    Write-Verbose "Processing PR #$($PullRequestID): $($PullRequestTitle)"

    # Store current location
    $currentLocation = Get-Location

    try {
        # Navigate to repo path
        Set-Location -Path $RepositoryPath

        # Parse completion date
        $completionDate = [datetime]::Parse($PullRequestClosedDate)

        # We'll search for commits around the completion date
        $searchStart = $completionDate.AddDays(-3)
        $searchEnd = $completionDate.AddDays(3)
        $searchStartISO = $searchStart.ToString("yyyy-MM-dd")
        $searchEndISO = $searchEnd.ToString("yyyy-MM-dd")

        Write-Verbose "Searching for commits between $searchStartISO and $searchEndISO for PR: $($PullRequestTitle)"

        # Extract keywords from PR title and source branch
        $titleKeywords = $PullRequestTitle -split ' ' | Where-Object { $_.Length -gt 4 -and $_ -notmatch '^(the|and|for|with|from|this|that)$' }
        $sourceBranchName = $PullRequestSourceBranch -split '/' | Select-Object -Last 1

        # Search for commits in the date range
        $possibleCommits = & git log --format="%H|%s|%ci" --after="$searchStartISO" --before="$searchEndISO" $MainBranch

        $bestMatch = $null
        $bestScore = 0

        # Score each commit based on title and branch matches
        foreach ($commit in $possibleCommits) {
            $parts = $commit -split '\|'
            if ($parts.Count -ge 2) {
                $commitId = $parts[0]
                $commitMsg = $parts[1]

                # Calculate match score
                $score = 0

                # Check for exact PR title
                if ($commitMsg -match [regex]::Escape($PullRequestTitle)) {
                    $score += 10
                }

                # Check for source branch name
                if ($commitMsg -match [regex]::Escape($sourceBranchName) -or
                    $commitMsg -match [regex]::Escape($PullRequestSourceBranch)) {
                    $score += 5
                }

                # Check for title keywords
                foreach ($keyword in $titleKeywords) {
                    if ($commitMsg -match [regex]::Escape($keyword)) {
                        $score += 1
                    }
                }

                # Update best match if this is better
                if ($score -gt $bestScore) {
                    $bestScore = $score
                    $bestMatch = $commitId
                }
            }
        }

        # If we found a good match, get the metrics
        if ($bestScore -ge 2 -and $bestMatch) {
            Write-Verbose "Found matching commit: $bestMatch with score $bestScore"

            # Get metrics for this commit
            # For a squashed merge, we compare with the parent commit
            $commitInfo = & git show --format="%P" $bestMatch
            if ($commitInfo -and $commitInfo[0]) {
                $parentCommit = $commitInfo[0]
                Write-Verbose "Found parent commit: $parentCommit"

                # Get numstat output
                $diffOutput = & git show --numstat --format="%H" $bestMatch

                # Initialize metrics
                $additions = 0
                $deletions = 0
                $filesChanged = 0
                $detailedFiles = @()

                # Process numstat output
                foreach ($line in $diffOutput) {
                    if ($line -match '^\s*(\d+)\s+(\d+)\s+(.+)$') {
                        $additions += [int]$Matches[1]
                        $deletions += [int]$Matches[2]
                        $filesChanged++
                        $detailedFiles += $Matches[3]
                    }
                }

                # Update PR with metrics using our new PullRequestFileChangeMetric type
                if ($filesChanged -gt 0) {
                    Write-Verbose "  Updated metrics: $filesChanged files, +$additions, -$deletions"

                    # Create a new metrics object
                    $metrics = [PullRequestFileChangeMetric]::new($filesChanged, $additions, $deletions)

                    # Add detailed files to the metrics object
                    foreach ($file in $detailedFiles) {
                        $metrics.AddDetailedFile($file)
                    }
                }
                return $metrics
            }
        }
        else {
            Write-Warning "No matching commit found for PR #$($PullRequestID)"
        }
    }
    catch {
        Write-Warning "Error processing PR #$($PullRequestID): $_"
    }
    finally {
        # Return to original location
        Set-Location -Path $currentLocation
    }

    return [PullRequestFileChangeMetric]::new(0,0,0)
}

function Get-PullRequestWorkItem {
    <#
    .SYNOPSIS
    Retrieves work items associated with a specific pull request.

    .DESCRIPTION
    Gets all work items linked to a pull request from the Azure DevOps API.
    Returns a strongly-typed collection of work item objects.

    .PARAMETER Params
    An AzDOApiParameters object containing the required Azure DevOps connection parameters.

    .PARAMETER PullRequestId
    The ID of the pull request to get work items for.

    .EXAMPLE
    $params = [AzDOApiParameters]::new("MyOrg", "MyProject", "MyRepo", $authHeaders, "api-version=7.0")
    $workItems = Get-PullRequestWorkItem -Params $params -PullRequestId 123

    .NOTES
    This function retrieves the basic work item references linked to the pull request.
    For detailed work item information, you would need to make additional API calls.
    #>
    [CmdletBinding()]
    [OutputType([AzDOWorkItemReference[]])]
    param(
        [Parameter(Mandatory=$true)]
        [AzDOApiParameters]$Params,

        [Parameter(Mandatory=$true)]
        [int]$PullRequestId
    )

    try {

        # Form the API URL
        $workItemsUrl = "$($Params.GetBaseApiUrl())/git/repositories/$($Params.RepositoryId)/pullRequests/$PullRequestId/workitems?$($Params.ApiVersion)"

        Write-Verbose "Retrieving work items for PR ID: $PullRequestId from $workItemsUrl"

        # Get work items data
        $workItemsResponse = Invoke-AzureDevOpsApi -Uri $workItemsUrl -Method "GET" -Headers $Params.Headers

        # Check if we have valid data
        if ($null -eq $workItemsResponse -or $null -eq $workItemsResponse.value) {
            Write-Verbose "No work items found for PR ID: $PullRequestId"
            return [AzDOWorkItemReference[]]@()
        }

        # Create work item collection
        $workItems = [AzDOWorkItemReference[]]@()

        # Process each work item
        foreach ($workItemRef in $workItemsResponse.value) {
            if ($null -eq $workItemRef) { continue }

            # Create work item reference object
            $workItem = [AzDOWorkItemReference]::new()
            $workItem.Id = $workItemRef.id
            $workItem.Url = $workItemRef.url

            # Extract work item type from URL if available
            if ($workItemRef.url -match '/workItems/(\d+)') {
                $workItem.WorkItemId = [int]$Matches[1]
            }

            # Add work item to collection
            $workItems += $workItem
        }

        return $workItems
    }
    catch {
        Write-Warning "Error retrieving work items for PR ID: $PullRequestId. Error: $_"
        return [AzDOWorkItemReference[]]@()
    }
}

function Get-WorkItemDetail {
    <#
    .SYNOPSIS
    Retrieves detailed information for a specific work item.

    .DESCRIPTION
    Gets the full details of a work item from the Azure DevOps API.
    Returns a strongly-typed work item object with all properties.

    .PARAMETER Params
    An AzDOApiParameters object containing the required Azure DevOps connection parameters.

    .PARAMETER WorkItemId
    The ID of the work item to retrieve.

    .EXAMPLE
    $params = [AzDOApiParameters]::new("MyOrg", "MyProject", "MyRepo", $authHeaders, "api-version=7.0")
    $workItem = Get-WorkItemDetail -Params $params -WorkItemId 123

    .NOTES
    This function retrieves detailed work item information including fields, relations, and history.
    #>
    [CmdletBinding()]
    [OutputType([AzDOWorkItem])]
    param(
        [Parameter(Mandatory=$true)]
        [AzDOApiParameters]$Params,

        [Parameter(Mandatory=$true)]
        [int]$WorkItemId
    )

    try {

        $workItemUrl = "$($Params.GetBaseApiUrl())/wit/workitems/$($WorkItemId)?$($Params.ApiVersion)&expand=all"

        Write-Verbose "Retrieving work item details for ID: $WorkItemId from $workItemUrl"

        # Get work item data
        $workItemResponse = Invoke-AzureDevOpsApi -Uri $workItemUrl -Method "GET" -Headers $Params.Headers

        # Check if we have valid data
        if ($null -eq $workItemResponse) {
            Write-Verbose "No work item found for ID: $WorkItemId"
            return $null
        }

        # Create work item object
        $workItem = [AzDOWorkItem]::new()
        $workItem.Id = $workItemResponse.id
        $workItem.Rev = $workItemResponse.rev
        $workItem.Url = $workItemResponse.url

        # Extract common fields
        if ($workItemResponse.fields) {
            $workItem.WorkItemType = $workItemResponse.fields.'System.WorkItemType'
            $workItem.Title = $workItemResponse.fields.'System.Title'
            $workItem.State = $workItemResponse.fields.'System.State'
            $workItem.CreatedBy = $workItemResponse.fields.'System.CreatedBy'
            $workItem.AssignedTo = $workItemResponse.fields.'System.AssignedTo'

            # Try to parse dates
            if ($workItemResponse.fields.'System.CreatedDate') {
                try {
                    $workItem.CreatedDate = [DateTime]::Parse($workItemResponse.fields.'System.CreatedDate')
                } catch {
                    $workItem.CreatedDate = $null
                }
            }

            if ($workItemResponse.fields.'System.ChangedDate') {
                try {
                    $workItem.ChangedDate = [DateTime]::Parse($workItemResponse.fields.'System.ChangedDate')
                } catch {
                    $workItem.ChangedDate = $null
                }
            }
        }

        # Store relations if available
        if ($workItemResponse.relations) {
            $workItem.Relations = $workItemResponse.relations
        }

        return $workItem
    }
    catch {
        Write-Warning "Error retrieving work item details for ID: $WorkItemId. Error: $_"
        return $null
    }
}

function Get-PullRequestWorkItemDetail {
    <#
    .SYNOPSIS
    Retrieves work items associated with a pull request along with their detailed information.

    .DESCRIPTION
    Gets all work items linked to a pull request and retrieves detailed information for each.
    This function combines Get-PullRequestWorkItem and Get-WorkItemDetail into a single operation.

    .PARAMETER Params
    An AzDOApiParameters object containing the required Azure DevOps connection parameters.

    .PARAMETER PullRequestId
    The ID of the pull request to get work items for.

    .PARAMETER IncludeDetails
    Optional. If set to true, retrieves detailed information for each work item. Default is true.

    .EXAMPLE
    $params = [AzDOApiParameters]::new("MyOrg", "MyProject", "MyRepo", $authHeaders, "api-version=7.0")
    $workItemDetails = Get-PullRequestWorkItemDetail -Params $params -PullRequestId 123

    .NOTES
    This function makes multiple API calls - one to get the work item references and one per work item for details.
    #>
    [CmdletBinding()]
    [OutputType([AzDOWorkItem[]])]
    param(
        [Parameter(Mandatory=$true)]
        [AzDOApiParameters]$Params,

        [Parameter(Mandatory=$true)]
        [int]$PullRequestId,

        [Parameter(Mandatory=$false)]
        [bool]$IncludeDetails = $true
    )

    try {
        # Get repository ID
        $repositoryId = Get-RepositoryId -Params $Params
        if (-not $repositoryId) {
            Write-Error "Failed to get repository ID for '$($Params.Repository)'"
            return [AzDOWorkItem[]]@()
        }

        # Get work item references from the PR
        Write-Verbose "Getting work item references for PR #$PullRequestId"
        $workItemRefs = Get-PullRequestWorkItem -Params $Params -PullRequestId $PullRequestId

        if ($workItemRefs.Count -eq 0) {
            Write-Verbose "No work items found associated with PR #$PullRequestId"
            return [AzDOWorkItem[]]@()
        }

        Write-Verbose "Found $($workItemRefs.Count) work items associated with PR #$PullRequestId"

        # Create result collection
        $workItems = [AzDOWorkItem[]]@()

        # Get detailed information for each work item if requested
        if ($IncludeDetails) {
            foreach ($workItemRef in $workItemRefs) {
                if ($null -eq $workItemRef.WorkItemId) {
                    Write-Warning "Work item reference does not contain a valid work item ID. Skipping."
                    continue
                }

                Write-Verbose "Getting details for work item #$($workItemRef.WorkItemId)"
                [AzDOWorkItem]$workItemDetail = Get-WorkItemDetail -Params $Params -WorkItemId $workItemRef.WorkItemId

                if ($null -ne $workItemDetail) {
                    $workItems += $workItemDetail
                }
            }
        } else {
            # If details not requested, create basic work item objects from references
            foreach ($workItemRef in $workItemRefs) {
                if ($null -eq $workItemRef.WorkItemId) {
                    continue
                }

                $basicWorkItem = [AzDOWorkItem]::new()
                $basicWorkItem.Id = $workItemRef.WorkItemId
                $basicWorkItem.Url = $workItemRef.Url

                $workItems += $basicWorkItem
            }
        }

        return $workItems
    }
    catch {
        Write-Warning "Error retrieving work item details for PR ID: $PullRequestId. Error: $_"
        return [AzDOWorkItem[]]@()
    }
}

function Get-MainBranchFileExtension {
    <#
    .SYNOPSIS
    Counts file extensions in the main branch repository using local file system.

    .DESCRIPTION
    This function analyzes the files in a local Git repository to count how many files
    exist of each type (by extension). It only looks at the current state of the
    repository (not historical data).

    .PARAMETER RepoPath
    Path to the local Git repository. Default is the current directory.

    .EXAMPLE
    $fileExtensions = Get-MainBranchFileExtension -RepoPath "/path/to/repo"

    .OUTPUTS
    System.Collections.Hashtable with file extension categories as keys and counts as values
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param(
        [Parameter(Mandatory=$false)]
        [string]$RepoPath = "."
    )

    # Go to the repository directory
    Push-Location $RepoPath

    try {


        # Initialize extension categorization
        $extensionCategories = @{
            "JavaScript/TypeScript" = @('.js', '.jsx', '.ts', '.tsx')
            "Python" = @('.py', '.pyc', '.pyo', '.pyd')
            "C#" = @('.cs', '.vb', '.fs', '.xaml')
            "Java" = @('.java', '.jsp', '.jspx', '.class')
            "Go" = @('.go')
            "Rust" = @('.rs')
            "C/C++" = @('.c', '.cpp', '.cc', '.h', '.hpp')
            "Shell Scripts" = @('.sh', '.bash', '.zsh', '.ksh', '.bat', '.cmd')
            "HTML/CSS" = @('.html', '.htm', '.css', '.scss', '.sass', '.less')
            "Documentation (Markdown)" = @('.md', '.txt', '.rtf')
            "JSON" = @('.json')
            "YAML" = @('.yml', '.yaml')
            "XML" = @('.xml', '.config', '.xsd', '.dtd')
            "SQL" = @('.sql')
            "Bicep/ARM Templates" = @('.bicep', '.arm')
            "Terraform" = @('.tf', '.tfvars', '.hcl')
            "Docker" = @('Dockerfile', '.dockerfile')
            "Configuration Files" = @('.ini', '.conf', '.config', '.cfg', '.env')
            "PowerShell" = @('.ps1', '.psm1', '.psd1')
            "Other" = @() # Will capture everything else
        }

        # Initialize results hashtable
        $results = @{}
        foreach ($category in $extensionCategories.Keys) {
            $results[$category] = 0
        }

        # Get all files in repository
        $files = git ls-files

        foreach ($file in $files) {
            # Skip directories
            if (Test-Path $file -PathType Container) { continue }

            $extension = [System.IO.Path]::GetExtension($file).ToLower()
            $filename = [System.IO.Path]::GetFileName($file).ToLower()

            $categorized = $false

            # Categorize the file
            foreach ($category in $extensionCategories.Keys) {
                if ($categorized) { break }

                foreach ($ext in $extensionCategories[$category]) {
                    if (($extension -and $extension -eq $ext) -or ($filename -eq $ext)) {
                        $results[$category]++
                        $categorized = $true
                        break
                    }
                }
            }

            # If not categorized, add to "Other"
            if (-not $categorized) {
                $results["Other"]++
            }
        }

        # Remove empty categories
        $emptyCategories = @($results.Keys | Where-Object { $results[$_] -eq 0 })
        foreach ($category in $emptyCategories) {
            $results.Remove($category)
        }

        return $results
    }
    finally {
        # Return to the original directory
        Pop-Location
    }
}

# Export the functions
Export-ModuleMember -Function @(
    'Get-MainBranchPRMetric',
    'Get-MainBranchFileExtension',
    'Get-RepositoryId',
    'Get-PullRequestList',
    'Get-PullRequestCommitList',
    'Get-PullRequestReviewerList',
    'Get-AzDOPullRequestThread',
    'Get-PullRequestWorkItem',
    'Get-WorkItemDetail',
    'Get-PullRequestWorkItemDetail'
)
