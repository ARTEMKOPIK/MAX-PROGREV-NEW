using AtlantisGrev.API.DTOs;
using AtlantisGrev.API.Services;
using Microsoft.AspNetCore.Mvc;

namespace AtlantisGrev.API.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly SupabaseService _supabaseService;
    private readonly AuthService _authService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(
        SupabaseService supabaseService,
        AuthService authService,
        ILogger<AuthController> logger)
    {
        _supabaseService = supabaseService;
        _authService = authService;
        _logger = logger;
    }

    [HttpPost("login")]
    public async Task<ActionResult<ApiResponse<LoginResponse>>> Login([FromBody] LoginRequest request)
    {
        try
        {
            // Get or create user
            var user = await _supabaseService.GetUserAsync(request.TelegramId);
            
            if (user == null)
            {
                // Handle referral if provided
                long? referrerId = null;
                if (!string.IsNullOrEmpty(request.ReferralCode))
                {
                    var referrer = await _supabaseService.GetUserByAffiliateCodeAsync(request.ReferralCode);
                    if (referrer != null)
                    {
                        referrerId = referrer.Id;
                        await _supabaseService.IncrementUserReferralsAsync(referrer.Id);
                    }
                }

                user = await _supabaseService.CreateUserAsync(
                    request.TelegramId,
                    request.Username,
                    referrerId
                );

                if (user == null)
                    return BadRequest(ApiResponse<LoginResponse>.ErrorResponse("Failed to create user"));
            }

            // Generate tokens
            var accessToken = _authService.GenerateAccessToken(user.Id, user.Username);
            var refreshToken = _authService.GenerateRefreshToken();

            var response = new LoginResponse
            {
                AccessToken = accessToken,
                RefreshToken = refreshToken,
                ExpiresAt = DateTime.UtcNow.AddDays(7),
                User = new UserDto
                {
                    Id = user.Id,
                    Username = user.Username,
                    PaidAccounts = user.PaidAccounts,
                    Referrals = user.Referrals,
                    AffiliateBalance = user.AffiliateBalance,
                    TotalEarned = user.TotalEarned,
                    AffiliateCode = user.AffiliateCode,
                    RegistrationDate = user.RegistrationDate
                }
            };

            return Ok(ApiResponse<LoginResponse>.SuccessResponse(response, "Login successful"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during login");
            return StatusCode(500, ApiResponse<LoginResponse>.ErrorResponse("Internal server error"));
        }
    }

    [HttpPost("refresh")]
    public async Task<ActionResult<ApiResponse<LoginResponse>>> RefreshToken([FromBody] RefreshTokenRequest request)
    {
        try
        {
            // In a production app, you'd validate the refresh token against a database
            // For now, we'll just generate new tokens
            
            // This is a simplified implementation
            // You should store refresh tokens in the database and validate them properly
            
            return BadRequest(ApiResponse<LoginResponse>.ErrorResponse("Invalid refresh token"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error during token refresh");
            return StatusCode(500, ApiResponse<LoginResponse>.ErrorResponse("Internal server error"));
        }
    }
}

