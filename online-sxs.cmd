<# : batch portion
@echo off

:: GPL-3.0-only license
:: he3als 2023

:: set the 'onlinesxsSilent' variable to **anything** for silencing the script
:: can only be used with the CLI argument
:: ----------------------------------------------
:: set onlinesxsSilent=true
:: $env:onlinesxsSilent = 'true'

:: you can pass a path to a .cab as a CLI argument to install it without user input
if "%~2"=="" (
	if not "%~f1"=="" (
		if not exist "%~f1" (
			echo Path argument specified doesn't exist.
			exit /b 1
		) else (
			if not "%~x1"==".cab" (
				echo Specified path argument is not a .cab file.
				exit /b 1
			)
		)
		set "cabArg=%~f1"
	) else (
		set onlinesxsSilent=
		fltmc >nul 2>&1 || (
			echo Administrator privileges are required.
			PowerShell Start -Verb RunAs '%0' 2> nul || (
				echo You must run this script as admin.
				pause & exit /b 1
			)
			exit /b 0
		)
	)
) else (
	echo Invalid ^(multiple^) arguments passsed.
	exit /b 1
)

powershell -nop -ex unrestricted -c if (Test-Path """env:cabArg""") {$cabArg = """%cabArg%"""}; if (Test-Path """env:onlinesxsSilent""") {$silent = $true}; Get-Content """%~f0""" -Raw ^| iex & exit /b
: end batch / begin PowerShell #>

$certRegPath = "HKLM:\Software\Microsoft\SystemCertificates\ROOT\Certificates"

function PauseNul ($message = "Press any key to exit... ") {
	Write-Host $message -NoNewLine
	$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') | Out-Null
}

if ($silent) {$ProgressPreference = 'SilentlyContinue'}

if (!($cabArg)) {
	Write-Host "This will install a specified CBS package online, meaning live on your current install of Windows." -ForegroundColor Yellow
	Start-Sleep 1
	PauseNul "Press any key to continue... "
	Write-Host "`n"
	
	Write-Warning "Opening file dialog to select CBS package CAB..."
	Add-Type -AssemblyName System.Windows.Forms
	$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
	$openFileDialog.Filter = "CBS Package Files (*.cab)|*.cab"
	$openFileDialog.Title = "Select a CBS Package File"
	if ($openFileDialog.ShowDialog() -eq 'OK') {
		$cabPath = $openFileDialog.FileName
		cls
	} else {exit}
} else {$cabPath = $cabArg}

try {
	if (!($silent)) {Write-Warning "Importing and checking certificate..."}
	try {
		$cert = (Get-AuthenticodeSignature $cabPath).SignerCertificate
		foreach ($usage in $cert.Extensions.EnhancedKeyUsages) { if ($usage.Value -eq "1.3.6.1.4.1.311.10.3.6") { $correctUsage = $true } }
		if (!($correctUsage)) {
			if (!($silent)) {Write-Host 'The certificate inside of the CAB selected does not have the "Windows System Component Verification" enhanced key usage.' -ForegroundColor Red}
			if (!($cabArg)) {PauseNul}; exit 1
		}
		$certPath = [System.IO.Path]::GetTempFileName()
		[System.IO.File]::WriteAllBytes($certPath, $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert))
		Import-Certificate $certPath -CertStoreLocation "Cert:\LocalMachine\Root" | Out-Null
		Copy-Item -Path "$certRegPath\$($cert.Thumbprint)" "$certRegPath\8A334AA8052DD244A647306A76B8178FA215F344" -Force | Out-Null
	} catch {
		Write-Host "`nSomething went wrong importing and checking the certificate of: $cabPath" -ForegroundColor Red
		Write-Host "$_`n" -ForegroundColor Red
		if (!($cabArg)) {PauseNul}; exit 1
	}

	if (!($silent)) {Write-Warning "Adding package..."}
	try {
		Add-WindowsPackage -Online -PackagePath $cabPath -NoRestart -IgnoreCheck -LogLevel 1 *>$null
	} catch {
		Write-Host "Something went wrong adding the package: $cabPath" -ForegroundColor Red
		Write-Host "$_`n" -ForegroundColor Red
		if (!($cabArg)) {PauseNul}; exit 1
	}
} finally {
	if (!($silent)) {Write-Warning "Cleaning up certificates..."}
	Get-ChildItem "Cert:\LocalMachine\Root\$($cert.Thumbprint)" | Remove-Item -Force | Out-Null
	Remove-Item "$certRegPath\8A334AA8052DD244A647306A76B8178FA215F344" -Force -Recurse | Out-Null
}

if (!($silent)) {Write-Host "`nCompleted!" -ForegroundColor Green}
if (!($cabArg)) {
	choice /c yn /n /m "Would you like to restart now to apply the changes? [Y/N] "
	if ($lastexitcode -eq 1) {Restart-Computer}
}