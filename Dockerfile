# Dockerfile for building a .NET application
# This Dockerfile uses the official .NET SDK image to build the application.
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
# Set the working directory inside the container
WORKDIR /src
# Copy the project file and restore dependencies
COPY ./src/SandboxService/SandboxService.csproj ./SandboxService/
# Restore the project dependencies
RUN dotnet restore ./SandboxService/SandboxService.csproj
# Copy the rest of the application code
COPY ./src/SandboxService/ ./SandboxService/
# Build the application in Release configuration
WORKDIR /src/SandboxService
RUN dotnet publish -c Release -o /app/publish
# Use the official .NET runtime image to run the application
FROM mcr.microsoft.com/dotnet/aspnet:8.0
# Set the working directory inside the container    
WORKDIR /app
# Copy the published application from the build stage
COPY --from=build /app/publish .
# Expose the port that the application will run on
ENV ASPNETCORE_URLS=http://+:8080
# it documents that the container listens on port 8080 at runtime
EXPOSE 8080
# Set the entry point to run the application
ENTRYPOINT ["dotnet", "SandboxService.dll"]
