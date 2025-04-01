using System.Net;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Moq;
using Moq.Protected;

// ReSharper disable PrivateFieldCanBeConvertedToLocalVariable

namespace InferencePipeline.Tests;

public class EndpointDataProcessorTests
{
    private readonly string endpointUri = "https://test-endpoint.com/predict";
    private readonly FakeSinkData expectedSinkData;
    private readonly HttpClient httpClient;
    private readonly Mock<HttpMessageHandler> httpMessageHandlerMock;
    private readonly Mock<ILogger<EndpointDataProcessor<FakeSourceData, FakeSinkData>>> loggerMock;
    private readonly Mock<IOptions<InferencePipelineOptions>> optionsMock;
    private readonly FakeSourceData sourceData;
    private readonly EndpointDataProcessor<FakeSourceData, FakeSinkData> sut;

    public EndpointDataProcessorTests()
    {
        loggerMock = new Mock<ILogger<EndpointDataProcessor<FakeSourceData, FakeSinkData>>>();

        optionsMock = new Mock<IOptions<InferencePipelineOptions>>();
        optionsMock.Setup(o => o.Value).Returns(new InferencePipelineOptions
        {
            EndpointUri = endpointUri,
            SourceTopic = "source/topic",
            SinkTopic = "sink/topic"
        });

        httpMessageHandlerMock = new Mock<HttpMessageHandler>();
        httpClient = new HttpClient(httpMessageHandlerMock.Object);

        sourceData = new FakeSourceData { Id = 42, Name = "Test Data" };
        expectedSinkData = new FakeSinkData { Result = "Processed", Score = 0.95 };

        sut = new EndpointDataProcessor<FakeSourceData, FakeSinkData>(
            loggerMock.Object,
            optionsMock.Object,
            httpClient);
    }

    private void SendAsyncSetup(HttpResponseMessage responseMessage)
    {
        httpMessageHandlerMock
            .Protected()
            .Setup<Task<HttpResponseMessage>>(
                "SendAsync",
                ItExpr.IsAny<HttpRequestMessage>(),
                ItExpr.IsAny<CancellationToken>())
            .ReturnsAsync(responseMessage);
    }

    [Fact]
    public async Task WhenValidRequest_ProcessDataAsync_ReturnsParsedResponse()
    {
        // Arrange
        var responseContent = JsonSerializer.Serialize(expectedSinkData);
        SendAsyncSetup(new HttpResponseMessage
        {
            StatusCode = HttpStatusCode.OK,
            Content = new StringContent(responseContent)
        });

        // Act
        var actual = await sut.ProcessDataAsync(sourceData, CancellationToken.None);

        // Assert
        Assert.NotNull(actual);
        Assert.Equivalent(expectedSinkData, actual);
    }

    [Fact]
    public async Task WhenNonSuccessfulStatusCode_ProcessDataAsync_ThrowsHttpRequestException()
    {
        // Arrange
        var errorResponse = "Testing internal server error";
        SendAsyncSetup(new HttpResponseMessage
        {
            StatusCode = HttpStatusCode.InternalServerError,
            Content = new StringContent(errorResponse)
        });

        // Act & Assert
        var exception = await Assert.ThrowsAsync<HttpRequestException>(
            () => sut.ProcessDataAsync(sourceData, CancellationToken.None)
        );

        Assert.Contains("500", exception.Message);
    }

    [Fact]
    public async Task WhenInvalidJsonReturned_ProcessDataAsync_ThrowsJsonException()
    {
        // Arrange
        var invalidJson = "{ invalid json: structure }";
        SendAsyncSetup(new HttpResponseMessage
        {
            StatusCode = HttpStatusCode.OK,
            Content = new StringContent(invalidJson)
        });

        // Act & Assert
        await Assert.ThrowsAsync<JsonException>(
            () => sut.ProcessDataAsync(sourceData, CancellationToken.None)
        );
    }

    [Fact]
    public async Task WhenSourceDataIsNull_ProcessDataAsync_StillMakesRequestAndReturnsResponse()
    {
        // Arrange
        var responseContent = JsonSerializer.Serialize(expectedSinkData);
        SendAsyncSetup(new HttpResponseMessage
        {
            StatusCode = HttpStatusCode.OK,
            Content = new StringContent(responseContent)
        });

        // Act
        var actual = await sut.ProcessDataAsync(null, CancellationToken.None);

        // Assert
        Assert.NotNull(actual);
        Assert.Equivalent(expectedSinkData, actual);
    }

    [Fact]
    public async Task WhenHttpRequestThrowsException_ProcessDataAsync_PropagatesException()
    {
        // Arrange
        var expectedException = new HttpRequestException("Simulated network failure");

        httpMessageHandlerMock
            .Protected()
            .Setup<Task<HttpResponseMessage>>(
                "SendAsync",
                ItExpr.IsAny<HttpRequestMessage>(),
                ItExpr.IsAny<CancellationToken>())
            .ThrowsAsync(expectedException);

        // Act & Assert
        var actualException = await Assert.ThrowsAsync<HttpRequestException>(
            () => sut.ProcessDataAsync(sourceData, CancellationToken.None)
        );

        Assert.Same(expectedException, actualException);
    }

    [Fact]
    public async Task WhenEmptyResponseReturned_ProcessDataAsync_ReturnsNull()
    {
        // Arrange
        var emptyResponse = "";
        SendAsyncSetup(new HttpResponseMessage
        {
            StatusCode = HttpStatusCode.OK,
            Content = new StringContent(emptyResponse)
        });

        // Act
        var actual = await sut.ProcessDataAsync(sourceData, CancellationToken.None);

        // Assert
        Assert.Null(actual);
    }

    public class FakeSourceData
    {
        public int Id { get; set; }
        public string? Name { get; set; }
    }

    public class FakeSinkData
    {
        public string? Result { get; set; }
        public double Score { get; set; }
    }
}
