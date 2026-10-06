import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:voom_delivery_app/main.dart';
import 'package:voom_delivery_app/models/delivery.dart';
import 'package:voom_delivery_app/models/product.dart';
import 'package:voom_delivery_app/services/api_client.dart';
import 'package:voom_delivery_app/widgets/voom_logo.dart';

Map<String, dynamic> _deliveryJson() => {
      'id': 1,
      'reference': 'VD-ABC123',
      'type': 'express',
      'type_label': 'Express',
      'status': 'assigned',
      'status_label': 'Livreur assigné',
      'payment_status': 'verified',
      'payment_status_label': 'Paiement confirmé',
      'pickup': {'address': 'Bè', 'lat': 6.1375, 'lng': 1.24, 'contact_name': 'Ama', 'contact_phone': '+22890'},
      'dropoff': {'address': 'Kégué', 'lat': 6.165, 'lng': 1.26, 'contact_name': 'Yao', 'contact_phone': '+22893'},
      'distance_km': 4.2,
      'delivery_fee': 2100,
      'items_amount': 0,
      'total_amount': 2100,
      'courier': {'name': 'Kossi', 'phone_number': '+22891', 'vehicle': 'Moto'},
      'latest_payment': null,
      'can_pay': false,
      'can_cancel': false,
      'created_at': '2026-10-06T15:10:00+00:00',
    };

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await initializeDateFormatting('fr');
  });

  testWidgets('démarre sur le splash puis affiche la connexion sans session', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final api = ApiClient(httpClient: MockClient((_) async => http.Response('{}', 404)));

    await tester.pumpWidget(VoomDeliveryApp(api: api));
    expect(find.byType(VoomLogo), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Connectez-vous à votre compte'), findsOneWidget);
    expect(find.text('Email ou téléphone'), findsOneWidget);
  });

  test('ApiClient remonte le premier message de validation Laravel', () async {
    final api = ApiClient(
      httpClient: MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer t0k');
        return http.Response(
          jsonEncode({
            'message': 'The given data was invalid.',
            'errors': {
              'transaction_ref': ['Cette référence de transaction a déjà été utilisée.'],
            },
          }),
          422,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    )..token = 't0k';

    expect(
      () => api.post('/deliveries/1/payment'),
      throwsA(isA<ApiException>()
          .having((e) => e.message, 'message', 'Cette référence de transaction a déjà été utilisée.')
          .having((e) => e.statusCode, 'status', 422)),
    );
  });

  test('ApiClient signale une session expirée (401)', () async {
    var unauthorized = false;
    final api = ApiClient(httpClient: MockClient((_) async => http.Response('{"message":"Unauthenticated."}', 401)))
      ..onUnauthorized = () => unauthorized = true;

    await expectLater(api.get('/me'), throwsA(isA<ApiException>()));
    expect(unauthorized, isTrue);
  });

  test('PaymentInfo et CheckoutStart lisent le mode agrégateur', () {
    final info = PaymentInfo.fromJson({
      'mode': 'gateway',
      'gateway': 'kkiapay',
      'fee_note': '1,9 % de frais de service à la charge du payeur',
      'merchant_name': 'VOOM Delivery',
      'instructions': null,
      'methods': [
        {'method': 'flooz', 'label': 'Flooz (Moov Africa)', 'merchant_number': null},
        {'method': 'mixx', 'label': 'Mixx by Yas', 'merchant_number': null},
      ],
    });
    expect(info.isGateway, isTrue);
    expect(info.methods.map((m) => m.method), ['flooz', 'mixx']);
    expect(info.methods.first.merchantNumber, isNull);

    final start = CheckoutStart.fromJson({
      'payment': {'id': 7},
      'mode': 'redirect',
      'message': 'Finalisez le paiement',
      'redirect_url': 'https://voom-delivery-api.onrender.com/paiement/abc',
    });
    expect(start.paymentId, 7);
    expect(start.redirectUrl, contains('/paiement/'));
  });

  test('Delivery.fromJson lit les points A/B et le livreur', () {
    final d = Delivery.fromJson(_deliveryJson());

    expect(d.type, DeliveryType.express);
    expect(d.pickup.lat, 6.1375);
    expect(d.dropoff.contactPhone, '+22893');
    expect(d.courier?.name, 'Kossi');
    expect(d.isActive, isTrue);
  });
}
