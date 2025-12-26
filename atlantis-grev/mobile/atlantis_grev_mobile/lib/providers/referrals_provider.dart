import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class ReferralDto {
  final int userId;
  final String username;
  final DateTime joinedAt;
  final int paidAccounts;
  final double earnedFromReferral;

  ReferralDto({
    required this.userId,
    required this.username,
    required this.joinedAt,
    required this.paidAccounts,
    required this.earnedFromReferral,
  });

  factory ReferralDto.fromJson(Map<String, dynamic> json) {
    return ReferralDto(
      userId: json['userId'] ?? 0,
      username: json['username'] ?? '',
      joinedAt: DateTime.parse(json['joinedAt'] ?? DateTime.now().toIso8601String()),
      paidAccounts: json['paidAccounts'] ?? 0,
      earnedFromReferral: (json['earnedFromReferral'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ReferralsState {
  final int totalReferrals;
  final int activeReferrals;
  final double affiliateBalance;
  final double totalEarned;
  final String affiliateCode;
  final String referralLink;
  final List<ReferralDto> recentReferrals;
  final List<Map<String, dynamic>> withdrawals;
  final bool isLoading;
  final String? error;

  ReferralsState({
    this.totalReferrals = 0,
    this.activeReferrals = 0,
    this.affiliateBalance = 0.0,
    this.totalEarned = 0.0,
    this.affiliateCode = '',
    this.referralLink = '',
    this.recentReferrals = const [],
    this.withdrawals = const [],
    this.isLoading = false,
    this.error,
  });

  ReferralsState copyWith({
    int? totalReferrals,
    int? activeReferrals,
    double? affiliateBalance,
    double? totalEarned,
    String? affiliateCode,
    String? referralLink,
    List<ReferralDto>? recentReferrals,
    List<Map<String, dynamic>>? withdrawals,
    bool? isLoading,
    String? error,
  }) {
    return ReferralsState(
      totalReferrals: totalReferrals ?? this.totalReferrals,
      activeReferrals: activeReferrals ?? this.activeReferrals,
      affiliateBalance: affiliateBalance ?? this.affiliateBalance,
      totalEarned: totalEarned ?? this.totalEarned,
      affiliateCode: affiliateCode ?? this.affiliateCode,
      referralLink: referralLink ?? this.referralLink,
      recentReferrals: recentReferrals ?? this.recentReferrals,
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
      
      final recentReferralsList = (stats['recentReferrals'] as List?)
          ?.map((r) => ReferralDto.fromJson(r as Map<String, dynamic>))
          .toList() ?? [];
      
      state = state.copyWith(
        totalReferrals: stats['totalReferrals'] ?? 0,
        activeReferrals: stats['activeReferrals'] ?? 0,
        affiliateBalance: (stats['affiliateBalance'] as num?)?.toDouble() ?? 0.0,
        totalEarned: (stats['totalEarned'] as num?)?.toDouble() ?? 0.0,
        affiliateCode: stats['affiliateCode'] ?? '',
        referralLink: stats['referralLink'] ?? '',
        recentReferrals: recentReferralsList,
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

