FROM mcr.microsoft.com/dotnet/runtime:9.0@sha256:e7cd42242b524ef92228d509dd65eae7ea71b3758e887cb064b55c6a4c00adde AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/sdk:9.0@sha256:02db4ba0d86bd754c1ca9ff1f1faff178fa921f32d576d4f3b8ef3a8c04a88e8 AS build
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
