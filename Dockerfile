FROM microsoft/aspnet:4.6.2-windowsservercore-10.0.14393.1066

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

MAINTAINER Vedran Vucetic <vedran.vucetic@gmail.com>
LABEL maintainer "vedran.vucetic@gmail.com"

ENV NS_VERSION="v0.1-alpha.2" 
	API_KEY=""

RUN Write-Host 'Downloading ServerMonitor'; \
	Invoke-WebRequest -outfile C:\ServiceMonitor.exe "https://github.com/Microsoft/iis-docker/blob/master/windowsservercore/ServiceMonitor.exe?raw=true" -UseBasicParsing;

RUN Write-Host 'Downloading Nuget Server'; \
	Invoke-WebRequest -outfile web.zip "https://github.com/vvucetic/Nuget-Server-Docker-Container/releases/download/$($env:NS_VERSION)/Web.zip" -UseBasicParsing; \
	Write-Host 'Extracting Nuget Server'; \
	Expand-Archive web.zip -DestinationPath C:\NugetServer; \
	Write-Host 'Removing zip'; \
	Remove-Item web.zip; \
	Write-Host 'Creating IIS site'; \
	Import-module IISAdministration; \
	New-IISSite -Name "NugetServer" -PhysicalPath C:\NugetServer -BindingInformation "*:8080:";

HEALTHCHECK CMD powershell -command   \
    try { \
     $response = iwr http://localhost:8080 -UseBasicParsing; \
     if ($response.StatusCode -eq 200) { return 0} \
     else {return 1}; \
    } catch { return 1 }

CMD Write-Host 'Configuring ApiKey'; \
	$webConfig = 'C:\NugetServer\Configuration\AppSettings.config'; \
	$doc = (Get-Content $webConfig) -as [Xml]; \
	$obj = $doc.appSettings.add | where {$_.Key -eq 'apiKey'}; \	
	$obj.value = $env:API_KEY; \
	Write-Host 'API_KEY Configured: $($obj.value)'; \
	$doc.Save($webConfig);
	
EXPOSE 8080
	
ENTRYPOINT ["C:\\ServiceMonitor.exe ", "w3svc"]