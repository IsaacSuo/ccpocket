import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

void main() {
  test('exposes subscription product fields used by the no-GMS app', () {
    const option = SubscriptionOption(
      id: 'monthly-3',
      productId: 'supporter_monthly_10',
    );
    const product = StoreProduct(
      identifier: 'supporter_monthly_10:monthly-3',
      title: 'Supporter Monthly',
      price: 2.99,
      priceString: r'$2.99',
      defaultOption: option,
      subscriptionPeriod: 'P1M',
    );

    expect(product.price, 2.99);
    expect(product.defaultOption?.id, 'monthly-3');
    expect(product.defaultOption?.productId, 'supporter_monthly_10');
  });

  test('exposes entitlement fields used by the no-GMS app', () {
    const entitlement = EntitlementInfo(
      isActive: true,
      productIdentifier: 'supporter_monthly_10',
      productPlanIdentifier: 'monthly-3',
      originalPurchaseDate: '2026-01-01T00:00:00Z',
      latestPurchaseDate: '2026-07-01T00:00:00Z',
    );

    expect(entitlement.isActive, isTrue);
    expect(entitlement.productIdentifier, 'supporter_monthly_10');
    expect(entitlement.productPlanIdentifier, 'monthly-3');
  });
}
