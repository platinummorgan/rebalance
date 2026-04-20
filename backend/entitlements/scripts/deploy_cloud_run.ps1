param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectId,

    [Parameter(Mandatory = $true)]
    [string]$Region,

    [Parameter(Mandatory = $false)]
    [string]$ServiceName = "wealth-dial-entitlements",

    [Parameter(Mandatory = $false)]
    [string]$Image = ""
)

$ErrorActionPreference = "Stop"
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$serviceRoot = Resolve-Path (Join-Path $scriptRoot "..")

if (-not $Image) {
    $Image = "gcr.io/$ProjectId/$ServiceName:latest"
}

Write-Host "Deploying $ServiceName to Cloud Run..."
Write-Host "Project: $ProjectId"
Write-Host "Region:  $Region"
Write-Host "Image:   $Image"

gcloud config set project $ProjectId | Out-Null

# Build and push image
Push-Location $serviceRoot
gcloud builds submit `
    --tag $Image `
    .
Pop-Location

# Deploy service
gcloud run deploy $ServiceName `
    --image $Image `
    --region $Region `
    --platform managed `
    --allow-unauthenticated `
    --set-env-vars "GOOGLE_PLAY_PACKAGE_NAME=com.wealthdial.app,GOOGLE_PLAY_LIFETIME_PRODUCT_IDS=founder_lifetime,ALLOW_TOKEN_TRANSFER=false" `
    --update-secrets "ENTITLEMENT_API_KEY=ENTITLEMENT_API_KEY:latest"

$url = gcloud run services describe $ServiceName --region $Region --format "value(status.url)"
Write-Host ""
Write-Host "Deployment complete."
Write-Host "Service URL: $url"
Write-Host ""
Write-Host "Next step: use this URL for Flutter --dart-define ENTITLEMENT_API_BASE_URL."
