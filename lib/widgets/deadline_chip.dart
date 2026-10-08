import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/colors.dart';
import '../utils/formatters.dart';

/// Heure limite de livraison avec compte à rebours (rouge si dépassée ou proche).
class DeadlineChip extends StatefulWidget {
  final DateTime deadline;
  final bool done;

  const DeadlineChip({super.key, required this.deadline, this.done = false});

  @override
  State<DeadlineChip> createState() => _DeadlineChipState();
}

class _DeadlineChipState extends State<DeadlineChip> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!widget.done) _timer = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.deadline.difference(DateTime.now());
    final late = !widget.done && left.isNegative;
    final soon = !widget.done && !late && left.inMinutes < 45;
    final color = late ? AppColors.error : (soon ? AppColors.warning : AppColors.textSecondary);

    final text = widget.done
        ? 'Limite : ${formatTime(widget.deadline)}'
        : late
            ? 'En retard de ${_duration(-left)}'
            : 'Avant ${formatTime(widget.deadline)} · reste ${_duration(left)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(late ? Icons.alarm_off : Icons.alarm, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  static String _duration(Duration d) {
    if (d.inHours >= 1) return '${d.inHours} h ${d.inMinutes.remainder(60).toString().padLeft(2, '0')}';
    return '${d.inMinutes} min';
  }
}
