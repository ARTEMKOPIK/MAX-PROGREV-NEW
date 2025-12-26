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
      id: json['id'],
      username: json['username'],
      paidAccounts: json['paidAccounts'],
      referrals: json['referrals'],
      affiliateBalance: (json['affiliateBalance'] as num).toDouble(),
      totalEarned: (json['totalEarned'] as num).toDouble(),
      affiliateCode: json['affiliateCode'],
      registrationDate: DateTime.parse(json['registrationDate']),
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

