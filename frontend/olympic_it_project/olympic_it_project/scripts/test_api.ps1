try {
  Invoke-RestMethod -Method Post -Uri 'http://localhost:8080/api/dev/init-admin' -ErrorAction SilentlyContinue | Out-Null
} catch {}

try {
  $login = Invoke-RestMethod -Method Post -Uri 'http://localhost:8080/api/auth/login' -ContentType 'application/json' -Body '{"username":"admin","password":"123456"}' -ErrorAction Stop
  Write-Output "LOGIN_JSON: $($login | ConvertTo-Json -Depth 5)"
  $token = $login.data.accessToken
  Write-Output "TOKEN: $token"
} catch {
  Write-Output "LOGIN_FAILED: $($_.Exception.Message)"
  exit 1
}

if ([string]::IsNullOrEmpty($token)) { Write-Output 'No token'; exit 1 }

try {
  $create = Invoke-RestMethod -Method Post -Uri 'http://localhost:8080/api/admin/academic-year/create' -ContentType 'application/json' -Body '{"academicYearName":"2026-2028-ps-test"}' -Headers @{ Authorization = "Bearer $token" } -ErrorAction Stop
  Write-Output "CREATE_JSON: $($create | ConvertTo-Json -Depth 5)"
} catch {
  $err = $_.Exception
  if ($err -and $err.Response) {
    $status = $err.Response.StatusCode.value__
    $stream = $err.Response.GetResponseStream()
    $sr = New-Object System.IO.StreamReader($stream)
    $body = $sr.ReadToEnd()
    Write-Output "CREATE_ERROR_STATUS: $status"
    Write-Output "CREATE_ERROR_BODY: $body"
  } else {
    Write-Output "CREATE_EXCEPTION: $($_.Exception.Message)"
  }
}
