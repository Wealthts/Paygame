/// Model ของรางวัล (ตาราง REWARDS)
class Reward {
  final int id;
  final String name;
  final String tag; // ข้อความสั้นบนไอคอน เช่น ฿20, 5%
  final int pointsCost;
  final double discountValue;

  const Reward({
    required this.id,
    required this.name,
    required this.tag,
    required this.pointsCost,
    required this.discountValue,
  });

  factory Reward.fromJson(Map<String, dynamic> json) => Reward(
        id: json['reward_id'] as int,
        name: json['reward_name'] as String,
        tag: json['tag'] as String? ?? '',
        pointsCost: json['points_cost'] as int,
        discountValue: (json['discount_value'] as num).toDouble(),
      );
}
