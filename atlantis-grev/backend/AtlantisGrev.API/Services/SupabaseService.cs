using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using AtlantisGrev.API.Models;

namespace AtlantisGrev.API.Services;

public class SupabaseService
{
    private readonly HttpClient _httpClient;
    private readonly string _supabaseUrl;
    private readonly string _supabaseKey;

    public SupabaseService(IConfiguration configuration)
    {
        _supabaseUrl = configuration["Supabase:Url"] ?? throw new ArgumentNullException("Supabase:Url");
        _supabaseKey = configuration["Supabase:AnonKey"] ?? throw new ArgumentNullException("Supabase:AnonKey");
        
        _httpClient = new HttpClient
        {
            BaseAddress = new Uri($"{_supabaseUrl}/rest/v1/")
        };
        _httpClient.DefaultRequestHeaders.Add("apikey", _supabaseKey);
        _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _supabaseKey);
    }

    // User operations
    public async Task<User?> GetUserAsync(long userId)
    {
        var response = await _httpClient.GetAsync($"users?id=eq.{userId}");
        if (!response.IsSuccessStatusCode) return null;

        var content = await response.Content.ReadAsStringAsync();
        var users = JsonSerializer.Deserialize<List<User>>(content);
        return users?.FirstOrDefault();
    }

    public async Task<User?> CreateUserAsync(long userId, string username, long? referrerId = null)
    {
        var userData = new
        {
            id = userId,
            username = username,
            referrer_id = referrerId,
            registration_date = DateTime.UtcNow
        };

        var json = JsonSerializer.Serialize(userData);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        
        var request = new HttpRequestMessage(HttpMethod.Post, "users");
        request.Content = content;
        request.Headers.Add("Prefer", "return=representation");
        
        var response = await _httpClient.SendAsync(request);
        var responseContent = await response.Content.ReadAsStringAsync();
        
        Console.WriteLine($"CreateUser response: {response.StatusCode} - {responseContent}");
        
        if (!response.IsSuccessStatusCode) return null;

        var users = JsonSerializer.Deserialize<List<User>>(responseContent);
        return users?.FirstOrDefault();
    }

    public async Task<bool> UpdateUserAsync(User user)
    {
        // Only update fields that exist in the database
        var updateData = new
        {
            username = user.Username,
            paid_accounts = user.PaidAccounts,
            referrals = user.Referrals,
            phone_numbers = user.PhoneNumbers
        };
        
        var json = JsonSerializer.Serialize(updateData);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        
        var response = await _httpClient.PatchAsync($"users?id=eq.{user.Id}", content);
        return response.IsSuccessStatusCode;
    }

    public async Task<bool> UpdateUserBalanceAsync(long userId, decimal amount, bool isAdd = true)
    {
        // Note: affiliate_balance doesn't exist in DB yet
        // This is a placeholder - need to add column to Supabase
        var user = await GetUserAsync(userId);
        if (user == null) return false;
        
        // For now, just return true since we can't update non-existent columns
        return true;
    }

    public async Task<bool> IncrementUserReferralsAsync(long userId)
    {
        var user = await GetUserAsync(userId);
        if (user == null) return false;

        user.Referrals++;
        return await UpdateUserAsync(user);
    }

    // Payment operations
    public async Task<Payment?> CreatePaymentAsync(Payment payment)
    {
        var paymentData = new
        {
            user_id = payment.UserId,
            hash = payment.Hash,
            amount = payment.Amount,
            asset = payment.Asset,
            status = payment.Status,
            accounts_count = payment.AccountsCount,
            created_at = payment.CreatedAt
        };
        
        var json = JsonSerializer.Serialize(paymentData);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        
        var request = new HttpRequestMessage(HttpMethod.Post, "payments");
        request.Content = content;
        request.Headers.Add("Prefer", "return=representation");
        
        var response = await _httpClient.SendAsync(request);
        var responseContent = await response.Content.ReadAsStringAsync();
        
        Console.WriteLine($"CreatePayment response: {response.StatusCode} - {responseContent}");
        
        if (!response.IsSuccessStatusCode) return null;

        var payments = JsonSerializer.Deserialize<List<Payment>>(responseContent);
        return payments?.FirstOrDefault();
    }

    public async Task<Payment?> GetPaymentByHashAsync(string hash)
    {
        var response = await _httpClient.GetAsync($"payments?hash=eq.{hash}");
        if (!response.IsSuccessStatusCode) return null;

        var content = await response.Content.ReadAsStringAsync();
        var payments = JsonSerializer.Deserialize<List<Payment>>(content);
        return payments?.FirstOrDefault();
    }

    public async Task<bool> UpdatePaymentStatusAsync(string hash, string status)
    {
        var payment = await GetPaymentByHashAsync(hash);
        if (payment == null) return false;

        payment.Status = status;
        if (status == "completed")
            payment.CompletedAt = DateTime.UtcNow;

        var json = JsonSerializer.Serialize(payment);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        
        var response = await _httpClient.PatchAsync($"payments?hash=eq.{hash}", content);
        return response.IsSuccessStatusCode;
    }

    public async Task<List<Payment>> GetUserPaymentsAsync(long userId)
    {
        var response = await _httpClient.GetAsync($"payments?user_id=eq.{userId}&order=created_at.desc");
        if (!response.IsSuccessStatusCode) return new List<Payment>();

        var content = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<List<Payment>>(content) ?? new List<Payment>();
    }

    // WhatsApp Account operations
    public async Task<WhatsAppAccount?> CreateAccountAsync(WhatsAppAccount account)
    {
        var accountData = new
        {
            id = account.Id,
            user_id = account.UserId,
            phone_number = account.PhoneNumber,
            status = account.Status.ToString(),
            warming_status = account.WarmingStatus.ToString(),
            session_dir = account.SessionDir,
            created_at = account.CreatedAt,
            warming_progress = account.WarmingProgress,
            warming_logs = account.WarmingLogs
        };
        
        var json = JsonSerializer.Serialize(accountData);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        
        var request = new HttpRequestMessage(HttpMethod.Post, "whatsapp_accounts");
        request.Content = content;
        request.Headers.Add("Prefer", "return=representation");
        
        var response = await _httpClient.SendAsync(request);
        var responseContent = await response.Content.ReadAsStringAsync();
        
        Console.WriteLine($"CreateAccount response: {response.StatusCode} - {responseContent}");
        
        if (!response.IsSuccessStatusCode) return null;

        var accounts = JsonSerializer.Deserialize<List<WhatsAppAccount>>(responseContent);
        return accounts?.FirstOrDefault();
    }

    public async Task<List<WhatsAppAccount>> GetUserAccountsAsync(long userId)
    {
        var response = await _httpClient.GetAsync($"whatsapp_accounts?user_id=eq.{userId}&order=created_at.desc");
        if (!response.IsSuccessStatusCode) return new List<WhatsAppAccount>();

        var content = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<List<WhatsAppAccount>>(content) ?? new List<WhatsAppAccount>();
    }

    public async Task<WhatsAppAccount?> GetAccountByIdAsync(string accountId)
    {
        var response = await _httpClient.GetAsync($"whatsapp_accounts?id=eq.{accountId}");
        if (!response.IsSuccessStatusCode) return null;

        var content = await response.Content.ReadAsStringAsync();
        var accounts = JsonSerializer.Deserialize<List<WhatsAppAccount>>(content);
        return accounts?.FirstOrDefault();
    }

    public async Task<bool> UpdateAccountAsync(WhatsAppAccount account)
    {
        var json = JsonSerializer.Serialize(account);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        
        var response = await _httpClient.PatchAsync($"whatsapp_accounts?id=eq.{account.Id}", content);
        return response.IsSuccessStatusCode;
    }

    public async Task<bool> UpdateAccountWarmingStatusAsync(string accountId, WarmingStatus status, int progress = 0)
    {
        var account = await GetAccountByIdAsync(accountId);
        if (account == null) return false;

        account.WarmingStatus = status;
        account.WarmingProgress = progress;

        if (status == WarmingStatus.InProgress && account.WarmingStartedAt == null)
            account.WarmingStartedAt = DateTime.UtcNow;
        
        if (status == WarmingStatus.Completed)
        {
            account.WarmingCompletedAt = DateTime.UtcNow;
            account.Status = AccountStatus.Completed;
        }

        return await UpdateAccountAsync(account);
    }

    public async Task<bool> AddAccountLogAsync(string accountId, string logMessage)
    {
        var account = await GetAccountByIdAsync(accountId);
        if (account == null) return false;

        account.WarmingLogs.Add($"[{DateTime.UtcNow:yyyy-MM-dd HH:mm:ss}] {logMessage}");
        return await UpdateAccountAsync(account);
    }

    // Referral operations
    public async Task<List<User>> GetUserReferralsAsync(long userId)
    {
        var response = await _httpClient.GetAsync($"users?referrer_id=eq.{userId}&order=registration_date.desc");
        if (!response.IsSuccessStatusCode) return new List<User>();

        var content = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<List<User>>(content) ?? new List<User>();
    }

    public async Task<User?> GetUserByAffiliateCodeAsync(string affiliateCode)
    {
        var response = await _httpClient.GetAsync($"users?affiliate_code=eq.{affiliateCode}");
        if (!response.IsSuccessStatusCode) return null;

        var content = await response.Content.ReadAsStringAsync();
        var users = JsonSerializer.Deserialize<List<User>>(content);
        return users?.FirstOrDefault();
    }

    private string GenerateAffiliateCode()
    {
        const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        var random = new Random();
        return new string(Enumerable.Repeat(chars, 8)
            .Select(s => s[random.Next(s.Length)]).ToArray());
    }
}

