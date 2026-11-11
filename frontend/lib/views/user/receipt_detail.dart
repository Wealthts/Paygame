import 'package:flutter/material.dart';

import 'package:frontend/theme/app_colors.dart';

/// เส้นประแบบใบเสร็จ
class DashedDivider extends StatelessWidget {
  final double dashWidth;
  final double gap;
  final Color color;

  const DashedDivider({
    super.key,
    this.dashWidth = 6,
    this.gap = 4,
    this.color = AppColors.border,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = (constraints.maxWidth / (dashWidth + gap)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              count,
              (_) => SizedBox(
                width: dashWidth,
                height: 2,
                child: DecoratedBox(decoration: BoxDecoration(color: color)),
              ),
            ),
          );
        },
      ),
    );
  }
}
