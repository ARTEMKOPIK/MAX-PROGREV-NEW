import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/whatsapp_account.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class AccountsState {
  final List<WhatsAppAccount> accounts;
  final bool isLoading;
  final String? error;
  final int total;
  final int active;
  final int warming;
  final int completed;

  AccountsState({
    this.accounts = const [],
    this.isLoading = false,
    this.error,
    this.total = 0,
    this.active = 0,
    this.warming = 0,
    this.completed = 0,
  });

  AccountsState copyWith({
    List<WhatsAppAccount>? accounts,
    bool? isLoading,
    String? error,
    int? total,
    int? active,
    int? warming,
    int? completed,
  }) {
    return AccountsState(
      accounts: accounts ?? this.accounts,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      total: total ?? this.total,
      active: active ?? this.active,
      warming: warming ?? this.warming,
      completed: completed ?? this.completed,
    );
  }
}

class AccountsNotifier extends StateNotifier<AccountsState> {
  final ApiService _apiService;

  AccountsNotifier(this._apiService) : super(AccountsState());

  Future<void> fetchAccounts() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final accounts = await _apiService.getMyAccounts();
      
      final total = accounts.length;
      final active = accounts.where((a) => a.status == 'Active').length;
      final warming = accounts.where((a) => a.warmingStatus == 'InProgress').length;
      final completed = accounts.where((a) => a.status == 'Completed').length;
      
      state = state.copyWith(
        accounts: accounts,
        total: total,
        active: active,
        warming: warming,
        completed: completed,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<WhatsAppAccount?> getAccountDetails(String accountId) async {
    try {
      return await _apiService.getAccountDetails(accountId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<bool> startWarming(String accountId) async {
    try {
      await _apiService.startWarming(accountId);
      await fetchAccounts(); // Refresh list
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> warmingAction(String accountId, String action) async {
    try {
      await _apiService.warmingAction(accountId, action);
      await fetchAccounts(); // Refresh list
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final accountsProvider = StateNotifierProvider<AccountsNotifier, AccountsState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AccountsNotifier(apiService);
});

