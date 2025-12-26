using System.Text.Json.Serialization;

namespace AtlantisGrev.API.Models;

public class Payment
{
    [JsonPropertyName("id")]
    public long Id { get; set; }
    
    [JsonPropertyName("user_id")]
    public long UserId { get; set; }
    
    [JsonPropertyName("hash")]
    public string Hash { get; set; } = string.Empty;
    
    [JsonPropertyName("amount")]
    public decimal Amount { get; set; }
    
    [JsonPropertyName("asset")]
    public string Asset { get; set; } = "USDT";
    
    [JsonPropertyName("status")]
    public string Status { get; set; } = "pending";
    
    [JsonPropertyName("accounts_count")]
    public int AccountsCount { get; set; }
    
    [JsonPropertyName("created_at")]
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    [JsonPropertyName("completed_at")]
    public DateTime? CompletedAt { get; set; }
}

