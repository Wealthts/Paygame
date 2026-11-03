/// Model ความเคลื่อนไหวแต้ม (ตาราง POINT_TRANSACTIONS)
enum PointType { earn, redeem, adjust }

class PointTransaction {
  final String description;
  final PointType type;
  final int pointsDelta; // + ได้แต้ม / - ใช้แต้ม
  final DateTime createdAt;

  const PointTransaction({
    required this.description,
    required this.type,
    required this.pointsDelta,
    required this.createdAt,
  });

  bool get isPositive => pointsDelta >= 0;

  factory PointTransaction.fromJson(Map<String, dynamic> json) => PointTransaction(
        description: json['description'] as String,
        type: PointType.values.byName(json['type'] as String),
        pointsDelta: json['points_delta'] as int,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
