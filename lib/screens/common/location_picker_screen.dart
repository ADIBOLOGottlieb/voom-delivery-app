import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../services/geocoding_service.dart';
import '../../utils/colors.dart';
import '../../widgets/bottom_action_bar.dart';
import '../../widgets/delivery_map.dart';

/// Choix d'un lieu, à la manière du partage de position de WhatsApp :
/// « Envoyer ma position actuelle », épingle à déplacer, recherche d'un lieu, adresse trouvée automatiquement.
/// Renvoie un [Place] via Navigator.pop.
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
  final _map = MapController();
  final _geo = GeocodingService();
  final _searchController = TextEditingController();

  late LatLng _center = widget.initial ?? LocationPickerScreen.lome;
  LatLng? _myPosition;
  double? _accuracy;
  Place? _place;
  bool _resolving = false;
  bool _locating = false;
  bool _dragging = false;

  List<Place> _results = const [];
  bool _searching = false;
  Timer? _reverseDebounce;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _locate(moveMap: widget.initial == null, silent: true);
    _resolve();
  }

  @override
  void dispose() {
    _reverseDebounce?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _locate({bool moveMap = true, bool silent = false}) async {
    setState(() => _locating = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) throw 'Activez la localisation du téléphone.';
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw "L'accès à la position a été refusé.";
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
      );
      if (!mounted) return;
      setState(() {
        _myPosition = LatLng(pos.latitude, pos.longitude);
        _accuracy = pos.accuracy;
      });
      if (moveMap) _moveTo(_myPosition!);
    } catch (e) {
      if (!silent) messenger.showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _moveTo(LatLng point) {
    _map.move(point, 17);
    setState(() => _center = point);
    _resolve();
  }

  /// Adresse du point sous l'épingle (attend que la carte soit immobile).
  void _resolve() {
    _reverseDebounce?.cancel();
    _reverseDebounce = Timer(const Duration(milliseconds: 600), () async {
      setState(() => _resolving = true);
      final point = _center;
      final place = await _geo.reverse(point);
      if (!mounted || point != _center) return;
      setState(() {
        _place = place ?? Place(point: point, label: 'Position sur la carte');
        _resolving = false;
      });
    });
  }

  void _onSearchChanged(String text) {
    _searchDebounce?.cancel();
    if (text.trim().length < 3) {
      setState(() => _results = const []);
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 700), () async {
      setState(() => _searching = true);
      final results = await _geo.search(text);
      if (mounted) {
        setState(() {
          _results = results;
          _searching = false;
        });
      }
    });
  }

  void _pickResult(Place place) {
    FocusScope.of(context).unfocus();
    _searchController.text = place.label;
    setState(() {
      _results = const [];
      _place = place;
      _center = place.point;
    });
    _map.move(place.point, 17);
  }

  void _confirm([Place? place]) {
    final chosen = place ?? _place;
    final point = place?.point ?? _center;
    Navigator.of(context)
        .pop(Place(point: point, label: chosen?.label ?? 'Position sur la carte', details: chosen?.details));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 16,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              onPositionChanged: (camera, hasGesture) {
                _center = camera.center;
                if (hasGesture && !_dragging) setState(() => _dragging = true);
              },
              onMapEvent: (event) {
                if (event is MapEventMoveEnd || event is MapEventFlingAnimationEnd) {
                  setState(() => _dragging = false);
                  _resolve();
                }
              },
            ),
            children: [
              osmTiles(),
              if (_myPosition != null) ...[
                CircleLayer(circles: [
                  CircleMarker(
                    point: _myPosition!,
                    radius: (_accuracy ?? 20).clamp(10, 80).toDouble(),
                    useRadiusInMeter: true,
                    color: AppColors.info.withValues(alpha: 0.15),
                    borderColor: AppColors.info.withValues(alpha: 0.4),
                    borderStrokeWidth: 1,
                  ),
                ]),
                MarkerLayer(markers: [
                  Marker(
                    point: _myPosition!,
                    width: 20,
                    height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.info,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ]),
              ],
              osmAttribution(),
            ],
          ),

          // Épingle fixe : elle « saute » quand on déplace la carte, comme dans WhatsApp.
          IgnorePointer(
            child: Center(
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 150),
                offset: Offset(0, _dragging ? -0.75 : -0.5),
                child: const Icon(Icons.location_on, size: 52, color: AppColors.error),
              ),
            ),
          ),

          // Recherche d'un lieu.
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un quartier, une rue, un marché…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  if (_results.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final r = _results[i];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.place_outlined),
                            title: Text(r.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: r.details == null
                                ? null
                                : Text(r.details!, maxLines: 1, overflow: TextOverflow.ellipsis),
                            onTap: () => _pickResult(r),
                          );
                        },
                      ),
                    ),
                ],
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
              onPressed: _locating ? null : () => _locate(),
              child: _locating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location, color: AppColors.info),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        summary: _myPosition == null
            ? null
            : Material(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.info,
                    child: Icon(Icons.my_location, color: Colors.white, size: 20),
                  ),
                  title: const Text('Envoyer ma position actuelle', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Précision : ${(_accuracy ?? 0).round()} m'),
                  onTap: () async {
                    final here = _myPosition!;
                    final place = await _geo.reverse(here);
                    if (mounted) _confirm(place ?? Place(point: here, label: 'Ma position'));
                  },
                ),
              ),
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.error),
              const SizedBox(width: 8),
              Expanded(
                child: _resolving || _dragging
                    ? Text("Recherche de l'adresse…", style: Theme.of(context).textTheme.bodyMedium)
                    : Text(
                        _place?.label ?? "Déplacez la carte pour placer l'épingle",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _dragging ? null : () => _confirm(),
            icon: const Icon(Icons.check),
            label: const Text('Valider cet emplacement'),
          ),
        ],
      ),
    );
  }
}
