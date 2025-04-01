using Azure.Iot.Operations.Mqtt.Session;
using Azure.Iot.Operations.Protocol;
using Azure.Iot.Operations.Protocol.Connection;
using Microsoft.Extensions.Options;

namespace InferencePipeline;

/// <summary>
///     Interface for creating new <see cref="ISinkSender{TSinkData}" /> objects.
/// </summary>
/// <typeparam name="TSinkData">Sink data to send.</typeparam>
public interface ISinkSenderFactory<TSinkData>
    where TSinkData : class
{
    /// <summary>
    ///     Method that creates the new <see cref="ISinkSender{TSinkData}" /> object.
    /// </summary>
    /// <returns>The newly created <see cref="ISinkSender{TSinkData}" />.</returns>
    Task<ISinkSender<TSinkData>> Create();
}

/// <summary>
///     Factory for connecting <see cref="MqttSessionClient" /> and returning a new <see cref="SinkSender{TSinkData}" />.
/// </summary>
/// <param name="logger">The logger for logging data.</param>
/// <param name="options">Application settings provided by ConfigurationSettings.</param>
/// <param name="applicationContext">Required by the IoT Operations SDK.</param>
/// <typeparam name="TSinkData">Sink data to send.</typeparam>
public class SinkSenderFactory<TSinkData>(
    ILogger<SinkSenderFactory<TSinkData>> logger,
    IOptions<InferencePipelineOptions> options,
    ApplicationContext applicationContext) : ISinkSenderFactory<TSinkData>
    where TSinkData : class
{
    /// <summary>
    ///     Connects <see cref="MqttSessionClient" /> and returns a new <see cref="SinkSender{TSinkData}" />
    /// </summary>
    /// <returns>A newly created <see cref="SinkSender{TSinkData}" /></returns>
    public async Task<ISinkSender<TSinkData>> Create()
    {
        var settings = MqttConnectionSettings.FromEnvVars();
        settings.ClientId += "-pipe-sink";

        logger.LogInformation("Starting MQTT session: {settings}", settings);

        MqttSessionClient client = new();
        await client.ConnectAsync(settings);

        return new SinkSender<TSinkData>(applicationContext, client)
        {
            TopicPattern = options.Value.SinkTopic
        };
    }
}