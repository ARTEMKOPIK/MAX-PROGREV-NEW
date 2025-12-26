import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

class AccountStoreScreen extends ConsumerStatefulWidget {
  const AccountStoreScreen({super.key});

  @override
  ConsumerState<AccountStoreScreen> createState() => _AccountStoreScreenState();
}

class _AccountStoreScreenState extends ConsumerState<AccountStoreScreen> {
  final _referralCodeController = TextEditingController();
  int _selectedCount = 1;
  bool _isProcessing = false;
  static const double pricePerAccount = 0.50;

  @override
  void dispose() {
    _referralCodeController.dispose();
    super.dispose();
  }

  double get totalPrice => _selectedCount * pricePerAccount;

  Future<void> _handlePurchase() async {
    setState(() => _isProcessing = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final referralCode = _referralCodeController.text.trim();

      final response = await apiService.purchaseAccounts(
        _selectedCount,
        referralCode: referralCode.isEmpty ? null : referralCode,
      );

      final invoiceUrl = response['invoiceUrl'] as String;
      final invoiceHash = response['invoiceHash'] as String;

      if (mounted) {
        // Show success dialog with invoice info
        final shouldOpen = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Payment Invoice Created',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your payment invoice has been created successfully.',
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 16),
                _buildInfoRow('Accounts:', '$_selectedCount'),
                _buildInfoRow('Total:', '\$${totalPrice.toStringAsFixed(2)} USDT'),
                _buildInfoRow('Invoice ID:', invoiceHash.substring(0, 8) + '...'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Accounts will be created automatically after payment',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
                child: const Text('Open Invoice'),
              ),
            ],
          ),
        );

        if (shouldOpen == true) {
          // Open invoice URL in browser
          final uri = Uri.parse(invoiceUrl);
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Invoice opened. Complete payment to receive accounts.'),
                  backgroundColor: AppTheme.successColor,
                  action: SnackBarAction(
                    label: 'OK',
                    textColor: Colors.white,
                    onPressed: () {},
                  ),
                ),
              );
              Navigator.pop(context); // Return to previous screen
            }
          } catch (e) {
            throw Exception('Could not open invoice URL: $e');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Account Store',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Card
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
                    Icons.shopping_bag,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'WhatsApp Accounts',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ready for warming',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Price Card
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Price per account',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  Text(
                    '\$$pricePerAccount USDT',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quantity Selector
            Text(
              'Select Quantity',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _selectedCount > 1
                        ? () => setState(() => _selectedCount--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppTheme.primaryColor,
                    iconSize: 36,
                  ),
                  Column(
                    children: [
                      Text(
                        '$_selectedCount',
                        style: GoogleFonts.poppins(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        _selectedCount == 1 ? 'account' : 'accounts',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _selectedCount < 100
                        ? () => setState(() => _selectedCount++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppTheme.primaryColor,
                    iconSize: 36,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Quick Select Buttons
            Row(
              children: [
                Expanded(child: _buildQuickSelectButton(5)),
                const SizedBox(width: 8),
                Expanded(child: _buildQuickSelectButton(10)),
                const SizedBox(width: 8),
                Expanded(child: _buildQuickSelectButton(25)),
                const SizedBox(width: 8),
                Expanded(child: _buildQuickSelectButton(50)),
              ],
            ),

            const SizedBox(height: 24),

            // Referral Code Field
            Text(
              'Referral Code (Optional)',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _referralCodeController,
              decoration: InputDecoration(
                hintText: 'Enter referral code',
                prefixIcon: const Icon(Icons.card_giftcard),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Total Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Price',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '\$${totalPrice.toStringAsFixed(2)} USDT',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Purchase Button
            ElevatedButton(
              onPressed: _isProcessing ? null : _handlePurchase,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Purchase Accounts',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),

            const SizedBox(height: 16),

            // Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppTheme.secondaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment via Crypto Pay',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Accounts will be automatically created and available in your account after payment confirmation.',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSelectButton(int count) {
    return OutlinedButton(
      onPressed: () => setState(() => _selectedCount = count),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
        side: BorderSide(
          color: _selectedCount == count
              ? AppTheme.primaryColor
              : AppTheme.textSecondaryColor.withOpacity(0.3),
          width: _selectedCount == count ? 2 : 1,
        ),
        backgroundColor: _selectedCount == count
            ? AppTheme.primaryColor.withOpacity(0.1)
            : null,
      ),
      child: Text(
        '$count',
        style: GoogleFonts.poppins(
          fontWeight: _selectedCount == count ? FontWeight.bold : FontWeight.normal,
          color: _selectedCount == count
              ? AppTheme.primaryColor
              : AppTheme.textSecondaryColor,
        ),
      ),
    );
  }
}

