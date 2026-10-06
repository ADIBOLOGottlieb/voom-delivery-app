import 'package:flutter/material.dart';

import '../models/delivery.dart';
import '../utils/colors.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const StatusChip({super.key, required this.label, required this.color});

  factory StatusChip.delivery(Delivery d) => StatusChip(
        label: d.statusLabel,
        color: switch (d.status) {
          DeliveryStatus.assigned => AppColors.info,
          DeliveryStatus.pickedUp => Colors.indigo,
          DeliveryStatus.delivered => AppColors.success,
          DeliveryStatus.cancelled => AppColors.error,
          _ => AppColors.textSecondary,
        },
      );

  factory StatusChip.payment(Delivery d) => StatusChip(
        label: d.paymentStatusLabel,
        color: switch (d.paymentStatus) {
          PaymentStatus.submitted => AppColors.warning,
          PaymentStatus.verified => AppColors.success,
          PaymentStatus.rejected => AppColors.error,
          _ => AppColors.textSecondary,
        },
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
