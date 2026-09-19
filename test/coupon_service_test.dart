import 'package:flutter_test/flutter_test.dart';
import 'package:hemlukart_app/models/coupon_model.dart';
import 'package:hemlukart_app/services/coupon_service.dart';
import 'package:hemlukart_app/services/order_service.dart';

void main() {
  group('Coupon Integration Tests', () {
    test('CouponModel parses JSON correctly and calculates discount', () {
      final json = {
        "id": "e039343c-1236-4b7c-9c4e-294e0cb274cf",
        "code": "UM8QHI3X",
        "name": "Welcome 20% Off",
        "type": "percentage",
        "value": "18.00",
        "minOrderAmount": "0.00",
        "maxDiscountAmount": "1000.00",
        "isActive": true,
        "startDate": "2026-07-09T00:00:00.000Z",
        "expiryDate": "2026-12-31T23:59:59.000Z",
        "usageLimit": 100,
        "usedCount": 0,
        "createdAt": "2026-07-09T17:25:03.054Z"
      };

      final coupon = CouponModel.fromJson(json);
      expect(coupon.id, 'e039343c-1236-4b7c-9c4e-294e0cb274cf');
      expect(coupon.code, 'UM8QHI3X');
      expect(coupon.value, 18.0);
      expect(coupon.type, 'percentage');
      expect(coupon.isActive, true);

      // Subtotal = 100, discount 18% = 18.0
      expect(coupon.calculateDiscount(100.0), 18.0);
      expect(coupon.isValidForOrder(100.0), true);
    });

    test('CouponService.getCoupons API endpoint call works', () async {
      final response = await CouponService.getCoupons();
      expect(response, isNotNull);
      expect(response.data, isA<List<CouponModel>>());
    });

    test('OrderService.checkout accepts couponCode parameter', () async {
      final response = await OrderService.checkout(
        shippingAddressId: 'test-address-id',
        paymentMode: 'cod',
        paymentStatus: 'pending',
        couponCode: 'WELCOME10',
      );
      expect(response, isNotNull);
    });
  });
}
