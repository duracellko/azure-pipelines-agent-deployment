# Deletes build agent from specified agent pool

param
(
    [string] $VstsUrl,
    [string] $AuthToken,
    [string] $AgentPool = 'default',
    [string] $AgentName
)

try {

    # Construct authorization header
    $PATenc = [System.Text.Encoding]::ASCII.GetBytes(':' + $AuthToken)
    $PATenc = [System.Convert]::ToBase64String($PATenc)
    $headers = @{ Authorization = "Basic $PATenc" }

    Write-Output "Searching for agent $AgentName in pool $AgentPool."

    # Find specified pool
    $url = $VstsUrl + "_apis/distributedtask/pools"
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing -Headers $headers
    $pools = ConvertFrom-Json -InputObject $response.Content

    $pool = $pools.value | Where-Object { $_.name -eq $AgentPool }
    if ($null -eq $pool) {
        throw "Agent Pool '$AgentPool' was not found"
    }

    # Find agent in the pool
    $url = $VstsUrl + "_apis/distributedtask/pools/$($pool.id)/agents"
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing -Headers $headers
    $agents = ConvertFrom-Json -InputObject $response.Content

    $agent = $agents.value | Where-Object { $_.name -eq $AgentName }
    if ($null -eq $agent) {
        throw "Agent '$AgentName' was not found"
    }

    # Delete build agent
    Write-Output "Deleting build agent $($agent.id)."
    $url = $VstsUrl + "_apis/distributedtask/pools/$($pool.id)/agents/$($agent.id)?api-version=4.1"
    $response = Invoke-WebRequest -Uri $url -Method Delete -UseBasicParsing -Headers $headers
    Write-Output "Build agent $($agent.id) was deleted."
}
catch {
    throw
}
