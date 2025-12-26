import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/whatsapp_account.dart';

class AccountDetailsScreen extends ConsumerStatefulWidget {
  final String accountId;
  
  const AccountDetailsScreen({super.key, required this.accountId});

  @override
  ConsumerState<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends ConsumerState<AccountDetailsScreen> {
  WhatsAppAccount? _account;
  bool _isLoading = true;
  List<Map<String, dynamic>> _logs = [];
  int _logsOffset = 0;
  final int _logsLimit = 50;
  bool _loadingLogs = false;

  @override
  void initState() {
    super.initState();
    _loadAccountDetails();
  }

  Future<void> _loadAccountDetails() async {
    setState(() => _isLoading = true);

    try {
      final account = await ref.read(accountsProvider.notifier).getAccountDetails(widget.accountId);
      
      if (mounted) {
        setState(() {
          _account = account;
          _isLoading = false;
        });

        // Load logs if warming is active
        if (account?.isWarming == true) {
          await _loadWarmingLogs();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading account: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _loadWarmingLogs() async {
    if (_loadingLogs) return;
    
    setState(() => _loadingLogs = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final logs = await apiService.getWarmingLogs(
        widget.accountId,
        offset: _logsOffset,
        limit: _logsLimit,
      );

      if (mounted) {
        setState(() {
          _logs.addAll(logs);
          _logsOffset += logs.length;
          _loadingLogs = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingLogs = false);
      }
    }
  }

  Future<void> _handleWarmingAction(String action) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Action', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to ${action.toLowerCase()} warming for this account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await ref.read(accountsProvider.notifier).warmingAction(
        widget.accountId,
        action,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Action completed: $action'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          await _loadAccountDetails(); // Refresh
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Action failed'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _handleStartWarming() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start Warming', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: const Text('Start the warming process for this account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Start'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await ref.read(accountsProvider.notifier).startWarming(widget.accountId);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Warming started successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          await _loadAccountDetails(); // Refresh
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to start warming'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Account Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAccountDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _account == null
              ? const Center(child: Text('Account not found'))
              : RefreshIndicator(
                  onRefresh: _loadAccountDetails,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Account Info Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.phone_android,
                                size: 64,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _account!.phoneNumber,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildStatusChip(_account!.warmingStatus),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Progress Card (if warming)
                        if (_account!.isWarming) ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Warming Progress',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      '${_account!.warmingProgress}%',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                LinearProgressIndicator(
                                  value: _account!.warmingProgress / 100,
                                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Info Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                'Status',
                                _account!.status,
                                Icons.info_outline,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInfoCard(
                                'Created',
                                _formatDate(_account!.createdAt),
                                Icons.calendar_today,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Action Buttons
                        Text(
                          'Actions',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),

                        if (_account!.canStartWarming)
                          ElevatedButton.icon(
                            onPressed: _handleStartWarming,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Warming'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppTheme.primaryColor,
                            ),
                          )
                        else if (_account!.canResumeWarming)
                          ElevatedButton.icon(
                            onPressed: () => _handleWarmingAction('resume'),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Resume Warming'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppTheme.primaryColor,
                            ),
                          )
                        else if (_account!.canPauseWarming) ...[
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _handleWarmingAction('pause'),
                                  icon: const Icon(Icons.pause),
                                  label: const Text('Pause'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _handleWarmingAction('stop'),
                                  icon: const Icon(Icons.stop),
                                  label: const Text('Stop'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.errorColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Warming Logs
                        if (_logs.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Warming Logs',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${_logs.length} entries',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._logs.map((log) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.textSecondaryColor.withOpacity(0.1),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _getLogIcon(log['type'] ?? ''),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            log['message'] ?? '',
                                            style: GoogleFonts.poppins(fontSize: 13),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDateTime(log['timestamp']),
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: AppTheme.textSecondaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          if (_loadingLogs)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else
                            TextButton(
                              onPressed: _loadWarmingLogs,
                              child: const Text('Load More Logs'),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'completed':
        color = AppTheme.successColor;
        icon = Icons.check_circle;
        break;
      case 'in_progress':
      case 'inprogress':
        color = AppTheme.warningColor;
        icon = Icons.hourglass_empty;
        break;
      case 'paused':
        color = AppTheme.secondaryColor;
        icon = Icons.pause_circle;
        break;
      case 'failed':
        color = AppTheme.errorColor;
        icon = Icons.error;
        break;
      default:
        color = AppTheme.textSecondaryColor;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            status,
            style: GoogleFonts.poppins(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getLogIcon(String type) {
    switch (type.toLowerCase()) {
      case 'success':
        return const Icon(Icons.check_circle, color: AppTheme.successColor, size: 20);
      case 'error':
        return const Icon(Icons.error, color: AppTheme.errorColor, size: 20);
      case 'warning':
        return const Icon(Icons.warning, color: AppTheme.warningColor, size: 20);
      default:
        return const Icon(Icons.info, color: AppTheme.primaryColor, size: 20);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return '';
    
    try {
      final date = timestamp is String 
          ? DateTime.parse(timestamp)
          : timestamp as DateTime;
      
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp.toString();
    }
  }
}
