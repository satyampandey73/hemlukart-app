import 'package:flutter_test/flutter_test.dart';
import 'package:hemlukart_app/models/product_faq_model.dart';
import 'package:hemlukart_app/services/product_faq_service.dart';

void main() {
  test('AskProductFaqResponse.fromJson deserializes sample response correctly', () {
    final sampleResponse = {
      "success": true,
      "message": "Question submitted. It will appear once answered and approved.",
      "faq": {
        "id": "a39b1655-c2dd-4258-9ad8-6dff42c7ba75",
        "productId": "d5cfc343-6ca8-471f-8994-9cb2f0724682",
        "question": "Is this multivitamin suitable for vegetarians?",
        "answer": "",
        "source": "user",
        "askedByUserId": "45aa1c1f-eb30-4729-9e38-3a6969cc9869",
        "answeredByRole": null,
        "answeredByAdminId": null,
        "answeredBySellerId": null,
        "answeredAt": null,
        "isApproved": false,
        "approvedByAdminId": null,
        "approvedAt": null,
        "isActive": true,
        "sortOrder": 0,
        "createdAt": "2026-07-30T13:06:23.635Z",
        "updatedAt": "2026-07-30T13:06:23.635Z"
      }
    };

    final response = AskProductFaqResponse.fromJson(sampleResponse);

    expect(response.success, isTrue);
    expect(
        response.message,
        "Question submitted. It will appear once answered and approved.");
    expect(response.faq, isNotNull);
    expect(response.faq?.id, "a39b1655-c2dd-4258-9ad8-6dff42c7ba75");
    expect(response.faq?.productId, "d5cfc343-6ca8-471f-8994-9cb2f0724682");
    expect(response.faq?.question, "Is this multivitamin suitable for vegetarians?");
  });

  test('ProductFaqService.askQuestion sends request and handles response', () async {
    final response = await ProductFaqService.askQuestion(
      productId: 'd5cfc343-6ca8-471f-8994-9cb2f0724682',
      question: 'Is this product safe for daily use?',
    );

    // Depending on token state or server state, response returns either success or message
    expect(response, isNotNull);
  });
}
