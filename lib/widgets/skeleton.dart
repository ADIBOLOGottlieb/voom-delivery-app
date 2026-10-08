import 'package:flutter/material.dart';

import '../utils/colors.dart';

/// Bloc gris animé affiché pendant le chargement (au lieu d'un simple rond qui tourne).
class Skeleton extends StatefulWidget {
  final double? width;
  final double height;
  final double radius;

  const Skeleton({super.key, this.width, required this.height, this.radius = 12});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.45, end: 1.0).animate(_c),
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(widget.radius)),
      ),
    );
  }
}

/// Liste de cartes fantômes.
class SkeletonList extends StatelessWidget {
  final int count;
  final double itemHeight;

  const SkeletonList({super.key, this.count = 3, this.itemHeight = 110});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < count; i++)
          Padding(padding: const EdgeInsets.only(bottom: 12), child: Skeleton(height: itemHeight, radius: 16)),
      ],
    );
  }
}
