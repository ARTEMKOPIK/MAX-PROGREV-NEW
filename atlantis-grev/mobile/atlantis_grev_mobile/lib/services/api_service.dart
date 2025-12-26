import 'package:dio/dio.dart';
import '../models/user.dart';
import '../models/whatsapp_account.dart';

class ApiService {
  // Update this with your production API URL
  static const String baseUrl = 'http://localhost:8080'; // Change to production URL when deploying
  late final Dio _dio;
  String? _accessToken;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptor for auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // Handle token expiration
        if (error.response?.statusCode == 401) {
          // Token refresh logic would go here
          // For now, user needs to re-login
          _accessToken = null;
        }
        return handler.next(error);
      },
    ));
  }

  void setAccessToken(String token) {
    _accessToken = token;
  }

  void clearAccessToken() {
    _accessToken = null;
  }

  // Auth endpoints
  Future<Map<String, dynamic>> login(int telegramId, String username, {String? referralCode}) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'telegramId': telegramId,
        'username': username,
        if (referralCode != null) 'referralCode': referralCode,
      });
      
      if (response.data['success']) {
        final data = response.data['data'];
        _accessToken = data['accessToken'];
        return data;
      } else {
        throw Exception(response.data['message'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  // Account endpoints
  Future<Map<String, dynamic>> purchaseAccounts(int count, {String? referralCode}) async {
    try {
      final response = await _dio.post('/api/accounts/purchase', data: {
        'count': count,
        if (referralCode != null) 'referralCode': referralCode,
      });
      
      if (response.data['success']) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Purchase failed');
      }
    } catch (e) {
      throw Exception('Purchase failed: $e');
    }
  }

  Future<List<WhatsAppAccount>> getMyAccounts() async {
    try {
      final response = await _dio.get('/api/accounts/my-accounts');
      
      if (response.data['success']) {
        final accounts = (response.data['data']['accounts'] as List)
            .map((json) => WhatsAppAccount.fromJson(json))
            .toList();
        return accounts;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch accounts');
      }
    } catch (e) {
      throw Exception('Failed to fetch accounts: $e');
    }
  }

  Future<WhatsAppAccount> getAccountDetails(String accountId) async {
    try {
      final response = await _dio.get('/api/accounts/$accountId');
      
      if (response.data['success']) {
        return WhatsAppAccount.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch account details');
      }
    } catch (e) {
      throw Exception('Failed to fetch account details: $e');
    }
  }

  // Warming endpoints
  Future<Map<String, dynamic>> startWarming(String accountId) async {
    try {
      final response = await _dio.post('/api/warming/start', data: {
        'accountId': accountId,
      });
      
      if (response.data['success']) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to start warming');
      }
    } catch (e) {
      throw Exception('Failed to start warming: $e');
    }
  }

  Future<Map<String, dynamic>> getWarmingStatus(String accountId) async {
    try {
      final response = await _dio.get('/api/warming/status/$accountId');
      
      if (response.data['success']) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch warming status');
      }
    } catch (e) {
      throw Exception('Failed to fetch warming status: $e');
    }
  }

  Future<Map<String, dynamic>> warmingAction(String accountId, String action) async {
    try {
      final response = await _dio.post('/api/warming/action', data: {
        'accountId': accountId,
        'action': action,
      });
      
      if (response.data['success']) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to perform action');
      }
    } catch (e) {
      throw Exception('Failed to perform action: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getWarmingLogs(String accountId, {int offset = 0, int limit = 50}) async {
    try {
      final response = await _dio.get('/api/warming/logs/$accountId', queryParameters: {
        'offset': offset,
        'limit': limit,
      });
      
      if (response.data['success']) {
        return List<Map<String, dynamic>>.from(response.data['data']['logs']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch logs');
      }
    } catch (e) {
      throw Exception('Failed to fetch logs: $e');
    }
  }

  // Referral endpoints
  Future<Map<String, dynamic>> getReferralStats() async {
    try {
      final response = await _dio.get('/api/referrals/stats');
      
      if (response.data['success']) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch referral stats');
      }
    } catch (e) {
      throw Exception('Failed to fetch referral stats: $e');
    }
  }

  Future<Map<String, dynamic>> withdraw(double amount, String walletAddress) async {
    try {
      final response = await _dio.post('/api/referrals/withdraw', data: {
        'amount': amount,
        'walletAddress': walletAddress,
      });
      
      if (response.data['success']) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Withdrawal failed');
      }
    } catch (e) {
      throw Exception('Withdrawal failed: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getWithdrawals() async {
    try {
      final response = await _dio.get('/api/referrals/withdrawals');
      
      if (response.data['success']) {
        return List<Map<String, dynamic>>.from(response.data['data']['withdrawals']);
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch withdrawals');
      }
    } catch (e) {
      throw Exception('Failed to fetch withdrawals: $e');
    }
  }
}
