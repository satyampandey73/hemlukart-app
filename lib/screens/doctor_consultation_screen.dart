import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import 'doctor_listing_screen.dart';
import 'doctor_profile_screen.dart';
import 'book_appointment_screen.dart';
import 'login_screen.dart';

class DoctorConsultationScreen extends StatefulWidget {
  const DoctorConsultationScreen({super.key});

  @override
  State<DoctorConsultationScreen> createState() => _DoctorConsultationScreenState();
}

class _DoctorConsultationScreenState extends State<DoctorConsultationScreen> {
  final AppState _appState = AppState();

  final List<Map<String, dynamic>> _specialties = [
    {'name': 'General Physician', 'icon': Icons.medical_services_outlined, 'color': Colors.blue},
    {'name': 'Dermatology', 'icon': Icons.face_retouching_natural_outlined, 'color': Colors.pink},
    {'name': 'Cardiology', 'icon': Icons.favorite_border, 'color': Colors.red},
    {'name': 'Urology', 'icon': Icons.water_drop_outlined, 'color': Colors.amber},
    {'name': 'Psychiatry', 'icon': Icons.psychology_outlined, 'color': Colors.indigo},
    {'name': 'Pediatrics', 'icon': Icons.child_care, 'color': Colors.green},
    {'name': 'Dentist', 'icon': Icons.badge_outlined, 'color': Colors.teal},
  ];

