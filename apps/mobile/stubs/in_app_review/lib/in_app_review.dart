class InAppReview {
  InAppReview._();

  static final InAppReview instance = InAppReview._();

  Future<bool> isAvailable() async => false;

  Future<void> requestReview() async {}
}
