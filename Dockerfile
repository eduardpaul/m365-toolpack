FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04 AS base

RUN apt update && apt upgrade -y

# wsl specific
RUN echo '\n\n\
[user]\n\
default=vscode\n' | tee -a /etc/wsl.conf
RUN apt install software-properties-common -y && add-apt-repository ppa:wslutilities/wslu
RUN apt update && apt-get install keychain gawk libsigsegv2 wslu -y

RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
RUN curl -sL https://aka.ms/DevTunnelCliInstall | bash

# Install node using NVM Azure Function Tools V4 M365 CLI SPFx 18 global packages
ENV NODE_VERSION 18.19.0
ENV NVM_DIR /usr/local/nvm
RUN mkdir -p /usr/local/nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default \
    && npm i -g azure-functions-core-tools@4 @pnp/cli-microsoft365 gulp-cli yo @microsoft/generator-sharepoint@1.18.0 --unsafe-perm true

# install microsoft feed (pwsh and dotnet)
RUN wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb

# Update distro
RUN apt update && apt upgrade -y
RUN apt install -y powershell
RUN pwsh -c Install-Module -Name Microsoft.Graph -Scope AllUsers -Repository PSGallery -Force
RUN pwsh -c Install-Module -Name Az -Scope AllUsers -Repository PSGallery -Force
RUN pwsh -c Install-Module -Name PnP.PowerShell -Scope AllUsers -Repository PSGallery -Force

RUN touch /etc/apt/preferences
RUN echo '\
Package: dotnet* aspnet* netstandard*\
Pin: origin "packages.microsoft.com"\
Pin-Priority: -10\'

RUN curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin -c 6.0 --install-dir /usr/share/dotnet
RUN curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin -c 7.0 --install-dir /usr/share/dotnet
RUN curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin -c 8.0 --install-dir /usr/share/dotnet
RUN /usr/share/dotnet/dotnet tool install Microsoft.PowerApps.CLI.Tool --global

RUN echo '\n\n\
export NVM_DIR='${NVM_DIR}'\n'\
'export NODE_VERSION='${NODE_VERSION} | tee -a /root/.profile /home/vscode/.profile
RUN echo '\n\n\
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"\n\
export DOTNET_ROOT=/usr/share/dotnet\n\
export NODE_PATH=${NVM_DIR}/versions/node/v${NODE_VERSION}/lib/node_modules\n\
export PATH=$DOTNET_ROOT:$DOTNET_ROOT/tools:${NVM_DIR}/versions/node/v${NODE_VERSION}/bin:${PATH}\n\
export NODE_OPTIONS="--max-old-space-size=8192"' | tee -a /root/.profile /home/vscode/.profile 

USER vscode

RUN mkdir /home/vscode/.ssh
RUN echo '\n\n\
eval `ssh-agent -s`\n\
eval `keychain --eval id_rsa`' | tee -a /home/vscode/.bashrc

ENTRYPOINT [ "/bin/bash", "-l", "-c" ]

# utilities
# fix key issues: chmod 600 ~/.ssh/id_rsa; chmod 600 ~/.ssh/id_rsa.pub
# fix token time issues: sudo hwclock -s
# powershell to install pfx files:

# $storeName = [System.Enum]::Parse([System.Security.Cryptography.X509Certificates.StoreName], "My", $true)
# $storeLocation = [System.Enum]::Parse([System.Security.Cryptography.X509Certificates.StoreLocation], "CurrentUser", $true)
# $path = "./cert.pfx"
# $password = ""
# 
# Write-Host "Installing certificate from '$path' to '$storeName' certificate store (location: $storeLocation)..."
# $cert = $null
# if ([string]::IsNullOrEmpty($password)) {
#     $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($path)
# }
# else {
#     $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($path, $password, [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable)
# }
# if ($null -eq $cert) {
#     throw [System.ArgumentNullException]::new("Unable to create certificate from provided arguments.")
# }
# $store = New-Object System.Security.Cryptography.X509Certificates.X509Store($storeName, $storeLocation)
# $store.Open("ReadWrite")
# $store.Add($cert)
# $certificates = $store.Certificates.Find("FindByThumbprint", $cert.Thumbprint, $false)
# if ($certificates.Count -le 0) {
#     throw [System.ArgumentNullException]::new("Unable to validate certificate was added to store.")
# }
# Write-Host "Done."
# $store.Close()
