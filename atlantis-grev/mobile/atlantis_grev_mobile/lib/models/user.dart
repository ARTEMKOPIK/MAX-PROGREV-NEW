class User {
  final int id;
  final String username;
  final int paidAccounts;
  final int referrals;
  final double affiliateBalance;
  final double totalEarned;
  final String affiliateCode;
  final DateTime registrationDate;

  User({
    required this.id,
    required this.username,
    required this.paidAccounts,
    required this.referrals,
    required this.affiliateBalance,
    required this.totalEarned,
    required this.affiliateCode,
    required this.registrationDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username'] as String? ?? '',
      paidAccounts: (json['paidAccounts'] as num?)?.toInt() ?? 0,
      referrals: (json['referrals'] as num?)?.toInt() ?? 0,
      affiliateBalance: (json['affiliateBalance'] as num?)?.toDouble() ?? 0.0,
      totalEarned: (json['totalEarned'] as num?)?.toDouble() ?? 0.0,
      affiliateCode: json['affiliateCode'] as String? ?? '',
      registrationDate: json['registrationDate'] != null 
          ? DateTime.parse(json['registrationDate']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'paidAccounts': paidAccounts,
      'referrals': referrals,
      'affiliateBalance': affiliateBalance,
      'totalEarned': totalEarned,
      'affiliateCode': affiliateCode,
      'registrationDate': registrationDate.toIso8601String(),
    };
  }
}

