### Installs Cloud Drive Mapper if not already present and configures license

IF (Get-ItemProperty -Path "HKLM:\SOFTWARE\IAM Cloud\CloudDriveMapper"){exit}

#create tempt directory for download location
New-Item -Path "c:\" -Name "temp" -ItemType "directory"

#Enter License Key
 #Make sure to keep the ' ' 
 #Example   $LicenseKey = '21334asd123123'
$LicenseKey = '<ENTER LICENSE KEY HERE>'

#Configure Execution policy to allow script to install 
$ex = Get-ExecutionPolicy
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force

#Download and install 
$filename = 'CDMInstaller.msi';$uri = [System.Uri]'https://iacm1gblcor1res1str1.blob.core.windows.net/cdm/2.9.3.1/setupcdmx64.msi' ; Invoke-WebRequest -Uri $uri  -OutFile C:\temp\$filename ; msiexec /i c:\temp\CDMInstaller.msi /norestart /quiet /qn 

Start-Sleep 3

# Set requires registry keys

New-Item -Path "HKLM:\SOFTWARE" -Name 'IAM Cloud' -force
New-Item -Path "HKLM:\SOFTWARE\IAM Cloud" -Name CloudDriveMapper -force
New-ItemProperty -Path "HKLM:\SOFTWARE\IAM Cloud\CloudDriveMapper" -Name LicenceKey -Value $LicenseKey -force
New-ItemProperty -Path "HKLM:\SOFTWARE\IAM Cloud\CloudDriveMapper" -Name EnableAdvanceMode -Value "True" -force


#Sleep to allow time for files to be created in C:\programs so start-process will work
Start-Sleep 3

#Start CDM
Start-Process 'C:\Program Files\IAM Cloud\Cloud Drive Mapper\CloudDriveMapper.exe'

Set-ExecutionPolicy -ExecutionPolicy $ex -Force