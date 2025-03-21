# Use Azure Functions base image for .NET isolated
FROM mcr.microsoft.com/azure-functions/dotnet-isolated:4-dotnet-isolated9.0-appservice AS base
WORKDIR /home/site/wwwroot
EXPOSE 80

# Build stage
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src

# Copy only necessary files for dependency restoration
COPY ["function-app-demo/function-app-demo.csproj", "function-app-demo/"]

# Restore the dependencies
RUN dotnet restore "./function-app-demo/function-app-demo.csproj"

# Copy the rest of the source code
COPY ./function-app-demo ./function-app-demo

# Build the application
RUN dotnet build "./function-app-demo/function-app-demo.csproj" -c $BUILD_CONFIGURATION --no-restore -o /app/build

# Publish the application
FROM build AS publish
RUN dotnet publish "./function-app-demo/function-app-demo.csproj" -c $BUILD_CONFIGURATION --no-restore -o /app/publish /p:UseAppHost=false

# Final runtime stage
FROM base AS final
WORKDIR /home/site/wwwroot

## Optional: Add a non-root user for enhanced security
#RUN adduser --disabled-password --gecos "" azureuser && \
#    chown -R azureuser /home/site/wwwroot
#USER azureuser

# Copy the published app
COPY --from=publish /app/publish .

# Set Azure Function environment variables
ENV AZURE_FUNCTIONS_ENVIRONMENT=Development \
    AzureWebJobsScriptRoot=/home/site/wwwroot \
    AzureFunctionsJobHost__Logging__Console__IsEnabled=true
