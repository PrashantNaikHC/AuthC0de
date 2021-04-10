Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

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

Add-Type -TypeDefinition $cSource -ReferencedAssemblies System.Windows.Forms,System.Drawing
$wshell = New-Object -ComObject wscript.shell;

function Get-ClipData {
    $clipdata = C:\Users\user\AppData\Local\Android\Sdk\platform-tools\adb.exe shell am broadcast -a clipper.get
    $clip = [regex]::match($clipdata, '"([^"]+)"').Groups[1].Value
    return $clip
}

function Set-ClipData($param) {
    $clipdata = C:\Users\user\AppData\Local\Android\Sdk\platform-tools\adb.exe shell am broadcast -a clipper.set -e text $param
    Write-Output $clipdata
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
    [Clicker]::LeftClickAtPoint(1080,450)
    $wshell.SendKeys($param)
    [System.Windows.Forms.SendKeys]::SendWait('7{ENTER}')
}

while($TRUE){
   Clear-Host []
   $clip = Get-ClipData
   if(Check-UpdatedClipData($clip)){
        Write-Output "Listening for data..."
   } else {
        if(Validate-AuthCodeData($clip)){
            Paste-Code($clip)
            Set-ClipDataCompletion
        }
   }
   Start-Sleep -s 1
}
