import 'package:flutter_test/flutter_test.dart';
import 'package:hemlukart_app/models/testimonial_model.dart';
import 'package:hemlukart_app/services/testimonial_service.dart';

void main() {
  test('TestimonialModel.fromJson parses API response correctly', () {
    final json = {
      "id": "82391e4f-b5e1-4cc1-b541-ad65edd75324",
      "name": "Linda Sharma",
      "image": "",
      "rating": 5,
      "testimonial":
          "I was skeptical about online healthcare, but AYUSH Care changed my mind. The doctors really listen and provide holistic advice.",
      "isVerified": true,
      "isActive": true,
      "isDeleted": false,
      "deletedAt": null,
      "createdAt": "2026-07-29T12:36:07.511Z",
      "updatedAt": "2026-07-29T12:36:07.511Z"
    };

    final testimonial = TestimonialModel.fromJson(json);

    expect(testimonial.id, "82391e4f-b5e1-4cc1-b541-ad65edd75324");
    expect(testimonial.name, "Linda Sharma");
    expect(testimonial.rating, 5);
    expect(testimonial.testimonial, contains("AYUSH Care"));
    expect(testimonial.isVerified, true);
    expect(testimonial.isActive, true);
    expect(testimonial.isDeleted, false);
  });

  test('TestimonialApiResponse.fromJson parses full payload correctly', () {
    final jsonResponse = {
      "success": true,
      "testimonials": [
        {
          "id": "82391e4f-b5e1-4cc1-b541-ad65edd75324",
          "name": "Linda Sharma",
          "image": "",
          "rating": 5,
          "testimonial":
              "I was skeptical about online healthcare, but AYUSH Care changed my mind. The doctors really listen and provide holistic advice.",
          "isVerified": true,
          "isActive": true,
          "isDeleted": false,
          "deletedAt": null,
          "createdAt": "2026-07-29T12:36:07.511Z",
          "updatedAt": "2026-07-29T12:36:07.511Z"
        }
      ]
    };

    final response = TestimonialApiResponse.fromJson(jsonResponse);

    expect(response.success, true);
    expect(response.testimonials.length, 1);
    expect(response.testimonials.first.name, "Linda Sharma");
  });

  test('TestimonialService.getTestimonials fetches live API data', () async {
    final response = await TestimonialService.getTestimonials();
    expect(response.success, true);
    expect(response.testimonials, isNotEmpty);
  });
}
