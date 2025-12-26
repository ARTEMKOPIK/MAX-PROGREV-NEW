using System.Net.Http.Json;
using System.Text;
using System.Text.Json;

namespace AtlantisGrev.WarmingService;

public class ApiClient
{
    private readonly HttpClient _httpClient;
    private readonly string _baseUrl;

    public ApiClient(string baseUrl)
    {
        _baseUrl = baseUrl;
        _httpClient = new HttpClient
        {
            BaseAddress = new Uri(_baseUrl)
        };
    }

    public async Task<bool> UpdateWarmingStatus(string accountId, string status, int progress)
    {
        try
        {
            var payload = new
            {
                accountId,
                status,
                progress
            };

            var response = await _httpClient.PostAsJsonAsync("/api/warming/update-status", payload);
            return response.IsSuccessStatusCode;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[ApiClient] Failed to update status: {ex.Message}");
            return false;
        }
    }

    public async Task<bool> AddWarmingLog(string accountId, string logMessage)
    {
        try
        {
            var payload = new
            {
                accountId,
                logMessage,
                timestamp = DateTime.UtcNow
            };

            var response = await _httpClient.PostAsJsonAsync("/api/warming/add-log", payload);
            return response.IsSuccessStatusCode;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[ApiClient] Failed to add log: {ex.Message}");
            return false;
        }
    }

    public async Task<bool> CompleteWarming(string accountId)
    {
        try
        {
            var payload = new
            {
                accountId,
                completedAt = DateTime.UtcNow
            };

            var response = await _httpClient.PostAsJsonAsync("/api/warming/complete", payload);
            return response.IsSuccessStatusCode;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[ApiClient] Failed to complete warming: {ex.Message}");
            return false;
        }
    }

    public async Task<bool> FailWarming(string accountId, string reason)
    {
        try
        {
            var payload = new
            {
                accountId,
                reason,
                failedAt = DateTime.UtcNow
            };

            var response = await _httpClient.PostAsJsonAsync("/api/warming/fail", payload);
            return response.IsSuccessStatusCode;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[ApiClient] Failed to mark warming as failed: {ex.Message}");
            return false;
        }
    }
}

