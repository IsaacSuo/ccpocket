enum LogLevel { debug }

enum PurchasesErrorCode { purchaseCancelledError, unknownError }

class PurchasesErrorHelper {
  PurchasesErrorHelper._();

  static PurchasesErrorCode getErrorCode(Object error) {
    return PurchasesErrorCode.unknownError;
  }
}

class PurchasesConfiguration {
  const PurchasesConfiguration(this.apiKey);

  final String apiKey;
}

class Purchases {
  Purchases._();

  static Future<void> setLogLevel(LogLevel level) async {}

  static Future<void> configure(PurchasesConfiguration configuration) async {}

  static Future<Offerings> getOfferings() async => const Offerings();

  static Future<CustomerInfo> getCustomerInfo() async => const CustomerInfo();

  static Future<PurchaseResult> purchase(PurchaseParams params) async {
    return const PurchaseResult(CustomerInfo());
  }

  static Future<CustomerInfo> restorePurchases() async => const CustomerInfo();

  static void addCustomerInfoUpdateListener(
    CustomerInfoUpdateListener listener,
  ) {}

  static void removeCustomerInfoUpdateListener(
    CustomerInfoUpdateListener listener,
  ) {}
}

typedef CustomerInfoUpdateListener = void Function(CustomerInfo info);

class PurchaseParams {
  const PurchaseParams.package(this.package);

  final Package package;
}

class PurchaseResult {
  const PurchaseResult(this.customerInfo);

  final CustomerInfo customerInfo;
}

class Offerings {
  const Offerings({this.current});

  final Offering? current;
}

class Offering {
  const Offering({this.identifier, this.availablePackages = const []});

  final String? identifier;
  final List<Package> availablePackages;
}

class Package {
  const Package({required this.identifier, required this.storeProduct});

  final String identifier;
  final StoreProduct storeProduct;
}

class StoreProduct {
  const StoreProduct({
    required this.identifier,
    required this.title,
    required this.priceString,
    this.price = 0,
    this.defaultOption,
    this.subscriptionPeriod,
  });

  final String identifier;
  final String title;
  final double price;
  final String priceString;
  final SubscriptionOption? defaultOption;
  final String? subscriptionPeriod;
}

class SubscriptionOption {
  const SubscriptionOption({required this.id, required this.productId});

  final String id;
  final String productId;
}

class CustomerInfo {
  const CustomerInfo({
    this.entitlements = const EntitlementInfos(),
    this.nonSubscriptionTransactions = const [],
  });

  final EntitlementInfos entitlements;
  final List<StoreTransaction> nonSubscriptionTransactions;
}

class EntitlementInfos {
  const EntitlementInfos({this.all = const {}, this.active = const {}});

  final Map<String, EntitlementInfo> all;
  final Map<String, EntitlementInfo> active;
}

class EntitlementInfo {
  const EntitlementInfo({
    this.isActive = false,
    this.productIdentifier = '',
    this.productPlanIdentifier,
    this.originalPurchaseDate,
    this.latestPurchaseDate,
  });

  final bool isActive;
  final String productIdentifier;
  final String? productPlanIdentifier;
  final String? originalPurchaseDate;
  final String? latestPurchaseDate;
}

class StoreTransaction {
  const StoreTransaction({required this.productIdentifier});

  final String productIdentifier;
}
