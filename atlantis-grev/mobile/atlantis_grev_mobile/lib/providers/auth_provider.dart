import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final storageServiceProvider = Provider<StorageService>((ref) => StorageService());

class AuthState {
  final bool isAuthenticated;
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.isAuthenticated = false,
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthNotifier(this._apiService, this._storageService) : super(AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    
    final token = await _storageService.getAccessToken();
    if (token != null && token.isNotEmpty) {
      _apiService.setAccessToken(token);
      
      final userId = await _storageService.getUserId();
      if (userId != null) {
        // User is authenticated, set state
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
        );
        return;
      }
    }
    
    state = state.copyWith(isLoading: false);
  }

  Future<bool> login(int telegramId, String username, {String? referralCode}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.login(telegramId, username, referralCode: referralCode);
      
      final accessToken = response['accessToken'] as String;
      final refreshToken = response['refreshToken'] as String;
      final userData = response['user'] as Map<String, dynamic>;
      
      await _storageService.saveAccessToken(accessToken);
      await _storageService.saveRefreshToken(refreshToken);
      await _storageService.saveUserId((userData['id'] as num).toInt());
      
      _apiService.setAccessToken(accessToken);
      
      final user = User.fromJson(userData);
      state = state.copyWith(
        isAuthenticated: true,
        user: user,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _storageService.clearAll();
    _apiService.clearAccessToken();
    state = AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return AuthNotifier(apiService, storageService);
});
