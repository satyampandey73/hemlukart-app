import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../services/doctor_service.dart';
import 'doctor_listing_screen.dart';
import 'doctor_profile_screen.dart';
import 'book_appointment_screen.dart';
import 'login_screen.dart';

class DoctorConsultationScreen extends StatefulWidget {
  const DoctorConsultationScreen({super.key});

  @override
  State<DoctorConsultationScreen> createState() =>
      _DoctorConsultationScreenState();
}

class _DoctorConsultationScreenState extends State<DoctorConsultationScreen> {
  final AppState _appState = AppState();
  List<Doctor> _apiDoctors = [];
  bool _isLoadingDoctors = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    final res = await DoctorService.getAllDoctors();
    if (!mounted) return;
    if (res.success && res.doctors.isNotEmpty) {
      final initialDocs = res.doctors.map((apiDoc) => Doctor.fromApiDoctor(apiDoc)).toList();
      setState(() {
        _isLoadingDoctors = false;
        _apiDoctors = initialDocs;
      });

      final enriched = await DoctorService.enrichDoctorsWithDetails(res.doctors);
      if (mounted) {
        setState(() {
          _apiDoctors = enriched.map((apiDoc) => Doctor.fromApiDoctor(apiDoc)).toList();
        });
      }
    } else {
      setState(() {
        _isLoadingDoctors = false;
        _apiDoctors = _appState.mockDoctors;
      });
    }
  }

  Doctor get _highestExperienceDoctor {
    final list = _apiDoctors.isNotEmpty ? _apiDoctors : _appState.mockDoctors;
    if (list.isEmpty) {
      return const Doctor(
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
    }
    return list.reduce((curr, next) =>
        curr.experienceYears >= next.experienceYears ? curr : next);
  }

  final List<Map<String, dynamic>> _specialties = [
    {
      'name': 'General Physician',
      'icon': Icons.medical_services_outlined,
      'color': Colors.blue,
    },
    {
      'name': 'Dermatology',
      'icon': Icons.face_retouching_natural_outlined,
      'color': Colors.pink,
    },
    {'name': 'Cardiology', 'icon': Icons.favorite_border, 'color': Colors.red},
    {
      'name': 'Urology',
      'icon': Icons.water_drop_outlined,
      'color': Colors.amber,
    },
    {
      'name': 'Psychiatry',
      'icon': Icons.psychology_outlined,
      'color': Colors.indigo,
    },
    {'name': 'Pediatrics', 'icon': Icons.child_care, 'color': Colors.green},
    {'name': 'Dentist', 'icon': Icons.badge_outlined, 'color': Colors.teal},
  ];

  final List<Map<String, dynamic>> _topConcerns = [
    {
      'name': 'General Health',
      'desc': 'Fever, cough, cold',
      'icon': Icons.health_and_safety_outlined,
      'color': Colors.blue[50],
    },
    {
      'name': 'Child Care',
      'desc': 'Growth & infections',
      'icon': Icons.child_care_outlined,
      'color': Colors.pink[50],
    },
    {
      'name': 'Women\'s Health',
      'desc': 'Periods & pregnancy',
      'icon': Icons.female_outlined,
      'color': Colors.purple[50],
    },
    {
      'name': 'Skin & Hair',
      'desc': 'Acne, hairfall, rashes',
      'icon': Icons.face_retouching_natural_outlined,
      'color': Colors.amber[50],
    },
    {
      'name': 'Heart Health',
      'desc': 'BP, cholesterol issues',
      'icon': Icons.favorite_outline_sharp,
      'color': Colors.red[50],
    },
    {
      'name': 'Mental Health',
      'desc': 'Stress, anxiety, mood',
      'icon': Icons.psychology_outlined,
      'color': Colors.indigo[50],
    },
    {
      'name': 'Eye Care',
      'desc': 'Vision & strain',
      'icon': Icons.remove_red_eye_outlined,
      'color': Colors.teal[50],
    },
    {
      'name': 'Dental Care',
      'desc': 'Teeth pain & hygiene',
      'icon': Icons.clean_hands_outlined,
      'color': Colors.green[50],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section Header
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                topPadding + 16,
                16,
                24,
              ),
              color: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Consult Top Doctors',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Access verified Ayurvedic, Homeopathic, and Unani practitioners online or in-person.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.search, color: AppColors.textLight),
                        SizedBox(width: 8),
                        Text(
                          'Search for doctors, specializations...',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 14,
                          ),
                        ),
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
              child: Column(
                children: [
                  _buildConsultModeCard(
                    'Skip the travel!',
                    'Consult',
                    'Online',
                    'Private consultation • Video call • Starts at just ₹799',
                    'Consult Online',
                    const Color(0xFFCFF0F5),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DoctorListingScreen(consultationTypeFilter: 'online'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildConsultModeCard(
                    'Skip the wait!',
                    'Consult',
                    'Offline',
                    'In-person consultation • Clinic visit • Starts at just ₹799',
                    'Consult Offline',
                    const Color.fromRGBO(243, 232, 226, 1),
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DoctorListingScreen(consultationTypeFilter: 'in_person'),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Immediate Care highest experience doctor banner
            Builder(
              builder: (context) {
                final topDoc = _highestExperienceDoctor;
                final fee = topDoc.getFeeForType().toInt();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 250, 251, 252),
                          Color.fromARGB(255, 247, 248, 248),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[600],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'EXPERIENCED PHYSICIAN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 12),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${topDoc.rating}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DoctorProfileScreen(doctor: topDoc),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                onBackgroundImageError: (_, __) {},
                                backgroundImage: (topDoc.image.startsWith('http://') ||
                                        topDoc.image.startsWith('https://'))
                                    ? NetworkImage(topDoc.image) as ImageProvider
                                    : AssetImage(
                                        topDoc.image.isNotEmpty
                                            ? topDoc.image
                                            : 'assets/doctor_profile.png',
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      topDoc.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${topDoc.specialty} • ${topDoc.experienceYears} Yrs Exp',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.textLight,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (topDoc.degree.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        topDoc.degree,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildBadge(topDoc.specialty.isNotEmpty ? topDoc.specialty : 'General Health'),
                            const SizedBox(width: 4),
                            _buildBadge('${topDoc.experienceYears}+ Yrs Exp'),
                            const SizedBox(width: 4),
                            _buildBadge(topDoc.system.isNotEmpty ? topDoc.system : 'Verified Specialist'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fee > 0 ? '₹$fee/- only' : '₹199/- only',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const Text(
                                  'Get 20% cashback on PLUS',
                                  style: TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                if (await LoginScreen.checkAndNavigate(context)) {
                                  if (context.mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            BookAppointmentScreen(doctor: topDoc),
                                      ),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: const Text(
                                'Consult Now ⚡',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Browse by Specialties
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Browse by Specialties',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DoctorListingScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 78,
                      margin: const EdgeInsets.only(right: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color.fromARGB(
                              255,
                              248,
                              249,
                              248,
                            ),
                            child: Icon(
                              spec['icon'],
                              color: const Color.fromRGBO(22, 155, 145, 1),
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            spec['name'],
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DoctorListingScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: concern['color'],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black.withValues(alpha: 0.02)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          concern['icon'],
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                concern['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                concern['desc'],
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textLight,
                                ),
                              ),
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
                  const Text(
                    'Featured Doctors',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DoctorListingScreen(),
                      ),
                    ),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 220,
              child: _isLoadingDoctors
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _apiDoctors.isNotEmpty
                          ? _apiDoctors.length
                          : _appState.mockDoctors.length,
                      itemBuilder: (context, idx) {
                        final doc = _apiDoctors.isNotEmpty
                            ? _apiDoctors[idx]
                            : _appState.mockDoctors[idx];
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
                  const Text(
                    'How to book a consultation?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildStepRow(
                    '1',
                    'Select health concern',
                    'Choose from 20+ specialties or describe your symptoms to find the right care.',
                  ),
                  _buildStepRow(
                    '2',
                    'Choose doctor',
                    'Browse through our verified specialists, check their profiles, and select your preferred expert.',
                  ),
                  _buildStepRow(
                    '3',
                    'Enter details',
                    'Provide brief medical history and patient details for a comprehensive consultation.',
                  ),
                  _buildStepRow(
                    '4',
                    'Select slot',
                    'Pick a convenient time slot and pay securely to start your online consultation.',
                  ),
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
            child: Text(
              stepNum,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
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
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        txt,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.blue,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildConsultModeCard(
    String topText,
    String mainText,
    String highlightText,
    String description,
    String buttonText,
    Color bgColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top text and main title
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: topText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textDark,
                      height: 1.2,
                    ),
                  ),
                  const TextSpan(text: '\n', style: TextStyle(height: 0.4)),
                  TextSpan(
                    text: mainText,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppColors.textDark,
                    ),
                  ),
                  const TextSpan(text: '\n', style: TextStyle(height: 0.3)),
                  TextSpan(
                    text: highlightText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: bgColor == const Color.fromRGBO(243, 232, 226, 1)
                          ? const Color(0xFF8B6F47)
                          : const Color(0xFF17A2B8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Description
            Text(
              description,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textDark,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            // Doctor avatars
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundImage: const AssetImage(
                    'assets/doctor_profile.png',
                  ),
                ),
                Transform.translate(
                  offset: const Offset(-8, 0),
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.blue[200],
                    child: const Text('👨', style: TextStyle(fontSize: 14)),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(-16, 0),
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.green[200],
                    child: const Text('👩', style: TextStyle(fontSize: 14)),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(-24, 0),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '+139',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '+139 Doctors are online',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      bgColor == const Color.fromRGBO(243, 232, 226, 1)
                      ? const Color(0xFFA0663F)
                      : const Color(0xFF17A2B8),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Benefits
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Expanded(
                  child: Column(
                    children: [
                      Icon(
                        Icons.verified_user,
                        size: 18,
                        color: AppColors.textDark,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Verified\nDoctors',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.textDark,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Icon(
                        Icons.description,
                        size: 18,
                        color: AppColors.textDark,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Digital\nPrescription',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.textDark,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Icon(
                        Icons.follow_the_signs,
                        size: 18,
                        color: AppColors.textDark,
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Free\nFollow-up',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.textDark,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocCard(Doctor doc) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DoctorProfileScreen(doctor: doc)),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: (doc.image.startsWith('http://') || doc.image.startsWith('https://'))
                            ? NetworkImage(doc.image) as ImageProvider
                            : AssetImage(
                                doc.image.isNotEmpty
                                    ? doc.image
                                    : 'assets/doctor_profile.png',
                              ),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppColors.primary,
                            size: 10,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${doc.rating}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              doc.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppColors.textDark,
              ),
            ),
            Text(
              doc.specialty,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.textLight),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.work_outline,
                  size: 10,
                  color: AppColors.textLight,
                ),
                const SizedBox(width: 4),
                Text(
                  '${doc.experienceYears} Yrs Exp.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${doc.getFeeForType().toInt()}/Consultation',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              height: 24,
              child: ElevatedButton(
                onPressed: () async {
                  if (await LoginScreen.checkAndNavigate(context)) {
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookAppointmentScreen(doctor: doc),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  'Book Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
