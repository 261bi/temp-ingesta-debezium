$ErrorActionPreference = 'Stop'

$connectUrl = 'http://localhost:38083/connectors'
$root = Split-Path -Parent $PSScriptRoot

$sinkConfig = Get-Content -Raw (Join-Path $root 'connectors\postgres-sink.config.json')

Invoke-RestMethod -Method Put -Uri "$connectUrl/postgres-cdc-sink/config" -ContentType 'application/json' -Body $sinkConfig | Out-Null

for ($attempt = 1; $attempt -le 10; $attempt++) {
	try {
		$status = Invoke-RestMethod -Method Get -Uri "$connectUrl/postgres-cdc-sink/status"
		if ($status.connector.state) {
			return $status
		}
	}
	catch {
		if ($attempt -eq 10) {
			throw
		}
	}

	Start-Sleep -Seconds 1
}