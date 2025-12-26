import 'package:flutter/material.dart';

class AccountDetailsScreen extends StatelessWidget {
  final String accountId;
  
  const AccountDetailsScreen({super.key, required this.accountId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Details'),
      ),
      body: Center(
        child: Text('Account Details for: $accountId'),
      ),
    );
  }
}

