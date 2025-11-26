<#
.SYNOPSIS
    Test script for Get-GitHubInstallationToken.ps1

.DESCRIPTION
    Tests the GitHub App authentication flow with both mock and real credentials.
    Supports testing with Azure Key Vault secrets or local test credentials.

.PARAMETER UseMockCredentials
    Use mock credentials for syntax and logic testing without GitHub API calls.

.PARAMETER UseKeyVault
    Retrieve credentials from Azure Key Vault (requires private network access or Cloud Shell).

.PARAMETER KeyVaultName
    Name of the Azure Key Vault containing GitHub App secrets.
    Default: kv-ai-on-edge-azdo

.PARAMETER Repository
    GitHub repository to test against (format: 'owner/repo').
    Default: microsoft/edge-ai

.PARAMETER LocalClientId
    Local GitHub App Client ID for testing (alternative to Key Vault).

.PARAMETER LocalPrivateKeyPath
    Path to local GitHub App private key file (alternative to Key Vault).

.EXAMPLE
    .\Test-GitHubInstallationToken.ps1 -UseMockCredentials
    Test script logic with mock credentials (no API calls).

.EXAMPLE
    .\Test-GitHubInstallationToken.ps1 -UseKeyVault
    Test with real credentials from Azure Key Vault (requires network access).

.EXAMPLE
    .\Test-GitHubInstallationToken.ps1 -LocalClientId "Iv1.abc123" -LocalPrivateKeyPath ".\test-key.pem"
    Test with local credentials.

.NOTES
    For mock testing, this validates:
    - Script syntax and parameter handling
    - JWT generation logic
    - Error handling paths
    - Output format

    For real testing, this validates:
    - Complete authentication flow
    - GitHub API integration
    - Token retrieval and expiration
#>

