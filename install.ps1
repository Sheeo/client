$env:PYTHON = "C:\Python27"
$env:QTIMPL = "PyQt4"

$BASE_PATH = ""

$BASE_URL = "https://www.python.org/ftp/python/"
$GET_PIP_URL = "https://bootstrap.pypa.io/get-pip.py"
$LUA_PATH = "C:\Program Files (x86)\Lua\5.1"
$GET_PIP_PATH = "C:\get-pip.py"

$webclient = (new-object net.webclient)
$python_home = "C:\Python27"

$env:INCLUDE = $env:INCLUDE + ":" + $LUA_PATH + "\include"

Write-Host "env | grep INCLUDE"
Write-Host $env:INCLUDE



# Install choco
if (!(Get-Command "choco" -errorAction SilentlyContinue)) {
  Write-Host "Installing chocolatey"
  iex ($webclient.DownloadString('https://chocolatey.org/install.ps1'))
}
else {
  Write-Host "chocolatey already installed"
}

# Install Visual C++ Redistributable (We should probably ship this with the client)
# This is going to fail with error code 3010, which means 'screw you, reboot'
# being awesome, we ignore this silly advice.
try {
 choco install -y vcredist2008 -x86
}
catch {}

if (!(Get-Command "python" -errorAction SilentlyContinue)) {
  $webclient.DownloadFile("https://www.python.org/ftp/python/2.7.10/python-2.7.10.msi", "c:\python2.msi")
  Start-Process -FilePath C:\python2.msi -ArgumentList "/passive" -Wait -Passthru
 }

choco install -y git

"Reloading Path"
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")

if (-not(Test-Path "C:\vcc_py2-7.msi")) {
  Write-Host "Downloading python2.7 compiler"
  (new-object net.webclient).DownloadFile("http://download.microsoft.com/download/7/9/6/796EF2E4-801B-4FC4-AB28-B59FBF6D907B/VCForPython27.msi", "C:\vcc_py2-7.msi")
}
Write-Host "Running python2.7 compiler installer"
Start-Process -FilePath C:\vcc_py2-7.msi -ArgumentList "/passive" -Wait -Passthru

Write-Host "Downloading stdint.h into include directory"
$webclient.DownloadFile("http://msinttypes.googlecode.com/svn/trunk/stdint.h", $python_home + "\include\stdint.h")

# Install pip
$pip_path = $python_home + "\Scripts\pip.exe"
$python_path = $python_home + "\python.exe"
if (-not(Test-Path $pip_path)) {
  Write-Host "Installing pip..."
  $webclient = New-Object System.Net.WebClient
  $webclient.DownloadFile($GET_PIP_URL, $GET_PIP_PATH)
  Write-Host "Executing:" $python_path $GET_PIP_PATH
  Start-Process -FilePath "$python_path" -ArgumentList "$GET_PIP_PATH" -Wait -Passthru
} else {
  Write-Host "pip already installed."
}

function InstallPackage ($pkg) {
    & $pip_path install $pkg
}
InstallPackage http://content.faforever.com/wheel/lupa-1.1-cp27-none-win32.whl
InstallPackage wheel
InstallPackage pytest
InstallPackage cx_Freeze

if ($env:QTIMPL -eq "PyQt4"){
    Write-Host "Installing PyQt4"
    $webclient.DownloadFile("http://sourceforge.net/projects/pyqt/files/PyQt4/PyQt-4.11.3/PyQt4-4.11.3-gpl-Py2.7-Qt4.8.6-x32.exe", "C:\install-PyQt4.exe")
    Start-Process -FilePath C:\install-PyQt4.exe -ArgumentList "/S" -Wait -Passthru
}

if ($env:QTIMPL -eq "PyQt5"){
    $webclient.DownloadFile("http://sourceforge.net/projects/pyqt/files/PyQt5/PyQt-5.4/PyQt5-5.4-gpl-Py3.4-Qt5.4.0-x32.exe/download", "C:\install-PyQt5.exe")
    Start-Process -FilePath C:\install-PyQt5.exe -ArgumentList "/S" -Wait -Passthru
}

& $pip_path install -r c:\vagrant\requirements.txt

$env:Path = $python_home + ";" + $env:Path

"Updating path"
[Environment]::SetEnvironmentVariable("Path", $env:Path, [System.EnvironmentVariableTarget]::Machine)
Write-Host "New path: " + $env:Path
