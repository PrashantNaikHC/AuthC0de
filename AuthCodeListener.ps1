#########################################################################################
#  Login script for automated AuthCode login using ADB
#  Author: prasnaik
#########################################################################################

Add-Type –AssemblyName System.Speech

$cSource = @'
using System;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Windows.Forms;
public class Clicker
{
//https://msdn.microsoft.com/en-us/library/windows/desktop/ms646270(v=vs.85).aspx
[StructLayout(LayoutKind.Sequential)]
struct INPUT
{
    public int        type; // 0 = INPUT_MOUSE,
                            // 1 = INPUT_KEYBOARD
                            // 2 = INPUT_HARDWARE
    public MOUSEINPUT mi;
}

//https://msdn.microsoft.com/en-us/library/windows/desktop/ms646273(v=vs.85).aspx
[StructLayout(LayoutKind.Sequential)]
struct MOUSEINPUT
{
    public int    dx ;
    public int    dy ;
    public int    mouseData ;
    public int    dwFlags;
    public int    time;
    public IntPtr dwExtraInfo;
}

//This covers most use cases although complex mice may have additional buttons
//There are additional constants you can use for those cases, see the msdn page
const int MOUSEEVENTF_MOVED      = 0x0001 ;
const int MOUSEEVENTF_LEFTDOWN   = 0x0002 ;
const int MOUSEEVENTF_LEFTUP     = 0x0004 ;
const int MOUSEEVENTF_RIGHTDOWN  = 0x0008 ;
const int MOUSEEVENTF_RIGHTUP    = 0x0010 ;
const int MOUSEEVENTF_MIDDLEDOWN = 0x0020 ;
const int MOUSEEVENTF_MIDDLEUP   = 0x0040 ;
const int MOUSEEVENTF_WHEEL      = 0x0080 ;
const int MOUSEEVENTF_XDOWN      = 0x0100 ;
const int MOUSEEVENTF_XUP        = 0x0200 ;
const int MOUSEEVENTF_ABSOLUTE   = 0x8000 ;

const int screen_length = 0x10000 ;

//https://msdn.microsoft.com/en-us/library/windows/desktop/ms646310(v=vs.85).aspx
[System.Runtime.InteropServices.DllImport("user32.dll")]
extern static uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

public static void LeftClickAtPoint(int x, int y)
{
    //Move the mouse
    INPUT[] input = new INPUT[3];
    input[0].mi.dx = x*(65535/System.Windows.Forms.Screen.PrimaryScreen.Bounds.Width);
    input[0].mi.dy = y*(65535/System.Windows.Forms.Screen.PrimaryScreen.Bounds.Height);
    input[0].mi.dwFlags = MOUSEEVENTF_MOVED | MOUSEEVENTF_ABSOLUTE;
    //Left mouse button down
    input[1].mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
    //Left mouse button up
    input[2].mi.dwFlags = MOUSEEVENTF_LEFTUP;
    SendInput(3, input, Marshal.SizeOf(input[0]));
}
}
'@
$SpeechSynthesizer = New-Object –TypeName System.Speech.Synthesis.SpeechSynthesizer

Add-Type -TypeDefinition $cSource -ReferencedAssemblies System.Windows.Forms,System.Drawing
$wshell = New-Object -ComObject wscript.shell;

function Get-ClipData {
    $clipdata = C:\Users\user\AppData\Local\Android\Sdk\platform-tools\adb.exe shell am broadcast -a clipper.get
    $clip = [regex]::match($clipdata, '"([^"]+)"').Groups[1].Value
    return $clip
}

function Set-ClipData($param) {
    $clipdata = C:\Users\user\AppData\Local\Android\Sdk\platform-tools\adb.exe shell am broadcast -a clipper.set -e text $param
}

function Set-ClipDataCompletion() {
    # marker for completion
    Set-ClipData("-")
}

function Check-UpdatedClipData($param) {
    if($param -eq "-") {
        return $TRUE
    } 
    return $FALSE
}

function Validate-AuthCodeData($param) {
    if(($param -match '^[0-9]+$') -and ($param.length -eq 6)) {
        return $TRUE
    }
    return $FALSE
}

function Validate-AuthCodeData($param) {
    if(($param -match '^[0-9]+$') -and ($param.length -eq 6)) {
        return $TRUE
    }
    return $FALSE
}

function Paste-Code($param) {
    # Hardcoded location on the browser
    [Clicker]::LeftClickAtPoint(1080,450)
    $wshell.SendKeys($param)
    [System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
    $SpeechSynthesizer.Speak('Login Completed')
    Write-Output "fetched $param on $(Get-Date)"
}

function Send-TapEvent($x,$y) {
    C:\Users\user\AppData\Local\Android\Sdk\platform-tools\adb.exe shell input tap $x $y
}

function Send-IntputTextEvent($param) {
    C:\Users\user\AppData\Local\Android\Sdk\platform-tools\adb.exe shell input text $param
}

function Invoke-Authenticator {
    Start-Sleep -s 5
    {C:\Users\user\AppData\Local\Android\Sdk\platform-tools\adb.exe shell monkey -p com.tcs.totp -c android.intent.category.LAUNCHER 1} | out-null
}

function Open-Authenticator {
    $startTime = Get-Date
    $SpeechSynthesizer.Speak('Fetching auth code')
    Invoke-Authenticator
    # Hardcoded location on the device
    #C:\Users\user\AppData\Local\Android\Sdk\platform-tools\adb.exe shell input tap 520 1390
    Send-TapEvent(520,1390)
    Send-TapEvent(880,1200)
    # Code to bypass the biometric auth
    Send-IntputTextEvent("1245")
    Send-TapEvent(520,1390)
}

function Intro {
    Write-Output  "   _____          __  .__           _______       .___      "
    Write-Output  "  /  _  \  __ ___/  |_|  |__   ____ \   _  \    __| _/____  "
    Write-Output  " /  /_\  \|  |  \   __\  |  \_/ ___\/  /_\  \  / __ |/ __ \ "
    Write-Output  "/    |    \  |  /|  | |   Y  \  \___\  \_/   \/ /_/  \ ___/ "
    Write-Output  "\____|__  /____/ |__| |___|  /\___  >\_____  /\____ | \___ >"
    Write-Output  "        \/                 \/     \/       \/      \/     \/ "
    Write-Output "Press F2 to fetch the Authcode."
}

function Trigger-AuthCodeFetch {
  # key code for F2 key:
  $key = 113    
    
  # this is the c# definition of a static Windows API method:
  $Signature = @'
    [DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
    public static extern short GetAsyncKeyState(int virtualKeyCode); 
'@

  Add-Type -MemberDefinition $Signature -Name Keyboard -Namespace PsOneApi
  [bool]([PsOneApi.Keyboard]::GetAsyncKeyState($key) -eq -32767)
}

Clear-Host []
Intro
while($TRUE){
   $clip = Get-ClipData
   if((-Not (Check-UpdatedClipData($clip))) -And (Validate-AuthCodeData($clip))){
            Paste-Code($clip)
            Set-ClipDataCompletion
        
   }
   if (Trigger-AuthCodeFetch) { 
        Open-Authenticator 
   }
   Start-Sleep -s 1
}
