using System.Collections.Concurrent;

namespace AtlantisGrev.WarmingService;

public class QueueManager
{
    private readonly ConcurrentQueue<WarmingJob> _jobQueue = new();
    private readonly ConcurrentDictionary<string, WarmingJob> _activeJobs = new();
    private readonly int _maxConcurrentJobs;

    public QueueManager(int maxConcurrentJobs = 5)
    {
        _maxConcurrentJobs = maxConcurrentJobs;
    }

    public void EnqueueJob(WarmingJob job)
    {
        _jobQueue.Enqueue(job);
        Console.WriteLine($"[QueueManager] Job enqueued: {job.AccountId}");
    }

    public bool TryDequeueJob(out WarmingJob? job)
    {
        if (_activeJobs.Count >= _maxConcurrentJobs)
        {
            job = null;
            return false;
        }

        if (_jobQueue.TryDequeue(out job))
        {
            _activeJobs[job.AccountId] = job;
            Console.WriteLine($"[QueueManager] Job dequeued: {job.AccountId}");
            return true;
        }

        return false;
    }

    public void CompleteJob(string accountId)
    {
        if (_activeJobs.TryRemove(accountId, out var job))
        {
            Console.WriteLine($"[QueueManager] Job completed: {accountId}");
        }
    }

    public bool IsJobActive(string accountId)
    {
        return _activeJobs.ContainsKey(accountId);
    }

    public int GetQueueLength()
    {
        return _jobQueue.Count;
    }

    public int GetActiveJobsCount()
    {
        return _activeJobs.Count;
    }
}

public class WarmingJob
{
    public string AccountId { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string SessionDir { get; set; } = string.Empty;
    public DateTime QueuedAt { get; set; } = DateTime.UtcNow;
    public WarmingJobStatus Status { get; set; } = WarmingJobStatus.Queued;
}

public enum WarmingJobStatus
{
    Queued,
    Running,
    Paused,
    Completed,
    Failed
}

