// Loyalty wallet models, mirroring GET /api/loyalty/wallet.

class Voucher {
  final int id;
  final double amountOff;
  final bool used;
  final DateTime createdAt;

  Voucher({
    required this.id,
    required this.amountOff,
    required this.used,
    required this.createdAt,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'] as int,
      amountOff: (json['amountOff'] as num).toDouble(),
      used: json['used'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

/// One predetermined reward tier from the catalog (points -> voucher value).
class RewardTier {
  final String id;
  final int points;
  final double amountOff;

  RewardTier({
    required this.id,
    required this.points,
    required this.amountOff,
  });

  factory RewardTier.fromJson(Map<String, dynamic> json) {
    return RewardTier(
      id: json['id'] as String,
      points: json['points'] as int,
      amountOff: (json['amountOff'] as num).toDouble(),
    );
  }
}

class Wallet {
  final int balance;
  final List<Voucher> vouchers;
  final List<RewardTier> tiers;

  Wallet({
    required this.balance,
    required this.vouchers,
    this.tiers = const [],
  });

  /// Vouchers still available to spend.
  List<Voucher> get availableVouchers =>
      vouchers.where((v) => !v.used).toList();

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      balance: json['balance'] as int? ?? 0,
      vouchers: (json['vouchers'] as List? ?? [])
          .map((v) => Voucher.fromJson(v as Map<String, dynamic>))
          .toList(),
      tiers: (json['tiers'] as List? ?? [])
          .map((t) => RewardTier.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}
