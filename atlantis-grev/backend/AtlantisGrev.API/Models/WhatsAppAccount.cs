using System.Text.Json.Serialization;

namespace AtlantisGrev.API.Models;

public class WhatsAppAccount
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = Guid.NewGuid().ToString();
    
    [JsonPropertyName("user_id")]
    public long UserId { get; set; }
    
    [JsonPropertyName("phone_number")]
    public string PhoneNumber { get; set; } = string.Empty;
    
    [JsonPropertyName("status")]
    public AccountStatus Status { get; set; } = AccountStatus.Idle;
    
    [JsonPropertyName("warming_status")]
    public WarmingStatus WarmingStatus { get; set; } = WarmingStatus.NotStarted;
    
    [JsonPropertyName("session_dir")]
    public string SessionDir { get; set; } = string.Empty;
    
    [JsonPropertyName("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    [JsonPropertyName("warming_started_at")]
    public DateTime? WarmingStartedAt { get; set; }
    
    [JsonPropertyName("warming_completed_at")]
    public DateTime? WarmingCompletedAt { get; set; }
    
    [JsonPropertyName("warming_progress")]
    public int WarmingProgress { get; set; } = 0;
    
    [JsonPropertyName("warming_logs")]
    public List<string> WarmingLogs { get; set; } = new();
}

public enum AccountStatus
{
    Idle,
    Active,
    Warming,
    Completed,
    Failed,
    Suspended
}

public enum WarmingStatus
{
    NotStarted,
    Queued,
    InProgress,
    Paused,
    Completed,
    Failed
}

