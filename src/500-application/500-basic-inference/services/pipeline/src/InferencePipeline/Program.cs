using System.Text.Json.Nodes;
using Azure.Iot.Operations.Protocol;
using InferencePipeline;

var builder = Host.CreateApplicationBuilder(args);

// Add environment variables as application configuration.
builder.Configuration.AddEnvironmentVariables();
builder.Services.Configure<InferencePipelineOptions>(builder.Configuration);

builder.Services
    // Register required IoT Operations SDK services.
    .AddSingleton<ApplicationContext>()
    // Register receiver and sender services.
    .AddScoped<ISourceReceiverFactory<JsonNode>, SourceReceiverFactory<JsonNode>>()
    .AddScoped<ISinkSenderFactory<JsonNode>, SinkSenderFactory<JsonNode>>()

    // Register data processor services.
    .AddScoped<HttpClient>(_ => new HttpClient())
    .AddScoped<IPipelineDataProcessor<JsonNode, JsonNode>, EndpointDataProcessor<JsonNode, JsonNode>>()

    // Register pipeline service.
    .AddHostedService<PipelineService<JsonNode, JsonNode>>();

var host = builder.Build();
await host.RunAsync();
