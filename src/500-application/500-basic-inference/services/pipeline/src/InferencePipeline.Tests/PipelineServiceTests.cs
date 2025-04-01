using System.Globalization;
using System.Reflection;
using Azure.Iot.Operations.Protocol.Models;
using Azure.Iot.Operations.Protocol.Telemetry;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Moq;

// ReSharper disable UnusedAutoPropertyAccessor.Global
// ReSharper disable MemberCanBeProtected.Global
// ReSharper disable ConvertConstructorToMemberInitializers
// ReSharper disable InconsistentNaming
// ReSharper disable PrivateFieldCanBeConvertedToLocalVariable

namespace InferencePipeline.Tests;

public class PipelineService_WhenReceivingMultipleTests : PipelineServiceTestsBase, IAsyncLifetime
{
    private readonly CancellationTokenSource cancellationTokenSource;
    private readonly List<FakeSinkData> sinkDataList;
    private readonly List<FakeSourceData> sourceDataList;

    public PipelineService_WhenReceivingMultipleTests()
    {
        // Create test data with multiple source and corresponding sink messages
        sourceDataList =
        [
            new FakeSourceData { Id = 1, Name = "Test1" },
            new FakeSourceData { Id = 2, Name = "Test2" },
            new FakeSourceData { Id = 3, Name = "Test3" }
        ];

        sinkDataList =
        [
            new FakeSinkData { Result = "Processed1", Score = 0.91 },
            new FakeSinkData { Result = "Processed2", Score = 0.92 },
            new FakeSinkData { Result = "Processed3", Score = 0.93 }
        ];

        cancellationTokenSource = new CancellationTokenSource();
    }

    public async ValueTask InitializeAsync()
    {
        await sut.StartAsync(cancellationTokenSource.Token);
    }

    public ValueTask DisposeAsync()
    {
        return ValueTask.CompletedTask;
    }

    [Fact]
    public async Task WhenMultipleMessagesReceived_ProcessDataAsync_ProcessesAllMessages()
    {
        // Arrange
        dataProcessorMock
            .Setup(p =>
                p.ProcessDataAsync(It.IsAny<FakeSourceData?>(), It.IsAny<CancellationToken>()))
            .Returns<FakeSourceData?, CancellationToken>((sourceData, _) =>
            {
                // Return the corresponding sink data based on the source data's ID
                var index = sourceDataList.FindIndex(s => s.Id == sourceData!.Id);
                return Task.FromResult(sinkDataList[index])!;
            });

        // Act
        foreach (var sourceData in sourceDataList)
            await OnTelemetryReceived(sourceData, $"test-sender-{sourceData.Id}");

        // Verify each message was sent to the sink with correct data
        foreach (var expected in sinkDataList)
            sinkSenderMock.Verify(s => s.SendTelemetryAsync(
                    It.Is<FakeSinkData>(actual => expected == actual),
                    It.IsAny<Dictionary<string, string>>(),
                    It.IsAny<MqttQualityOfServiceLevel>(),
                    It.IsAny<TimeSpan?>(),
                    It.IsAny<CancellationToken>()),
                Times.Once);
    }
}

public class PipelineService_WhenReceivingOneTests : PipelineServiceTestsBase, IAsyncLifetime
{
    private readonly CancellationTokenSource cancellationTokenSource;
    private readonly FakeSinkData sinkData;
    private readonly FakeSourceData sourceData;

    public PipelineService_WhenReceivingOneTests()
    {
        sourceData = new FakeSourceData { Id = 1, Name = "Test" };
        sinkData = new FakeSinkData { Result = "Processed", Score = 0.95 };
        cancellationTokenSource = new CancellationTokenSource();
    }

    public async ValueTask InitializeAsync()
    {
        await sut.StartAsync(cancellationTokenSource.Token);
    }

    public ValueTask DisposeAsync()
    {
        return ValueTask.CompletedTask;
    }

