import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Lieu trouvé (recherche ou position sur la carte).
class Place {
  final LatLng point;

  /// Adresse courte lisible (rue, quartier, ville).
  final String label;

  /// Adresse complète renvoyée par OpenStreetMap.
  final String? details;

  const Place({required this.point, required this.label, this.details});
}

/// Adresses gratuites via Nominatim (OpenStreetMap) — sans clé ni carte bancaire.
///
/// Politique d'usage : au plus 1 requête/seconde et un User-Agent identifiant l'application.
class GeocodingService {
  GeocodingService({http.Client? client}) : _http = client ?? http.Client();

  final http.Client _http;
  static const _base = 'https://nominatim.openstreetmap.org';
  static const _headers = {'User-Agent': 'VOOMDelivery/1.0 (Lome, Togo)', 'Accept-Language': 'fr'};

  /// Adresse correspondant à un point de la carte (null si introuvable ou hors ligne).
  Future<Place?> reverse(LatLng point) async {
    try {
      final uri = Uri.parse(
        '$_base/reverse?format=jsonv2&zoom=18&addressdetails=1&lat=${point.latitude}&lon=${point.longitude}',
      );
      final res = await _http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      if (json['error'] != null) return null;
      return Place(point: point, label: _shortLabel(json), details: json['display_name'] as String?);
    } catch (_) {
      return null;
    }
  }

  /// Recherche de lieux au Togo (quartiers, rues, marchés, commerces…).
  Future<List<Place>> search(String query) async {
    if (query.trim().length < 3) return const [];
    try {
      final uri = Uri.parse('$_base/search').replace(queryParameters: {
        'format': 'jsonv2',
        'addressdetails': '1',
        'limit': '8',
        'countrycodes': 'tg',
        'q': query.trim(),
      });
      final res = await _http.get(uri, headers: _headers).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return const [];
      return (jsonDecode(utf8.decode(res.bodyBytes)) as List).map((e) {
        final json = e as Map<String, dynamic>;
        return Place(
          point: LatLng(double.parse(json['lat'] as String), double.parse(json['lon'] as String)),
          label: _shortLabel(json),
          details: json['display_name'] as String?,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  static String _shortLabel(Map<String, dynamic> json) {
    final a = (json['address'] as Map<String, dynamic>?) ?? const {};
    final parts = <String?>[
      json['name'] as String?,
      a['road'] as String?,
      (a['suburb'] ?? a['neighbourhood'] ?? a['quarter']) as String?,
      (a['city'] ?? a['town'] ?? a['village']) as String?,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).toSet().toList();
    if (parts.isNotEmpty) return parts.take(3).join(', ');
    return (json['display_name'] as String? ?? 'Position sélectionnée').split(',').take(3).join(',');
  }
}
