FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# Update distro
RUN apt-get update && apt-get upgrade -y

# Install node using NVM
# Install Azure Function Tools V4
# Install M365 CLI
# Install SPFx 18 global packages
ENV NODE_VERSION 18.18.2
ENV NVM_DIR /usr/local/nvm
RUN mkdir -p /usr/local/nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default \
    && npm i -g azure-functions-core-tools@4 @pnp/cli-microsoft365 gulp-cli yo @microsoft/generator-sharepoint@1.18.0 --unsafe-perm true

# # Install dotnet sdk 6.0
RUN apt-get install -y dotnet-sdk-6.0

# Install PowerApps CLI and certificate utility
RUN dotnet tool install Microsoft.PowerApps.CLI.Tool --tool-path /usr/local/dotnet/tools
RUN dotnet tool install dotnet-certificate-tool --tool-path /usr/local/dotnet/tools

# Install PowerShell
RUN wget -q https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb
RUN dpkg -i packages-microsoft-prod.deb && rm packages-microsoft-prod.deb
RUN apt-get update && apt-get install -y powershell

# Install Azure PowerShell
RUN pwsh -c Install-Module -Name Az -Repository PSGallery -Force
# Install PnP PowerShell
RUN pwsh -c Install-Module -Name PnP.PowerShell -Repository PSGallery -Force
# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

RUN echo '\n\n\
export NVM_DIR=${NVM_DIR}\n\
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"\n\
export NODE_PATH=${NVM_DIR}/versions/node/v${NODE_VERSION}/lib/node_modules\n\
export PATH=/usr/local/dotnet/tools:${NVM_DIR}/versions/node/v${NODE_VERSION}/bin:${PATH}\n\
export NODE_OPTIONS="--max-old-space-size=8192"' | tee -a /root/.profile /home/vscode/.profile 

ENTRYPOINT [ "/bin/bash", "-l", "-c" ]
