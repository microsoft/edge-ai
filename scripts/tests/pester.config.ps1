param(
    [switch]$CI,
    [switch]$CodeCoverage,
    [string]$OutputPath = './test-results',
    [string[]]$Path = @('./scripts')
)

$config = New-PesterConfiguration

$config.Run.Path = $Path
$config.Run.Exit = $CI.IsPresent
$config.Run.PassThru = $true

$config.Output.Verbosity = if ($CI) { 'Detailed' } else { 'Normal' }

$config.TestResult.Enabled = $true
$config.TestResult.OutputFormat = 'NUnitXml'
$config.TestResult.OutputPath = Join-Path $OutputPath 'test-results.xml'

if ($CodeCoverage) {
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.OutputFormat = 'JaCoCo'
    $config.CodeCoverage.OutputPath = Join-Path $OutputPath 'coverage.xml'
    $config.CodeCoverage.Path = $Path
}

$config.Filter.ExcludeTag = @('Integration', 'Slow')

return $config
