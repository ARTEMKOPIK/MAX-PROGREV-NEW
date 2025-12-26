namespace AtlantisGrev.API.DTOs;

public class LoginRequest
{
    public long TelegramId { get; set; }
    public string Username { get; set; } = string.Empty;
    public string? ReferralCode { get; set; }
}

public class LoginResponse
{
    public string AccessToken { get; set; } = string.Empty;
    public string RefreshToken { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public UserDto User { get; set; } = null!;
}

public class RefreshTokenRequest
{
    public string RefreshToken { get; set; } = string.Empty;
}

public class UserDto
{
    public long Id { get; set; }
    public string Username { get; set; } = string.Empty;
    public int PaidAccounts { get; set; }
    public int Referrals { get; set; }
    public decimal AffiliateBalance { get; set; }
    public decimal TotalEarned { get; set; }
    public string AffiliateCode { get; set; } = string.Empty;
    public DateTime RegistrationDate { get; set; }
}

