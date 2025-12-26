using System.Globalization;
using System.Text;
using System.Text.Json;

namespace AtlantisGrev.API.Services;

public class InvoiceInfo
{
    public string Url { get; set; } = string.Empty;
    public string Hash { get; set; } = string.Empty;
}

public class TransferInfo
{
    public long TransferId { get; set; }
    public string SpendId { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string CompletedAt { get; set; } = string.Empty;
}

public class CryptoPayService
{
    private readonly HttpClient _httpClient;
    private readonly string _apiToken;

    public CryptoPayService(IConfiguration configuration)
    {
        _apiToken = configuration["CryptoPay:Token"] ?? throw new ArgumentNullException("CryptoPay:Token");
        _httpClient = new HttpClient
        {
            BaseAddress = new Uri("https://pay.crypt.bot/api/")
        };
        _httpClient.DefaultRequestHeaders.Add("Crypto-Pay-API-Token", _apiToken);
    }

    public async Task<InvoiceInfo?> CreateInvoiceAsync(decimal amount, string asset, string description)
    {
        try
        {
            var payload = new
            {
                asset = asset,
                amount = amount.ToString("F2", CultureInfo.InvariantCulture),
                description = description
            };

            var json = JsonSerializer.Serialize(payload);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            var response = await _httpClient.PostAsync("createInvoice", content);
            var responseContent = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                Console.WriteLine($"CryptoPay API error: {responseContent}");
                return null;
            }

            var doc = JsonDocument.Parse(responseContent);
            if (!doc.RootElement.TryGetProperty("ok", out var okElement) || !okElement.GetBoolean())
                return null;

            if (!doc.RootElement.TryGetProperty("result", out var resultElement))
                return null;

            var payUrl = resultElement.GetProperty("pay_url").GetString() ?? string.Empty;
            var invoiceId = resultElement.GetProperty("invoice_id").GetInt64().ToString();

            return new InvoiceInfo
            {
                Url = payUrl,
                Hash = invoiceId
            };
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error creating invoice: {ex.Message}");
            return null;
        }
    }

    public async Task<string?> GetInvoiceStatusAsync(string invoiceId)
    {
        try
        {
            var response = await _httpClient.GetAsync($"getInvoices?invoice_ids={invoiceId}");
            var responseContent = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
                return null;

            var doc = JsonDocument.Parse(responseContent);
            if (!doc.RootElement.TryGetProperty("ok", out var okElement) || !okElement.GetBoolean())
                return null;

            if (!doc.RootElement.TryGetProperty("result", out var resultElement))
                return null;

            if (!resultElement.TryGetProperty("items", out var itemsElement))
                return null;

            var items = itemsElement.EnumerateArray().ToList();
            if (items.Count == 0)
                return null;

            return items[0].GetProperty("status").GetString();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error getting invoice status: {ex.Message}");
            return null;
        }
    }

    public async Task<TransferInfo?> CreateTransferAsync(long userId, string asset, decimal amount, string spendId)
    {
        try
        {
            var payload = new
            {
                user_id = userId,
                asset = asset,
                amount = amount.ToString("F8", CultureInfo.InvariantCulture),
                spend_id = spendId,
                comment = "Affiliate withdrawal from Atlantis Grev"
            };

            var json = JsonSerializer.Serialize(payload);
            var content = new StringContent(json, Encoding.UTF8, "application/json");

            var response = await _httpClient.PostAsync("transfer", content);
            var responseContent = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
            {
                Console.WriteLine($"CryptoPay transfer error: {responseContent}");
                return null;
            }

            var doc = JsonDocument.Parse(responseContent);
            if (!doc.RootElement.TryGetProperty("ok", out var okElement) || !okElement.GetBoolean())
                return null;

            if (!doc.RootElement.TryGetProperty("result", out var resultElement))
                return null;

            return new TransferInfo
            {
                TransferId = resultElement.GetProperty("transfer_id").GetInt64(),
                SpendId = resultElement.GetProperty("spend_id").GetString() ?? string.Empty,
                Status = resultElement.GetProperty("status").GetString() ?? string.Empty,
                CompletedAt = resultElement.TryGetProperty("completed_at", out var completedAtElement)
                    ? completedAtElement.GetString() ?? string.Empty
                    : string.Empty
            };
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error creating transfer: {ex.Message}");
            return null;
        }
    }

    public async Task<decimal> GetBalanceAsync(string asset = "USDT")
    {
        try
        {
            var response = await _httpClient.GetAsync("getBalance");
            var responseContent = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
                return 0;

            var doc = JsonDocument.Parse(responseContent);
            if (!doc.RootElement.TryGetProperty("ok", out var okElement) || !okElement.GetBoolean())
                return 0;

            if (!doc.RootElement.TryGetProperty("result", out var resultElement))
                return 0;

            foreach (var item in resultElement.EnumerateArray())
            {
                var currencyCode = item.GetProperty("currency_code").GetString();
                if (currencyCode == asset)
                {
                    var availableStr = item.GetProperty("available").GetString();
                    if (decimal.TryParse(availableStr, NumberStyles.Any, CultureInfo.InvariantCulture, out var available))
                        return available;
                }
            }

            return 0;
        }
        catch (Exception ex)
        {
            Console.WriteLine($"Error getting balance: {ex.Message}");
            return 0;
        }
    }
}

