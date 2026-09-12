class PaymentRecord {
  final String id;
  final String appointmentId;
  final double amount;
  final String currency;
  final String status;
  final String paymentMethod;
  final String? cardLast4;
  final String? cardBrand;
  final String? transactionId;
  final String createdAt;
  final String? receiptUrl;
  final String psychologistName;
  final String appointmentDate;
  final String appointmentStatus;

  PaymentRecord({
    required this.id,
    required this.appointmentId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.paymentMethod,
    this.cardLast4,
    this.cardBrand,
    this.transactionId,
    required this.createdAt,
    this.receiptUrl,
    required this.psychologistName,
    required this.appointmentDate,
    required this.appointmentStatus,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id'] ?? '',
      appointmentId: json['appointmentId'] ?? '',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      currency: json['currency'] ?? 'MXN',
      status: json['status'] ?? 'PENDING',
      paymentMethod: json['paymentMethod'] ?? 'CREDIT_CARD',
      cardLast4: json['cardLast4'],
      cardBrand: json['cardBrand'],
      transactionId: json['transactionId'],
      createdAt: json['createdAt'] ?? '',
      receiptUrl: json['receiptUrl'],
      psychologistName: json['psychologistName'] ?? 'Profesional',
      appointmentDate: json['appointmentDate'] ?? '',
      appointmentStatus: json['appointmentStatus'] ?? '',
    );
  }
}

class MonthlyEarningsItem {
  final String month;
  final String monthName;
  final double grossAmount;
  final double platformFee;
  final double netAmount;
  final int consultationCount;

  MonthlyEarningsItem({
    required this.month,
    required this.monthName,
    required this.grossAmount,
    required this.platformFee,
    required this.netAmount,
    required this.consultationCount,
  });

  factory MonthlyEarningsItem.fromJson(Map<String, dynamic> json) {
    return MonthlyEarningsItem(
      month: json['month'] ?? '',
      monthName: json['monthName'] ?? '',
      grossAmount: (json['grossAmount'] is num) ? (json['grossAmount'] as num).toDouble() : 0.0,
      platformFee: (json['platformFee'] is num) ? (json['platformFee'] as num).toDouble() : 0.0,
      netAmount: (json['netAmount'] is num) ? (json['netAmount'] as num).toDouble() : 0.0,
      consultationCount: (json['consultationCount'] is num) ? (json['consultationCount'] as num).toInt() : 0,
    );
  }
}

class TransactionSummaryItem {
  final String paymentId;
  final String appointmentId;
  final String createdAt;
  final String patientName;
  final double grossAmount;
  final double platformFee;
  final double netAmount;
  final String currency;
  final String appointmentStatus;
  final String fundStatus; // HELD | AVAILABLE
  final String? cardLast4;
  final String? cardBrand;

  TransactionSummaryItem({
    required this.paymentId,
    required this.appointmentId,
    required this.createdAt,
    required this.patientName,
    required this.grossAmount,
    required this.platformFee,
    required this.netAmount,
    required this.currency,
    required this.appointmentStatus,
    required this.fundStatus,
    this.cardLast4,
    this.cardBrand,
  });

  factory TransactionSummaryItem.fromJson(Map<String, dynamic> json) {
    return TransactionSummaryItem(
      paymentId: json['paymentId'] ?? '',
      appointmentId: json['appointmentId'] ?? '',
      createdAt: json['createdAt'] ?? '',
      patientName: json['patientName'] ?? 'Paciente',
      grossAmount: (json['grossAmount'] is num) ? (json['grossAmount'] as num).toDouble() : 0.0,
      platformFee: (json['platformFee'] is num) ? (json['platformFee'] as num).toDouble() : 0.0,
      netAmount: (json['netAmount'] is num) ? (json['netAmount'] as num).toDouble() : 0.0,
      currency: json['currency'] ?? 'MXN',
      appointmentStatus: json['appointmentStatus'] ?? '',
      fundStatus: json['fundStatus'] ?? 'HELD',
      cardLast4: json['cardLast4'],
      cardBrand: json['cardBrand'],
    );
  }
}

class EarningsSummary {
  final String psychologistId;
  final String currency;
  final double availableBalance;
  final double heldBalance;
  final double pendingPayoutBalance;
  final double totalWithdrawn;
  final double lifetimeNetEarnings;
  final double lifetimePlatformFees;
  final double lifetimeGrossVolume;
  final List<MonthlyEarningsItem> monthlyBreakdown;
  final List<TransactionSummaryItem> recentTransactions;

