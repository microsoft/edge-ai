# AzDO-Types.psm1
# Type definitions for Azure DevOps API interactions

class AzDOApiParameters {
    [string]$Organization
    [string]$Project
    [string]$Repository
    [hashtable]$Headers
    [string]$ApiVersion
    [string]$RepositoryId

    # Default constructor
    AzDOApiParameters() {
        $this.Repository = $null
    }

    # Constructor with required parameters
    AzDOApiParameters([string]$Organization, [string]$Project, [hashtable]$Headers, [string]$ApiVersion) {
        $this.Organization = $Organization
        $this.Project = $Project
        $this.Repository = $null
        $this.Headers = $Headers
        $this.ApiVersion = $ApiVersion
    }

    # Constructor with all parameters
    AzDOApiParameters([string]$Organization, [string]$Project, [string]$Repository, [hashtable]$Headers, [string]$ApiVersion) {
        $this.Organization = $Organization
        $this.Project = $Project
        $this.Repository = $Repository
        $this.Headers = $Headers
        $this.ApiVersion = $ApiVersion
    }

    # Validate required properties are set
    [bool] Validate() {
        return -not [string]::IsNullOrWhiteSpace($this.Organization) -and
               -not [string]::IsNullOrWhiteSpace($this.Project) -and
               $null -ne $this.Headers -and
               -not [string]::IsNullOrWhiteSpace($this.ApiVersion)
    }

    # Generate the base API URL
    [string] GetBaseApiUrl() {
        return "https://dev.azure.com/$($this.Organization)/$($this.Project)/_apis"
    }
}

# Pull Request class to represent an Azure DevOps PR
class AzDOPullRequest {
    # Basic properties
    [int]$Id
    [int]$PullRequestId
    [string]$Title
    [string]$Description
    [string]$Status
    [string]$MergeStatus
    [string]$MergeId

    # API URLs
    [string]$Url
    [string]$RemoteUrl

    # PR metadata
    [string]$CodeReviewId
    [bool]$SupportsIterations
    [string]$ArtifactId
    [bool]$IsDraft

    # Repository information
    [string]$RepositoryId
    [string]$RepositoryName
    [string]$ProjectId
    [string]$RepositoryUrl

    # Branch information
    [string]$SourceRefName
    [string]$TargetRefName
    [string]$SourceBranch
    [string]$TargetBranch

    # Author information
    [string]$CreatedById
    [string]$CreatedByName
    [string]$CreatedByEmail
    [string]$CreatedByDisplayName
    [string]$CreatedByUniqueName
    [string]$CreatedByImageUrl

    # Dates
    [datetime]$CreationDate
    [datetime]$ClosedDate
    [datetime]$LastUpdateTime

    # Commit information
    [AzDOPullRequestCommit]$LastMergeCommit
    [AzDOPullRequestCommit]$LastMergeSourceCommit
    [AzDOPullRequestCommit]$LastMergeTargetCommit

    # Related information
    [AzDOPullRequestReviewer[]]$Reviewers
    [AzDOWorkItem[]]$WorkItems
    [String[]]$DetailedFiles

    # Default constructor
    AzDOPullRequest() {
        $this.Reviewers = [AzDOPullRequestReviewer[]]@()
        $this.WorkItems = [AzDOWorkItem[]]@()
        $this.DetailedFiles = [String[]]@()
        $this.LastMergeCommit = $null
        $this.LastMergeSourceCommit = $null
        $this.LastMergeTargetCommit = $null
    }


    # Method to get web URL
    [string] GetWebUrl() {
        # Format: https://dev.azure.com/{organization}/{project}/_git/{repository}/pullrequest/{id}
        return "https://dev.azure.com/$($this.Organization)/$($this.Project)/_git/$($this.RepositoryName)/pullrequest/$($this.Id)"
    }
}

# Reviewer class for pull requests
class AzDOPullRequestReviewer {
    [string]$Id
    [string]$DisplayName
    [string]$UniqueName
    [int]$VoteValue
    [string]$VoteStatus
    [bool]$IsRequired
    [bool]$HasDeclined
    [Nullable[datetime]]$VoteDate  # Changed from [datetime] to [Nullable[datetime]] to support null values

    # Default constructor
    AzDOPullRequestReviewer() {
    }

    # Constructor with basic properties
    AzDOPullRequestReviewer([string]$Id, [string]$DisplayName, [string]$UniqueName) {
        $this.Id = $Id
        $this.DisplayName = $DisplayName
        $this.UniqueName = $UniqueName
        $this.VoteValue = 0
        $this.VoteStatus = "No vote"
        $this.IsRequired = $false
        $this.HasDeclined = $false
        $this.VoteDate = $null  # Now can be safely set to null
    }
}

# Class representing a single commit in a pull request
class AzDOPullRequestCommit {
    [string]$CommitId
    [string]$Author
    [string]$CommitterName
    [string]$Comment
    [datetime]$CommitterDate
    [string]$Url