  final List<Map<String, dynamic>> _topConcerns = [
    {'name': 'General Health', 'desc': 'Fever, cough, cold', 'icon': Icons.health_and_safety_outlined, 'color': Colors.blue[50]},
    {'name': 'Child Care', 'desc': 'Growth & infections', 'icon': Icons.child_care_outlined, 'color': Colors.pink[50]},
    {'name': 'Women\'s Health', 'desc': 'Periods & pregnancy', 'icon': Icons.female_outlined, 'color': Colors.purple[50]},
    {'name': 'Skin & Hair', 'desc': 'Acne, hairfall, rashes', 'icon': Icons.face_retouching_natural_outlined, 'color': Colors.amber[50]},
    {'name': 'Heart Health', 'desc': 'BP, cholesterol issues', 'icon': Icons.favorite_outline_sharp, 'color': Colors.red[50]},
    {'name': 'Mental Health', 'desc': 'Stress, anxiety, mood', 'icon': Icons.psychology_outlined, 'color': Colors.indigo[50]},
    {'name': 'Eye Care', 'desc': 'Vision & strain', 'icon': Icons.remove_red_eye_outlined, 'color': Colors.teal[50]},
    {'name': 'Dental Care', 'desc': 'Teeth pain & hygiene', 'icon': Icons.clean_hands_outlined, 'color': Colors.green[50]},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight.withOpacity(0.3),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              color: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Consult Top Doctors',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Access verified Ayurvedic, Homeopathic, and Unani practitioners online or in-person.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.search, color: AppColors.textLight),
                        SizedBox(width: 8),
                        Text('Search for doctors, specializations...', style: TextStyle(color: AppColors.textLight, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Online vs Offline Banner cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildConsultModeCard(
                      'Consult Offline',
                      'Clinic Visit\nStarts at ₹799',
                      Icons.apartment_rounded,
                      const Color(0xFFFEE2E2),
                      const Color(0xFFEF4444),
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorListingScreen(systemFilter: 'Ayurveda'))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildConsultModeCard(
                      'Consult Online',
                      'Video/Audio Call\nStarts at ₹799',
                      Icons.videocam_outlined,
                      const Color(0xFFD1FAE5),
                      AppColors.primary,
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorListingScreen())),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Immediate Care general physician banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE0F2FE), Color(0xFFEEF2F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.blue[600], borderRadius: BorderRadius.circular(4)),
                      child: const Text('IMMEDIATE CARE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: const AssetImage('assets/doctor_profile.png'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Dr. Pathan Irshad Khan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                              SizedBox(height: 2),
                              Text('General Physician • 5 Yrs Exp', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildBadge('General Health'),
                        const SizedBox(width: 4),
                        _buildBadge('Child Care'),
                        const SizedBox(width: 4),
                        _buildBadge('Blood Sugar'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('₹199/- only', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                            Text('Get 20% cashback on PLUS', style: TextStyle(color: AppColors.textLight, fontSize: 10)),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            final dummyDoc = Doctor(
                              id: 'dummy',
                              name: 'Dr. Pathan Irshad Khan',
                              specialty: 'General Physician',
                              degree: 'MBBS, MD',
                              system: 'Allopathy',
                              experienceYears: 5,
                              consultationFee: 199,
                              rating: 4.8,
                              reviewsCount: 12,
                              image: '',
                              languages: ['English', 'Hindi'],
                              clinicName: 'Immediate Care Hub',
                              clinicAddress: 'Online Portal',
                              about: 'Immediate consult practitioner',
                            );
                            LoginScreen.checkAndNavigate(context).then((loggedIn) {
                              if (loggedIn && mounted) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => BookAppointmentScreen(doctor: dummyDoc)));
                              }
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text('Consult Now ⚡', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Browse by Specialties
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Browse by Specialties',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _specialties.length,
                itemBuilder: (context, idx) {
                  final spec = _specialties[idx];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorListingScreen()));
                    },
                    child: Container(
                      width: 90,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: spec['color'].withOpacity(0.1),
                            child: Icon(spec['icon'], color: spec['color'], size: 24),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            spec['name'],
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textDark),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Top Concerns
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Top Concerns',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.2,
              ),
              itemCount: _topConcerns.length,
              itemBuilder: (context, idx) {
                final concern = _topConcerns[idx];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorListingScreen()));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: concern['color'],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black.withOpacity(0.02)),
                    ),
                    child: Row(
                      children: [
                        Icon(concern['icon'], color: AppColors.primary, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(concern['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark)),
                              const SizedBox(height: 2),
                              Text(concern['desc'], style: const TextStyle(fontSize: 9, color: AppColors.textLight)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Featured Doctors List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Featured Doctors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorListingScreen())),
                    child: const Text('View All', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _appState.mockDoctors.length,
                itemBuilder: (context, idx) {
                  final doc = _appState.mockDoctors[idx];
                  return _buildDocCard(doc);
                },
              ),
            ),

            const SizedBox(height: 32),

            // Testimonials Banner
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              width: double.infinity,
              child: Column(
                children: [
                  const Text('How to book a consultation?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                  const SizedBox(height: 20),
                  _buildStepRow('1', 'Select health concern', 'Choose from 20+ specialties or describe your symptoms to find the right care.'),
                  _buildStepRow('2', 'Choose doctor', 'Browse through our verified specialists, check their profiles, and select your preferred expert.'),
                  _buildStepRow('3', 'Enter details', 'Provide brief medical history and patient details for a comprehensive consultation.'),
                  _buildStepRow('4', 'Select slot', 'Pick a convenient time slot and pay securely to start your online consultation.'),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow(String stepNum, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.primary,
            child: Text(stepNum, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: AppColors.textLight, fontSize: 11, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String txt) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(12)),
      child: Text(txt, style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildConsultModeCard(String title, String subtitle, IconData icon, Color bgColor, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.02)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white.withOpacity(0.8),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.textLight, height: 1.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildDocCard(Doctor doc) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorProfileScreen(doctor: doc)));
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: AssetImage(doc.image.isNotEmpty ? doc.image : 'assets/doctor_profile.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              doc.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
            ),
            Text(
              doc.specialty,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.textLight),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('₹${doc.consultationFee.toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 10),
                    const SizedBox(width: 2),
                    Text('${doc.rating}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 28,
              child: ElevatedButton(
                onPressed: () async {
                  if (await LoginScreen.checkAndNavigate(context)) {
                    if (mounted) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => BookAppointmentScreen(doctor: doc)));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Book Appointment', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
