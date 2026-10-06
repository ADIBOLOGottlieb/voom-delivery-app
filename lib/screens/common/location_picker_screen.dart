import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../utils/colors.dart';
import '../../widgets/bottom_action_bar.dart';

/// Sélection d'un point sur la carte : l'utilisateur déplace la carte sous l'épingle centrale.
/// Renvoie le [LatLng] choisi via Navigator.pop.
class LocationPickerScreen extends StatefulWidget {
  final String title;
  final LatLng? initial;

  const LocationPickerScreen({super.key, required this.title, this.initial});

  /// Centre de Lomé, utilisé si aucune position n'est connue.
  static const lome = LatLng(6.1319, 1.2228);

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _controller;
  late LatLng _target = widget.initial ?? LocationPickerScreen.lome;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    if (widget.initial == null) _goToMyPosition(silent: true);
  }

  Future<void> _goToMyPosition({bool silent = false}) async {
    setState(() => _locating = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw 'Activez la localisation du téléphone.';
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw "L'accès à la position a été refusé.";
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
      );
      final latLng = LatLng(pos.latitude, pos.longitude);
      _target = latLng;
      await _controller?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 17));
    } catch (e) {
      if (!silent) {
        messenger.showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _target, zoom: 16),
            onMapCreated: (c) => _controller = c,
            onCameraMove: (position) => _target = position.target,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          // Épingle fixe : remontée d'une demi-hauteur pour que sa pointe soit au centre de la carte.
          IgnorePointer(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -24),
                child: const Icon(Icons.location_pin, size: 48, color: AppColors.error),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  "Déplacez la carte pour placer l'épingle exactement sur le lieu.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.small(
              heroTag: 'my-location',
              tooltip: 'Ma position',
              backgroundColor: AppColors.background,
              onPressed: _locating ? null : _goToMyPosition,
              child: _locating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location, color: AppColors.secondary),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        children: [
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(_target),
            icon: const Icon(Icons.check),
            label: const Text('Valider cet emplacement'),
          ),
        ],
      ),
    );
  }
}