    AzDOPullRequestCommit([PSCustomObject]$commitData) {
        if ($null -ne $commitData) {
            $this.CommitId = $commitData.commitId
            $this.Url = $commitData.url

            # Handle author information if available
            if ($commitData.PSObject.Properties.Name -contains "author" -and $null -ne $commitData.author) {
                $this.Author = $commitData.author.name
            }

            # Handle committer information if available
            if ($commitData.PSObject.Properties.Name -contains "committer" -and $null -ne $commitData.committer) {
                $this.CommitterName = $commitData.committer.name

                # Parse the committer date if it exists
                if ($commitData.committer.PSObject.Properties.Name -contains "date" -and $commitData.committer.date) {
                    try {
                        $this.CommitterDate = [datetime]::Parse($commitData.committer.date)
                    }
                    catch {
                        $this.CommitterDate = [datetime]::MinValue
                        Write-Verbose "Failed to parse committer date: $($commitData.committer.date)"
                    }
                }
            }

            # Handle comment/message if available
            if ($commitData.PSObject.Properties.Name -contains "comment") {
                $this.Comment = $commitData.comment
            }
            elseif ($commitData.PSObject.Properties.Name -contains "message") {
                $this.Comment = $commitData.message
            }
        }
    }

    # Default constructor
    AzDOPullRequestCommit() {
        $this.CommitId = ""
        $this.Author = ""
        $this.CommitterName = ""
        $this.Comment = ""
        $this.CommitterDate = [datetime]::MinValue
        $this.Url = ""
    }
}

# Class for Pull Request Comment representation
class AzDOPullRequestComment {
    [int]$Id
    [string]$Content
    [string]$CommentType
    [string]$AuthorEmail
    [string]$AuthorDisplayName
    [datetime]$CreatedDate
    [datetime]$LastUpdatedDate
    [bool]$IsDeleted
    [int]$ParentCommentId  # Added missing property

    # Default constructor
    AzDOPullRequestComment() {}

    # Constructor with parameters
    AzDOPullRequestComment([PSCustomObject]$commentData) {
        $this.Id = $commentData.id
        $this.Content = $commentData.content
        $this.CommentType = $commentData.commentType
        $this.AuthorEmail = $commentData.author.uniqueName
        $this.AuthorDisplayName = $commentData.author.displayName
        $this.CreatedDate = [DateTime]::Parse($commentData.publishedDate)
        $this.ParentCommentId = $commentData.parentCommentId  # Initialize the new property

        # Handle optional properties
        if ($commentData.PSObject.Properties['lastUpdatedDate'] -and $commentData.lastUpdatedDate) {
            $this.LastUpdatedDate = [DateTime]::Parse($commentData.lastUpdatedDate)
        }
        $this.IsDeleted = [bool]($commentData.isDeleted)
    }
}

# Class for Pull Request Thread representation
class AzDOPullRequestThread {
    [int]$Id
    [string]$Status
    [datetime]$CreatedDate
    [bool]$IsDeleted
    [int]$CommentsCount
    [AzDOPullRequestComment[]]$Comments
    [string]$FilePath
    [int]$Position
    [PSCustomObject]$ThreadContext

    # Default constructor
    AzDOPullRequestThread() {}

    # Constructor with parameters
    AzDOPullRequestThread([PSCustomObject]$threadData) {
        $this.Id = $threadData.id
        $this.Status = $threadData.status
        $this.CreatedDate = [DateTime]::Parse($threadData.publishedDate)
        $this.IsDeleted = [bool]($threadData.isDeleted)
        $this.CommentsCount = $threadData.comments.Count
        $this.ThreadContext = $threadData.threadContext  # Store the thread context

        # Handle file path for code comments
        if ($threadData.threadContext -and $threadData.threadContext.filePath) {
            $this.FilePath = $threadData.threadContext.filePath
            if ($threadData.threadContext.rightFileStart) {
                $this.Position = $threadData.threadContext.rightFileStart.line
            }
        }

        # Process comments
        $this.Comments = [AzDOPullRequestComment[]]@()
        foreach ($comment in $threadData.comments) {
            $this.Comments += [AzDOPullRequestComment]::new($comment)
        }
        $this.Comments = $this.Comments
    }
}

# Collection class for PR threads
class AzDOPullRequestThreadCollection {
    [int]$TotalThreads
    [int]$TotalComments
    [int]$ActiveThreads
    [int]$FixedThreads
    [int]$ClosedThreads
    [AzDOPullRequestThread[]]$Threads
    [hashtable]$CommentsByReviewer
    [datetime]$FirstReviewerEngagement

    # Default constructor
    AzDOPullRequestThreadCollection() {
        $this.TotalThreads = 0
        $this.TotalComments = 0
        $this.ActiveThreads = 0
        $this.FixedThreads = 0
        $this.ClosedThreads = 0
        $this.Threads = @()
        $this.CommentsByReviewer = @{}
        $this.FirstReviewerEngagement = $null
    }

