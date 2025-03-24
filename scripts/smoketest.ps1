param (
    [string]$url,
    [int]$maxRetries,
    [int]$sleepTime,
    [hashtable]$headers = @{}
)

$success = $false
for ($i = 0; $i -lt $maxRetries; $i++) {
    Write-Host "Request $($i + 1) of $maxRetries"
    try {
        Invoke-RestMethod -Uri $url -Headers $headers
        $success = $true
        break
    } catch {
        Write-Host "Request failed with status code $($_.Exception.Response.StatusCode)"
        Write-Host "Retrying in $sleepTime seconds..."
        Start-Sleep -Seconds $sleepTime
    }
}
if (-not $success) {
    Write-Error "HealthCheck failed after $maxRetries attempts."
    exit 1
}
