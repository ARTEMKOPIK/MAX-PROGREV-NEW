import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/account_card.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/referrals_provider.dart';
import '../accounts/my_accounts_screen.dart';
import '../accounts/account_details_screen.dart';
import '../store/account_store_screen.dart';
import '../referrals/referrals_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(accountsProvider.notifier).fetchAccounts();
      ref.read(referralsProvider.notifier).fetchStats();
    });
  }

  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardContent();
      case 1:
        return const MyAccountsScreen();
      case 2:
        return const AccountStoreScreen();
      case 3:
        return const ReferralsScreen();
      default:
        return _buildDashboardContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getSelectedScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.smartphone_outlined),
            selectedIcon: Icon(Icons.smartphone),
            label: 'Accounts',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart_outlined),
            selectedIcon: Icon(Icons.shopping_cart),
            label: 'Store',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Referrals',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    final accountsState = ref.watch(accountsProvider);
    final referralsState = ref.watch(referralsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(accountsProvider.notifier).fetchAccounts();
          await ref.read(referralsProvider.notifier).fetchStats();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Affiliate Balance',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${referralsState.affiliateBalance.toStringAsFixed(2)} USDT',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildBalanceInfo('Paid Accounts', '${accountsState.total}'),
                        const SizedBox(width: 32),
                        _buildBalanceInfo('Active Warming', '${accountsState.warming}'),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Quick Stats
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Total Accounts',
                      value: '${accountsState.total}',
                      icon: Icons.smartphone,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      title: 'Completed',
                      value: '${accountsState.completed}',
                      icon: Icons.check_circle,
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Referrals',
                      value: '${referralsState.totalReferrals}',
                      icon: Icons.people,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: StatCard(
                      title: 'Earnings',
                      value: '\$${referralsState.totalEarned.toStringAsFixed(0)}',
                      icon: Icons.attach_money,
                      color: AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Active Accounts Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Warming',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedIndex = 1);
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Active Accounts List
              if (accountsState.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (accountsState.accounts.isEmpty)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No accounts yet',
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _selectedIndex = 2);
                        },
                        child: const Text('Buy Accounts'),
                      ),
                    ],
                  ),
                )
              else
                ...accountsState.accounts
                    .where((a) => a.isWarming)
                    .take(3)
                    .map((account) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AccountCard(
                            phoneNumber: account.phoneNumber,
                            status: account.warmingStatus,
                            progress: account.warmingProgress,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AccountDetailsScreen(accountId: account.id),
                                ),
                              );
                            },
                          ),
                        )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

