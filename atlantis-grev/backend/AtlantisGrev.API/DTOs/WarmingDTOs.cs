namespace AtlantisGrev.API.DTOs;

public class StartWarmingRequest
{
    public string AccountId { get; set; } = string.Empty;
}

public class WarmingStatusDto
{
    public string AccountId { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public int Progress { get; set; }
    public DateTime? StartedAt { get; set; }
    public DateTime? EstimatedCompletion { get; set; }
    public List<string> RecentLogs { get; set; } = new();
}

public class WarmingActionRequest
{
    public string AccountId { get; set; } = string.Empty;
    public string Action { get; set; } = string.Empty; // "start", "pause", "resume", "stop"
}

public class WarmingLogsRequest
{
    public string AccountId { get; set; } = string.Empty;
    public int Offset { get; set; } = 0;
    public int Limit { get; set; } = 50;
}

public class WarmingLogsResponse
{
    public List<WarmingLogEntry> Logs { get; set; } = new();
    public int Total { get; set; }
}

public class WarmingLogEntry
{
    public DateTime Timestamp { get; set; }
    public string Level { get; set; } = "info"; // "info", "warning", "error", "success"
    public string Message { get; set; } = string.Empty;
}

