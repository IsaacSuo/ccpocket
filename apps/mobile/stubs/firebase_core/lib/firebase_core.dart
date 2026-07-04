class FirebaseApp {
  const FirebaseApp();
}

class Firebase {
  Firebase._();

  static List<FirebaseApp> get apps => const [];

  static Future<FirebaseApp> initializeApp() async => const FirebaseApp();
}
