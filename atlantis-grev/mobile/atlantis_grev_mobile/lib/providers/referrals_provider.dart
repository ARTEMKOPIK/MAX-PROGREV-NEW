import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class ReferralsState {
  final int totalReferrals;
  final double affiliateBalance;
  final double totalEarned;
  final String affiliateCode;
  final List<Map<String, dynamic>> withdrawals;
  final bool isLoading;
  final String? error;

  ReferralsState({
    this.totalReferrals = 0,
    this.affiliateBalance = 0.0,
    this.totalEarned = 0.0,
    this.affiliateCode = '',
    this.withdrawals = const [],
    this.isLoading = false,
    this.error,
  });

  ReferralsState copyWith({
    int? totalReferrals,
    double? affiliateBalance,
    double? totalEarned,
    String? affiliateCode,
    List<Map<String, dynamic>>? withdrawals,
    bool? isLoading,
    String? error,
  }) {
    return ReferralsState(
      totalReferrals: totalReferrals ?? this.totalReferrals,
      affiliateBalance: affiliateBalance ?? this.affiliateBalance,
      totalEarned: totalEarned ?? this.totalEarned,
      affiliateCode: affiliateCode ?? this.affiliateCode,
      withdrawals: withdrawals ?? this.withdrawals,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ReferralsNotifier extends StateNotifier<ReferralsState> {
  final ApiService _apiService;

  ReferralsNotifier(this._apiService) : super(ReferralsState());

  Future<void> fetchStats() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final stats = await _apiService.getReferralStats();
      
      state = state.copyWith(
        totalReferrals: stats['totalReferrals'] ?? 0,
        affiliateBalance: (stats['affiliateBalance'] as num?)?.toDouble() ?? 0.0,
        totalEarned: (stats['totalEarned'] as num?)?.toDouble() ?? 0.0,
        affiliateCode: stats['affiliateCode'] ?? '',
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> fetchWithdrawals() async {
    try {
      final withdrawals = await _apiService.getWithdrawals();
      state = state.copyWith(withdrawals: withdrawals);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> withdraw(double amount, String walletAddress) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiService.withdraw(amount, walletAddress);
      
      // Refresh stats
      await fetchStats();
      await fetchWithdrawals();
      
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final referralsProvider = StateNotifierProvider<ReferralsNotifier, ReferralsState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ReferralsNotifier(apiService);
});

