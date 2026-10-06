import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/delivery.dart';

/// Carte Google Maps affichant le point A (récupération, vert) et le point B (destination, rouge).
class DeliveryMap extends StatelessWidget {
  final DeliveryPoint pickup;
  final DeliveryPoint dropoff;
  final double height;

  const DeliveryMap({super.key, required this.pickup, required this.dropoff, this.height = 260});

  LatLngBounds get _bounds => LatLngBounds(
        southwest: LatLng(math.min(pickup.lat, dropoff.lat), math.min(pickup.lng, dropoff.lng)),
        northeast: LatLng(math.max(pickup.lat, dropoff.lat), math.max(pickup.lng, dropoff.lng)),
      );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        child: GoogleMap(
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
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          // Permet de manipuler la carte même placée dans une vue défilante.
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
          },
        ),
      ),
    );
  }
}