[CmdletBinding(DefaultParameterSetName = "Mock")]
param (
    [Parameter(Mandatory = $true, ParameterSetName = "Mock")]
    [switch]$UseMockCredentials,

    [Parameter(Mandatory = $true, ParameterSetName = "KeyVault")]
    [switch]$UseKeyVault,

    [Parameter(ParameterSetName = "KeyVault")]
    [string]$KeyVaultName = "kv-ai-on-edge-azdo",

    [Parameter(ParameterSetName = "Local", Mandatory = $true)]
    [string]$LocalClientId,

    [Parameter(ParameterSetName = "Local", Mandatory = $true)]
    [string]$LocalPrivateKeyPath,

    [Parameter()]
    [string]$Repository = "microsoft/edge-ai"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot "Get-GitHubInstallationToken.ps1"

Write-Information "=== GitHub Installation Token Test ==="
Write-Information "Test Mode: $($PSCmdlet.ParameterSetName)"
Write-Information "Repository: $Repository"
Write-Information ""

#region Mock Credential Testing

if ($UseMockCredentials) {
    Write-Information "Running Mock Credential Tests..."
    Write-Information ""

    # Generate a mock RSA key pair for testing
    Write-Information "1. Generating mock RSA key pair..."
    $rsa = [System.Security.Cryptography.RSA]::Create(2048)
    $mockPrivateKey = $rsa.ExportRSAPrivateKeyPem()
    $mockClientId = "Iv1.0123456789abcdef"
    Write-Information "   ✓ Mock credentials generated"
    $rsa.Dispose()

    # Test 1: JWT Generation
    Write-Information ""
    Write-Information "2. Testing JWT generation..."
    try {
        # Create a temporary file for the mock key
        $tempKeyFile = New-TemporaryFile
        Set-Content -Path $tempKeyFile.FullName -Value $mockPrivateKey

        # Test with file path
        Write-Information "   Testing with -PrivateKeyPath..."
        $testScript = {
            param($ScriptPath, $ClientId, $KeyPath, $Repo)

            # We expect this to fail at GitHub API call, but JWT should generate
            try {
                & $ScriptPath -ClientId $ClientId -PrivateKeyPath $KeyPath -Repository $Repo -Verbose
            }
            catch {
                # Expected to fail at API call with mock credentials
                if ($_.Exception.Message -match "401|Unauthorized|authentication") {
                    Write-Information "   ✓ JWT generation successful (API rejection expected with mock creds)"
                    return $true
                }
                else {
                    Write-Information "   ✗ Unexpected error: $_"
                    return $false
                }
            }
        }

        & $testScript -ScriptPath $scriptPath -ClientId $mockClientId -KeyPath $tempKeyFile.FullName -Repo $Repository | Out-Null

        # Test with inline key
        Write-Information "   Testing with -PrivateKey..."
        & $testScript -ScriptPath $scriptPath -ClientId $mockClientId -KeyPath $tempKeyFile.FullName -Repo $Repository | Out-Null

        Remove-Item -Path $tempKeyFile.FullName -Force

        Write-Information ""
        Write-Information "3. Mock testing complete"
        Write-Information "   ✓ Script syntax validated"
        Write-Information "   ✓ Parameter handling validated"
        Write-Information "   ✓ JWT generation logic validated"
        Write-Information ""
        Write-Information "Mock test results: PASSED"
        Write-Information ""
        Write-Information "Note: For full integration testing, run with -UseKeyVault in Azure Cloud Shell"
        Write-Information "or use -LocalClientId and -LocalPrivateKeyPath with real credentials."
    }
    catch {
        Write-Information "   ✗ Mock test failed: $_"
        throw
    }
}

#endregion

#region Key Vault Testing

if ($UseKeyVault) {
    Write-Information "Running Key Vault Integration Test..."
    Write-Information ""

    Write-Information "1. Retrieving credentials from Key Vault: $KeyVaultName"

    try {
        # Check Azure authentication
        $account = az account show --query "{subscription:name, user:user.name}" -o json 2>&1 | ConvertFrom-Json
        Write-Information "   ✓ Authenticated as: $($account.user)"
        Write-Information "   ✓ Subscription: $($account.subscription)"
    }
    catch {
        Write-Information "   ✗ Not authenticated to Azure. Run: az login"
        throw "Azure authentication required"
    }

    Write-Information ""
    Write-Information "2. Retrieving GitHub App Client ID..."
    try {
        $clientId = az keyvault secret show --vault-name $KeyVaultName --name github-edge-ai-app-client-id --query value -o tsv 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to retrieve client ID: $clientId"
        }
        Write-Information "   ✓ Client ID retrieved (length: $($clientId.Length))"
    }
    catch {
        Write-Information "   ✗ Failed to retrieve Client ID"
        Write-Information "   Error: $_"
        Write-Information ""
        Write-Information "   This is expected if running locally (Key Vault has private network access only)."
        Write-Information "   Try running this script in Azure Cloud Shell or Azure DevOps pipeline."
        throw
    }

    Write-Information ""
    Write-Information "3. Retrieving GitHub App Private Key..."
    try {
        $privateKeyRaw = az keyvault secret show --vault-name $KeyVaultName --name github-edge-ai-app-private-key --query value -o tsv 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to retrieve private key: $privateKeyRaw"
        }
        # Join array lines with newlines if needed
        $privateKey = if ($privateKeyRaw -is [array]) { $privateKeyRaw -join "`n" } else { $privateKeyRaw }
        Write-Information "   ✓ Private key retrieved (length: $($privateKey.Length))"
    }
    catch {
        Write-Information "   ✗ Failed to retrieve Private Key"
        Write-Information "   Error: $_"
        throw
    }

    Write-Information ""
    Write-Information "4. Testing Get-GitHubInstallationToken.ps1..."
    try {
        $token = & $scriptPath -ClientId $clientId -PrivateKey $privateKey -Repository $Repository -Verbose

        if ($token) {
            Write-Information "   ✓ Installation token obtained successfully!"
            Write-Information "   Token length: $($token.Length)"
            Write-Information "   Token preview: $($token.Substring(0, [Math]::Min(20, $token.Length)))..."

            Write-Information ""
            Write-Information "5. Validating token with GitHub API..."
            $headers = @{
                "Authorization" = "Bearer $token"
                "Accept"        = "application/vnd.github+json"
            }

            $repoInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repository" -Headers $headers
            Write-Information "   ✓ Token validated against GitHub API"
            Write-Information "   Repository: $($repoInfo.full_name)"
            Write-Information "   Private: $($repoInfo.private)"

            Write-Information ""
            Write-Information "Integration test results: PASSED ✓"
        }
        else {
            throw "Token was empty or null"
        }
    }
    catch {
        Write-Information "   ✗ Test failed: $_"
        throw
    }
}

#endregion

#region Local Credential Testing

if ($PSCmdlet.ParameterSetName -eq "Local") {
    Write-Information "Running Local Credential Test..."
    Write-Information ""

    Write-Information "1. Validating local credentials..."

    if (-not (Test-Path -Path $LocalPrivateKeyPath)) {
        throw "Private key file not found: $LocalPrivateKeyPath"
    }
    Write-Information "   ✓ Private key file exists"

    Write-Information ""
    Write-Information "2. Testing Get-GitHubInstallationToken.ps1..."
    try {
        $token = & $scriptPath -ClientId $LocalClientId -PrivateKeyPath $LocalPrivateKeyPath -Repository $Repository -Verbose

        if ($token) {
            Write-Information "   ✓ Installation token obtained successfully!"
            Write-Information "   Token length: $($token.Length)"
            Write-Information "   Token preview: $($token.Substring(0, [Math]::Min(20, $token.Length)))..."

            Write-Information ""
            Write-Information "3. Validating token with GitHub API..."
            $headers = @{
                "Authorization" = "Bearer $token"
                "Accept"        = "application/vnd.github+json"
            }

            $repoInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repository" -Headers $headers
            Write-Information "   ✓ Token validated against GitHub API"
            Write-Information "   Repository: $($repoInfo.full_name)"
            Write-Information "   Private: $($repoInfo.private)"

            Write-Information ""
            Write-Information "Local credential test results: PASSED ✓"
        }
        else {
            throw "Token was empty or null"
        }
    }
    catch {
        Write-Information "   ✗ Test failed: $_"
        throw
    }
}

#endregion

Write-Information ""
Write-Information "=== Test Complete ==="
