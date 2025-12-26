using AtlantisGrev.API.DTOs;
using AtlantisGrev.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace AtlantisGrev.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ReferralsController : ControllerBase
{
    private readonly SupabaseService _supabaseService;
    private readonly CryptoPayService _cryptoPayService;
    private readonly ILogger<ReferralsController> _logger;
    private readonly IConfiguration _configuration;
    private const decimal MinimumWithdrawal = 0.05m;
    private const decimal MaximumWithdrawal = 1000.00m;

    public ReferralsController(
        SupabaseService supabaseService,
        CryptoPayService cryptoPayService,
        ILogger<ReferralsController> logger,
        IConfiguration configuration)
    {
        _supabaseService = supabaseService;
        _cryptoPayService = cryptoPayService;
        _logger = logger;
        _configuration = configuration;
    }

    private long GetUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return long.Parse(userIdClaim ?? "0");
    }

    [HttpGet("stats")]
    public async Task<ActionResult<ApiResponse<ReferralStatsDto>>> GetReferralStats()
    {
        try
        {
            var userId = GetUserId();
            var user = await _supabaseService.GetUserAsync(userId);

            if (user == null)
                return NotFound(ApiResponse<ReferralStatsDto>.ErrorResponse("User not found"));

            var referrals = await _supabaseService.GetUserReferralsAsync(userId);
            
            var baseUrl = _configuration["App:BaseUrl"] ?? "https://atlantisgrev.com";
            var referralLink = $"{baseUrl}?ref={user.AffiliateCode}";

            var referralDtos = referrals.Select(r => new ReferralDto
            {
                UserId = r.Id,
                Username = r.Username,
                JoinedAt = r.RegistrationDate,
                PaidAccounts = r.PaidAccounts,
                EarnedFromReferral = r.PaidAccounts * 0.50m * 0.10m // Calculate commission
            }).ToList();

            var response = new ReferralStatsDto
            {
                AffiliateCode = user.AffiliateCode,
                ReferralLink = referralLink,
                AffiliateBalance = user.AffiliateBalance,
                TotalEarned = user.TotalEarned,
                TotalReferrals = referrals.Count,
                ActiveReferrals = referrals.Count(r => r.PaidAccounts > 0),
                RecentReferrals = referralDtos.Take(10).ToList()
            };

            return Ok(ApiResponse<ReferralStatsDto>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting referral stats");
            return StatusCode(500, ApiResponse<ReferralStatsDto>.ErrorResponse("Internal server error"));
        }
    }

    [HttpPost("withdraw")]
    public async Task<ActionResult<ApiResponse<WithdrawalResponse>>> Withdraw([FromBody] WithdrawalRequest request)
    {
        try
        {
            var userId = GetUserId();
            var user = await _supabaseService.GetUserAsync(userId);

            if (user == null)
                return NotFound(ApiResponse<WithdrawalResponse>.ErrorResponse("User not found"));

            // Validation
            if (request.Amount < MinimumWithdrawal)
                return BadRequest(ApiResponse<WithdrawalResponse>.ErrorResponse($"Minimum withdrawal amount is {MinimumWithdrawal} USDT"));

            if (request.Amount > MaximumWithdrawal)
                return BadRequest(ApiResponse<WithdrawalResponse>.ErrorResponse($"Maximum withdrawal amount is {MaximumWithdrawal} USDT"));

            if (user.AffiliateBalance < request.Amount)
                return BadRequest(ApiResponse<WithdrawalResponse>.ErrorResponse("Insufficient balance"));

            if (string.IsNullOrWhiteSpace(request.WalletAddress))
                return BadRequest(ApiResponse<WithdrawalResponse>.ErrorResponse("Wallet address is required"));

            // Create unique spend ID
            var spendId = $"withdrawal_{userId}_{DateTime.UtcNow.Ticks}";

            // Create transfer via Crypto Pay
            var transfer = await _cryptoPayService.CreateTransferAsync(
                userId,
                "USDT",
                request.Amount,
                spendId
            );

            if (transfer == null)
                return StatusCode(500, ApiResponse<WithdrawalResponse>.ErrorResponse("Failed to process withdrawal"));

            // Deduct from user balance
            await _supabaseService.UpdateUserBalanceAsync(userId, request.Amount, false);

            var response = new WithdrawalResponse
            {
                TransactionId = transfer.TransferId.ToString(),
                Amount = request.Amount,
                Status = transfer.Status,
                CreatedAt = DateTime.UtcNow
            };

            return Ok(ApiResponse<WithdrawalResponse>.SuccessResponse(response, "Withdrawal processed successfully"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing withdrawal");
            return StatusCode(500, ApiResponse<WithdrawalResponse>.ErrorResponse("Internal server error"));
        }
    }

    [HttpGet("withdrawals")]
    public async Task<ActionResult<ApiResponse<WithdrawalHistoryDto>>> GetWithdrawals()
    {
        try
        {
            var userId = GetUserId();
            
            // In production, you'd store withdrawal records in the database
            // For now, returning empty list
            var response = new WithdrawalHistoryDto
            {
                Withdrawals = new List<WithdrawalDto>(),
                Total = 0
            };

            return Ok(ApiResponse<WithdrawalHistoryDto>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting withdrawal history");
            return StatusCode(500, ApiResponse<WithdrawalHistoryDto>.ErrorResponse("Internal server error"));
        }
    }
}