    # Constructor with parameters
    AzDOPullRequestThreadCollection([PSCustomObject]$threadsResponse) {
        $this.TotalThreads = $threadsResponse.count
        $this.TotalComments = 0
        $this.ActiveThreads = 0
        $this.FixedThreads = 0
        $this.ClosedThreads = 0
        $this.CommentsByReviewer = @{}

        # Track first reviewer engagement
        $firstEngagementTime = $null

        # Create a dynamic list for threads
        $this.Threads = New-Object System.Collections.Generic.List[AzDOPullRequestThread]

        # Process threads - if threadsResponse has no value property or it's null, skip processing
        if ($threadsResponse.PSObject.Properties.Name -contains "value" -and $null -ne $threadsResponse.value) {
            foreach ($thread in $threadsResponse.value) {
                try {
                    # Create thread object
                    $threadObj = [AzDOPullRequestThread]::new($thread)
                    $this.Threads.Add($threadObj)  # Use .Add() method instead of += operator

                    # Update thread status counts - use the thread data directly
                    if ($thread.PSObject.Properties.Name -contains "status") {
                        if ($thread.status -eq "active") { $this.ActiveThreads++ }
                        elseif ($thread.status -eq "fixed") { $this.FixedThreads++ }
                        elseif ($thread.status -eq "closed") { $this.ClosedThreads++ }
                    }

                    # Process comments only if they exist
                    if ($thread.PSObject.Properties.Name -contains "comments" -and $null -ne $thread.comments) {
                        foreach ($comment in $thread.comments) {
                            $this.TotalComments++

                            # Safely check author properties with null checks
                            $commentAuthorName = $null
                            $threadAuthorName = $null

                            if ($comment.PSObject.Properties.Name -contains "author" -and
                                $null -ne $comment.author -and
                                $comment.author.PSObject.Properties.Name -contains "displayName") {
                                $commentAuthorName = $comment.author.displayName
                            }

                            if ($thread.PSObject.Properties.Name -contains "author" -and
                                $null -ne $thread.author -and
                                $thread.author.PSObject.Properties.Name -contains "displayName") {
                                $threadAuthorName = $thread.author.displayName
                            }

                            # Track first non-author engagement for SLO metrics
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
                                    # Continue execution after logging the error
                                }
                            }

                            # Track comments by reviewer with proper null checks
                            if ($comment.PSObject.Properties.Name -contains "author" -and
                                $null -ne $comment.author -and
                                $comment.author.PSObject.Properties.Name -contains "uniqueName") {

                                $authorEmail = $comment.author.uniqueName
                                $commentType = if ($comment.PSObject.Properties.Name -contains "commentType") { $comment.commentType } else { "" }

                                if (-not [string]::IsNullOrEmpty($authorEmail) -and $commentType -ne "system") {
                                    if (-not $this.CommentsByReviewer.ContainsKey($authorEmail)) {
                                        $this.CommentsByReviewer[$authorEmail] = @{
                                            Count = 0
                                            DisplayName = $commentAuthorName
                                            Email = $authorEmail
                                        }

                                        # Safely parse and add date
                                        if ($comment.PSObject.Properties.Name -contains "publishedDate") {
                                            try {
                                                $this.CommentsByReviewer[$authorEmail].FirstCommentTime = [DateTime]::Parse($comment.publishedDate)
                                            }
                                            catch {
                                                Write-Verbose "Failed to parse comment date for reviewer $($authorEmail): $_"
                                                # If date parsing fails, don't add the property
                                            }
                                        }
                                    }
                                    $this.CommentsByReviewer[$authorEmail].Count++
                                }
                            }
                        }
                    }
                }
                catch {
                    # Log the error but continue processing other threads
                    Write-Warning "Error processing thread: $_"
                }
            }
        }

        # Set the first reviewer engagement time
        $this.FirstReviewerEngagement = $firstEngagementTime

        # Don't convert to fixed-size array - keep as a List<> for future additions if needed
        # If a fixed-size array is required, only do this at the very end of processing
    }
}

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
    PullRequestFileChangeMetric() {  # Fixed: constructor name matches class name
        $this.DetailedFiles = [String[]]@()
    }

    # Constructor with initial values
    PullRequestFileChangeMetric([int]$filesChanged, [int]$additions, [int]$deletions) {  # Fixed: name matches
        $this.FilesChanged = $filesChanged
        $this.Additions = $additions
        $this.Deletions = $deletions
        $this.DetailedFiles = [String[]]@()
    }

    # Add a detailed file to the collection
    [void] AddDetailedFile([string]$filePath) {
        $this.DetailedFiles += $filePath
    }

    # Get total lines changed (additions + deletions)
    [int] GetTotalChanges() {
        return $this.Additions + $this.Deletions
    }
}

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

class AzDOWorkItem {
    [int]$Id
    [int]$Rev
    [string]$Url
    [string]$WorkItemType
    [string]$Title
    [string]$State
    [string]$CreatedBy
    [string]$AssignedTo
    [DateTime]$CreatedDate
    [DateTime]$ChangedDate
    [array]$Relations = @()

    AzDOWorkItem() {
        # Default constructor
    }
}

Export-ModuleMember -Variable *
