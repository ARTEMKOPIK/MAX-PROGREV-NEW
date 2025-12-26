using System.Net;
using System.Text;
using System.Text.Json;

namespace AtlantisGrev.WarmingService;

public class WebServer
{
    private readonly QueueManager _queueManager;
    private readonly int _port;
    private HttpListener? _listener;

    public WebServer(QueueManager queueManager, int port)
    {
        _queueManager = queueManager;
        _port = port;
    }

    public async Task StartAsync(CancellationToken cancellationToken)
    {
        _listener = new HttpListener();
        _listener.Prefixes.Add($"http://localhost:{_port}/");
        _listener.Start();

        Console.WriteLine($"[WebServer] Listening on port {_port}");

        while (!cancellationToken.IsCancellationRequested)
        {
            try
            {
                var context = await _listener.GetContextAsync();
                _ = Task.Run(() => HandleRequestAsync(context), cancellationToken);
            }
            catch (Exception ex)
            {
                if (!cancellationToken.IsCancellationRequested)
                {
                    Console.WriteLine($"[WebServer] Error: {ex.Message}");
                }
            }
        }

        _listener?.Stop();
        _listener?.Close();
    }

    private async Task HandleRequestAsync(HttpListenerContext context)
    {
        var request = context.Request;
        var response = context.Response;

        try
        {
            if (request.HttpMethod == "POST" && request.Url?.AbsolutePath == "/start-warming")
            {
                await HandleStartWarmingAsync(request, response);
            }
            else if (request.HttpMethod == "GET" && request.Url?.AbsolutePath == "/status")
            {
                await HandleStatusAsync(response);
            }
            else
            {
                response.StatusCode = 404;
                await WriteJsonResponse(response, new { error = "Not found" });
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[WebServer] Request error: {ex.Message}");
            response.StatusCode = 500;
            await WriteJsonResponse(response, new { error = "Internal server error" });
        }
    }

    private async Task HandleStartWarmingAsync(HttpListenerRequest request, HttpListenerResponse response)
    {
        using var reader = new StreamReader(request.InputStream, request.ContentEncoding);
        var body = await reader.ReadToEndAsync();
        
        var data = JsonSerializer.Deserialize<StartWarmingRequest>(body);
        
        if (data == null || string.IsNullOrEmpty(data.AccountId))
        {
            response.StatusCode = 400;
            await WriteJsonResponse(response, new { error = "Invalid request" });
            return;
        }

        var job = new WarmingJob
        {
            AccountId = data.AccountId,
            PhoneNumber = data.PhoneNumber ?? "",
            SessionDir = data.SessionDir ?? "",
            QueuedAt = DateTime.UtcNow
        };

        _queueManager.EnqueueJob(job);

        response.StatusCode = 200;
        await WriteJsonResponse(response, new
        {
            success = true,
            message = "Job queued successfully",
            accountId = job.AccountId,
            queuePosition = _queueManager.GetQueueLength()
        });
    }

    private async Task HandleStatusAsync(HttpListenerResponse response)
    {
        response.StatusCode = 200;
        await WriteJsonResponse(response, new
        {
            status = "running",
            queueLength = _queueManager.GetQueueLength(),
            activeJobs = _queueManager.GetActiveJobsCount()
        });
    }

    private static async Task WriteJsonResponse(HttpListenerResponse response, object data)
    {
        response.ContentType = "application/json";
        var json = JsonSerializer.Serialize(data);
        var buffer = Encoding.UTF8.GetBytes(json);
        response.ContentLength64 = buffer.Length;
        await response.OutputStream.WriteAsync(buffer);
        response.OutputStream.Close();
    }
}

public class StartWarmingRequest
{
    public string AccountId { get; set; } = string.Empty;
    public string? PhoneNumber { get; set; }
    public string? SessionDir { get; set; }
}

