import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/delivery.dart';
import '../screens/common/full_map_screen.dart';
import '../utils/colors.dart';

/// Carte Google Maps affichant le point A (récupération, vert) et le point B (destination, rouge).
///
/// Intégrée dans une page qui défile ([interactive] = false), la carte est figée pour ne pas
/// bloquer le défilement, et un bouton ouvre la version plein écran manipulable.
class DeliveryMap extends StatelessWidget {
  final DeliveryPoint pickup;
  final DeliveryPoint dropoff;
  final double height;
  final bool interactive;

  const DeliveryMap({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.height = 260,
    this.interactive = false,
  });

  LatLngBounds get _bounds => LatLngBounds(
        southwest: LatLng(math.min(pickup.lat, dropoff.lat), math.min(pickup.lng, dropoff.lng)),
        northeast: LatLng(math.max(pickup.lat, dropoff.lat), math.max(pickup.lng, dropoff.lng)),
      );

  @override
  Widget build(BuildContext context) {
    final map = GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng((pickup.lat + dropoff.lat) / 2, (pickup.lng + dropoff.lng) / 2),
        zoom: 13,
      ),
      onMapCreated: (controller) {
        // Cadre les deux points une fois la carte affichée.
        Future.delayed(const Duration(milliseconds: 300), () {
          controller.animateCamera(CameraUpdate.newLatLngBounds(_bounds, 60));
        });
      },
      markers: {
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup.latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: 'A · Récupération', snippet: pickup.address),
        ),
        Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoff.latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'B · Destination', snippet: dropoff.address),
        ),
      },
      polylines: {
        Polyline(
          polylineId: const PolylineId('ab'),
          points: [pickup.latLng, dropoff.latLng],
          width: 3,
          color: Colors.black54,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      },
      myLocationEnabled: interactive,
      myLocationButtonEnabled: interactive,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      scrollGesturesEnabled: interactive,
      zoomGesturesEnabled: interactive,
      rotateGesturesEnabled: interactive,
      tiltGesturesEnabled: interactive,
    );

    if (interactive) return SizedBox(height: height, child: map);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(child: map),
            Positioned(
              right: 8,
              bottom: 8,
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.background,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 2,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FullMapScreen(title: 'Carte A → B', pickup: pickup, dropoff: dropoff),
                  ),
                ),
                icon: const Icon(Icons.fullscreen),
                label: const Text('Plein écran'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
