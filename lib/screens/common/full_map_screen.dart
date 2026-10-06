import 'package:flutter/material.dart';

import '../../models/delivery.dart';
import '../../utils/launchers.dart';
import '../../widgets/bottom_action_bar.dart';
import '../../widgets/delivery_map.dart';

/// Carte A/B en plein écran, manipulable librement (zoom, déplacement).
class FullMapScreen extends StatelessWidget {
  final String title;
  final DeliveryPoint pickup;
  final DeliveryPoint dropoff;

  const FullMapScreen({super.key, required this.title, required this.pickup, required this.dropoff});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: DeliveryMap(pickup: pickup, dropoff: dropoff, interactive: true, height: double.infinity),
      bottomNavigationBar: BottomActionBar(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => openNavigation(context, pickup.lat, pickup.lng),
                  icon: const Icon(Icons.navigation_outlined),
                  label: const Text('Vers A'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => openNavigation(context, dropoff.lat, dropoff.lng),
                  icon: const Icon(Icons.navigation),
                  label: const Text('Vers B'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
