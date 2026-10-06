import 'package:flutter/material.dart';

import '../models/delivery.dart';
import '../utils/colors.dart';

extension DeliveryTypeStyle on DeliveryType {
  IconData get icon => switch (this) {
        DeliveryType.plis => Icons.mail,
        DeliveryType.colis => Icons.inventory_2,
        DeliveryType.express => Icons.flash_on,
        DeliveryType.programmee => Icons.schedule,
      };

  Color get color => switch (this) {
        DeliveryType.plis => AppColors.primaryDark,
        DeliveryType.colis => AppColors.info,
        DeliveryType.express => AppColors.warning,
        DeliveryType.programmee => AppColors.success,
      };
}

/// Types de livraison en tuiles de même largeur sur une seule ligne.
/// Avec [selected], sert de sélecteur ; sinon, de raccourcis.
class DeliveryTypeTiles extends StatelessWidget {
  final List<DeliveryType> types;
  final DeliveryType? selected;
  final ValueChanged<DeliveryType> onTap;

  const DeliveryTypeTiles({
    super.key,
    this.types = DeliveryType.values,
    this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < types.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _Tile(type: types[i], selected: selected == types[i], onTap: () => onTap(types[i]))),
        ],
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final DeliveryType type;
  final bool selected;
  final VoidCallback onTap;

  const _Tile({required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = type.color;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.primary : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? AppColors.secondary : Colors.transparent, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(type.icon, color: selected ? AppColors.secondary : color, size: 26),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(type.label, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
