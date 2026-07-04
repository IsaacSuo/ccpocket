class RemoteNotification {
  const RemoteNotification({this.title, this.body});

  final String? title;
  final String? body;
}

class RemoteMessage {
  const RemoteMessage({
    this.data = const {},
    this.notification,
  });

  final Map<String, dynamic> data;
  final RemoteNotification? notification;
}

typedef BackgroundMessageHandler = Future<void> Function(RemoteMessage message);

class FirebaseMessaging {
  FirebaseMessaging._();

  static final FirebaseMessaging instance = FirebaseMessaging._();

  static Stream<RemoteMessage> get onMessage => const Stream.empty();

  static Stream<RemoteMessage> get onMessageOpenedApp => const Stream.empty();

  static void onBackgroundMessage(BackgroundMessageHandler handler) {}

  Stream<String> get onTokenRefresh => const Stream.empty();

  Future<void> requestPermission({
    bool alert = true,
    bool announcement = false,
    bool badge = true,
    bool carPlay = false,
    bool criticalAlert = false,
    bool provisional = false,
    bool sound = true,
  }) async {}

  Future<void> setForegroundNotificationPresentationOptions({
    bool alert = false,
    bool badge = false,
    bool sound = false,
  }) async {}

  Future<String?> getToken({String? vapidKey}) async => null;

  Future<RemoteMessage?> getInitialMessage() async => null;
}
