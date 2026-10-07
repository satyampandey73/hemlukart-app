import 'package:flutter_test/flutter_test.dart';
import 'package:hemlukart_app/constants/app_state.dart';
import 'package:hemlukart_app/models/order_model.dart';

void main() {
  test('CancelOrderApiResponse correctly parses backend cancellation response', () {
    final responsePayload = {
      "success": true,
      "message": "Order cancelled successfully",
      "data": {
        "id": "eeb76dcd-d540-40ea-a9de-53c2b3d24ada",
        "orderNo": "ORD-20261002120034-3268",
        "buyerType": "user",
        "customerId": "beffcad4-7592-4c49-8a84-e63f688149b6",
        "doctorId": null,
        "cartId": "0a1a8881-7de2-4582-97df-ffadb3cfb630",
        "shippingAddressId": "26bd5360-0390-45e3-90c7-6c0a97192bac",
        "deliveryName": "Mohd Soyeb",
        "deliveryPhone": "8528482058",
        "deliveryAddress": "New Zaidi Gali No.10,Mandawali",
        "deliveryCity": "New Zaidi Gali No.10,Mandawali",
        "deliveryState": "New Delhi",
        "deliveryPincode": "110092",
        "deliveryInstruction": "",
        "paymentMode": "cod",
        "paymentStatus": "pending",
        "paymentProvider": null,
        "paymentReference": null,
        "paidAt": null,
        "orderStatus": "cancelled",
        "couponId": null,
        "couponCode": null,
        "couponDiscount": "0.00",
        "subtotal": "1052.00",
        "discountAmount": "0.00",
        "taxAmount": "0.00",
        "shippingCharge": "0.00",
        "totalAmount": "1052.00",
        "codAmount": "1052.00",
        "prescriptionRequired": false,
        "prescriptionUrl": null,
        "note": "",
        "createdAt": "2026-10-02T12:00:34.351Z",
        "updatedAt": "2026-10-02T12:01:33.896Z"
      }
    };

    final result = CancelOrderApiResponse.fromJson(responsePayload);
    expect(result.success, isTrue);
    expect(result.message, "Order cancelled successfully");
    expect(result.data, isNotNull);
    expect(result.data!.id, "eeb76dcd-d540-40ea-a9de-53c2b3d24ada");
    expect(result.data!.orderNo, "ORD-20261002120034-3268");
    expect(result.data!.orderStatus, "cancelled");
    expect(result.data!.totalAmount, 1052.0);
  });

  test('AppState activeToken resolves doctor token when doctor logged in', () {
    final appState = AppState();

    // Patient mode
    appState.setDoctorSessionForTest(null);
    expect(appState.isDoctorLoggedIn, isFalse);

    // Doctor mode
    appState.setDoctorSessionForTest('mock-doctor-jwt');
    expect(appState.isDoctorLoggedIn, isTrue);
    expect(appState.activeToken, 'mock-doctor-jwt');

    // Reset
    appState.setDoctorSessionForTest(null);
  });
}
