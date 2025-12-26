using System.Text.Json.Serialization;

namespace AtlantisGrev.API.Models;

public class User
{
    [JsonPropertyName("id")]
    public long Id { get; set; }
    
    [JsonPropertyName("username")]
    public string Username { get; set; } = string.Empty;
    
    [JsonPropertyName("paid_accounts")]
    public int PaidAccounts { get; set; } = 0;
    
    [JsonPropertyName("referrals")]
    public int Referrals { get; set; } = 0;
    
    [JsonPropertyName("registration_date")]
    public DateTime RegistrationDate { get; set; } = DateTime.UtcNow;
    
    [JsonPropertyName("referrer_id")]
    public long? ReferrerId { get; set; }
    
    [JsonPropertyName("phone_numbers")]
    public List<string> PhoneNumbers { get; set; } = new();
    
    [JsonPropertyName("affiliate_balance")]
    public decimal AffiliateBalance { get; set; } = 0;
    
    [JsonPropertyName("total_earned")]
    public decimal TotalEarned { get; set; } = 0;
    
    [JsonPropertyName("affiliate_code")]
    public string AffiliateCode { get; set; } = string.Empty;
}

