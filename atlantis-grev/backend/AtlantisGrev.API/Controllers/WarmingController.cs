using AtlantisGrev.API.DTOs;
using AtlantisGrev.API.Models;
using AtlantisGrev.API.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;

namespace AtlantisGrev.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class WarmingController : ControllerBase
{
    private readonly SupabaseService _supabaseService;
    private readonly ILogger<WarmingController> _logger;
    private readonly IConfiguration _configuration;

    public WarmingController(
        SupabaseService supabaseService,
        ILogger<WarmingController> logger,
        IConfiguration configuration)
    {
        _supabaseService = supabaseService;
        _logger = logger;
        _configuration = configuration;
    }

    private long GetUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return long.Parse(userIdClaim ?? "0");
    }

    [HttpPost("start")]
    public async Task<ActionResult<ApiResponse<WarmingStatusDto>>> StartWarming([FromBody] StartWarmingRequest request)
    {
        try
        {
            var userId = GetUserId();
            var account = await _supabaseService.GetAccountByIdAsync(request.AccountId);

            if (account == null)
                return NotFound(ApiResponse<WarmingStatusDto>.ErrorResponse("Account not found"));

            if (account.UserId != userId)
                return Forbid();

            if (account.WarmingStatus == WarmingStatus.InProgress)
                return BadRequest(ApiResponse<WarmingStatusDto>.ErrorResponse("Warming already in progress"));

            // Update account status to queued
            await _supabaseService.UpdateAccountWarmingStatusAsync(account.Id, WarmingStatus.Queued);
            await _supabaseService.AddAccountLogAsync(account.Id, "Warming queued");

            // Send HTTP request to warming service
            var warmingServiceUrl = _configuration["WarmingService:Url"] ?? "http://localhost:5001";
            try
            {
                using var httpClient = new HttpClient();
                httpClient.Timeout = TimeSpan.FromSeconds(30);
                
                var warmingRequest = new
                {
                    accountId = account.Id,
                    phoneNumber = account.PhoneNumber,
                    config = new
                    {
                        dailyMessages = 50,
                        messageInterval = 30,
                        enableGroupMessages = true,
                        enableStatusUpdates = true
                    }
                };

                var content = new StringContent(
                    System.Text.Json.JsonSerializer.Serialize(warmingRequest),
                    System.Text.Encoding.UTF8,
                    "application/json"
                );

                var response = await httpClient.PostAsync($"{warmingServiceUrl}/api/warming/start", content);
                
                if (response.IsSuccessStatusCode)
                {
                    _logger.LogInformation($"Successfully sent warming request to service for account {account.Id}");
                    await _supabaseService.UpdateAccountWarmingStatusAsync(account.Id, WarmingStatus.InProgress);
                }
                else
                {
                    _logger.LogWarning($"Warming service returned status {response.StatusCode}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, $"Failed to send warming request to service: {ex.Message}");
                // Don't fail the whole request if warming service is unavailable
                // Account is already queued and will be picked up when service is available
            }

            var statusResponse = new WarmingStatusDto
            {
                AccountId = account.Id,
                Status = WarmingStatus.Queued.ToString(),
                Progress = 0,
                StartedAt = null,
                EstimatedCompletion = DateTime.UtcNow.AddHours(24),
                RecentLogs = new List<string> { "Warming queued" }
            };

            return Ok(ApiResponse<WarmingStatusDto>.SuccessResponse(statusResponse, "Warming started successfully"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error starting warming");
            return StatusCode(500, ApiResponse<WarmingStatusDto>.ErrorResponse("Internal server error"));
        }
    }

    [HttpGet("status/{accountId}")]
    public async Task<ActionResult<ApiResponse<WarmingStatusDto>>> GetWarmingStatus(string accountId)
    {
        try
        {
            var userId = GetUserId();
            var account = await _supabaseService.GetAccountByIdAsync(accountId);

            if (account == null)
                return NotFound(ApiResponse<WarmingStatusDto>.ErrorResponse("Account not found"));

            if (account.UserId != userId)
                return Forbid();

            var recentLogs = account.WarmingLogs.TakeLast(10).ToList();
            
            var response = new WarmingStatusDto
            {
                AccountId = account.Id,
                Status = account.WarmingStatus.ToString(),
                Progress = account.WarmingProgress,
                StartedAt = account.WarmingStartedAt,
                EstimatedCompletion = account.WarmingStartedAt?.AddHours(24),
                RecentLogs = recentLogs
            };

            return Ok(ApiResponse<WarmingStatusDto>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting warming status");
            return StatusCode(500, ApiResponse<WarmingStatusDto>.ErrorResponse("Internal server error"));
        }
    }

    [HttpPost("action")]
    public async Task<ActionResult<ApiResponse<WarmingStatusDto>>> WarmingAction([FromBody] WarmingActionRequest request)
    {
        try
        {
            var userId = GetUserId();
            var account = await _supabaseService.GetAccountByIdAsync(request.AccountId);

            if (account == null)
                return NotFound(ApiResponse<WarmingStatusDto>.ErrorResponse("Account not found"));

            if (account.UserId != userId)
                return Forbid();

            switch (request.Action.ToLower())
            {
                case "pause":
                    if (account.WarmingStatus != WarmingStatus.InProgress)
                        return BadRequest(ApiResponse<WarmingStatusDto>.ErrorResponse("Cannot pause warming that is not in progress"));
                    
                    await _supabaseService.UpdateAccountWarmingStatusAsync(account.Id, WarmingStatus.Paused);
                    await _supabaseService.AddAccountLogAsync(account.Id, "Warming paused by user");
                    break;

                case "resume":
                    if (account.WarmingStatus != WarmingStatus.Paused)
                        return BadRequest(ApiResponse<WarmingStatusDto>.ErrorResponse("Cannot resume warming that is not paused"));
                    
                    await _supabaseService.UpdateAccountWarmingStatusAsync(account.Id, WarmingStatus.InProgress);
                    await _supabaseService.AddAccountLogAsync(account.Id, "Warming resumed by user");
                    break;

                case "stop":
                    if (account.WarmingStatus == WarmingStatus.Completed)
                        return BadRequest(ApiResponse<WarmingStatusDto>.ErrorResponse("Cannot stop completed warming"));
                    
                    await _supabaseService.UpdateAccountWarmingStatusAsync(account.Id, WarmingStatus.Failed);
                    await _supabaseService.AddAccountLogAsync(account.Id, "Warming stopped by user");
                    break;

                default:
                    return BadRequest(ApiResponse<WarmingStatusDto>.ErrorResponse("Invalid action"));
            }

            account = await _supabaseService.GetAccountByIdAsync(request.AccountId);
            
            var response = new WarmingStatusDto
            {
                AccountId = account!.Id,
                Status = account.WarmingStatus.ToString(),
                Progress = account.WarmingProgress,
                StartedAt = account.WarmingStartedAt,
                RecentLogs = account.WarmingLogs.TakeLast(10).ToList()
            };

            return Ok(ApiResponse<WarmingStatusDto>.SuccessResponse(response, $"Warming {request.Action} successful"));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error performing warming action");
            return StatusCode(500, ApiResponse<WarmingStatusDto>.ErrorResponse("Internal server error"));
        }
    }

    [HttpGet("logs/{accountId}")]
    public async Task<ActionResult<ApiResponse<WarmingLogsResponse>>> GetWarmingLogs(
        string accountId,
        [FromQuery] int offset = 0,
        [FromQuery] int limit = 50)
    {
        try
        {
            var userId = GetUserId();
            var account = await _supabaseService.GetAccountByIdAsync(accountId);

            if (account == null)
                return NotFound(ApiResponse<WarmingLogsResponse>.ErrorResponse("Account not found"));

            if (account.UserId != userId)
                return Forbid();

            var logs = account.WarmingLogs
                .Skip(offset)
                .Take(limit)
                .Select(log => new WarmingLogEntry
                {
                    Timestamp = DateTime.UtcNow, // Parse from log string in production
                    Level = "info",
                    Message = log
                })
                .ToList();

            var response = new WarmingLogsResponse
            {
                Logs = logs,
                Total = account.WarmingLogs.Count
            };

            return Ok(ApiResponse<WarmingLogsResponse>.SuccessResponse(response));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting warming logs");
            return StatusCode(500, ApiResponse<WarmingLogsResponse>.ErrorResponse("Internal server error"));
        }
    }
}
