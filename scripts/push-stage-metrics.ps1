param(
    [string]$Stage,
    [ValidateSet("INIT", "SUCCESS", "FAILURE", "UNSTABLE")]
    [string]$Status
)

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# CI/CD PIPELINE STAGES
# ------------------------------------------------------------

$stages = @(
    "Checkout",
    "Install",
    "Lint",
    "Test",
    "Security Scan - Trivy",
    "SonarCloud Analysis",
    "Docker Build",
    "Archive Application",
    "Deploy to Vercel",
    "OWASP ZAP Scan",
    "DefectDojo - Trivy",
    "DefectDojo - ZAP"
)

# ------------------------------------------------------------
# FILES
# ------------------------------------------------------------

$stateFile = "ci-stage-state.json"
$metricsFile = "ci-stage-metrics.prom"

# ------------------------------------------------------------
# INITIALIZE ALL STAGES
#
# -1 = NOT RUN
#  0 = FAILED
#  1 = SUCCESS
#  2 = UNSTABLE
# ------------------------------------------------------------

if ($Status -eq "INIT") {

    $state = [ordered]@{}

    foreach ($s in $stages) {
        $state[$s] = -1
    }

    $state | ConvertTo-Json | Set-Content -Path $stateFile -Encoding UTF8
}

# ------------------------------------------------------------
# UPDATE ONE STAGE
# ------------------------------------------------------------

else {

    if (Test-Path $stateFile) {

        $stateObject = Get-Content -Path $stateFile -Raw |
            ConvertFrom-Json

        $state = [ordered]@{}

        foreach ($s in $stages) {

            $property = $stateObject.PSObject.Properties[$s]

            if ($null -ne $property) {
                $state[$s] = [int]$property.Value
            }
            else {
                $state[$s] = -1
            }
        }
    }

    else {

        $state = [ordered]@{}

        foreach ($s in $stages) {
            $state[$s] = -1
        }
    }

    # Validate stage name
    if ($Stage -notin $stages) {
        Write-Host "WARNING: Unknown stage: $Stage"
        exit 0
    }

    # Set stage status
    switch ($Status) {

        "SUCCESS" {
            $state[$Stage] = 1
        }

        "FAILURE" {
            $state[$Stage] = 0
        }

        "UNSTABLE" {
            $state[$Stage] = 2
        }
    }

    $state | ConvertTo-Json | Set-Content -Path $stateFile -Encoding UTF8
}

# ------------------------------------------------------------
# CREATE PROMETHEUS METRICS
# ------------------------------------------------------------

$lines = @()

$lines += "# TYPE ci_stage_status gauge"

foreach ($s in $stages) {

    $value = [int]$state[$s]

    # Escape Prometheus label characters
    $escapedStage = $s.Replace('\', '\\').Replace('"', '\"')

    $lines += "ci_stage_status{stage=`"$escapedStage`"} $value"
}

# Add current Jenkins build number
$buildNumber = $env:BUILD_NUMBER

if ([string]::IsNullOrWhiteSpace($buildNumber)) {
    $buildNumber = "0"
}

$lines += ""
$lines += "# TYPE ci_pipeline_build_number gauge"
$lines += "ci_pipeline_build_number $buildNumber"

$payload = ($lines -join "`n") + "`n"

# ------------------------------------------------------------
# WRITE METRICS FILE
# ------------------------------------------------------------

[System.IO.File]::WriteAllText(
    $metricsFile,
    $payload,
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host ""
Write-Host "=========================================="
Write-Host "CI/CD STAGE METRICS"
Write-Host "=========================================="
Write-Host $payload

# ------------------------------------------------------------
# PUSH TO PROMETHEUS PUSHGATEWAY
# ------------------------------------------------------------

$pushgatewayUrl =
    "http://localhost:9091/metrics/job/jenkins-stages/instance/todo-list"

Write-Host "Pushing metrics to:"
Write-Host $pushgatewayUrl

curl.exe -sS --fail-with-body `
    --data-binary "@$metricsFile" `
    "$pushgatewayUrl"

if ($LASTEXITCODE -ne 0) {
    Write-Host "WARNING: Failed to push metrics to Pushgateway."
    exit 0
}

Write-Host ""
Write-Host "Stage metrics pushed successfully."