  EarningsSummary({
    required this.psychologistId,
    required this.currency,
    required this.availableBalance,
    required this.heldBalance,
    required this.pendingPayoutBalance,
    required this.totalWithdrawn,
    required this.lifetimeNetEarnings,
    required this.lifetimePlatformFees,
    required this.lifetimeGrossVolume,
    required this.monthlyBreakdown,
    required this.recentTransactions,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      psychologistId: json['psychologistId'] ?? '',
      currency: json['currency'] ?? 'MXN',
      availableBalance: (json['availableBalance'] is num) ? (json['availableBalance'] as num).toDouble() : 0.0,
      heldBalance: (json['heldBalance'] is num) ? (json['heldBalance'] as num).toDouble() : 0.0,
      pendingPayoutBalance: (json['pendingPayoutBalance'] is num) ? (json['pendingPayoutBalance'] as num).toDouble() : 0.0,
      totalWithdrawn: (json['totalWithdrawn'] is num) ? (json['totalWithdrawn'] as num).toDouble() : 0.0,
      lifetimeNetEarnings: (json['lifetimeNetEarnings'] is num) ? (json['lifetimeNetEarnings'] as num).toDouble() : 0.0,
      lifetimePlatformFees: (json['lifetimePlatformFees'] is num) ? (json['lifetimePlatformFees'] as num).toDouble() : 0.0,
      lifetimeGrossVolume: (json['lifetimeGrossVolume'] is num) ? (json['lifetimeGrossVolume'] as num).toDouble() : 0.0,
      monthlyBreakdown: (json['monthlyBreakdown'] as List<dynamic>?)
              ?.map((item) => MonthlyEarningsItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      recentTransactions: (json['recentTransactions'] as List<dynamic>?)
              ?.map((item) => TransactionSummaryItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class PayoutItem {
  final String id;
  final double amount;
  final String currency;
  final String status;
  final String bankName;
  final String accountClabe;
  final String requestedAt;
  final String? processedAt;
  final String? notes;

  PayoutItem({
    required this.id,
    required this.amount,
    required this.currency,
    required this.status,
    required this.bankName,
    required this.accountClabe,
    required this.requestedAt,
    this.processedAt,
    this.notes,
  });

  factory PayoutItem.fromJson(Map<String, dynamic> json) {
    return PayoutItem(
      id: json['id'] ?? '',
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      currency: json['currency'] ?? 'MXN',
      status: json['status'] ?? 'REQUESTED',
      bankName: json['bankName'] ?? '',
      accountClabe: json['accountClabe'] ?? '',
      requestedAt: json['requestedAt'] ?? '',
      processedAt: json['processedAt'],
      notes: json['notes'],
    );
  }
}

class DigitalReceipt {
  final String receiptNumber;
  final String date;
  final String? transactionId;
  final double amount;
  final String currency;
  final double platformFee;
  final double netAmount;
  final String status;
  final String paymentMethod;
  final String? cardLast4;
  final String? cardBrand;
  final String patientName;
  final String patientEmail;
  final String psychologistName;
  final String appointmentStartAt;

  DigitalReceipt({
    required this.receiptNumber,
    required this.date,
    this.transactionId,
    required this.amount,
    required this.currency,
    required this.platformFee,
    required this.netAmount,
    required this.status,
    required this.paymentMethod,
    this.cardLast4,
    this.cardBrand,
    required this.patientName,
    required this.patientEmail,
    required this.psychologistName,
    required this.appointmentStartAt,
  });

  factory DigitalReceipt.fromJson(Map<String, dynamic> json) {
    final patient = json['patient'] as Map<String, dynamic>? ?? {};
    final psychologist = json['psychologist'] as Map<String, dynamic>? ?? {};
    final appointment = json['appointment'] as Map<String, dynamic>? ?? {};

    return DigitalReceipt(
      receiptNumber: json['receiptNumber'] ?? '',
      date: json['date'] ?? '',
      transactionId: json['transactionId'],
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      currency: json['currency'] ?? 'MXN',
      platformFee: (json['platformFee'] is num) ? (json['platformFee'] as num).toDouble() : 0.0,
      netAmount: (json['netAmount'] is num) ? (json['netAmount'] as num).toDouble() : 0.0,
      status: json['status'] ?? 'SUCCEEDED',
      paymentMethod: json['paymentMethod'] ?? 'CREDIT_CARD',
      cardLast4: json['cardLast4'],
      cardBrand: json['cardBrand'],
      patientName: patient['name'] ?? '',
      patientEmail: patient['email'] ?? '',
      psychologistName: psychologist['name'] ?? '',
      appointmentStartAt: appointment['startAt'] ?? '',
    );
  }
}
