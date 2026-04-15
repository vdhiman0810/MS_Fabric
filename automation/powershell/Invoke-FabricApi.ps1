param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("GET", "POST", "PATCH", "PUT", "DELETE")]
    [string] $Method,

    [Parameter(Mandatory = $true)]
    [string] $Uri,

    [Parameter(Mandatory = $false)]
    [object] $Body
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$token = az account get-access-token --resource https://api.fabric.microsoft.com --query accessToken -o tsv

if (-not $token) {
    throw "Failed to obtain a Fabric API access token from Azure CLI."
}

$headers = @{
    Authorization = "Bearer $token"
}

if ($PSBoundParameters.ContainsKey("Body")) {
    $jsonBody = $Body | ConvertTo-Json -Depth 20
    Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers -ContentType "application/json" -Body $jsonBody
}
else {
    Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers
}

