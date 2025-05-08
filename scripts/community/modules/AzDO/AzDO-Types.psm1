# AzDO-Types.psm1
# Type definitions for Azure DevOps API interactions

class AzDOApiParameters {
    [string]$Organization
    [string]$Project
    [string]$Repository
    [System.Collections.IDictionary]$Headers
    [string]$ApiVersion
    [string]$RepositoryId

    # Default constructor
    AzDOApiParameters() {
        $this.Repository = $null
    }

    # Constructor with required parameters
    AzDOApiParameters([string]$Organization, [string]$Project, [string]$Repository, [System.Collections.IDictionary]$Headers, [string]$ApiVersion) {
        $this.Organization = $Organization
        $this.Project = $Project
        $this.Repository = $Repository
        $this.Headers = $Headers
        $this.ApiVersion = $ApiVersion
    }

    # Constructor with repository ID instead of name
    AzDOApiParameters([string]$Organization, [string]$Project, [hashtable]$Headers, [string]$ApiVersion) {
        $this.Organization = $Organization
        $this.Project = $Project
        $this.Repository = $null
        $this.Headers = $Headers
        $this.ApiVersion = $ApiVersion
    }

    # Get the base API URL
    [string] GetBaseApiUrl() {
        return "https://dev.azure.com/$($this.Organization)/$($this.Project)/_apis"
    }

    # Validate parameters
    [bool] Validate() {
        return -not [string]::IsNullOrWhiteSpace($this.Organization) -and -not [string]::IsNullOrWhiteSpace($this.Project)
    }
}

# Class for pull request data
class AzDOPullRequest {
    [int]$Id
    [int]$PullRequestId
    [string]$Title
    [string]$Description
    [string]$Status # active, abandoned, completed
    [string]$MergeStatus
    [string]$MergeId
    [string]$Url
    [bool]$IsDraft
    [string]$CodeReviewId
    [bool]$SupportsIterations

    # Repository info
    [string]$RepositoryId
    [string]$RepositoryName
    [string]$RepositoryUrl

    # Branch info
    [string]$SourceBranch
    [string]$TargetBranch
    [string]$SourceRefName
    [string]$TargetRefName

    # Author info
    [string]$CreatedById
    [string]$CreatedByName
    [string]$CreatedByDisplayName
    [string]$CreatedByEmail
    [string]$CreatedByUniqueName
    [string]$CreatedByImageUrl

    # Commit info
    [AzDOPullRequestCommit]$LastMergeCommit
    [AzDOPullRequestCommit]$LastMergeSourceCommit
    [AzDOPullRequestCommit]$LastMergeTargetCommit

    # Dates
    [DateTime]$CreationDate
    [DateTime]$ClosedDate
    [DateTime]$LastUpdateTime

    # Additional metadata
    [array]$WorkItems
    [array]$Reviewers
    [int]$CommentCount
    [array]$Commits
}

# Class for pull request commit data
class AzDOPullRequestCommit {
    [string]$CommitId
    [string]$Author
    [string]$AuthorEmail
    [string]$Comment
    [DateTime]$CommittedDate
    [string]$Url

    AzDOPullRequestCommit() {
        # Default constructor
    }

    AzDOPullRequestCommit([PSObject]$commitData) {
        if ($null -ne $commitData) {
            $this.CommitId = $commitData.commitId

            if ($commitData.PSObject.Properties.Name -contains "author") {
                $this.Author = $commitData.author.name
                $this.AuthorEmail = $commitData.author.email
            }

            $this.Comment = if ($commitData.PSObject.Properties.Name -contains "comment") { $commitData.comment } else { "" }

            if ($commitData.PSObject.Properties.Name -contains "committer") {
                try {
                    if ($null -ne $commitData.committer.date) {
                        $this.CommittedDate = [DateTime]::Parse($commitData.committer.date)
                    }
                }
                catch {
                    Write-Warning "Error parsing committed date: $_"
                }
            }

            $this.Url = if ($commitData.PSObject.Properties.Name -contains "url") { $commitData.url } else { "" }
        }
    }
}

# Class for pull request reviewer data
class AzDOPullRequestReviewer {
    [string]$Id
    [string]$DisplayName
    [string]$UniqueName
    [int]$VoteValue
    [string]$VoteStatus
    [bool]$IsRequired
    [bool]$HasDeclined

    AzDOPullRequestReviewer() {
        # Default constructor
        $this.VoteValue = 0
        $this.VoteStatus = "No vote"
        $this.IsRequired = $false
        $this.HasDeclined = $false
    }
}

# Class for pull request thread tracking
class AzDOPullRequestThread {
    [string]$Id
    [string]$Status
    [bool]$IsDeleted
    [DateTime]$PublishedDate
    [DateTime]$LastUpdatedDate
    [array]$Comments
    [int]$CommentCount
    [string]$ThreadType
    [string]$ThreadContext
    [bool]$HasComments

    AzDOPullRequestThread() {
        # Default constructor
        $this.Comments = @()
        $this.CommentCount = 0
        $this.HasComments = $false
    }

