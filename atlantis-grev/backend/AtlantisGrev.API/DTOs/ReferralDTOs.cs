namespace AtlantisGrev.API.DTOs;

public class ReferralStatsDto
{
    public string AffiliateCode { get; set; } = string.Empty;
    public string ReferralLink { get; set; } = string.Empty;
    public decimal AffiliateBalance { get; set; }
    public decimal TotalEarned { get; set; }
    public int TotalReferrals { get; set; }
    public int ActiveReferrals { get; set; }
    public List<ReferralDto> RecentReferrals { get; set; } = new();
}

public class ReferralDto
{
    public long UserId { get; set; }
    public string Username { get; set; } = string.Empty;
    public DateTime JoinedAt { get; set; }
    public int PaidAccounts { get; set; }
    public decimal EarnedFromReferral { get; set; }
}

public class WithdrawalRequest
{
    public decimal Amount { get; set; }
    public string WalletAddress { get; set; } = string.Empty;
}

public class WithdrawalResponse
{
    public string TransactionId { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class WithdrawalHistoryDto
{
    public List<WithdrawalDto> Withdrawals { get; set; } = new();
    public int Total { get; set; }
}

public class WithdrawalDto
{
    public string Id { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string WalletAddress { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
}

