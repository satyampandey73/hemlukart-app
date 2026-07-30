import 'package:flutter_test/flutter_test.dart';
import 'package:hemlukart_app/models/product_faq_model.dart';
import 'package:hemlukart_app/services/product_faq_service.dart';

void main() {
  test('ProductFaqModel deserializes JSON correctly', () {
    final faqJson = {
      "id": "59c660e9-9e0a-47b2-a786-093f8c737faf",
      "productId": "bcebcbee-106e-4c54-a575-8f406931b94d",
      "question": "Is this medicine safe during pregnancy?",
      "answer": "Please consult your healthcare practitioner before consumption.",
      "source": "admin",
      "askedByUserId": null,
      "answeredByRole": "admin",
      "answeredByAdminId": "c1ca650a-bd21-4e9e-933b-f3147a50d334",
      "answeredBySellerId": null,
      "answeredAt": "2026-07-13T14:00:50.006Z",
      "isApproved": true,
      "approvedByAdminId": "c1ca650a-bd21-4e9e-933b-f3147a50d334",
      "approvedAt": "2026-07-13T14:00:50.006Z",
      "isActive": true,
      "sortOrder": 2,
      "createdAt": "2026-07-13T14:00:50.099Z",
      "updatedAt": "2026-07-13T14:16:25.170Z"
    };

    final faq = ProductFaqModel.fromJson(faqJson);
    expect(faq.id, "59c660e9-9e0a-47b2-a786-093f8c737faf");
    expect(faq.productId, "bcebcbee-106e-4c54-a575-8f406931b94d");
    expect(faq.question, "Is this medicine safe during pregnancy?");
    expect(faq.answer, "Please consult your healthcare practitioner before consumption.");
    expect(faq.isApproved, isTrue);
    expect(faq.isActive, isTrue);
  });

  test('ProductFaqsApiResponse deserializes root list payload correctly', () {
    final responseJson = {
      "success": true,
      "faqs": [
        {
          "id": "59c660e9-9e0a-47b2-a786-093f8c737faf",
          "productId": "bcebcbee-106e-4c54-a575-8f406931b94d",
          "question": "fsd fddf",
          "answer": "csxds fd",
          "isApproved": true,
          "isActive": true,
          "sortOrder": 2
        }
      ]
    };

    final apiResponse = ProductFaqsApiResponse.fromJson(responseJson);
    expect(apiResponse.success, isTrue);
    expect(apiResponse.faqs.length, 1);
    expect(apiResponse.faqs.first.question, "fsd fddf");
  });

  test('ProductFaqService.getFaqsByProductId executes API call correctly', () async {
    final response = await ProductFaqService.getFaqsByProductId("bcebcbee-106e-4c54-a575-8f406931b94d");
    expect(response, isA<ProductFaqsApiResponse>());
  });
}
