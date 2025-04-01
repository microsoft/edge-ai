using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Options;

namespace InferencePipeline;

/// <summary>
///     Process source data responds with sink data, see
/// </summary>
/// <typeparam name="TSourceData">Source data to process.</typeparam>
/// <typeparam name="TSinkData">Sink data to return.</typeparam>
/// <seealso cref="EndpointDataProcessor{TSourceData,TSinkData}" />
public interface IPipelineDataProcessor<in TSourceData, TSinkData>
    where TSourceData : class
    where TSinkData : class
{
    Task<TSinkData?> ProcessDataAsync(TSourceData? sourceData, CancellationToken stoppingToken = default);
}

/// <summary>
///     Process source data responds with sink data, see
///     <see cref="EndpointDataProcessor{TSourceData,TSinkData}.ProcessDataAsync" />
/// </summary>
/// <param name="logger">Logger for logging data.</param>
/// <param name="options">Application settings provided by ConfigurationSettings.</param>
/// <param name="httpClient">HTTP Client for sending source data to an endpoint.</param>
/// <typeparam name="TSourceData">Source data to process.</typeparam>
/// <typeparam name="TSinkData">Sink data to return.</typeparam>
public class EndpointDataProcessor<TSourceData, TSinkData>(
    ILogger<EndpointDataProcessor<TSourceData, TSinkData>> logger,
    IOptions<InferencePipelineOptions> options,
    HttpClient httpClient
) : IPipelineDataProcessor<TSourceData, TSinkData>
    where TSourceData : class
    where TSinkData : class
{
    /// <summary>
    ///     Processes source data by sending it as a JSON body to the <see cref="InferencePipelineOptions.EndpointUri" />.
    ///     The response body is read as JSON and converted into <see cref="TSinkData" /> before be returned as sink data.
    /// </summary>
    /// <param name="sourceData"><see cref="TSourceData" /> source data from receiver.</param>
    /// <param name="stoppingToken">Standard cancellation token.</param>
    /// <returns>
    ///     Response body from endpoint as <see cref="TSinkData" />.
    /// </returns>
    public async Task<TSinkData?> ProcessDataAsync(TSourceData? sourceData, CancellationToken stoppingToken)
    {
        // Send data to prediction endpoint for processing.
        var response =
            await httpClient.PostAsync(options.Value.EndpointUri, JsonContent.Create(sourceData), stoppingToken);

        if (!response.IsSuccessStatusCode)
        {
            // Log error if result returned anything other than a success status code.
            logger.LogError(
                "Failed to get prediction. Status Code: {StatusCode}, Reason Phrase: {ReasonPhrase}, Body: {Body}",
                response.StatusCode, response.ReasonPhrase,
                await response.Content.ReadAsStringAsync(stoppingToken));
            // Throw the HttpRequestException to be handled in pipeline.
            response.EnsureSuccessStatusCode();
        }

        // Read out content from response.
        var responseContent = await response.Content.ReadAsStringAsync(stoppingToken);

        if (logger.IsEnabled(LogLevel.Debug))
            logger.LogDebug("Received prediction: {result}", responseContent);

        // Deserialize response content any was returned otherwise return null.
        return string.IsNullOrWhiteSpace(responseContent)
            ? null
            : JsonSerializer.Deserialize<TSinkData>(responseContent);
    }
}