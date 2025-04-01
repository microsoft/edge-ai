using Azure.Iot.Operations.Mqtt.Session;
using Azure.Iot.Operations.Protocol;
using Azure.Iot.Operations.Protocol.Connection;
using Azure.Iot.Operations.Protocol.Telemetry;
using Microsoft.Extensions.Options;

namespace InferencePipeline;

/// <summary>
///     Interface for creating new <see cref="ISourceReceiver{TSourceData}" /> objects.
/// </summary>
/// <typeparam name="TSourceData">Source data to receive.</typeparam>
public interface ISourceReceiverFactory<TSourceData>
    where TSourceData : class
{
    /// <summary>
    ///     Method that creates the new <see cref="ISourceReceiver{TSourceData}" /> object.
    /// </summary>
    /// <param name="onTelemetryReceived">Async delegate that will handle receiving the <see cref="TSourceData" />.</param>
    /// <returns>The newly created <see cref="ISourceReceiver{TSourceData}" />.</returns>
    Task<ISourceReceiver<TSourceData>> Create(
        Func<string, TSourceData, IncomingTelemetryMetadata, Task> onTelemetryReceived);
}

/// <summary>
///     Factory for connecting <see cref="MqttSessionClient" /> and returning a new
///     <see cref="SourceReceiver{TSourceData}" />.
/// </summary>
/// <param name="logger">The logger for logging data.</param>
/// <param name="options">Application settings provided by ConfigurationSettings.</param>
/// <param name="applicationContext">Required by the IoT Operations SDK.</param>
/// <typeparam name="TSourceData">Source data to receive.</typeparam>
public class SourceReceiverFactory<TSourceData>(
    ILogger<SourceReceiverFactory<TSourceData>> logger,
    IOptions<InferencePipelineOptions> options,
    ApplicationContext applicationContext) : ISourceReceiverFactory<TSourceData>
    where TSourceData : class
{
    /// <summary>
    ///     Connects <see cref="MqttSessionClient" /> and returns a new <see cref="SourceReceiver{TSourceData}" />
    /// </summary>
    /// <param name="onTelemetryReceived">Async delegate that will handle receiving the <see cref="TSourceData" />.</param>
    /// <returns>A newly created <see cref="SourceReceiver{TSourceData}" />.</returns>
    public async Task<ISourceReceiver<TSourceData>> Create(
        Func<string, TSourceData, IncomingTelemetryMetadata, Task> onTelemetryReceived)
    {
        var settings = MqttConnectionSettings.FromEnvVars();
        settings.ClientId += "-pipe-source";

        logger.LogInformation("Starting MQTT session: {settings}", settings);

        MqttSessionClient client = new();
        await client.ConnectAsync(settings);

        return new SourceReceiver<TSourceData>(applicationContext, client)
        {
            TopicPattern = options.Value.SourceTopic,
            OnTelemetryReceived = onTelemetryReceived
        };
    }
}