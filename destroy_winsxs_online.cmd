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

# cabs also work, like "C:\Users\User\Desktop\NoDefender-Package31bf3856ad364e35amd641.0.0.0.cab"
$packagePath = "C:\package"

# ----------- #

function Exit-Prompt {
	Read-Host "Press enter to exit"
	exit 1
}

Write-Host "This will install a specified unsigned CBS package in the script online, meaining live on your current install." -ForegroundColor Yellow
Write-Host "Only run this in a virtual machine, it's highly experimental.`n" -ForegroundColor Red
Start-Sleep 1
pause

if (Test-Path -Path $packagePath -PathType leaf) {
	$tempFolder = "$env:windir\Temp\sxsonlinetemp"
	if (Test-Path -Path "$tempFolder") {Remove-Item -Force -Recurse -Path "$tempFolder"}
	New-Item -Path $tempFolder -ItemType Directory | Out-Null
	Write-Warning "Extracing CAB to: $tempFolder"
	expand "$packagePath" -F:* "$tempFolder" | Out-Null
	if (!(Test-Path -Path "$tempFolder\update.mum")) {
		Write-Host "Something went wrong extracting your specified CAB!" -ForegroundColor Red
		Write-Host "update.mum not found or folder doesn't exist."
		Exit-Prompt
	}
	$packagePath = $tempFolder
}

$certRegPath = "HKLM\Software\Microsoft\SystemCertificates\ROOT\Certificates"
$catPath = "$packagePath\update.cat"
$mumPath = "$packagePath\update.mum"
# temp
$cerPath = "$env:temp\Destroy-WinSxS-Online.cer"

if (!(Test-Path "$catPath") -or !(Test-Path "$mumPath")) {
	Write-Host "The package path selected is invalid: $packagePath"
	Exit-Prompt
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

Write-Host ""
Write-Warning "Deleting fake certificate from Registry..."
reg delete "$certRegpath\8a334aa8052dd244a647306a76b8178fa215f344" /f /va | Out-Null

Write-Warning "Deleting certificate from store..."
certutil -delstore Root "$thumbprint" | Out-Null

Write-Host "`nCompleted!" -ForegroundColor Green
Exit-Prompt