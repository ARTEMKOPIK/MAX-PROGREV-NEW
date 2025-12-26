using AtlantisGrev.WarmingService;
using MaxTelegramBot;

Console.WriteLine("===========================================");
Console.WriteLine("   Atlantis Grev - Warming Service");
Console.WriteLine("===========================================");
Console.WriteLine();

// Configuration
var backendApiUrl = Environment.GetEnvironmentVariable("BACKEND_API_URL") 
    ?? "http://localhost:5000";
var maxConcurrentJobs = int.Parse(Environment.GetEnvironmentVariable("MAX_CONCURRENT_JOBS") ?? "5");

Console.WriteLine($"Backend API URL: {backendApiUrl}");
Console.WriteLine($"Max Concurrent Jobs: {maxConcurrentJobs}");
Console.WriteLine();

// Initialize components
var queueManager = new QueueManager(maxConcurrentJobs);
var apiClient = new ApiClient(backendApiUrl);
var automation = new MaxWebAutomation();
var worker = new WarmingWorker(queueManager, apiClient, automation);

// Handle shutdown gracefully
var cts = new CancellationTokenSource();
Console.CancelKeyPress += (sender, args) =>
{
    Console.WriteLine("\n[Service] Shutting down...");
    args.Cancel = true;
    worker.Stop();
    cts.Cancel();
};

// Start HTTP server for receiving warming requests
var webServer = new WebServer(queueManager, 5001);
_ = webServer.StartAsync(cts.Token);

Console.WriteLine("[Service] HTTP Server started on port 5001");
Console.WriteLine("[Service] Warming Worker started");
Console.WriteLine("[Service] Ready to process jobs");
Console.WriteLine();
Console.WriteLine("Press Ctrl+C to stop...");
Console.WriteLine();

// Start processing jobs
await worker.StartAsync();

Console.WriteLine("[Service] Stopped");
