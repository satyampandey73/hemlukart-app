import 'package:flutter_test/flutter_test.dart';
import 'package:hemlukart_app/constants/app_state.dart';
import 'package:hemlukart_app/models/rating_model.dart';

void main() {
  test('GetRatingsResponse deserializes doctor rating endpoint JSON correctly', () {
    final jsonSample = {
      "success": true,
      "targetDetails": {
        "id": "cf7be8ed-6c0b-4fe9-b3ec-5ea1c43077b9",
        "mobile": "9876543210",
        "isMobileVerified": true,
        "fullName": "Dr. Raj Kumar Singh",
        "gender": "male",
        "dateOfBirth": "1988-05-15T00:00:00.000Z",
        "email": "raj.singh@example.com",
        "address": "123 MG Road",
        "city": "Mumbai",
        "state": "Maharashtra",
        "pinCode": "400001",
        "ayushSystem": "Ayurveda (BAMS)",
        "graduationDetails": {
          "yearOfPassing": 2012,
          "universityName": "Maharashtra University of Health Sciences"
        },
        "registrationNumber": "AYUSH-MH-123456",
        "stateAyushCouncil": "Maharashtra Council of Indian Medicine",
        "highestQualification": {
          "degree": "MD",
          "yearOfPassing": 2015,
          "specialization": "Kayachikitsa",
          "universityName": "Maharashtra University of Health Sciences"
        },
        "totalExperience": 13,
        "currentClinicOrHospital": "Raj Ayurvedic Clinic",
        "currentDesignation": "Senior Ayurvedic Consultant",
        "expertise": {
          "areasOfExpertise": [
            "Diabetes",
            "Digestive Disorders",
            "Lifestyle Disorders"
          ],
          "consultationLanguages": [
            "Hindi",
            "English",
            "Marathi"
          ]
        },
        "about": "Experienced Ayurvedic doctor with more than thirteen years of clinical practice, specializing in diabetes, digestive disorders, and lifestyle-related health conditions.",
        "consultationPhilosophy": "I focus on identifying the root cause and creating practical, personalized treatment plans.",
        "achievements": "Consulted more than 5000 patients and conducted multiple community health awareness programs."
      },
      "stats": {
        "averageScore": "4.0",
        "totalRatings": 2
      },
      "ratings": [
        {
          "id": "7dcccda7-c38d-4179-bc91-8cfb2578a489",
          "score": 4,
          "review": "good doctor highly recommended",
          "createdAt": "2026-08-04T08:50:42.344Z",
          "userId": "45aa1c1f-eb30-4729-9e38-3a6969cc9869",
          "targetId": "cf7be8ed-6c0b-4fe9-b3ec-5ea1c43077b9",
          "targetType": "doctor",
          "user": {
            "id": "45aa1c1f-eb30-4729-9e38-3a6969cc9869",
            "fullName": "John Doe",
            "profileImage": "https://res.cloudinary.com/dubhfgcd6/image/upload/v1785763591/doctor-consultation/profiles/kbbne0ogeewojjy4earl.png"
          }
        },
        {
          "id": "0f41f6c4-a610-458d-9fb7-57aafe43f8d7",
          "score": 4,
          "review": "good doctor highly recommended",
          "createdAt": "2026-08-04T08:32:26.207Z",
          "userId": "fbf7e381-26f6-4226-aaf0-804871049d23",
          "targetId": "cf7be8ed-6c0b-4fe9-b3ec-5ea1c43077b9",
          "targetType": "doctor",
          "user": {
            "id": "fbf7e381-26f6-4226-aaf0-804871049d23",
            "fullName": "Rakesh Kr",
            "profileImage": "https://res.cloudinary.com/dubhfgcd6/image/upload/v1785768681/doctor-consultation/profiles/wazayez5srefoixugnj0.jpg"
          }
        }
      ]
    };

    final response = GetRatingsResponse.fromJson(jsonSample);

    expect(response.success, isTrue);
    expect(response.stats, isNotNull);
    expect(response.stats!.averageScore, equals(4.0));
    expect(response.stats!.totalRatings, equals(2));

    expect(response.ratings.length, equals(2));
    expect(response.ratings[0].review, equals("good doctor highly recommended"));
    expect(response.ratings[0].user?.fullName, equals("John Doe"));
    expect(response.ratings[0].user?.profileImage, contains("cloudinary"));

    final apiDoc = response.doctorDetails;
    expect(apiDoc, isNotNull);
    expect(apiDoc!.fullName, equals("Dr. Raj Kumar Singh"));
    expect(apiDoc.totalExperience, equals(13));
    expect(apiDoc.currentClinicOrHospital, equals("Raj Ayurvedic Clinic"));
    expect(apiDoc.expertise?.areasOfExpertise, contains("Diabetes"));

    final doc = Doctor.fromApiDoctor(
      apiDoc,
      rating: response.stats?.averageScore,
      reviewsCount: response.stats?.totalRatings,
    );

    expect(doc.name, equals("Dr. Raj Kumar Singh"));
    expect(doc.experienceYears, equals(13));
    expect(doc.rating, equals(4.0));
    expect(doc.reviewsCount, equals(2));
    expect(doc.clinicName, equals("Raj Ayurvedic Clinic"));
  });
}
