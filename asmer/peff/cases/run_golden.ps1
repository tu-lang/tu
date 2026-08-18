# Golden: mother tua vs self-hosted tu -c --target=windows
# Byte identity is not required: mother iterates unordered_map, selfhost sorts
# defined names. STRUCT compare uses dumpbin headers + symbol-name sets.
param(
  [string]$CoRoot = "E:\Workspace\co",
  [string]$TuRoot = "E:\Workspace\tu",
  [string]$TuExe = ""
)
$ErrorActionPreference = "Continue"
$bin = Join-Path $CoRoot "build-win\RelWithDebInfo"
$vcvars = "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
$envBlock = cmd /c "`"$vcvars`" >nul && set"
foreach ($line in $envBlock -split "`r?`n") {
  if ($line -match "^([^=]+)=(.*)$") {
    [Environment]::SetEnvironmentVariable($Matches[1], $Matches[2], "Process")
  }
}
$env:PATH = "C:\Windows\System32;C:\Windows;$bin;" + $env:PATH
$env:CO_PKG = Join-Path $CoRoot "build-win\lib\copkg"
$env:CO_WINDOWS_COASM = Join-Path $CoRoot "build-win\lib\coasm-windows"
$env:CO_PEFF_LIB = Join-Path $CoRoot "build-win\lib\copeff"
if (-not $TuExe) { $TuExe = Join-Path $env:TEMP "tu-selfhost-stage\tu.exe" }
$tua = Join-Path $bin "tua.exe"
$work = Join-Path $env:TEMP "peff-golden"
if (Test-Path $work) { Remove-Item -Recurse -Force $work }
New-Item -Force -ItemType Directory $work | Out-Null

function Get-CoffStruct([string]$path) {
  $h = dumpbin /HEADERS $path 2>$null | Out-String
  $s = dumpbin /SYMBOLS $path 2>$null | Out-String
  $names = [regex]::Matches($s, '\|\s+(\S+)\s*$') | ForEach-Object { $_.Groups[1].Value }
  $set = ($names | Sort-Object) -join ","
  $mach = if ($h -match '8664 machine') { '8664' } else { '?' }
  $nsec = if ($h -match '(\d+)\s+number of sections') { $Matches[1] } else { '?' }
  $nsym = if ($h -match '([0-9A-Fa-f]+)\s+number of symbols') { $Matches[1] } else { '?' }
  $t = if ($h -match 'SECTION HEADER #1[\s\S]*?([0-9A-Fa-f]+)\s+size of raw data') { $Matches[1] } else { '?' }
  $nr = if ($h -match 'SECTION HEADER #1[\s\S]*?([0-9A-Fa-f]+)\s+number of relocations') { $Matches[1] } else { '?' }
  return "$mach|$nsec|$nsym|$t|$nr|$set"
}

$files = @()
$files += Get-ChildItem (Join-Path $TuRoot "asmer\peff\cases\*.s")
$files += Get-ChildItem (Join-Path $CoRoot "asmer\peff\cases\*.s")
$coasm = Join-Path $CoRoot "build-win\lib\coasm-windows"
if (Test-Path $coasm) { $files += Get-ChildItem (Join-Path $coasm "*.s") }
$seen = @{}
$ident = 0; $struct = 0; $fail = 0; $n = 0
foreach ($f in $files) {
  $key = $f.Name.ToLower()
  if ($seen.ContainsKey($key)) { continue }
  $seen[$key] = $true
  $n++
  $md = Join-Path $work ("m-{0}" -f $f.BaseName)
  $sd = Join-Path $work ("s-{0}" -f $f.BaseName)
  New-Item -Force -ItemType Directory $md | Out-Null
  New-Item -Force -ItemType Directory $sd | Out-Null
  Copy-Item $f.FullName (Join-Path $md $f.Name)
  Copy-Item $f.FullName (Join-Path $sd $f.Name)
  Push-Location $md
  & $tua --target=windows -c $f.Name 2>$null | Out-Null
  $mrc = $LASTEXITCODE
  Pop-Location
  Push-Location $sd
  & $TuExe --target=windows -c $f.Name 2>$null | Out-Null
  $src = $LASTEXITCODE
  Pop-Location
  $mo = Join-Path $md ($f.BaseName + ".o")
  $so = Join-Path $sd ($f.BaseName + ".o")
  if (($mrc -ne 0) -or ($src -ne 0) -or -not (Test-Path $mo) -or -not (Test-Path $so)) {
    Write-Host "FAIL assemble $($f.Name) mother=$mrc self=$src"
    $fail++
    continue
  }
  cmd /c "fc /b `"$mo`" `"$so`" >nul"
  if ($LASTEXITCODE -eq 0) {
    Write-Host "IDENT $($f.Name)"
    $ident++
    $struct++
    continue
  }
  $a = Get-CoffStruct $mo
  $b = Get-CoffStruct $so
  if ($a -eq $b) {
    Write-Host "STRUCT $($f.Name) (order-only)"
    $struct++
  } else {
    Write-Host "FAIL struct $($f.Name)"
    Write-Host "  mother $a"
    Write-Host "  self   $b"
    $fail++
  }
}
Write-Host "==== golden files=$n ident=$ident struct_ok=$struct fail=$fail ===="
if ($fail -gt 0) { exit 1 }
exit 0