    [Fact]
    public async Task WhenValidData_OnTelemetryReceived_SendsToSink()
    {
        // Arrange
        dataProcessorMock
            .Setup(p =>
                p.ProcessDataAsync(It.IsAny<FakeSourceData?>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(sinkData);

        // Act
        await OnTelemetryReceived(sourceData);

        // Assert
        sinkSenderMock.Verify(s => s.SendTelemetryAsync(
                // Verify expected
                It.Is<FakeSinkData>(actual => sinkData == actual),
                It.IsAny<Dictionary<string, string>>(),
                It.IsAny<MqttQualityOfServiceLevel>(),
                It.IsAny<TimeSpan?>(),
                It.IsAny<CancellationToken>()),
            Times.Once);
    }

    [Fact]
    public async Task WhenSinkDataNull_OnTelemetryReceived_SkipsSendingToSink()
    {
        // Arrange
        dataProcessorMock
            .Setup(p =>
                p.ProcessDataAsync(It.IsAny<FakeSourceData>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync((FakeSinkData?)null);

        // Act
        await OnTelemetryReceived(sourceData);

        // Assert
        sinkSenderMock.Verify(s => s.SendTelemetryAsync(
                It.IsAny<FakeSinkData>(),
                It.IsAny<Dictionary<string, string>>(),
                It.IsAny<MqttQualityOfServiceLevel>(),
                It.IsAny<TimeSpan?>(),
                It.IsAny<CancellationToken>()),
            Times.Never);
    }

    [Fact]
    public async Task WhenHandlingDataThrowsException_OnTelemetryReceived_CallsStopApplication()
    {
        // Arrange
        dataProcessorMock
            .Setup(p =>
                p.ProcessDataAsync(It.IsAny<FakeSourceData>(), It.IsAny<CancellationToken>()))
            .ThrowsAsync(new Exception("Test exception"));

        // Act & Assert
        await Assert.ThrowsAsync<Exception>(() => OnTelemetryReceived(sourceData));

        // Verify application is stopped
        lifetimeMock.Verify(l => l.StopApplication(), Times.Once);
    }

    [Fact]
    public async Task WhenCancellationRequested_OnTelemetryReceived_CallsStopApplication()
    {
        // Arrange
        dataProcessorMock
            .Setup(p => p.ProcessDataAsync(It.IsAny<FakeSourceData>(), It.IsAny<CancellationToken>()))
            .Callback<FakeSourceData?, CancellationToken>((_, token) =>
                // Verify token is passed through to the data processor
                Assert.True(token.IsCancellationRequested))
            .ThrowsAsync(new OperationCanceledException());

        // Act & Assert
        await cancellationTokenSource.CancelAsync();
        await Assert.ThrowsAsync<OperationCanceledException>(() =>
            OnTelemetryReceived(sourceData));

        // Assert
        lifetimeMock.Verify(l => l.StopApplication(), Times.Once);
    }
}

public class PipelineServiceTests : PipelineServiceTestsBase
{
    [Fact]
    public async Task StartAsync_SubscribesToSourceTopic()
    {
        // Act
        await sut.StartAsync(CancellationToken.None);

        // Assert
        sourceReceiverFactoryMock.Verify(
            m =>
                m.Create(It.IsAny<Func<string, FakeSourceData, IncomingTelemetryMetadata, Task>>()),
            Times.Once);
    }

    [Fact]
    public async Task StopAsync_DisposesSourceAndSink()
    {
        // Need to start first to initialize the source and sink
        await sut.StartAsync(CancellationToken.None);

        // Act
        await sut.StopAsync(CancellationToken.None);

        // Assert
        sourceReceiverMock.Verify(s => s.DisposeAsync(), Times.Once);
        sinkSenderMock.Verify(s => s.DisposeAsync(), Times.Once);
    }
}

public abstract class PipelineServiceTestsBase
{
    protected readonly Mock<IPipelineDataProcessor<FakeSourceData, FakeSinkData>> dataProcessorMock;
    protected readonly Mock<IHostApplicationLifetime> lifetimeMock;
    protected readonly Mock<ILogger<PipelineService<FakeSourceData, FakeSinkData>>> loggerMock;
    protected readonly Mock<ISinkSenderFactory<FakeSinkData>> sinkSenderFactoryMock;
    protected readonly Mock<ISinkSender<FakeSinkData>> sinkSenderMock;
    protected readonly Mock<ISourceReceiverFactory<FakeSourceData>> sourceReceiverFactoryMock;
    protected readonly Mock<ISourceReceiver<FakeSourceData>> sourceReceiverMock;
    protected readonly PipelineService<FakeSourceData, FakeSinkData> sut;

    protected Func<string, FakeSourceData, IncomingTelemetryMetadata, Task> capturedOnTelemetryReceived =
        (_, _, _) => Task.CompletedTask;

    protected PipelineServiceTestsBase()
    {
        loggerMock = new Mock<ILogger<PipelineService<FakeSourceData, FakeSinkData>>>();
        lifetimeMock = new Mock<IHostApplicationLifetime>();
        dataProcessorMock = new Mock<IPipelineDataProcessor<FakeSourceData, FakeSinkData>>();

        sourceReceiverMock = new Mock<ISourceReceiver<FakeSourceData>>().SetupAllProperties();
        sinkSenderMock = new Mock<ISinkSender<FakeSinkData>>().SetupAllProperties();

        // Set up the source receiver factory mock, capture the telemetry received callback, and return the source receiver.
        sourceReceiverFactoryMock = new Mock<ISourceReceiverFactory<FakeSourceData>>();
        sourceReceiverFactoryMock
            .Setup(f => f.Create(It.IsAny<Func<string, FakeSourceData, IncomingTelemetryMetadata, Task>>()))
            .Callback<Func<string, FakeSourceData, IncomingTelemetryMetadata, Task>>(handler =>
                capturedOnTelemetryReceived = handler)
            .ReturnsAsync(sourceReceiverMock.Object);

        // Set up the sink sender factory mock and return the sink sender.
        sinkSenderFactoryMock = new Mock<ISinkSenderFactory<FakeSinkData>>();
        sinkSenderFactoryMock
            .Setup(f => f.Create())
            .ReturnsAsync(sinkSenderMock.Object);

        sut = new PipelineService<FakeSourceData, FakeSinkData>(
            loggerMock.Object,
            lifetimeMock.Object,
            sourceReceiverFactoryMock.Object,
            sinkSenderFactoryMock.Object,
            dataProcessorMock.Object);
    }

    protected async Task OnTelemetryReceived(FakeSourceData sourceData, string senderId = "test-sender-id")
    {
        // IncomingTelemetryMetadata has an internal constructor which requires Activator to create.
        var metadata = Activator.CreateInstance(typeof(IncomingTelemetryMetadata),
            BindingFlags.Instance | BindingFlags.NonPublic,
            null, [new MqttApplicationMessage(string.Empty), (uint)0, null], CultureInfo.CurrentCulture);

        if (metadata is IncomingTelemetryMetadata telemetryMetadata)
            await capturedOnTelemetryReceived(senderId, sourceData, telemetryMetadata);
        else
            throw new InvalidOperationException();
    }

    // Fake models for testing
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
