FROM mcr.microsoft.com/dotnet/runtime:9.0@sha256:c7f3e4154ba9f6dcdcbb4b7c81ff1b1be5057fcf78b55e46b50be0c1a5a7bced AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:9.0@sha256:c97a488465b7c0e3f193b7bb4b41d6b6e8530f388b5503c1413cb6b3b648b4f3 AS build
ARG BUILD_CONFIGURATION=Release

WORKDIR /src/InferencePipeline

COPY ./NuGet.config .
COPY ./src/InferencePipeline/InferencePipeline.csproj .

RUN dotnet restore InferencePipeline.csproj
COPY ./src/InferencePipeline .
RUN dotnet build InferencePipeline.csproj -c $BUILD_CONFIGURATION -o /app/build

FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish InferencePipeline.csproj -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "InferencePipeline.dll"]
