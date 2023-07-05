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

set "psScript=%~f0" & powershell -nop -c "if (Test-Path """env:ngen""") { $ngen = $true }; Get-Content """$env:psScript""" -Raw | iex" & exit /b
: end batch / begin PowerShell #>

# config
$packagePath = "C:\package"

# ----------- #

$certRegPath = "HKLM\Software\Microsoft\SystemCertificates\ROOT\Certificates"
$catPath = "$packagePath\update.cat"
$mumPath = "$packagePath\update.mum"
# temp
$cerPath = "$env:temp\Destroy-WinSxS-Online.cer"

Write-Host "This will install a selected package online, which is your current install." -ForegroundColor Yellow
Write-Host "Only run this in a virtual machine, it's highly experimental.`n" -ForegroundColor Red
Start-Sleep 1
pause

if (!(Test-Path "$catPath") -or !(Test-Path "$mumPath")) {
	Write-Host "The package path selected is invalid: $packagePath"
	Read-Host "Press enter to exit"
	exit 1
}

Write-Warning "Extracing certificate from security catalog..."
$catFileBytes = [System.IO.File]::ReadAllBytes("$catPath")
# create a temp file to save the .cat content
$tempCatFilePath = [System.IO.Path]::GetTempFileName()
[System.IO.File]::WriteAllBytes($tempCatFilePath, $catFileBytes)
# open as certificate
$certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($tempCatFilePath)
$thumbprint = $certificate.Thumbprint
# export the certificate
[System.IO.File]::WriteAllBytes($cerPath, $certificate.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert))
# delete the temp .cat file
[System.IO.File]::Delete($tempCatFilePath)

Write-Warning "Installing certificate to store..."
certutil -addstore root "$cerPath" | Out-Null

Write-Warning "Copying certificate to hardcoded Registry path..."
reg copy "$certRegPath\$thumbprint" "$certRegPath\8a334aa8052dd244a647306a76b8178fa215f344" /s /f | Out-Null

Write-Warning "Installing package with DISM..."
dism /online /add-package:"$mumPath" /norestart /logpath:"C:\Destroy-WinSxS-Online.log"

Write-Warning "Deleting fake certificate from Registry..."
reg delete "$certRegpath\8a334aa8052dd244a647306a76b8178fa215f344" /f /va | Out-Null

Write-Warning "Deleting certificate from store..."
certutil -delstore Root "$thumbprint" | Out-Null

Write-Host "`nCompleted!" -ForegroundColor Green
Read-Host "Press enter to exit"
exit 1