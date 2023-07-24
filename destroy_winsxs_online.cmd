<# : batch portion
@echo off
fltmc >nul 2>&1 || (
	echo Administrator privileges are required.
	PowerShell Start -Verb RunAs '%0' 2> nul || (
		echo You must run this script as admin.
		pause & exit /b 1
	)
	exit /b 0
)

set "psScript=%~f0" & powershell -nop -c "Get-Content """$env:psScript""" -Raw | iex" & exit /b
: end batch / begin PowerShell #>

# here you can bypass the CAB file picker and set a static CAB file
# alternatively, pass a CLI argument
# $cabPath = "C:\package"

# ----------- #

$certRegPath = "HKLM:\Software\Microsoft\SystemCertificates\ROOT\Certificates"

function PauseNul ($message = "Press any key to exit... ") {
	Write-Host $message -NoNewLine
	$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
	exit 1
}

Write-Host "This will install a specified self-signed CBS package, meaning live on your current install of Windows." -ForegroundColor Yellow
# i've tested it enough and it's fine
# Write-Host "Only run this in a virtual machine, it's highly experimental.`n" -ForegroundColor Red
Start-Sleep 1
pause
cls

if ($args[0]) {$cabPath = $args[0]}

if (!($cabPath)) {
	Write-Warning "Opening file dialog to select CBS package CAB..."
	Add-Type -AssemblyName System.Windows.Forms
	$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
	$openFileDialog.Filter = "CBS Package Files (*.cab)|*.cab"
	$openFileDialog.Title = "Select a CBS Package File"
	if ($openFileDialog.ShowDialog() -eq 'OK') {
		$cabPath = $openFileDialog.FileName
		cls
	} else {exit}
}

Write-Warning "Importing and checking certificate..."
$cert = (Get-AuthenticodeSignature $cabPath).SignerCertificate
foreach ($usage in $cert.Extensions.EnhancedKeyUsages) { if ($usage.Value -eq "1.3.6.1.4.1.311.10.3.6") { $correctUsage = $true } }
if (!($correctUsage)) {
	Write-Host 'The certificate inside of the CAB selected does not have the "Windows System Component Verification" enhanced key usage.' -ForegroundColor Red
	PauseNul
}
$certPath = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllBytes($certPath, $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert))
Import-Certificate $certPath -CertStoreLocation "Cert:\LocalMachine\Root" | Out-Null
Copy-Item -Path "$certRegPath\$($cert.Thumbprint)" "$certRegPath\8A334AA8052DD244A647306A76B8178FA215F344" -Force | Out-Null

Write-Warning "Adding package..."
Add-WindowsPackage -Online -PackagePath $cabPath -NoRestart -IgnoreCheck | Out-Null

Write-Warning "Cleaning up..."
Get-ChildItem "Cert:\LocalMachine\Root\$($cert.Thumbprint)" | Remove-Item -Force | Out-Null
Remove-Item "$certRegPath\8A334AA8052DD244A647306A76B8178FA215F344" -Force -Recurse | Out-Null

Write-Host "`nCompleted!" -ForegroundColor Green
choice /c yn /n /m "Would you like to restart now to apply the changes? [Y/N] "
if ($lastexitcode -eq 1) {Restart-Computer}