    AzDOPullRequestThread([PSObject]$threadData) {
        $this.Comments = @()

        if ($null -ne $threadData) {
            $this.Id = $threadData.id
            $this.Status = $threadData.status
            $this.ThreadType = if ($threadData.PSObject.Properties.Name -contains "threadContext") {
                if ($threadData.threadContext.PSObject.Properties.Name -contains "filePath") { "code" } else { "comment" }
            } else { "comment" }

            # Parse dates if available
            if ($threadData.PSObject.Properties.Name -contains "publishedDate") {
                try {
                    $this.PublishedDate = [DateTime]::Parse($threadData.publishedDate)
                } catch {
                    Write-Verbose "Failed to parse publishedDate: $_"
                    # Property remains unset
                }
            }
            if ($threadData.PSObject.Properties.Name -contains "lastUpdatedDate") {
                try {
                    $this.LastUpdatedDate = [DateTime]::Parse($threadData.lastUpdatedDate)
                } catch {
                    Write-Verbose "Failed to parse lastUpdatedDate: $_"
                    # Property remains unset
                }
            }

            # Extract comments if available
            if ($threadData.PSObject.Properties.Name -contains "comments" -and $null -ne $threadData.comments) {
                $this.Comments = $threadData.comments
                $this.CommentCount = $threadData.comments.Count
                $this.HasComments = $this.CommentCount -gt 0
            }

            # Extract thread context if available
            if ($threadData.PSObject.Properties.Name -contains "threadContext") {
                $this.ThreadContext = $threadData.threadContext | ConvertTo-Json -Depth 3 -Compress
            }
        }
    }
}

# Collection class for thread comments and statistics
class AzDOPullRequestThreadCollection {
    [int]$TotalThreads
    [int]$TotalComments
    [DateTime]$FirstReviewerEngagement
    [hashtable]$CommentsByReviewer

    AzDOPullRequestThreadCollection() {
        $this.TotalThreads = 0
        $this.TotalComments = 0
        $this.CommentsByReviewer = @{}
    }

    AzDOPullRequestThreadCollection([PSCustomObject]$threadsResponse) {
        $this.TotalThreads = 0
        $this.TotalComments = 0
        $this.CommentsByReviewer = @{}
        $firstEngagementTime = $null

        if ($threadsResponse.PSObject.Properties.Name -contains "value" -and $null -ne $threadsResponse.value) {
            $this.TotalThreads = $threadsResponse.value.Count

            foreach ($thread in $threadsResponse.value) {
                try {
                    if ($thread.PSObject.Properties.Name -contains "comments" -and $null -ne $thread.comments) {
                        foreach ($comment in $thread.comments) {
                            $this.TotalComments++

                            # Extract author info from comment
                            if ($comment.PSObject.Properties.Name -contains "author" -and
                                $null -ne $comment.author -and
                                $comment.author.PSObject.Properties.Name -contains "uniqueName") {

                                $authorEmail = $comment.author.uniqueName
                                $threadAuthorName = $threadsResponse.value[0].comments[0].author.uniqueName
                                $commentAuthorName = $comment.author.uniqueName
                                $commentType = if ($comment.PSObject.Properties.Name -contains "commentType") { $comment.commentType } else { "normal" }

                                # Track first engagement from someone other than the PR author
                                if ($null -ne $commentAuthorName -and
                                    $null -ne $threadAuthorName -and
                                    $commentAuthorName -ne $threadAuthorName) {
                                    try {
                                        if ($comment.PSObject.Properties.Name -contains "publishedDate") {
                                            $commentTime = [DateTime]::Parse($comment.publishedDate)
                                            if ($null -eq $firstEngagementTime -or $commentTime -lt $firstEngagementTime) {
                                                $firstEngagementTime = $commentTime
                                            }
                                        }
                                    }
                                    catch {
                                        Write-Verbose "Failed to parse comment date: $_"
                                    }
                                }

                                # Track comments by reviewer
                                if (-not [string]::IsNullOrEmpty($authorEmail) -and $commentType -ne "system") {
                                    if (-not $this.CommentsByReviewer.ContainsKey($authorEmail)) {
                                        $this.CommentsByReviewer[$authorEmail] = @{
                                            Count = 0
                                            FirstCommentTime = $null
                                            DisplayName = if ($comment.author.PSObject.Properties.Name -contains "displayName") {
                                                $comment.author.displayName
                                            } else {
                                                $authorEmail
                                            }
                                        }
                                    }

                                    if ($comment.PSObject.Properties.Name -contains "publishedDate") {
                                        try {
                                            $commentTime = [DateTime]::Parse($comment.publishedDate)
                                            if ($null -eq $this.CommentsByReviewer[$authorEmail].FirstCommentTime -or
                                                $commentTime -lt $this.CommentsByReviewer[$authorEmail].FirstCommentTime) {
                                                $this.CommentsByReviewer[$authorEmail].FirstCommentTime = $commentTime
                                            }
                                        }
                                        catch {
                                            Write-Verbose "Failed to parse comment date for reviewer $($authorEmail): $_"
                                        }
                                    }
                                    $this.CommentsByReviewer[$authorEmail].Count++
                                }
                            }
                        }
                    }
                }
                catch {
                    Write-Warning "Error processing thread: $_"
                }
            }
        }

        # Set the first reviewer engagement time
        $this.FirstReviewerEngagement = $firstEngagementTime
    }
}

