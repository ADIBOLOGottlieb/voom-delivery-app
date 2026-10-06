import '../models/delivery.dart';
import '../models/product.dart';
import 'api_client.dart';

/// Accès aux livraisons (client et livreur) et au catalogue.
class DeliveryService {
  DeliveryService(this._api);

  final ApiClient _api;

  List<T> _list<T>(dynamic response, T Function(Map<String, dynamic>) parse) =>
      ((response as Map<String, dynamic>)['data'] as List)
          .map((e) => parse(e as Map<String, dynamic>))
          .toList();

  Delivery _one(dynamic response) =>
      Delivery.fromJson((response as Map<String, dynamic>)['data'] as Map<String, dynamic>);

  // --- Client ---------------------------------------------------------------

  Future<List<Delivery>> myDeliveries() async =>
      _list(await _api.get('/deliveries'), Delivery.fromJson);

  Future<Delivery> getDelivery(int id) async => _one(await _api.get('/deliveries/$id'));

  Future<DeliveryQuote> quote({
    required DeliveryType type,
    required double pickupLat,
    required double pickupLng,
    required double dropoffLat,
    required double dropoffLng,
  }) async {
    final data = await _api.post('/deliveries/quote', {
      'type': type.value,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'dropoff_lat': dropoffLat,
      'dropoff_lng': dropoffLng,
    });
    return DeliveryQuote.fromJson(data as Map<String, dynamic>);
  }

  Future<Delivery> createDelivery(Map<String, dynamic> payload) async =>
      _one(await _api.post('/deliveries', payload));

  Future<Delivery> cancelDelivery(int id) async => _one(await _api.post('/deliveries/$id/cancel'));

  Future<Delivery> submitPayment({
    required int deliveryId,
    required String method,
    required String transactionRef,
    required String payerPhone,
    required String screenshotPath,
  }) async {
    return _one(await _api.postMultipart(
      '/deliveries/$deliveryId/payment',
      fields: {'method': method, 'transaction_ref': transactionRef, 'payer_phone': payerPhone},
      fileField: 'screenshot',
      filePath: screenshotPath,
    ));
  }

  Future<PaymentInfo> paymentInfo() async =>
      PaymentInfo.fromJson(await _api.get('/payment-info') as Map<String, dynamic>);

  Future<List<Product>> products({required String category, String? search}) async => _list(
        await _api.get('/products', query: {
          'category': category,
          if (search != null && search.isNotEmpty) 'search': search,
        }),
        Product.fromJson,
      );

  // --- Livreur --------------------------------------------------------------

  Future<List<Delivery>> courierDeliveries({bool history = false}) async => _list(
        await _api.get('/courier/deliveries', query: history ? {'scope': 'history'} : null),
        Delivery.fromJson,
      );

  Future<Delivery> courierDelivery(int id) async => _one(await _api.get('/courier/deliveries/$id'));

  Future<Delivery> updateCourierStatus(int id, String status) async =>
      _one(await _api.post('/courier/deliveries/$id/status', {'status': status}));
}
