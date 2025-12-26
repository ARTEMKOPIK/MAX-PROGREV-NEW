import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../providers/accounts_provider.dart';
import '../../widgets/account_card.dart';
import 'account_details_screen.dart';
import '../store/account_store_screen.dart';

class MyAccountsScreen extends ConsumerStatefulWidget {
  const MyAccountsScreen({super.key});

  @override
  ConsumerState<MyAccountsScreen> createState() => _MyAccountsScreenState();
}

class _MyAccountsScreenState extends ConsumerState<MyAccountsScreen> {
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(accountsProvider.notifier).fetchAccounts());
  }

  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(accountsProvider);

    // Filter accounts based on selected status
    final filteredAccounts = _filterStatus == 'all'
        ? accountsState.accounts
        : accountsState.accounts.where((account) {
            switch (_filterStatus) {
              case 'active':
                return account.status == 'active';
              case 'warming':
                return account.isWarming;
              case 'completed':
                return account.status == 'completed';
              default:
                return true;
            }
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Accounts',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountStoreScreen()),
              );
            },
            tooltip: 'Buy More Accounts',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('All', 'all', accountsState.total),
                const SizedBox(width: 8),
                _buildFilterChip('Active', 'active', accountsState.active),
                const SizedBox(width: 8),
                _buildFilterChip('Warming', 'warming', accountsState.warming),
                const SizedBox(width: 8),
                _buildFilterChip('Completed', 'completed', accountsState.completed),
              ],
            ),
          ),

          // Accounts List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(accountsProvider.notifier).fetchAccounts(),
              child: accountsState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : accountsState.error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: AppTheme.errorColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error loading accounts',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                accountsState.error!,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppTheme.textSecondaryColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => ref.read(accountsProvider.notifier).fetchAccounts(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : filteredAccounts.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredAccounts.length,
                              itemBuilder: (context, index) {
                                final account = filteredAccounts[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: AccountCard(
                                    phoneNumber: account.phoneNumber,
                                    status: account.warmingStatus,
                                    progress: account.warmingProgress,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AccountDetailsScreen(
                                            accountId: account.id,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filterStatus = value);
      },
      backgroundColor: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : null,
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: GoogleFonts.poppins(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    final message = _filterStatus == 'all'
        ? 'No accounts yet'
        : 'No ${_filterStatus} accounts';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _filterStatus == 'all' ? Icons.inbox_outlined : Icons.filter_alt_outlined,
            size: 80,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          if (_filterStatus == 'all') ...[
            Text(
              'Purchase your first WhatsApp account\nto start warming',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountStoreScreen()),
                );
              },
              icon: const Icon(Icons.shopping_cart),
              label: const Text('Buy Accounts'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: AppTheme.primaryColor,
              ),
            ),
          ] else ...[
            Text(
              'Try changing the filter',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() => _filterStatus = 'all');
              },
              child: const Text('Show All Accounts'),
            ),
          ],
        ],
      ),
    );
  }
}

