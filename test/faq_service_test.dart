import 'package:flutter_test/flutter_test.dart';
import 'package:hemlukart_app/models/faq_model.dart';
import 'package:hemlukart_app/services/faq_service.dart';

void main() {
  test('FaqModel.fromJson parses single FAQ correctly', () {
    final json = {
      "id": "b4d37048-296f-4bef-b32e-7aa1c0e6d959",
      "icon": "",
      "question": "What types of products does Hemlukart offer?",
      "answer":
          "Hemlukart specializes in authentic, high-quality Ayurvedic and natural wellness products. Our catalog includes organic supplements, wellness remedies, skincare products, and personalized herbal formulations designed to promote holistic health.",
      "sortOrder": 1,
      "isActive": true,
      "isDeleted": false,
      "deletedAt": null,
      "createdAt": "2026-07-29T13:28:56.427Z",
      "updatedAt": "2026-07-29T13:28:56.427Z"
    };

    final faq = FaqModel.fromJson(json);

    expect(faq.id, "b4d37048-296f-4bef-b32e-7aa1c0e6d959");
    expect(faq.question, contains("types of products"));
    expect(faq.sortOrder, 1);
    expect(faq.isActive, true);
    expect(faq.isDeleted, false);
  });

  test('FaqApiResponse.fromJson parses full payload correctly', () {
    final jsonResponse = {
      "success": true,
      "faqs": [
        {
          "id": "b4d37048-296f-4bef-b32e-7aa1c0e6d959",
          "icon": "",
          "question": "What types of products does Hemlukart offer?",
          "answer":
              "Hemlukart specializes in authentic, high-quality Ayurvedic and natural wellness products.",
          "sortOrder": 1,
          "isActive": true,
          "isDeleted": false,
          "deletedAt": null,
          "createdAt": "2026-07-29T13:28:56.427Z",
          "updatedAt": "2026-07-29T13:28:56.427Z"
        }
      ]
    };

    final response = FaqApiResponse.fromJson(jsonResponse);

    expect(response.success, true);
    expect(response.faqs.length, 1);
    expect(response.faqs.first.question, contains("Hemlukart offer"));
  });

  test('FaqService.getFaqs fetches live API data', () async {
    final response = await FaqService.getFaqs();
    expect(response.success, true);
    expect(response.faqs, isNotEmpty);
  });
}
