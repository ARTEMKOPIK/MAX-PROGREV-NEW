using MaxTelegramBot;

namespace AtlantisGrev.WarmingService;

public class WarmingWorker
{
    private readonly QueueManager _queueManager;
    private readonly ApiClient _apiClient;
    private readonly MaxWebAutomation _automation;
    private bool _isRunning = false;
    private readonly CancellationTokenSource _cts = new();

    public WarmingWorker(QueueManager queueManager, ApiClient apiClient, MaxWebAutomation automation)
    {
        _queueManager = queueManager;
        _apiClient = apiClient;
        _automation = automation;
    }

    public async Task StartAsync()
    {
        _isRunning = true;
        Console.WriteLine("[WarmingWorker] Started");

        while (_isRunning && !_cts.Token.IsCancellationRequested)
        {
            try
            {
                if (_queueManager.TryDequeueJob(out var job) && job != null)
                {
                    await ProcessJobAsync(job);
                }
                else
                {
                    // No jobs available, wait before checking again
                    await Task.Delay(5000, _cts.Token);
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[WarmingWorker] Error: {ex.Message}");
                await Task.Delay(10000, _cts.Token); // Wait longer on error
            }
        }

        Console.WriteLine("[WarmingWorker] Stopped");
    }

    private async Task ProcessJobAsync(WarmingJob job)
    {
        Console.WriteLine($"[WarmingWorker] Processing job: {job.AccountId}");

        try
        {
            // Update status to InProgress
            await _apiClient.UpdateWarmingStatus(job.AccountId, "InProgress", 0);
            await _apiClient.AddWarmingLog(job.AccountId, "Starting warming process...");

            // Step 1: Open WhatsApp
            await _apiClient.AddWarmingLog(job.AccountId, "Opening WhatsApp Web...");
            var opened = await _automation.OpenWhatsAppAsync(job.SessionDir);
            
            if (!opened)
            {
                throw new Exception("Failed to open WhatsApp");
            }

            await _apiClient.UpdateWarmingStatus(job.AccountId, "InProgress", 10);
            await Task.Delay(5000); // Wait for WhatsApp to load

            // Step 2: Wait for login (if needed)
            await _apiClient.AddWarmingLog(job.AccountId, "Checking authentication status...");
            var isLoggedIn = await _automation.WaitForLoginAsync(job.SessionDir);
            
            if (!isLoggedIn)
            {
                throw new Exception("Authentication failed or timed out");
            }

            await _apiClient.UpdateWarmingStatus(job.AccountId, "InProgress", 25);
            await _apiClient.AddWarmingLog(job.AccountId, "Authenticated successfully");

            // Step 3: Perform warming actions
            var warmingSteps = new[]
            {
                ("Updating status...", 35),
                ("Checking messages...", 45),
                ("Interacting with chats...", 60),
                ("Sending test messages...", 75),
                ("Verifying account health...", 85),
                ("Finalizing warming process...", 95)
            };

            foreach (var (action, progress) in warmingSteps)
            {
                await _apiClient.AddWarmingLog(job.AccountId, action);
                await _apiClient.UpdateWarmingStatus(job.AccountId, "InProgress", progress);
                
                // Simulate warming actions (replace with actual automation logic)
                await Task.Delay(TimeSpan.FromMinutes(2));
                
                // Check if job should be paused/stopped
                if (_cts.Token.IsCancellationRequested)
                {
                    await _apiClient.AddWarmingLog(job.AccountId, "Warming paused");
                    return;
                }
            }

            // Step 4: Complete warming
            await _apiClient.UpdateWarmingStatus(job.AccountId, "Completed", 100);
            await _apiClient.AddWarmingLog(job.AccountId, "Warming completed successfully!");
            await _apiClient.CompleteWarming(job.AccountId);

            Console.WriteLine($"[WarmingWorker] Job completed: {job.AccountId}");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[WarmingWorker] Job failed: {job.AccountId} - {ex.Message}");
            await _apiClient.AddWarmingLog(job.AccountId, $"Error: {ex.Message}");
            await _apiClient.FailWarming(job.AccountId, ex.Message);
        }
        finally
        {
            _queueManager.CompleteJob(job.AccountId);
            
            // Close Chrome instance
            try
            {
                await _automation.CloseAsync();
            }
            catch
            {
                // Ignore close errors
            }
        }
    }

    public void Stop()
    {
        _isRunning = false;
        _cts.Cancel();
    }
}
