# Windows equivalent of build_all.sh: analyze, test, build Windows + Android.
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

function Step($msg) { Write-Host "`n==> $msg" }
function Run($dir, [string[]]$cmd) {
  Push-Location $dir
  try { & $cmd[0] $cmd[1..($cmd.Length - 1)]; if ($LASTEXITCODE -ne 0) { throw "$($cmd -join ' ') failed in $dir" } }
  finally { Pop-Location }
}

Step 'Tool versions'; flutter --version
Step 'Dependencies'; Run . @('flutter', 'pub', 'get')
Step 'Analyze'; Run . @('dart', 'analyze', 'packages', 'apps')
Step 'Pure Dart tests'
foreach ($p in 'scanbridge_domain', 'scanbridge_protocol', 'scanbridge_template_engine', 'scanbridge_storage') { Run "packages\$p" @('dart', 'test') }
Step 'Desktop host tests'; Run apps\desktop @('flutter', 'test')

Step 'Build Windows'; Run apps\desktop @('flutter', 'build', 'windows', '--release')
$exe = 'apps\desktop\build\windows\x64\runner\Release\scanbridge_desktop.exe'
if (-not (Test-Path $exe)) { throw "MISSING: $exe" } else { Write-Host "OK: $exe" }

Step 'Build Android APK'; Run apps\mobile @('flutter', 'build', 'apk', '--release')
$apk = 'apps\mobile\build\app\outputs\flutter-apk\app-release.apk'
if (-not (Test-Path $apk)) { throw "MISSING: $apk" } else { Write-Host "OK: $apk" }
