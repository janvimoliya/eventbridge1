param(
    [switch]$IncludeDebug = $true,
    [switch]$IncludeRelease,
    [string]$ReleaseKeystorePath,
    [string]$ReleaseAlias,
    [string]$ReleaseStorePassword,
    [string]$ReleaseKeyPassword,
    [switch]$VerboseOutput
)

$ErrorActionPreference = 'Stop'

function Get-KeytoolCommand {
    $cmd = Get-Command keytool -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    if ($env:JAVA_HOME) {
        $javaHomeKeytool = Join-Path $env:JAVA_HOME 'bin\keytool.exe'
        if (Test-Path $javaHomeKeytool) {
            return $javaHomeKeytool
        }
    }

    throw 'keytool not found. Install JDK or set JAVA_HOME so keytool is available.'
}

function Get-Base64CertHash {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Keytool,
        [Parameter(Mandatory = $true)]
        [string]$KeystorePath,
        [Parameter(Mandatory = $true)]
        [string]$Alias,
        [Parameter(Mandatory = $true)]
        [string]$StorePassword,
        [Parameter(Mandatory = $true)]
        [string]$KeyPassword
    )

    if (-not (Test-Path $KeystorePath)) {
        if ($KeystorePath -match 'path\\to\\release\.jks') {
            throw "Keystore not found: $KeystorePath. This looks like the example placeholder path. Replace it with your real release keystore path."
        }

        throw "Keystore not found: $KeystorePath. Verify the file exists and the path is correct."
    }

    $tmpCert = Join-Path $env:TEMP ("fb-cert-" + [Guid]::NewGuid().ToString() + '.cer')

    try {
        $args = @(
            '-exportcert',
            '-alias', $Alias,
            '-keystore', $KeystorePath,
            '-storepass', $StorePassword,
            '-keypass', $KeyPassword,
            '-file', $tmpCert
        )

        if ($VerboseOutput) {
            Write-Host "Running keytool for alias '$Alias' in '$KeystorePath'"
        }

        & $Keytool @args | Out-Null

        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($tmpCert)
        return [Convert]::ToBase64String($cert.GetCertHash())
    }
    finally {
        if (Test-Path $tmpCert) {
            Remove-Item $tmpCert -Force -ErrorAction SilentlyContinue
        }
    }
}

$keytool = Get-KeytoolCommand

Write-Host ''
Write-Host 'Facebook Android Key Hash Generator' -ForegroundColor Cyan
Write-Host '====================================' -ForegroundColor Cyan
Write-Host ''

if ($IncludeDebug) {
    $debugKeystore = Join-Path $env:USERPROFILE '.android\debug.keystore'

    try {
        $debugHash = Get-Base64CertHash `
            -Keytool $keytool `
            -KeystorePath $debugKeystore `
            -Alias 'androiddebugkey' `
            -StorePassword 'android' `
            -KeyPassword 'android'

        Write-Host 'DEBUG_KEY_HASH:' -ForegroundColor Yellow
        Write-Host $debugHash -ForegroundColor Green
        Write-Host ''
    }
    catch {
        Write-Host 'DEBUG_KEY_HASH: ERROR' -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ''
    }
}

$hasReleaseInputs = -not [string]::IsNullOrWhiteSpace($ReleaseKeystorePath) -and `
                    -not [string]::IsNullOrWhiteSpace($ReleaseAlias) -and `
                    -not [string]::IsNullOrWhiteSpace($ReleaseStorePassword) -and `
                    -not [string]::IsNullOrWhiteSpace($ReleaseKeyPassword)

if ($IncludeRelease -or $hasReleaseInputs) {
    if (-not $hasReleaseInputs) {
        throw 'For release hash, provide -ReleaseKeystorePath -ReleaseAlias -ReleaseStorePassword -ReleaseKeyPassword.'
    }

    try {
        $releaseHash = Get-Base64CertHash `
            -Keytool $keytool `
            -KeystorePath $ReleaseKeystorePath `
            -Alias $ReleaseAlias `
            -StorePassword $ReleaseStorePassword `
            -KeyPassword $ReleaseKeyPassword

        Write-Host 'RELEASE_KEY_HASH:' -ForegroundColor Yellow
        Write-Host $releaseHash -ForegroundColor Green
        Write-Host ''
    }
    catch {
        Write-Host 'RELEASE_KEY_HASH: ERROR' -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ''
        exit 1
    }
}

Write-Host 'Done. Add these values to Meta Developers > Facebook Login > Settings > Key Hashes.' -ForegroundColor Cyan
