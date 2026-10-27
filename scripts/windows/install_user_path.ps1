# Append BinDir to the current user's PATH if missing (setx 1024 limit avoided).
# Called by install-windows.cmd. Default dev copy previously lived in ../co/windows/.
param(
  [Parameter(Mandatory = $true)]
  [string]$BinDir
)
$ErrorActionPreference = "Stop"
$bin = [System.IO.Path]::GetFullPath($BinDir)
$cur = [Environment]::GetEnvironmentVariable("Path", "User")
if ($null -eq $cur) { $cur = "" }
$parts = @($cur.Split(";", [StringSplitOptions]::RemoveEmptyEntries) | ForEach-Object { $_.TrimEnd("\") })
$norm = $bin.TrimEnd("\")
$hit = $false
foreach ($p in $parts) {
  if ([string]::Equals($p, $norm, [StringComparison]::OrdinalIgnoreCase)) { $hit = $true; break }
}
if (-not $hit) {
  if ($cur.Trim() -eq "") {
    [Environment]::SetEnvironmentVariable("Path", $norm, "User")
  } else {
    [Environment]::SetEnvironmentVariable("Path", ($cur.TrimEnd(";") + ";" + $norm), "User")
  }
  Write-Host "[install-windows] user PATH += $norm"
} else {
  Write-Host "[install-windows] user PATH already has $norm"
}

# Explorer / Win+R pick up User PATH after this. Already-running IDEs keep the old env.
try {
  if (-not ("Win32.NativeMethods" -as [type])) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
namespace Win32 {
  public class NativeMethods {
    [DllImport("user32.dll", SetLastError=true, CharSet=CharSet.Auto)]
    public static extern IntPtr SendMessageTimeout(
      IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
      uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
  }
}
"@
  }
  $unused = [UIntPtr]::Zero
  [void][Win32.NativeMethods]::SendMessageTimeout(
    [IntPtr]0xffff, 0x1A, [UIntPtr]::Zero, "Environment", 2, 2000, [ref]$unused)
} catch {
}
exit 0
