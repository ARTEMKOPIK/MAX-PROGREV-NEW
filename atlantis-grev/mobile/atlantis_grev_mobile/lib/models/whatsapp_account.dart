class WhatsAppAccount {
  final String id;
  final String phoneNumber;
  final String status;
  final String warmingStatus;
  final int warmingProgress;
  final DateTime createdAt;
  final DateTime? warmingStartedAt;
  final DateTime? warmingCompletedAt;
  final List<String>? warmingLogs;

  WhatsAppAccount({
    required this.id,
    required this.phoneNumber,
    required this.status,
    required this.warmingStatus,
    required this.warmingProgress,
    required this.createdAt,
    this.warmingStartedAt,
    this.warmingCompletedAt,
    this.warmingLogs,
  });

  factory WhatsAppAccount.fromJson(Map<String, dynamic> json) {
    return WhatsAppAccount(
      id: json['id'],
      phoneNumber: json['phoneNumber'],
      status: json['status'],
      warmingStatus: json['warmingStatus'],
      warmingProgress: json['warmingProgress'],
      createdAt: DateTime.parse(json['createdAt']),
      warmingStartedAt: json['warmingStartedAt'] != null 
          ? DateTime.parse(json['warmingStartedAt']) 
          : null,
      warmingCompletedAt: json['warmingCompletedAt'] != null 
          ? DateTime.parse(json['warmingCompletedAt']) 
          : null,
      warmingLogs: json['warmingLogs'] != null 
          ? List<String>.from(json['warmingLogs']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'status': status,
      'warmingStatus': warmingStatus,
      'warmingProgress': warmingProgress,
      'createdAt': createdAt.toIso8601String(),
      'warmingStartedAt': warmingStartedAt?.toIso8601String(),
      'warmingCompletedAt': warmingCompletedAt?.toIso8601String(),
      'warmingLogs': warmingLogs,
    };
  }

  // Helper methods
  bool get isWarming => warmingStatus == 'InProgress';
  bool get isCompleted => status == 'Completed';
  bool get isFailed => status == 'Failed';
  bool get canStartWarming => status == 'Idle' && warmingStatus == 'NotStarted';
  bool get canPauseWarming => warmingStatus == 'InProgress';
  bool get canResumeWarming => warmingStatus == 'Paused';
}

