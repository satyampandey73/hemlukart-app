import 'package:flutter_test/flutter_test.dart';
import 'package:hemlukart_app/models/order_model.dart';
import 'package:hemlukart_app/services/order_service.dart';

void main() {
  test('OrderService.checkout method accepts prescription parameter', () async {
    final response = await OrderService.checkout(
      shippingAddressId: '8f3b1a2c-1234-5678-90ab-cdef12345678',
      paymentMode: 'cod',
      paymentStatus: 'pending',
      prescription: 'https://res.cloudinary.com/your-cloud/image/upload/v12345/prescription.jpg',
    );

    expect(response, isNotNull);
  });

  test('CheckoutApiResponse parses prescription from backend response correctly', () {
    final json = {
      "success": true,
      "message": "Order placed successfully",
      "prescription": "https://res.cloudinary.com/your-cloud/image/upload/v1234/prescriptions/abc123.jpg",
      "data": {
        "order": {
          "id": "ord_123",
          "orderNo": "OD10001",
          "buyerType": "user",
          "customerId": "cust_1",
          "paymentMode": "cod",
          "paymentStatus": "pending",
          "orderStatus": "placed",
          "couponDiscount": "0.00",
          "subtotal": "500.00",
          "discountAmount": "0.00",
          "taxAmount": "0.00",
          "shippingCharge": "0.00",
          "totalAmount": "500.00",
          "codAmount": "500.00",
          "prescriptionRequired": true,
          "createdAt": "2026-08-01T12:00:00.000Z",
          "updatedAt": "2026-08-01T12:00:00.000Z"
        },
        "items": []
      }
    };

    final response = CheckoutApiResponse.fromJson(json);
    expect(response.success, true);
    expect(response.data, isNotNull);
    expect(response.data!.order.prescription, "https://res.cloudinary.com/your-cloud/image/upload/v1234/prescriptions/abc123.jpg");

    final orderObj = response.data!.toOrder([]);
    expect(orderObj.prescription, "https://res.cloudinary.com/your-cloud/image/upload/v1234/prescriptions/abc123.jpg");
  });

  test('OrderService.uploadPrescriptionFile converts local device path to Cloudinary URL', () async {
    const localDevicePath = '/data/user/0/com.example.hemlukart_app/cache/file_picker/1785584694203/Screenshot_2026-07-23-16-24-40-53_86c37949d9dbdf8b7705c7710b12afd5.jpg';
    final resultUrl = await OrderService.uploadPrescriptionFile(localDevicePath);

    expect(resultUrl.startsWith('https://res.cloudinary.com/'), true);
    expect(resultUrl.contains('Screenshot_2026-07-23-16-24-40-53_86c37949d9dbdf8b7705c7710b12afd5.jpg'), true);
  });
}
