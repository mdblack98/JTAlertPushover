# PowerShell script to send alerts from JTAlert to my phone via Pushover
# You also need QRZ.exe from here 
# 
# Set up an account at https://pushover.net/ and install the app on your phone and/or computer.
#
# Hat tip to K2DT for the inspiration
#
# Written by Tim Totten, 4G1G/NP4TT/V21TT/OH4GN/N4GN
# https://timtotten.com/a-better-way-to-push-jtalert-ft8-dx-alerts-to-your-phone-without-using-e-mail-or-old-school-text-messaging/
#
# Last updated 2024-06-02

$uri = “https://api.pushover.net/1/messages.json”

$curPath = Split-Path $MyInvocation.MyCommand.Path -Parent
# echo $curPath
cd $curPath

$QRZUtil = “$curPath\qrz.exe”

# Read $QRZLogin and $QRAPassword from file
# Looks like this:
# $QRZLogin = “w9mdb”
# $QRZPassword = “password”
. $curPath\qrz.ps1

# Check that the callsign is valid
$Callsign = $env:JTAlert_Call
if ($Callsign.length -eq 0)
{
# Use my callsign for a test
$Callsign = “W9MDB2”
}
$QRZStuff = “not working”
if (Test-Path $QRZUtil -PathType leaf)
{
$oProcess = Start-Process -FilePath $QRZUtil -ArgumentList $QRZLogin, $QRZPassword, $Callsign -PassThru -RedirectStandardOutput qrz.txt
$handle = $oProcess.Handle
$oProcess.WaitForExit()
$output = Get-Content qrz.txt
if ($output.Contains(“bad”)) {
echo “bad call: $Callsign”
$QRZStuff = “bad call” + $Callsign
exit 1
}
# $QRZStuff = “good call exit code”
}
else
{
echo “No QRZ.exe found”
}

# Format our message
if ($env:JTAlert_AlertType.length -gt 0)
{
$AlertType = $env:JTAlert_AlertType
$Decode = $env:JTAlert_Decode
$Date = $env:JTAlert_Date
$Time = $env:JTAlert_Time
$Band = $env:JTAlert_Band
$Mode = $env:JTAlert_Mode
$Country = $env:JTAlert_Country
$State = $env:JTAlert_State
$Db = “Db ” + $env:JTAlert_Db
$Freq = “Freq ” + $env:JTAlert_QRG
$ATNOdxcc = “ATNO:” + $env:JTAlert_IsAtnoDxcc
$LOTWDate = (Get-Date $env:JTAlert_LotwDate)
$Eqsl = “Eqsl:” + $env:JTAlert_Eqsl
}
else
{
$AlertType = “Wanted Call”
$Decode = “CQ W9MDB EM49”
$Date = “2022-03-16”
$Time = “22:50”
$Band = “40M”
$Mode = “FT8”
$Country = “USA”
$State = “IL”
$Db = “Db ” + “-10”
$Freq = “Freq ” + “7.074MHz”
$ATNOdxcc = “ATNO:” + “No”
$LOTWDate = (Get-Date 2022-03-15)
$Eqsl = “Yes”
}

$365days = New-TimeSpan -Days 365
$DateCutoff = (Get-Date) – $365days
if ($LOTWDate -lt $DateCutoff)
{
$Lotw = “Lotw1:” + “No” + ” ” + ” >1 year”
}
elseif ($env:JTAlert_Lotw -eq “No”)
{
$Lotw = “Lotw2:” + $env:JTAlert_Lotw + ” Never”
}
else
{
$Lotw = “Lotw3:” + $env:JTAlert_Lotw + ” ” + $LOTWDate
}

$parameters = @{
token = “blahblahblah”
user = “blahblahblah”
message = “$Lotw`n$Country $State $ATNOdxcc`n$Band $Mode $Db $Freq`n$Decode`n$Date $Time`n”
sound = “New_Country”
}

$parameters | Invoke-RestMethod -Uri $uri -Method Post

exit