using Azure.Iot.Operations.Protocol;
using Azure.Iot.Operations.Protocol.Models;
using Azure.Iot.Operations.Protocol.Telemetry;
using Azure.Iot.Operations.Services.SchemaRegistry;

namespace InferencePipeline;

/// <summary>
///     Interface for sending <see cref="TSinkData" /> by exposing <see cref="TelemetrySender{T}" /> methods and
///     properties.
/// </summary>
/// <typeparam name="TSinkData">Sink data to send.</typeparam>
/// <seealso cref="SinkSender{TSinkData}" />
public interface ISinkSender<in TSinkData> : IAsyncDisposable
    where TSinkData : class
{
    string TopicPattern { get; }

    Task SendTelemetryAsync(TSinkData telemetry,
        Dictionary<string, string>? additionalTopicTokenMap = null,
        MqttQualityOfServiceLevel qos = MqttQualityOfServiceLevel.AtLeastOnce,
        TimeSpan? telemetryTimeout = null,
        CancellationToken cancellationToken = default);
}

/// <summary>
///     Sends <see cref="TSinkData" /> to the sink MQTT publisher.
/// </summary>
/// <param name="applicationContext">Required by the IoT Operations SDK.</param>
/// <param name="mqttClient">Connected <see cref="IMqttPubSubClient" /> MqttSessionClient from the IoT Operations SDK.</param>
/// <typeparam name="TSinkData">Sink data to send.</typeparam>
/// <seealso cref="SinkSenderFactory{TSinkData}" />
/// <seealso cref="TelemetrySender{T}" />
public class SinkSender<TSinkData>(
    ApplicationContext applicationContext,
    IMqttPubSubClient mqttClient
) : TelemetrySender<TSinkData>(applicationContext, mqttClient, new Utf8JsonSerializer()),
    ISinkSender<TSinkData>
    where TSinkData : class;