# Class representing a work item reference linked to a PR
class AzDOWorkItemReference {
    [int]$Id
    [string]$Url
    [int]$WorkItemId

    AzDOWorkItemReference() {
        # Default constructor
    }

    AzDOWorkItemReference([int]$id, [string]$url) {
        $this.Id = $id
        $this.Url = $url

        # Try to extract the work item ID from URL
        if ($url -match '/workItems/(\d+)') {
            $this.WorkItemId = [int]$Matches[1]
        }
    }
}

# Class representing a detailed work item
class AzDOWorkItem {
    [int]$Id
    [int]$Rev
    [string]$Url
    [string]$WorkItemType
    [string]$Title
    [string]$Description
    [string]$State
    [string]$CreatedBy
    [string]$AssignedTo
    [DateTime]$CreatedDate
    [DateTime]$ChangedDate
    [array]$Relations = @()
    [hashtable]$Fields = @{}
    [int]$ParentId = 0
    [string[]]$ChildIds = @()
    [string[]]$Tags = @()

    # Properties for backlog hierarchy
    [string]$IndustryPillar
    [string]$Scenario
    [string]$Capability
    [string[]]$ScenarioList = @() # Added to support many-to-many relationships

    AzDOWorkItem() {
        # Default constructor
        $this.Relations = @()
        $this.Fields = @{}
        $this.ChildIds = @()
        $this.ScenarioList = @()
    }

    # Extract parent ID from relations
    [int] GetParentId() {
        if ($this.Relations) {
            $parentRelation = $this.Relations | Where-Object { $_.rel -eq 'System.LinkTypes.Hierarchy-Reverse' } | Select-Object -First 1
            if ($parentRelation -and $parentRelation.url -match '/workItems/(\d+)$') {
                return [int]$matches[1]
            }
        }
        return 0
    }
}

# Class representing file change metrics for a PR
class PullRequestFileChangeMetric {
    # Number of files changed in the PR
    [int]$FilesChanged = 0

    # Number of lines added in the PR
    [int]$Additions = 0

    # Number of lines deleted in the PR
    [int]$Deletions = 0

    # List of file paths that were modified
    [String[]]$DetailedFiles

    # Default constructor
    PullRequestFileChangeMetric() {
        $this.DetailedFiles = [String[]]@()
    }

    # Constructor with initial values
    PullRequestFileChangeMetric([int]$filesChanged, [int]$additions, [int]$deletions) {
        $this.FilesChanged = $filesChanged
        $this.Additions = $additions
        $this.Deletions = $deletions
        $this.DetailedFiles = [String[]]@()
    }

    # Method to add a detailed file path
    [void] AddDetailedFile([string]$filePath) {
        $this.DetailedFiles += $filePath
    }

    # Get total lines changed (additions + deletions)
    [int] GetTotalChanges() {
        return $this.Additions + $this.Deletions
    }
}

# Industry backlog specific work item types
class PillarWorkItem : AzDOWorkItem {

    # Simple default constructor with no logic
    PillarWorkItem() {
        # Empty constructor - inherits from base AzDOWorkItem
    }
}

class ScenarioWorkItem : AzDOWorkItem {
    # Add scenario-specific properties with no processing logic
    [string]$ParentPillar

    # Simple default constructor with no logic
    ScenarioWorkItem() {
        # Empty constructor - inherits from base AzDOWorkItem
    }
}

class CapabilityWorkItem : AzDOWorkItem {
    # Add capability-specific properties with no processing logic
    [string]$ParentScenario
    [int[]]$RelatedFeatureIds
    [string[]]$ScenarioList

    CapabilityWorkItem() {
        $this.ScenarioList = [String[]]@()
        $this.RelatedFeatureIds = [Int[]]@()
    }
}

class FeatureWorkItem : AzDOWorkItem {
    # Add feature-specific properties with no processing logic
    [string]$BusinessValue
    [string]$AcceptanceCriteria
    [int[]]$ParentCapabilityId

    FeatureWorkItem() {
        $this.ParentCapabilityId = [Int[]]@()
    }
}

class IndustryBacklogCollection {
    # Convert ArrayLists to strongly typed arrays
    [AzDOWorkItem[]]$WorkItems
    [AzDOWorkItem[]]$Pillars
    [ScenarioWorkItem[]]$Scenarios
    [CapabilityWorkItem[]]$Capabilities
    [FeatureWorkItem[]]$Features

    # Constructor - initialize with empty arrays
    IndustryBacklogCollection() {
        $this.WorkItems = @()
        $this.Pillars = @()
        $this.Scenarios = @()
        $this.Capabilities = @()
        $this.Features = @()
    }
}

Export-ModuleMember -Variable *
