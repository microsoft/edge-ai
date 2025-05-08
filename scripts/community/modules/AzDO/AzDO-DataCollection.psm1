# Import the AzDO-Types module
using module "./AzDO-Types.psm1"
# Import ReportTypes for IndustryBacklogCollection
using module "./AzDO-ReportTypes.psm1"

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

    # Validate parameters - no need for null check
    if (-not $Params.Validate()) {
        Write-Error "Invalid API parameters provided"
        return ""
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
            return ""
        }
    } catch {
        Write-Warning "Error retrieving repositories: $_"
        return ""
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

        # Remove null check, assume we always get data
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

        # Iterate through commits and add them to the list - removed null check
        foreach ($commitData in $commitsResponse.value) {
            # Create a new commit object for each commit
            $commit = [AzDOPullRequestCommit]::new($commitData)
            $commitList += $commit

            Write-Verbose "Added commit: $($commit.CommitId) by $($commit.Author)"
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

        # Check if we got valid reviewer data - removed null check
        # Translate vote values to readable status
        $voteStatusMap = @{
            10 = "Approved"
            5 = "Approved with suggestions"
            0 = "No vote"
            -5 = "Waiting for author"
            -10 = "Rejected"
        }

        foreach ($reviewerData in $reviewersResponse.value) {
            # Create new reviewer object
            $reviewer = [AzDOPullRequestReviewer]::new()
            $reviewer.Id = $reviewerData.id
            $reviewer.DisplayName = $reviewerData.displayName
            $reviewer.UniqueName = $reviewerData.uniqueName

            # Set vote value and status
            $voteValue = $reviewerData.vote ?? 0
            $reviewer.VoteValue = $voteValue

            $reviewer.VoteStatus = $voteStatusMap[$voteValue] ?? $voteStatusMap[0]

            # Set additional properties
            $reviewer.IsRequired = $reviewerData.isRequired
            $reviewer.HasDeclined = $reviewerData.hasDeclined

            # Add to collection with type checking
            $reviewers += $reviewer
        }

        return [AzDOPullRequestReviewer[]]$reviewers
    }
    catch {
        Write-Warning "Error retrieving reviewers for PR ID: $PullRequestId. Error: $_"
        return [AzDOPullRequestReviewer[]]@()
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

        # Removed null check for response - assume data is present
        Write-Verbose "Processing threads for PR ID: $PullRequestId"

        # Create thread collection
        $threads = [AzDOPullRequestThread[]]@()

        # Process each thread
        foreach ($threadData in $threadsResponse.value) {
            # Create thread object using constructor
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

        # Removed null check - assume valid data
        Write-Verbose "Processing work items for PR ID: $PullRequestId"

        # Create work item collection
        $workItems = [AzDOWorkItemReference[]]@()

        # Process each work item
        foreach ($workItemRef in $workItemsResponse.value) {
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

        # Removed null check - assume data exists

        # Create work item object
        $workItem = [AzDOWorkItem]::new()
        $workItem.Id = $workItemResponse.id
        $workItem.Rev = $workItemResponse.rev
        $workItem.Url = $workItemResponse.url

        # Extract common fields
        # Parse dates when parsing fields - removed null checks
        $workItem.WorkItemType = $workItemResponse.fields.'System.WorkItemType'
        $workItem.Title = $workItemResponse.fields.'System.Title'
        $workItem.State = $workItemResponse.fields.'System.State'
        $workItem.CreatedBy = $workItemResponse.fields.'System.CreatedBy'
        $workItem.AssignedTo = $workItemResponse.fields.'System.AssignedTo'

        $workItem.CreatedDate = [DateTime]::Parse($workItemResponse.fields.'System.CreatedDate')
        $workItem.ChangedDate = [DateTime]::Parse($workItemResponse.fields.'System.ChangedDate')

        # Store relations
        $workItem.Relations = $workItemResponse.relations

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

        # Get work item references from the PR
        Write-Verbose "Getting work item references for PR #$PullRequestId"
        $workItemRefs = Get-PullRequestWorkItem -Params $Params -PullRequestId $PullRequestId

        # Removed null check for workItemRefs - assume they exist
        Write-Verbose "Found $($workItemRefs.Count) work items associated with PR #$PullRequestId"

        # Create result collection
        $workItems = [AzDOWorkItem[]]@()

        # Get detailed information for each work item if requested
        if ($IncludeDetails) {
            foreach ($workItemRef in $workItemRefs) {
                Write-Verbose "Getting details for work item #$($workItemRef.WorkItemId)"
                [AzDOWorkItem]$workItemDetail = Get-WorkItemDetail -Params $Params -WorkItemId $workItemRef.WorkItemId
                $workItems += $workItemDetail
            }
        } else {
            # If details not requested, create basic work item objects from references
            foreach ($workItemRef in $workItemRefs) {
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
        $results = @{
            "JavaScript/TypeScript" = 0
            "Python" = 0
            "C#" = 0
            "Java" = 0
            "Go" = 0
            "Rust" = 0
            "C/C++" = 0
            "Shell Scripts" = 0
            "HTML/CSS" = 0
            "Documentation (Markdown)" = 0
            "JSON" = 0
            "YAML" = 0
            "XML" = 0
            "SQL" = 0
            "Bicep/ARM Templates" = 0
            "Terraform" = 0
            "Docker" = 0
            "Configuration Files" = 0
            "PowerShell" = 0
            "Other" = 0
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

function Get-IndustryBacklogItemsFromAzDO {
    <#
    .SYNOPSIS
    Retrieves industry backlog items from Azure DevOps.

    .DESCRIPTION
    Retrieves industry pillars, scenarios, capabilities, and related features from Azure DevOps.

    .PARAMETER Organization
    The Azure DevOps organization name.

    .PARAMETER Project
    The Azure DevOps project name.

    .PARAMETER AuthHeader
    The authentication header for API calls.

    .OUTPUTS
    IndustryBacklogCollection. An object containing the industry backlog hierarchy.
    #>
    [CmdletBinding()]
    [OutputType([IndustryBacklogCollection])]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Organization,

        [Parameter(Mandatory=$true)]
        [string]$Project,

        [Parameter(Mandatory=$true)]
        [hashtable]$AuthHeader
    )

    Write-Host "Starting Get-IndustryBacklogItemsFromAzDO function for $Organization/$Project"

    # Initialize collection for backlog items
    $backlogItems = [IndustryBacklogCollection]::new()

    # Get Industry Pillars
    Write-Host "Executing WIQL query for Industry Pillars"
    $pillarsQuery = @{
        query = "SELECT [System.Id], [System.WorkItemType], [System.Title], [System.State], [System.Tags], [System.Parent], [System.Description]
FROM WorkItems
WHERE [System.WorkItemType] = 'Industry Pillar'
AND [System.State] NOT IN ('Removed', 'Deleted')
ORDER BY [System.Title]"
    }

    # Pass the hashtable directly instead of converting to JSON
    $pillarsQueryResult = Invoke-AzureDevOpsApi -Uri "https://dev.azure.com/$Organization/$Project/_apis/wit/wiql?api-version=7.0" -Method "POST" -Body $pillarsQuery -Headers $AuthHeader

    if ($pillarsQueryResult -and $pillarsQueryResult.workItems) {
        $pillarIds = $pillarsQueryResult.workItems.id -join ","
        Write-Host "Retrieved $($pillarsQueryResult.workItems.Count) Industry Pillars"

        if ($pillarIds) {
            $pillarDetails = Invoke-AzureDevOpsApi -Uri "https://dev.azure.com/$Organization/$Project/_apis/wit/workitems?ids=$pillarIds&api-version=7.0&`$expand=relations" -Method "GET" -Headers $AuthHeader

            if ($pillarDetails -and $pillarDetails.value) {
                foreach ($pillar in $pillarDetails.value) {
                    # Add pillar to collection
                    $p = [PillarWorkItem]::new()
                    $p.Id = $pillar.id
                    $p.Title = $pillar.fields.'System.Title'
                    $p.Description = $pillar.fields.'System.Description'
                    $p.State = $pillar.fields.'System.State'
                    $p.Tags = $pillar.fields.'System.Tags'
                    $p.Description = $pillar.fields.'System.Description'
                    $backlogItems.Pillars += $p
                }
                Write-Host "Added $($pillarDetails.value.Count) Industry Pillars to collection"
            }
        }
    }

    # Get Scenarios
    Write-Host "Executing WIQL query for Scenarios"
    $scenariosQuery = @{
        query = "SELECT [System.Id], [System.WorkItemType], [System.Title], [System.State], [System.Tags], [System.Parent], [System.Description]
FROM WorkItems
WHERE [System.WorkItemType] = 'Scenario'
AND [System.State] NOT IN ('Removed', 'Deleted')
ORDER BY [System.Title]"
    }

    # Pass the hashtable directly instead of converting to JSON
    $scenariosQueryResult = Invoke-AzureDevOpsApi -Uri "https://dev.azure.com/$Organization/$Project/_apis/wit/wiql?api-version=7.0" -Method "POST" -Body $scenariosQuery -Headers $AuthHeader

    if ($scenariosQueryResult -and $scenariosQueryResult.workItems) {
        $scenarioIds = $scenariosQueryResult.workItems.id -join ","
        Write-Host "Retrieved $($scenariosQueryResult.workItems.Count) Scenarios"

        if ($scenarioIds) {
            $scenarioDetails = Invoke-AzureDevOpsApi -Uri "https://dev.azure.com/$Organization/$Project/_apis/wit/workitems?ids=$scenarioIds&api-version=7.0&`$expand=relations" -Method "GET" -Headers $AuthHeader

            if ($scenarioDetails -and $scenarioDetails.value) {
                foreach ($scenario in $scenarioDetails.value) {
                    # Add scenario to collection
                    $s = [ScenarioWorkItem]::new()
                    $s.Id = $scenario.id
                    $s.Title = $scenario.fields.'System.Title'
                    $s.Description = $scenario.fields.'System.Description'
                    $s.Tags = $scenario.fields.'System.Tags' -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }

                    # Link scenario to pillar if parent relation exists
                    if ($scenario.relations) {
                        foreach ($relation in $scenario.relations) {
                            if ($relation.attributes.name -eq "Parent") {
                                $parentId = $relation.url.Split('/')[-1]
                                $s.ParentId = $parentId
                            }
                        }
                    }
                    $backlogItems.Scenarios += $s
                }
                Write-Host "Added $($scenarioDetails.value.Count) Scenarios to collection"
            }
        }
    }

    # Get Capabilities - Updated query to ensure we get all fields needed including custom fields
    Write-Host "Executing WIQL query for Capabilities"
    $capabilitiesQuery = @{
        query = "SELECT [System.Id], [System.WorkItemType], [System.Title], [System.State], [System.Tags],
       [System.Parent], [Custom.ScenarioList], [System.Description]
FROM WorkItems
WHERE [System.WorkItemType] = 'Capability'
AND [System.State] NOT IN ('Removed', 'Deleted')
ORDER BY [System.Title]"
    }

    # Pass the hashtable directly instead of converting to JSON
    $capabilitiesQueryResult = Invoke-AzureDevOpsApi -Uri "https://dev.azure.com/$Organization/$Project/_apis/wit/wiql?api-version=7.0" -Method "POST" -Body $capabilitiesQuery -Headers $AuthHeader

    if ($capabilitiesQueryResult -and $capabilitiesQueryResult.workItems) {
        Write-Host "Found $($capabilitiesQueryResult.workItems.Count) capabilities from WIQL query"

        # Create collection to hold unique feature IDs
        $featureIds = [System.Collections.Generic.HashSet[string]]::new()

        # Capture all capability IDs returned from WIQL query
        $capabilityIds = $capabilitiesQueryResult.workItems.id -join ","
        Write-Host "Capability IDs from WIQL: $capabilityIds"

        if ($capabilityIds) {
            # Get detailed data for all capabilities
            $detailsUri = "https://dev.azure.com/$Organization/$Project/_apis/wit/workitems?ids=$capabilityIds&api-version=7.0&`$expand=relations"
            Write-Host "Getting capability details from: $detailsUri"
            $capabilityDetails = Invoke-AzureDevOpsApi -Uri $detailsUri -Method "GET" -Headers $AuthHeader

            if ($capabilityDetails -and $capabilityDetails.value) {
                Write-Host "Retrieved $($capabilityDetails.value.Count) capability details"

                # Loop through each capability to process its data
                foreach ($capability in $capabilityDetails.value) {
                    # Log capability information
                    Write-Host "Processing capability: #$($capability.id) - $($capability.fields.'System.Title')"

                    # Add capability to collection
                    $capabilityItem = [CapabilityWorkItem]::new()
                    $capabilityItem.Id = $capability.id
                    $capabilityItem.Title = $capability.fields.'System.Title'
                    $capabilityItem.Description = $capability.fields.'System.Description'

                    # Link capability to scenarios from Custom.ScenarioList if it exists
                    if ($capability.fields.'Custom.ScenarioList') {
                        # Add the System.Web assembly if not already loaded
                        if (-not ([System.Management.Automation.PSTypeName]'System.Web.HttpUtility').Type) {
                            Add-Type -AssemblyName System.Web
                        }

                        # Decode the entire ScenarioList string first to handle any HTML entities in the entire field
                        $decodedScenarioListString = [System.Web.HttpUtility]::HtmlDecode($capability.fields.'Custom.ScenarioList')
                        $scenarioList = $decodedScenarioListString -split ';'

                        Write-Host "Found ScenarioList field with $($scenarioList.Count) scenarios"
                        foreach ($scenarioId in $scenarioList) {
                            $scenarioId = $scenarioId.Trim()
                            if ($scenarioId) {
                                # The scenarioId should already be decoded from above, but decode again to be sure
                                $decodedScenarioId = [System.Web.HttpUtility]::HtmlDecode($scenarioId)
                                $capabilityItem.ScenarioList += $decodedScenarioId

                                # Use the decoded ID in the output message
                                Write-Host "  Linked capability #$($capability.id) to scenario #$decodedScenarioId"
                            }
                        }
                    } else {
                        Write-Host "  No Custom.ScenarioList field found for capability #$($capability.id)"
                    }

                    $backlogItems.Capabilities += $capabilityItem

                    # Extract feature IDs from relations
                    if ($capability.relations) {
                        Write-Host "  Found $($capability.relations.Count) relations for capability #$($capability.id)"

                        # Debug output all relations to see what we're getting
                        foreach ($relation in $capability.relations) {
                            Write-Host "  Relation: Type=$($relation.rel), URL=$($relation.url)"
                        }

                        foreach ($relation in $capability.relations) {
                            # Check if relation is related link and is a Feature work item
                            if ($relation.rel -eq "System.LinkTypes.Related" -or
                                $relation.rel -eq "System.LinkTypes.Dependency-Forward" -or
                                $relation.rel -eq "System.LinkTypes.Dependency-Reverse") {

                                # Extract the work item ID from the URL
                                $workItemId = $relation.url.Split('/')[-1]
                                Write-Host "  Found related work item: $workItemId from relation type: $($relation.rel)"

                                # Add to feature IDs collection for later lookup
                                $featureIds.Add($workItemId) | Out-Null
                                Write-Host "  Added work item #$workItemId to feature IDs collection"
                            } else {
                                Write-Host "  Relation type $($relation.rel) not tracked for features"
                            }
                        }
                    } else {
                        Write-Host "  No relations found for capability #$($capability.id)"
                    }
                }

                Write-Host "Added $($capabilityDetails.value.Count) Capabilities to collection"
                Write-Host "Found $($featureIds.Count) unique related Feature IDs"

                # Get feature details if we found any related features
                if ($featureIds.Count -gt 0) {
                    $featureIdsStr = $featureIds -join ","
                    Write-Host "Getting details for features: $featureIdsStr"

                    $featureDetails = Invoke-AzureDevOpsApi -Uri "https://dev.azure.com/$Organization/$Project/_apis/wit/workitems?ids=$featureIdsStr&api-version=7.0&`$expand=relations" -Method "GET" -Headers $AuthHeader

                    if ($featureDetails -and $featureDetails.value) {
                        Write-Host "Retrieved $($featureDetails.value.Count) features"

                        foreach ($feature in $featureDetails.value) {
                            # Check if it's a Feature work item type
                            if ($feature.fields.'System.WorkItemType' -eq 'Feature') {
                                Write-Host "Processing Feature #$($feature.id): $($feature.fields.'System.Title')"
                                $f = [FeatureWorkItem]::new()
                                $f.ID = $feature.id
                                $f.Title = $feature.fields.'System.Title'
                                $f.Description = $feature.fields.'System.Description'

                                # Link feature back to capabilities based on relations
                                if ($feature.relations) {
                                    Write-Host "  Feature #$($feature.id) has $($feature.relations.Count) relations"

                                    foreach ($relation in $feature.relations) {
                                        if ($relation.rel -eq "System.LinkTypes.Related" -or
                                            $relation.rel -eq "System.LinkTypes.Dependency-Forward" -or
                                            $relation.rel -eq "System.LinkTypes.Dependency-Reverse") {

                                            $relatedItemId = $relation.url.Split('/')[-1]
                                            Write-Host "  Feature has relation to work item #$relatedItemId"

                                            # Check if this related item is a capability we know about
                                            if ($capabilityDetails.value.id -contains $relatedItemId) {
                                                $f.ParentCapabilityId += $relatedItemId
                                                Write-Host "  Linked Feature #$($feature.id) to Capability #$relatedItemId"
                                            } else {
                                                Write-Host "  Work item #$relatedItemId is not a known capability"
                                            }
                                        }
                                    }
                                } else {
                                    Write-Host "  No relations found for Feature #$($feature.id)"
                                }

                                $backlogItems.Features += $f
                            } else {
                                Write-Host "Work item #$($feature.id) is not a Feature (Type: $($feature.fields.'System.WorkItemType'))"
                            }
                        }
                        Write-Host "Added $($featureDetails.value.Count) Features to collection"
                    } else {
                        Write-Host "No feature details retrieved or empty response"
                    }
                } else {
                    Write-Host "No related features found for capabilities."
                }
            } else {
                Write-Host "No capability details retrieved or empty response"
            }
        } else {
            Write-Host "No capability IDs found in the WIQL result"
        }
    } else {
        Write-Host "No capabilities found in WIQL query result"
    }

    Write-Host "Completed industry backlog collection with:"
    Write-Host "  - Pillars: $($backlogItems.Pillars.Count)"
    Write-Host "  - Scenarios: $($backlogItems.Scenarios.Count)"
    Write-Host "  - Capabilities: $($backlogItems.Capabilities.Count)"
    Write-Host "  - Features: $($backlogItems.Features.Count)"
    return $backlogItems
}

# Export all functions from this module
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
    'Get-PullRequestWorkItemDetail',
    'Get-IndustryBacklogItemsFromAzDO'
)
