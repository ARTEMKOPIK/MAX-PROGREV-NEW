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
        var user = new User
        {
            Id = userId,
            Username = username,
            ReferrerId = referrerId,
            AffiliateCode = GenerateAffiliateCode(),
            RegistrationDate = DateTime.UtcNow
        };

        var json = JsonSerializer.Serialize(user);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        
        var response = await _httpClient.PostAsync("users", content);
        if (!response.IsSuccessStatusCode) return null;

        var responseContent = await response.Content.ReadAsStringAsync();
        var users = JsonSerializer.Deserialize<List<User>>(responseContent);
        return users?.FirstOrDefault();
    }

    public async Task<bool> UpdateUserAsync(User user)
    {
        var json = JsonSerializer.Serialize(user);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        
        var response = await _httpClient.PatchAsync($"users?id=eq.{user.Id}", content);
        return response.IsSuccessStatusCode;
    }

    public async Task<bool> UpdateUserBalanceAsync(long userId, decimal amount, bool isAdd = true)
    {
        var user = await GetUserAsync(userId);
        if (user == null) return false;

        if (isAdd)
        {
            user.AffiliateBalance += amount;
            user.TotalEarned += amount;
        }
        else
        {
            if (user.AffiliateBalance < amount) return false;
            user.AffiliateBalance -= amount;
        }

        return await UpdateUserAsync(user);
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
        var json = JsonSerializer.Serialize(payment);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        
        var response = await _httpClient.PostAsync("payments", content);
        if (!response.IsSuccessStatusCode) return null;

        var responseContent = await response.Content.ReadAsStringAsync();
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
        var json = JsonSerializer.Serialize(account);
        var content = new StringContent(json, Encoding.UTF8, "application/json");
        
        var response = await _httpClient.PostAsync("whatsapp_accounts", content);
        if (!response.IsSuccessStatusCode) return null;

        var responseContent = await response.Content.ReadAsStringAsync();
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

