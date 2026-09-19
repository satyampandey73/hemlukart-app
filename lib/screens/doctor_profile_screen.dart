import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../models/doctor_model.dart';
import '../models/rating_model.dart';
import '../services/doctor_service.dart';
import '../services/rating_service.dart';
import 'book_appointment_screen.dart';
import 'clinic_detail_screen.dart';
import 'login_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  final Doctor doctor;
  const DoctorProfileScreen({super.key, required this.doctor});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final AppState _appState = AppState();
  late Doctor _docState;
  ApiDoctor? _apiDoctorDetails;
  int _activeTab = 0; // 0: About, 1: Experience, 2: Reviews
  List<RatingItem> _doctorRatings = [];
  RatingStats? _ratingStats;
  bool _isLoadingRatings = false;

  @override
  void initState() {
    super.initState();
    _docState = widget.doctor;
    _fetchDoctorRatings();
    _fetchDoctorDetails();
  }

  Future<void> _fetchDoctorDetails() async {
    if (!mounted) return;
    final res = await DoctorService.getDoctorById(widget.doctor.id);
    if (!mounted) return;
    if (res.success && res.doctor != null) {
      setState(() {
        _apiDoctorDetails = res.doctor;
        _docState = Doctor.fromApiDoctor(
          res.doctor!,
          rating: _ratingStats?.averageScore ?? _docState.rating,
          reviewsCount: _ratingStats?.totalRatings ?? _docState.reviewsCount,
        );
      });
    }
  }

  ImageProvider _getDoctorImageProvider(String imagePath) {
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return NetworkImage(imagePath);
    }
    if (imagePath.isNotEmpty) {
      return AssetImage(imagePath);
    }
    return const AssetImage('assets/doctor_profile.png');
  }

  String _formatDateStr(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final m = months[dt.month - 1];
      return '${dt.day} $m ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _fetchDoctorRatings() async {
    if (!mounted) return;
    setState(() => _isLoadingRatings = true);
    final res = await RatingService.getDoctorRatings(widget.doctor.id);
    if (mounted) {
      setState(() {
        _isLoadingRatings = false;
        if (res.success) {
          _doctorRatings = res.ratings;
          _ratingStats = res.stats;

          if (res.doctorDetails != null) {
            _apiDoctorDetails = res.doctorDetails;
            _docState = Doctor.fromApiDoctor(
              res.doctorDetails!,
              rating: res.stats?.averageScore,
              reviewsCount: res.stats?.totalRatings,
            );
          } else if (res.stats != null) {
            _docState = Doctor.fromApiDoctor(
              _apiDoctorDetails ??
                  widget.doctor.rawApiDoctor ??
                  ApiDoctor(
                    id: widget.doctor.id,
                    fullName: widget.doctor.name,
                  ),
              rating: res.stats!.averageScore,
              reviewsCount: res.stats!.totalRatings,
            );
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final doc = _docState;
    final isWish = _appState.wishlistDoctorIds.contains(doc.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          doc.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              isWish ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.white,
            ),
            onPressed: () async {
              final currentContext = context;
              final res = await _appState.toggleDoctorWishlist(doc.id);
              if (!mounted) return;
              if (currentContext.mounted) {
                ScaffoldMessenger.of(currentContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      res.message.isNotEmpty
                          ? res.message
                          : (isWish
                                ? 'Removed from wishlist'
                                : 'Added to wishlist'),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card Top Banner
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: _getDoctorImageProvider(doc.image),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Text(
                                  doc.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const Icon(
                                  Icons.verified,
                                  color: AppColors.secondary,
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              doc.degree,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textLight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${doc.experienceYears}+ Years Exp.',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[50],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 10,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${doc.rating} (${doc.reviewsCount})',
                                        style: const TextStyle(
                                          color: Colors.amber,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
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
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Consultation Fee',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            '₹${doc.consultationFee.toInt()} / session',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final currentContext = context;
                          if (await LoginScreen.checkAndNavigate(
                            currentContext,
                          )) {
                            if (!mounted) return;
                            if (currentContext.mounted) {
                              Navigator.push(
                                currentContext,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BookAppointmentScreen(doctor: doc),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Book Appointment',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Clinic Details Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    final clinicId = (doc.clinicId ?? '').trim();
                    if (clinicId.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ClinicDetailScreen(clinicId: clinicId),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.clinicName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                doc.clinicAddress,
                                style: const TextStyle(
                                  color: AppColors.textLight,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Consultation availability cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  if (_apiDoctorDetails?.schedules != null &&
                      _apiDoctorDetails!.schedules!.isNotEmpty)
                    _buildApiSchedulesCard(_apiDoctorDetails!.schedules!)
                  else ...[
                    _buildConsultationScheduleCard(
                      title: 'Online Consultation',
                      subtitle: 'Consult from the comfort of your home',
                      badgeLabel: 'Online',
                      badgeColor: AppColors.primary,
                      badgeBackground: AppColors.primary.withValues(
                        alpha: 0.12,
                      ),
                      icon: Icons.video_call_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildConsultationScheduleCard(
                      title: 'Offline Consultation',
                      subtitle: 'Visit the clinic for a face-to-face session',
                      badgeLabel: 'Offline',
                      badgeColor: AppColors.secondary,
                      badgeBackground: AppColors.secondary.withValues(
                        alpha: 0.12,
                      ),
                      icon: Icons.location_on_outlined,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tabs Selector
            Container(
              color: Colors.white,
              child: Row(
                children: [
                  _buildTabItem(0, 'About'),
                  _buildTabItem(1, 'Experience'),
                  _buildTabItem(2, 'Testimonials'),
                ],
              ),
            ),

            // Tab Content
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: _buildActiveTabContent(doc),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, String label) {
    final isSel = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSel ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSel ? AppColors.primary : AppColors.textLight,
              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(Doctor doc) {
    switch (_activeTab) {
      case 0:
        final areas = _apiDoctorDetails?.expertise?.areasOfExpertise ?? [];
        final langs =
            _apiDoctorDetails?.expertise?.consultationLanguages ?? doc.languages;
        final philosophy = _apiDoctorDetails?.consultationPhilosophy ?? '';
        final achievements = _apiDoctorDetails?.achievements ?? '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About ${doc.name.replaceFirst(RegExp(r'^Dr\.\s*', caseSensitive: false), '')}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              doc.about,
              style: const TextStyle(
                color: AppColors.textLight,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            if (philosophy.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Consultation Philosophy',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                philosophy,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],
            if (achievements.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Key Achievements',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                achievements,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              'Specializations & Expertise',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: areas.isNotEmpty
                  ? areas.map((area) => _SpecializationChip(area)).toList()
                  : const [
                      _SpecializationChip('Panchakarma'),
                      _SpecializationChip('Dietary Planning'),
                      _SpecializationChip('Stress Management'),
                      _SpecializationChip('Herbal Formulations'),
                    ],
            ),
            if (langs.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Consultation Languages',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    langs.map((lang) => _SpecializationChip(lang)).toList(),
              ),
            ],
          ],
        );
      case 1:
        final highestQual = _apiDoctorDetails?.highestQualification;
        final gradDetails = _apiDoctorDetails?.graduationDetails;
        final clinicOrHosp =
            _apiDoctorDetails?.currentClinicOrHospital ?? doc.clinicName;
        final designation =
            _apiDoctorDetails?.currentDesignation ?? 'Ayurvedic Consultant';
        final expYears =
            _apiDoctorDetails?.totalExperience ?? doc.experienceYears;
        final regNum = _apiDoctorDetails?.registrationNumber ?? '';
        final stateCouncil = _apiDoctorDetails?.stateAyushCouncil ?? '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Experience & Education',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            _buildTimelineRow(
              designation,
              '$clinicOrHosp • $expYears+ Years Experience',
              'Providing patient consultation, diagnostic evaluation, and specialized care treatment plans.',
            ),
            if (highestQual != null && highestQual.degree != null)
              _buildTimelineRow(
                '${highestQual.degree}${highestQual.specialization != null && highestQual.specialization!.isNotEmpty ? ' (${highestQual.specialization})' : ''}',
                '${highestQual.universityName ?? 'University'}${highestQual.yearOfPassing != null ? ' • ${highestQual.yearOfPassing}' : ''}',
                'Highest qualification in specialized Ayush medical practice.',
              ),
            if (gradDetails != null && gradDetails.universityName != null)
              _buildTimelineRow(
                'Graduation (${doc.system})',
                '${gradDetails.universityName}${gradDetails.yearOfPassing != null ? ' • ${gradDetails.yearOfPassing}' : ''}',
                'Bachelor degree graduation program in Ayush medicine.',
              )
            else
              _buildTimelineRow(
                'MD (Ayurveda)',
                'National Institute of Ayurveda • 2009 - 2012',
                'Doctoral specialization program focused on internal medicine and pharmacognosy research.',
              ),
            if (regNum.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Registration No: $regNum',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.textDark,
                            ),
                          ),
                          if (stateCouncil.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              stateCouncil,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textLight,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Patient Reviews',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textDark,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showWriteDoctorReviewBottomSheet,
                  icon: const Icon(
                    Icons.rate_review_outlined,
                    color: Colors.white,
                    size: 14,
                  ),
                  label: const Text(
                    'Rate Doctor',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRatingSummaryCard(),
            const SizedBox(height: 8),
            if (_isLoadingRatings)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_doctorRatings.isNotEmpty)
              Column(
                children:
                    _doctorRatings.map((item) => _buildRatingItemCard(item)).toList(),
              )
            else
              Column(
                children: [
                  _buildReviewCard(
                    'Ava R.',
                    5,
                    'Dr. Sharma listened carefully and explained everything clearly. The care was professional, kind, and reassuring from start to finish.',
                  ),
                  _buildReviewCard(
                    'Marcus K.',
                    5,
                    'The appointment was on time, and the staff made me feel comfortable. I appreciated the clear next steps and follow-up plan.',
                  ),
                ],
              ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildRatingSummaryCard() {
    final avgScore = _ratingStats?.averageScore ?? _docState.rating;
    final totalCount = _ratingStats?.totalRatings ?? _doctorRatings.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                avgScore.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < avgScore.round() ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$totalCount patient ${totalCount == 1 ? 'rating' : 'ratings'}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Container(width: 1, height: 60, color: AppColors.border),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Verified Doctor Ratings',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ratings and reviews are submitted by patients after completed consultations.',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingItemCard(RatingItem item) {
    final authorName = item.user?.fullName.isNotEmpty == true
        ? item.user!.fullName
        : 'Verified Patient';
    final profileImg = item.user?.profileImage ?? '';
    final dateFormatted = _formatDateStr(item.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                backgroundImage: profileImg.isNotEmpty
                    ? NetworkImage(profileImg)
                    : null,
                child: profileImg.isEmpty
                    ? Text(
                        authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textDark,
                      ),
                    ),
                    if (dateFormatted.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        dateFormatted,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < item.score ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          if (item.review.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              item.review,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimeStr(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        final minute = parts[1];
        final ampm = hour >= 12 ? 'PM' : 'AM';
        if (hour > 12) hour -= 12;
        if (hour == 0) hour = 12;
        final hourStr = hour.toString().padLeft(2, '0');
        return '$hourStr:$minute $ampm';
      }
    } catch (_) {}
    return timeStr;
  }

  Widget _buildApiSchedulesCard(List<DoctorSchedule> schedules) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Doctor Schedules',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${schedules.length} active schedule session${schedules.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Verified',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: schedules.map((sch) {
              final dayCapitalized = sch.dayOfWeek.isNotEmpty
                  ? '${sch.dayOfWeek[0].toUpperCase()}${sch.dayOfWeek.substring(1)}'
                  : 'Day';
              final sessionCap = sch.sessionName.isNotEmpty
                  ? '${sch.sessionName[0].toUpperCase()}${sch.sessionName.substring(1)}'
                  : 'Session';
              final formattedStart = _formatTimeStr(sch.startTime);
              final formattedEnd = _formatTimeStr(sch.endTime);
              final feeDouble = double.tryParse(sch.consultationFee) ?? 500.0;
              final typeLabel = sch.consultationType == 'in_person'
                  ? 'In Person'
                  : (sch.consultationType == 'online'
                        ? 'Online'
                        : sch.consultationType);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        dayCapitalized
                            .substring(
                              0,
                              dayCapitalized.length >= 3
                                  ? 3
                                  : dayCapitalized.length,
                            )
                            .toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$dayCapitalized • $sessionCap',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  typeLabel,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$formattedStart - $formattedEnd (${sch.slotDuration} mins slots)',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${feeDouble.toInt()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationScheduleCard({
    required String title,
    required String subtitle,
    required String badgeLabel,
    required Color badgeColor,
    required Color badgeBackground,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: badgeBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: badgeColor, size: 22),
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
                        fontSize: 16,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildScheduleDay('MON', [
                '09:00 AM',
                '10:30 AM',
                '02:00 PM',
              ], true),
              _buildScheduleDay('TUE', [
                '09:00 AM',
                '11:00 AM',
                '01:30 PM',
              ], false),
              _buildScheduleDay('WED', [
                '08:30 AM',
                '10:00 AM',
                '11:30 AM',
              ], true),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildScheduleDay('THU', [], false, isDisabled: true),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This Week',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleDay(
    String day,
    List<String> slots,
    bool isActive, {
    bool isDisabled = false,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: isDisabled
                  ? AppColors.border.withValues(alpha: 0.15)
                  : (isActive
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.backgroundLight),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDisabled
                    ? AppColors.border.withValues(alpha: 0.3)
                    : (isActive
                          ? AppColors.primary
                          : AppColors.border.withValues(alpha: 0.5)),
              ),
            ),
            child: Text(
              day,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDisabled
                    ? AppColors.textLight
                    : (isActive ? AppColors.primary : AppColors.textDark),
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (isDisabled)
            Text(
              'No slots available',
              style: TextStyle(color: AppColors.textLight, fontSize: 11),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: slots.map((slot) {
                final isSlotAvailable = day != 'TUE';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSlotAvailable
                          ? Colors.white
                          : AppColors.border.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      slot,
                      style: TextStyle(
                        fontSize: 11,
                        color: isSlotAvailable
                            ? AppColors.textDark
                            : AppColors.textLight,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(String title, String subtitle, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              const CircleAvatar(radius: 6, backgroundColor: AppColors.primary),
              Container(width: 2, height: 60, color: AppColors.border),
            ],
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
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

  Widget _buildReviewCard(String author, int rating, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                author,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.textDark,
                ),
              ),
              Row(
                children: List.generate(
                  rating,
                  (_) => const Icon(Icons.star, color: Colors.amber, size: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showWriteDoctorReviewBottomSheet() {
    if (!_appState.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please log in to submit a review for the doctor.',
          ),
          action: SnackBarAction(
            label: 'Log In',
            textColor: Colors.amber,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ),
      );
      return;
    }

    int selectedScore = 5;
    final reviewController = TextEditingController();
    bool isSubmitting = false;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Rate & Review Doctor',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Text(
                      widget.doctor.name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Your Rating',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starValue = index + 1;
                        return IconButton(
                          iconSize: 36,
                          icon: Icon(
                            starValue <= selectedScore
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            setModalState(() {
                              selectedScore = starValue;
                            });
                          },
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your Review',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reviewController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Share your consultation experience...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textLight,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (reviewController.text.trim().isEmpty) {
                                  setModalState(() {
                                    errorMessage =
                                        'Please write a review text before submitting.';
                                  });
                                  return;
                                }

                                setModalState(() {
                                  isSubmitting = true;
                                  errorMessage = null;
                                });

                                final res = await _appState.submitRating(
                                  targetId: widget.doctor.id,
                                  targetType: 'doctor',
                                  score: selectedScore,
                                  review: reviewController.text.trim(),
                                );

                                if (res.success) {
                                  if (!mounted) return;
                                  final currentContext = context;
                                  Navigator.pop(currentContext);
                                  ScaffoldMessenger.of(
                                    currentContext,
                                  ).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        res.message.isNotEmpty
                                            ? res.message
                                            : 'Doctor rating submitted successfully!',
                                      ),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                  _fetchDoctorRatings();
                                } else {
                                  setModalState(() {
                                    isSubmitting = false;
                                    errorMessage = res.message.isNotEmpty
                                        ? res.message
                                        : 'Failed to submit rating. Please try again.';
                                  });
                                }
                              },
                        child: isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Submit Review',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SpecializationChip extends StatelessWidget {
  final String label;
  const _SpecializationChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
