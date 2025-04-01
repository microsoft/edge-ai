namespace InferencePipeline;

/// <summary>
///     Application settings provided by ConfigurationSettings.
/// </summary>
public class InferencePipelineOptions
{
    [ConfigurationKeyName("ENDPOINT_URI")]
    public required string EndpointUri { get; init; }

    [ConfigurationKeyName("SOURCE_TOPIC")]
    public required string SourceTopic { get; init; }

    [ConfigurationKeyName("SINK_TOPIC")]
    public required string SinkTopic { get; init; }
}