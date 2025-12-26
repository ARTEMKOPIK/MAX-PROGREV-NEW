using AtlantisGrev.API.DTOs;
using AtlantisGrev.API.Models;
using AtlantisGrev.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using System.Text.Json;

namespace AtlantisGrev.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AccountsController : ControllerBase
{
    private readonly SupabaseService _supabaseService;
    private readonly CryptoPayService _cryptoPayService;
    private readonly ILogger<AccountsController> _logger;
    private const decimal PricePerAccount = 0.50m;
    private const decimal ReferralCommission = 0.10m;

    public AccountsController(
        SupabaseService supabaseService,
        CryptoPayService cryptoPayService,
        ILogger<AccountsController> logger)
    {
        _supabaseService = supabaseService;
        _cryptoPayService = cryptoPayService;
        _logger = logger;
    }

    private long GetUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return long.Parse(userIdClaim ?? "0");
    }

    [HttpPost("purchase")]
    public async Task<ActionResult<ApiResponse<PurchaseAccountResponse>>> PurchaseAccounts([FromBody] PurchaseAccountRequest request)
    {
        try
        {
            var userId = GetUserId();
            if (request.Count < 1 || request.Count > 100)
                return BadRequest(ApiResponse<PurchaseAccountResponse>.ErrorResponse("Invalid account count (1-100)"));

            var amount = request.Count * PricePerAccount;
            var description = $"Purchase {request.Count} WhatsApp account(s)";

            // Create invoice
            var invoice = await _cryptoPayService.CreateInvoiceAsync(amount, "USDT", description);
            if (invoice == null)
                return StatusCode(500, ApiResponse<PurchaseAccountResponse>.ErrorResponse("Failed to create payment invoice"));

            // Save payment to database
            var payment = new Payment
            {
                UserId = userId,
                Hash = invoice.Hash,
                Amount = amount,
                AccountsCount = request.Count,
                Status = "pending"
            };

            await _supabaseService.CreatePaymentAsync(payment);

            var response = new PurchaseAccountResponse
            {
                InvoiceUrl = invoice.Url,
                InvoiceHash = invoice.Hash,
                Amount = amount,
                AccountsCount = request.Count
            };

            return Ok(ApiResponse<PurchaseAccountResponse>.SuccessResponse(response, "Invoice created successfully"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error purchasing accounts");
            return StatusCode(500, ApiResponse<PurchaseAccountResponse>.ErrorResponse("Internal server error"));
        }
    }

    [HttpGet("my-accounts")]
    public async Task<ActionResult<ApiResponse<MyAccountsResponse>>> GetMyAccounts()
    {
        try
        {
            var userId = GetUserId();
            var accounts = await _supabaseService.GetUserAccountsAsync(userId);

            var accountDtos = accounts.Select(a => new AccountDto
            {
                Id = a.Id,
                PhoneNumber = a.PhoneNumber,
                Status = a.Status.ToString(),
                WarmingStatus = a.WarmingStatus.ToString(),
                WarmingProgress = a.WarmingProgress,
                CreatedAt = a.CreatedAt,
                WarmingStartedAt = a.WarmingStartedAt,
                WarmingCompletedAt = a.WarmingCompletedAt
            }).ToList();

            var response = new MyAccountsResponse
            {
                Accounts = accountDtos,
                Total = accounts.Count,
                Active = accounts.Count(a => a.Status == AccountStatus.Active),
                Warming = accounts.Count(a => a.WarmingStatus == WarmingStatus.InProgress),
                Completed = accounts.Count(a => a.Status == AccountStatus.Completed)
            };

            return Ok(ApiResponse<MyAccountsResponse>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting user accounts");
            return StatusCode(500, ApiResponse<MyAccountsResponse>.ErrorResponse("Internal server error"));
        }
    }

    [HttpGet("{accountId}")]
    public async Task<ActionResult<ApiResponse<AccountDetailsDto>>> GetAccountDetails(string accountId)
    {
        try
        {
            var userId = GetUserId();
            var account = await _supabaseService.GetAccountByIdAsync(accountId);

            if (account == null)
                return NotFound(ApiResponse<AccountDetailsDto>.ErrorResponse("Account not found"));

            if (account.UserId != userId)
                return Forbid();

            var response = new AccountDetailsDto
            {
                Id = account.Id,
                PhoneNumber = account.PhoneNumber,
                Status = account.Status.ToString(),
                WarmingStatus = account.WarmingStatus.ToString(),
                WarmingProgress = account.WarmingProgress,
                CreatedAt = account.CreatedAt,
                WarmingStartedAt = account.WarmingStartedAt,
                WarmingCompletedAt = account.WarmingCompletedAt,
                WarmingLogs = account.WarmingLogs
            };

            return Ok(ApiResponse<AccountDetailsDto>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting account details");
            return StatusCode(500, ApiResponse<AccountDetailsDto>.ErrorResponse("Internal server error"));
        }
    }

    [HttpPost("webhook/payment")]
    [AllowAnonymous]
    public async Task<IActionResult> PaymentWebhook([FromBody] JsonElement payload)
    {
        try
        {
            // Parse webhook payload from Crypto Pay
            _logger.LogInformation($"Received payment webhook: {payload}");

            // Extract payment information
            // This is a simplified version - you need to validate the webhook signature
            
            if (!payload.TryGetProperty("invoice_id", out var invoiceIdElement))
                return BadRequest("Invalid webhook payload");

            var invoiceId = invoiceIdElement.GetString();
            if (string.IsNullOrEmpty(invoiceId))
                return BadRequest("Missing invoice ID");

            var payment = await _supabaseService.GetPaymentByHashAsync(invoiceId);
            if (payment == null)
                return NotFound("Payment not found");

            // Check payment status from Crypto Pay
            var status = await _cryptoPayService.GetInvoiceStatusAsync(invoiceId);
            if (status == "paid")
            {
                // Update payment status
                await _supabaseService.UpdatePaymentStatusAsync(invoiceId, "completed");

                // Create WhatsApp accounts for the user
                var user = await _supabaseService.GetUserAsync(payment.UserId);
                if (user != null)
                {
                    for (int i = 0; i < payment.AccountsCount; i++)
                    {
                        var account = new WhatsAppAccount
                        {
                            UserId = payment.UserId,
                            PhoneNumber = $"PENDING_{Guid.NewGuid().ToString().Substring(0, 8)}",
                            Status = AccountStatus.Idle
                        };
                        await _supabaseService.CreateAccountAsync(account);
                    }

                    // Update user's paid accounts count
                    user.PaidAccounts += payment.AccountsCount;
                    await _supabaseService.UpdateUserAsync(user);

                    // Process referral commission if applicable
                    if (user.ReferrerId.HasValue)
                    {
                        var commission = payment.Amount * ReferralCommission;
                        await _supabaseService.UpdateUserBalanceAsync(user.ReferrerId.Value, commission, true);
                    }
                }
            }

            return Ok();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing payment webhook");
            return StatusCode(500);
        }
    }
}
