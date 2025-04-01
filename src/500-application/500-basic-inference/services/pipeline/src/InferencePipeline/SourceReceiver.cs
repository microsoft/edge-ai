using Azure.Iot.Operations.Protocol;
using Azure.Iot.Operations.Protocol.Telemetry;
using Azure.Iot.Operations.Services.SchemaRegistry;

namespace InferencePipeline;

/// <summary>
///     Interface for receiving <see cref="TSourceData" /> by exposing <see cref="TelemetryReceiver{T}" /> methods and
///     properties.
/// </summary>
/// <typeparam name="TSourceData">Source data to receive.</typeparam>
/// <seealso cref="SourceReceiver{TSourceData}" />
public interface ISourceReceiver<in TSourceData> : IAsyncDisposable
    where TSourceData : class
{
    string TopicPattern { get; }

    Func<string, TSourceData, IncomingTelemetryMetadata, Task>? OnTelemetryReceived { get; }

    Task StartAsync(CancellationToken cancellationToken);
}

/// <summary>
///     Receives <see cref="TSourceData" /> from the source MQTT subscriber.
/// </summary>
/// <param name="applicationContext">Required by the IoT Operations SDK.</param>
/// <param name="mqttClient">Connected <see cref="IMqttPubSubClient" /> MqttSessionClient from the IoT Operations SDK.</param>
/// <typeparam name="TSourceData">Source data to receive.</typeparam>
/// <seealso cref="SourceReceiverFactory{TSinkData}" />
/// <seealso cref="TelemetryReceiver{T}" />
public class SourceReceiver<TSourceData>(
    ApplicationContext applicationContext,
    IMqttPubSubClient mqttClient
) : TelemetryReceiver<TSourceData>(applicationContext, mqttClient, new Utf8JsonSerializer()),
    ISourceReceiver<TSourceData>
    where TSourceData : class;