import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../config/routes/app_routes.dart';
import '../../../firebase_options.dart';

final GlobalKey<NavigatorState> notificationNavigatorKey =
    GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> notificationScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class NotificationProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _notificationsSub;
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _foregroundMessageSub;
  StreamSubscription<RemoteMessage>? _openedMessageSub;

  List<Map<String, dynamic>> notifications = const [];
  String? _currentUid;
  String? errorMessage;
  bool isLoading = true;
  bool _localNotificationsReady = false;

  int get unreadCount =>
      notifications.where((item) => item['readAt'] == null).length;

  NotificationProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    _foregroundMessageSub = FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
      onError: (Object error) {
        debugPrint('Error al recibir notificación push: $error');
      },
    );
    _openedMessageSub = FirebaseMessaging.onMessageOpenedApp.listen(
      (_) => _openInbox(),
    );
    _authSubscription = _auth.authStateChanges().listen(
      _handleAuthChange,
      onError: (Object error) {
        errorMessage = 'No se pudo comprobar la sesión de notificaciones.';
        isLoading = false;
        debugPrint('Error al observar sesión de notificaciones: $error');
        notifyListeners();
      },
    );

    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _openInbox());
      }
    } on FirebaseException catch (error) {
      debugPrint('No se pudo leer la notificación de inicio: $error');
    }
  }

  Future<void> _handleAuthChange(User? user) async {
    await _notificationsSub?.cancel();
    await _tokenSub?.cancel();
    _notificationsSub = null;
    _tokenSub = null;
    _currentUid = user != null && !user.isAnonymous ? user.uid : null;
    notifications = const [];
    errorMessage = null;

    if (_currentUid == null) {
      isLoading = false;
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();
    _notificationsSub = _firestore
        .collection('users')
        .doc(_currentUid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .listen(
          (snapshot) {
            notifications = snapshot.docs
                .map((document) => {...document.data(), 'id': document.id})
                .toList();
            isLoading = false;
            errorMessage = null;
            notifyListeners();
          },
          onError: (Object error) {
            errorMessage = 'No se pudieron cargar tus notificaciones.';
            isLoading = false;
            debugPrint('Error al cargar notificaciones: $error');
            notifyListeners();
          },
        );

    await _registerForPushNotifications(_currentUid!);
  }

  Future<void> _registerForPushNotifications(String uid) async {
    const webVapidKey = String.fromEnvironment('FCM_WEB_VAPID_KEY');
    if (kIsWeb && webVapidKey.isEmpty) {
      debugPrint(
        'Configura FCM_WEB_VAPID_KEY para activar push en la versión web.',
      );
      return;
    }
    if (!kIsWeb &&
        defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('El usuario denegó los permisos de notificaciones.');
        return;
      }

      if (!kIsWeb) await _initializeLocalNotifications();
      final token = await _messaging.getToken(
        vapidKey: kIsWeb ? webVapidKey : null,
      );
      if (token != null && _currentUid == uid) {
        await _saveToken(uid, token);
      }
      _tokenSub = _messaging.onTokenRefresh.listen(
        (updatedToken) async {
          if (_currentUid == uid) await _saveToken(uid, updatedToken);
        },
        onError: (Object error) {
          debugPrint('No se pudo renovar el token de notificaciones: $error');
        },
      );
    } on FirebaseException catch (error) {
      debugPrint('No se pudo activar el registro push: $error');
    } on Exception catch (error) {
      debugPrint('Error al configurar notificaciones push: $error');
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    final tokenId = base64Url.encode(utf8.encode(token)).replaceAll('=', '');
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notification_tokens')
        .doc(tokenId)
        .set({
          'token': token,
          'platform': defaultTargetPlatform.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsReady) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('launcher_icon'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (_) => _openInbox(),
    );
    const channel = AndroidNotificationChannel(
      'zap_mexico_notifications',
      'Notificaciones de Zap México',
      description: 'Avisos de solicitudes, servicios y Marketplace.',
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    _localNotificationsReady = true;
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    if (kIsWeb) {
      notificationScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            '${notification.title ?? 'Zap México'}: ${notification.body ?? ''}',
          ),
        ),
      );
      return;
    }
    try {
      await _initializeLocalNotifications();
      await _localNotifications.show(
        message.messageId.hashCode,
        notification.title ?? 'Zap México',
        notification.body ?? '',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'zap_mexico_notifications',
            'Notificaciones de Zap México',
            channelDescription: 'Avisos de solicitudes y Marketplace.',
            importance: Importance.high,
            priority: Priority.high,
            icon: 'launcher_icon',
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } on Exception catch (error) {
      debugPrint('No se pudo mostrar la notificación en primer plano: $error');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final uid = _currentUid;
    if (uid == null) return;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'readAt': FieldValue.serverTimestamp()});
  }

  Future<void> markAllAsRead() async {
    final uid = _currentUid;
    if (uid == null) return;
    final unread = notifications
        .where((item) => item['readAt'] == null)
        .toList();
    for (var index = 0; index < unread.length; index += 450) {
      final batch = _firestore.batch();
      for (final item in unread.skip(index).take(450)) {
        batch.update(
          _firestore
              .collection('users')
              .doc(uid)
              .collection('notifications')
              .doc(item['id'].toString()),
          {'readAt': FieldValue.serverTimestamp()},
        );
      }
      await batch.commit();
    }
  }

  void _openInbox() {
    notificationNavigatorKey.currentState?.pushNamed(AppRoutes.notifications);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _notificationsSub?.cancel();
    _tokenSub?.cancel();
    _foregroundMessageSub?.cancel();
    _openedMessageSub?.cancel();
    super.dispose();
  }
}
