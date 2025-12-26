using AtlantisGrev.API.Models;

namespace AtlantisGrev.API.DTOs;

public class PurchaseAccountRequest
{
    public int Count { get; set; } = 1;
    public string? ReferralCode { get; set; }
}

public class PurchaseAccountResponse
{
    public string InvoiceUrl { get; set; } = string.Empty;
    public string InvoiceHash { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public int AccountsCount { get; set; }
}

public class AccountDto
{
    public string Id { get; set; } = string.Empty;
    public string PhoneNumber { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string WarmingStatus { get; set; } = string.Empty;
    public int WarmingProgress { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? WarmingStartedAt { get; set; }
    public DateTime? WarmingCompletedAt { get; set; }
}

public class AccountDetailsDto : AccountDto
{
    public List<string> WarmingLogs { get; set; } = new();
}

public class MyAccountsResponse
{
    public List<AccountDto> Accounts { get; set; } = new();
    public int Total { get; set; }
    public int Active { get; set; }
    public int Warming { get; set; }
    public int Completed { get; set; }
}

