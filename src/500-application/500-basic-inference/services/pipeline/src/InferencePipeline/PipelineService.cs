using System.Text.Json;
using Azure.Iot.Operations.Protocol.Telemetry;

namespace InferencePipeline;

/// <summary>
///     <see cref="BackgroundService" /> pipeline base class that will set up connections to
///     <see cref="ISourceReceiver{TSourceData}" /> and <see cref="ISinkSender{TSinkData}" />. Source data will be handled
///     and passed to an abstract <see cref="ProcessSourceDataAsync" /> method for processing.
/// </summary>
/// <param name="logger">Logger for logging data.</param>
/// <param name="lifetime">Lifetime needed to stop the application on error.</param>
/// <param name="sourceReceiverFactory">Factory for creating the <see cref="ISourceReceiver{TSourceData}" />.</param>
/// <param name="sinkSenderFactory">Factory for creating the <see cref="ISinkSender{TSinkData}" />.</param>
/// <typeparam name="TSourceData">Source data to receive.</typeparam>
/// <typeparam name="TSinkData">Sink data to send.</typeparam>
public abstract class PipelineServiceBase<TSourceData, TSinkData>(
    ILogger<PipelineServiceBase<TSourceData, TSinkData>> logger,
    IHostApplicationLifetime lifetime,
    ISourceReceiverFactory<TSourceData> sourceReceiverFactory,
    ISinkSenderFactory<TSinkData> sinkSenderFactory
) : BackgroundService where TSourceData : class where TSinkData : class
{
    private ISourceReceiver<TSourceData>? Source { get; set; }
    protected ISinkSender<TSinkData>? Sink { get; private set; }

    public override async Task StopAsync(CancellationToken cancellationToken)
    {
        await DisconnectAsync();
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (stoppingToken.IsCancellationRequested) return;

        try
        {
            logger.LogInformation("Starting MQTT pipeline");

            // Connect to the sink sender topic(s).
            Sink = await sinkSenderFactory.Create();
            logger.LogInformation("Connected Sink Sender: {SinkTopic}", Sink.TopicPattern);

            // Connect to the source receiver topic(s).
            Source = await sourceReceiverFactory.Create((senderId, data, metadata) =>
                HandleSourceDataAsync(senderId, data, metadata, stoppingToken));
            logger.LogInformation("Connected Source Receiver: {SourceTopic}", Source.TopicPattern);

            // Start the source receiver and process all data from topic(s).
            await Source.StartAsync(stoppingToken);
            logger.LogInformation("Source Receiver Finished: {SourceTopic}", Source.TopicPattern);
        }
        catch (Exception e)
        {
            logger.LogError(e, "Pipeline errored, stopping application");
            // Stop the application to prevent data loss.
            lifetime.StopApplication();
        }
    }

    protected abstract Task ProcessSourceDataAsync(string senderId, TSourceData sourceData,
        IncomingTelemetryMetadata metadata,
        CancellationToken stoppingToken);

    protected virtual async Task HandleSourceDataAsync(string senderId, TSourceData sourceData,
        IncomingTelemetryMetadata metadata, CancellationToken stoppingToken)
    {
        try
        {
            await ProcessSourceDataAsync(senderId, sourceData, metadata, stoppingToken);
        }
        catch (Exception ex)
        {
            if (ex is not OperationCanceledException)
                logger.LogError(ex,
                    "Failed handling senderId: {senderId}, data: {data}, user data metadata: {metadata}",
                    senderId, sourceData, JsonSerializer.Serialize(metadata.UserData));

            // Disconnect to prevent the current message from being acknowledged.
            // - Currently, throwing an exception will cause the message to be acknowledged and handled and eaten.
            await DisconnectAsync();

            // Stop the application to prevent missing messages from being processed.
            lifetime.StopApplication();
            throw;
        }
    }

    private async Task DisconnectAsync()
    {
        await IgnoreException(() => Source!.DisposeAsync().AsTask());
        await IgnoreException(() => Sink!.DisposeAsync().AsTask());
    }

    private async Task IgnoreException(Func<Task> func)
    {
        try
        {
            await func();
        }
        catch
        {
            /* noop */
        }
    }
}

/// <summary>
///     <see cref="BackgroundService" /> pipeline that will receive data from <see cref="ISourceReceiver{TSourceData}" />,
///     process the data with <see cref="IPipelineDataProcessor{TSourceData,TSinkData}" /> and then sends the data
///     <see cref="ISinkSender{TSinkData}" />.
/// </summary>
/// <param name="logger">Logger for logging data.</param>
/// <param name="lifetime">Lifetime needed to stop the application on error.</param>
/// <param name="sourceReceiverFactory">Factory for creating the <see cref="ISourceReceiver{TSourceData}" />.</param>
/// <param name="sinkSenderFactory">Factory for creating the <see cref="ISinkSender{TSinkData}" />.</param>
/// <param name="pipelineDataProcessor">
///     Data processor for processing the <see cref="TSourceData" /> into
///     <see cref="TSinkData" />.
/// </param>
/// <typeparam name="TSourceData">Source data to receive.</typeparam>
/// <typeparam name="TSinkData">Sink data to send.</typeparam>
public class PipelineService<TSourceData, TSinkData>(
    ILogger<PipelineService<TSourceData, TSinkData>> logger,
    IHostApplicationLifetime lifetime,
    ISourceReceiverFactory<TSourceData> sourceReceiverFactory,
    ISinkSenderFactory<TSinkData> sinkSenderFactory,
    IPipelineDataProcessor<TSourceData, TSinkData> pipelineDataProcessor
) : PipelineServiceBase<TSourceData, TSinkData>(
    logger,
    lifetime,
    sourceReceiverFactory,
    sinkSenderFactory
)
    where TSourceData : class
    where TSinkData : class
{
    protected override async Task ProcessSourceDataAsync(string senderId, TSourceData sourceData,
        IncomingTelemetryMetadata metadata,
        CancellationToken stoppingToken)
    {
        // Exit early if cancel requested, stop the application as a result.
        stoppingToken.ThrowIfCancellationRequested();

        if (logger.IsEnabled(LogLevel.Debug))
            logger.LogDebug(
                "Processing source data, senderId: {senderId}, data: {data}, user data metadata: {metadata}",
                senderId, sourceData, JsonSerializer.Serialize(metadata.UserData));

        // Process source data and send sink data if any was returned.
        var sinkData = await pipelineDataProcessor.ProcessDataAsync(sourceData, stoppingToken);

        if (logger.IsEnabled(LogLevel.Debug))
            logger.LogDebug("Process sink data senderId: {senderId}, data: {data}, user data metadata: {metadata}",
                senderId, sinkData, JsonSerializer.Serialize(metadata.UserData));

        // Only send data to the sink of data was returned by the prediction endpoint.
        if (sinkData != null)
            await Sink!.SendTelemetryAsync(sinkData, cancellationToken: stoppingToken);
    }
}
