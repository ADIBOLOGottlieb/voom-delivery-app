import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/user.dart';
import 'delivery_service.dart';

/// Notifications push (Firebase Cloud Messaging, gratuit) : rappels livreur et promos client.
///
/// Si Firebase n'est pas configuré (pas de google-services.json), tout est ignoré sans erreur.
class PushService {
  static final _local = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static bool get isReady => _ready;

  static const _urgent = AndroidNotificationChannel(
    'voom_urgent',
    'Livraisons urgentes',
    description: 'Rappels pour les livraisons Express et les heures limites',
    importance: Importance.max,
  );
  static const _default = AndroidNotificationChannel(
    'voom_default',
    'Notifications VOOM',
    description: 'Promotions et informations',
    importance: Importance.high,
  );

  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Notifications désactivées (Firebase non configuré) : $e');
      return;
    }

    final android = _local.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_urgent);
    await android?.createNotificationChannel(_default);
    await _local.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    );

    // Application ouverte : Android n'affiche pas les notifications FCM, on les affiche nous-mêmes.
    FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n == null) return;
      final urgent = n.android?.channelId == _urgent.id;
      final channel = urgent ? _urgent : _default;
      _local.show(
        id: message.hashCode,
        title: n.title,
        body: n.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            importance: channel.importance,
            priority: urgent ? Priority.max : Priority.high,
          ),
        ),
      );
    });

    _ready = true;
  }

  /// Après connexion : autorisation, envoi du jeton au serveur et abonnement aux annonces.
  static Future<void> register(User user, DeliveryService deliveries) async {
    if (!_ready) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token != null) await deliveries.registerDeviceToken(token);
      messaging.onTokenRefresh.listen((t) => deliveries.registerDeviceToken(t).catchError((_) {}));

      if (user.isCourier) {
        await messaging.subscribeToTopic('couriers');
        await messaging.unsubscribeFromTopic('clients');
      } else {
        await messaging.subscribeToTopic('clients');
        await messaging.unsubscribeFromTopic('couriers');
      }
    } catch (e) {
      debugPrint('Enregistrement des notifications impossible : $e');
    }
  }

  /// Déconnexion : plus d'annonces pour ce compte sur cet appareil.
  static Future<void> unregister() async {
    if (!_ready) return;
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic('clients');
      await FirebaseMessaging.instance.unsubscribeFromTopic('couriers');
    } catch (_) {}
  }
}
