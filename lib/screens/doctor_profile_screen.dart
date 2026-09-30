import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../models/doctor_model.dart';
import '../models/my_appointments_model.dart';
import '../models/rating_model.dart';
import '../services/appointment_service.dart';
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

  DateTime _selectedSlotDate = DateTime.now();
  DoctorSchedule? _selectedSchedule;
  List<UserAppointmentItem> _doctorBookedAppointments = [];
  int _slotWeekOffset = 0;
  late final PageController _slotPageController;

  List<DoctorSchedule> get _doctorSchedules {
    return _apiDoctorDetails?.schedules ??
        _docState.rawApiDoctor?.schedules ??
        widget.doctor.rawApiDoctor?.schedules ??
        [];
  }

  String _dayNameFromDate(DateTime date) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    return days[date.weekday - 1];
  }

  String _formatTime12h(String timeStr) {
    if (timeStr.isEmpty) return '';
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      int hour = int.tryParse(parts[0]) ?? 0;
      int minute = int.tryParse(parts[1]) ?? 0;
      final period = hour >= 12 ? 'PM' : 'AM';
      final h = hour % 12 == 0 ? 12 : hour % 12;
      final hStr = h.toString().padLeft(2, '0');
      final mStr = minute.toString().padLeft(2, '0');
      return '$hStr:$mStr $period';
    }
    return timeStr;
  }

  String _getShiftCategory(DoctorSchedule sch) {
    final session = sch.sessionName.toLowerCase().trim();
    if (session.contains('morning')) return 'Morning';
    if (session.contains('afternoon')) return 'Afternoon';
    if (session.contains('evening')) return 'Evening';
    if (session.contains('night')) return 'Night';

    int hour = 9;
    if (sch.startTime.isNotEmpty) {
      final parts = sch.startTime.split(':');
      hour = int.tryParse(parts[0]) ?? 9;
    }
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    if (hour < 21) return 'Evening';
    return 'Night';
  }

  bool _isSlotTimePassed(DoctorSchedule sch, DateTime date) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    if (!isToday) return false;
    try {
      final parts = sch.startTime.split(':');
      if (parts.isNotEmpty) {
        final h = int.tryParse(parts[0]) ?? 0;
        final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
        final slotDateTime = DateTime(date.year, date.month, date.day, h, m);
        return slotDateTime.isBefore(now);
      }
    } catch (_) {}
    return false;
  }

  bool _isSlotBooked(DoctorSchedule sch, DateTime date) {
    if (!sch.isAvailable) return true;
    if (_doctorBookedAppointments.isEmpty) return false;

    for (final apt in _doctorBookedAppointments) {
      final status = apt.status.toLowerCase().trim();
      if (status == 'cancelled' || status == 'rejected') continue;
      if (apt.appointmentDate.isEmpty) continue;

      try {
        final aptUtc = DateTime.parse(apt.appointmentDate).toUtc();
        final aptIst = aptUtc.add(const Duration(hours: 5, minutes: 30));

        if (aptIst.year != date.year ||
            aptIst.month != date.month ||
            aptIst.day != date.day) {
          continue;
        }

        final schStartParts = sch.startTime.split(':');
        if (schStartParts.isEmpty) continue;
        final schStartHour = int.tryParse(schStartParts[0]) ?? 0;
        final schStartMin =
            schStartParts.length > 1 ? (int.tryParse(schStartParts[1]) ?? 0) : 0;
        final schStartInMins = schStartHour * 60 + schStartMin;

        int schEndInMins;
        if (sch.endTime.isNotEmpty) {
          final schEndParts = sch.endTime.split(':');
          final schEndHour = int.tryParse(schEndParts[0]) ?? 0;
          final schEndMin =
              schEndParts.length > 1 ? (int.tryParse(schEndParts[1]) ?? 0) : 0;
          schEndInMins = schEndHour * 60 + schEndMin;
        } else {
          final dur = sch.slotDuration > 0 ? sch.slotDuration : 30;
          schEndInMins = schStartInMins + dur;
        }

        final aptStartInMins = aptIst.hour * 60 + aptIst.minute;
        final aptDur = apt.durationMinutes > 0 ? apt.durationMinutes : 30;
        final aptEndInMins = aptStartInMins + aptDur;

        final overlapStart =
            schStartInMins > aptStartInMins ? schStartInMins : aptStartInMins;
        final overlapEnd =
            schEndInMins < aptEndInMins ? schEndInMins : aptEndInMins;

        if (overlapStart < overlapEnd) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  bool get _hasAvailableSlotInWeek {
    final scheds = _doctorSchedules;
    if (scheds.isEmpty) return false;

    final now = DateTime.now();
    for (int i = 0; i < 15; i++) {
      final date = now.add(Duration(days: i));
      final dayName = _dayNameFromDate(date);
      final daySchedules = scheds
          .where((s) => s.dayOfWeek.toLowerCase().trim() == dayName && s.isAvailable)
          .toList();
      for (final s in daySchedules) {
        if (!_isSlotTimePassed(s, date) && !_isSlotBooked(s, date)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _docState = widget.doctor;
    if (widget.doctor.rawApiDoctor != null) {
      _apiDoctorDetails = widget.doctor.rawApiDoctor;
    }
    _fetchDoctorDetails();
    _fetchDoctorRatings();
    _initInitialSchedule();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diffDays = DateTime(_selectedSlotDate.year, _selectedSlotDate.month, _selectedSlotDate.day)
        .difference(today)
        .inDays;
    if (diffDays >= 0 && diffDays <= 15) {
      _slotWeekOffset = (diffDays / 7).floor().clamp(0, 2);
    } else {
      _selectedSlotDate = today;
      _slotWeekOffset = 0;
    }
    _slotPageController = PageController(initialPage: _slotWeekOffset);
  }

  @override
  void dispose() {
    _slotPageController.dispose();
    super.dispose();
  }

  void _initInitialSchedule() {
    final dayName = _dayNameFromDate(_selectedSlotDate);
    final daySchedules = _doctorSchedules
        .where((s) => s.dayOfWeek.toLowerCase().trim() == dayName && s.isAvailable)
        .toList();
    if (daySchedules.isNotEmpty) {
      try {
        _selectedSchedule = daySchedules.firstWhere(
          (s) =>
              !_isSlotBooked(s, _selectedSlotDate) &&
              !_isSlotTimePassed(s, _selectedSlotDate),
        );
        return;
      } catch (_) {
        _selectedSchedule = null;
      }
    }

    // Auto-select first upcoming date within 15 days that has an available unpassed slot
    final now = DateTime.now();
    for (int i = 0; i < 15; i++) {
      final candidateDate = now.add(Duration(days: i));
      final cDayName = _dayNameFromDate(candidateDate);
      final cSchedules = _doctorSchedules
          .where((s) => s.dayOfWeek.toLowerCase().trim() == cDayName && s.isAvailable)
          .toList();
      for (final s in cSchedules) {
        if (!_isSlotTimePassed(s, candidateDate) && !_isSlotBooked(s, candidateDate)) {
          _selectedSlotDate = candidateDate;
          _selectedSchedule = s;
          return;
        }
      }
    }
  }

  Future<void> _fetchDoctorDetails() async {
    final docId = _docState.id.trim().isNotEmpty
        ? _docState.id.trim()
        : widget.doctor.id.trim();
    if (docId.isEmpty) return;
    if (!mounted) return;

    final res = await DoctorService.getDoctorById(docId);
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

    final aptRes = await AppointmentService.getDoctorAppointmentsByDoctorId(
      doctorId: docId,
      token: _appState.authToken,
    );
    if (!mounted) return;
    if (aptRes.success) {
      setState(() {
        _doctorBookedAppointments = aptRes.appointments;
      });
    }

    setState(() {
      _initInitialSchedule();
    });
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

          if (res.doctorDetails != null &&
              res.doctorDetails!.schedules != null &&
              res.doctorDetails!.schedules!.isNotEmpty) {
            _apiDoctorDetails = res.doctorDetails;
          }
          if (res.stats != null) {
            _docState = Doctor.fromApiDoctor(
              _apiDoctorDetails ??
                  widget.doctor.rawApiDoctor ??
                  res.doctorDetails ??
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
                            onError: (_, __) {},
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Consultation Fee',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontSize: 11,
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _selectedSchedule != null
                                    ? '₹${_selectedSchedule!.consultationFee.replaceAll('.00', '')} / session'
                                    : (_doctorSchedules.isNotEmpty
                                        ? '₹${_doctorSchedules.first.consultationFee.replaceAll('.00', '')} / session'
                                        : '₹${doc.consultationFee.toInt()} / session'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (!_appState.isDoctorLoggedIn)
                        ElevatedButton(
                          onPressed: !_hasAvailableSlotInWeek
                              ? null
                              : () async {
                                  final currentContext = context;
                                  if (await LoginScreen.checkAndNavigate(
                                    currentContext,
                                  )) {
                                    if (!mounted) return;
                                    if (currentContext.mounted) {
                                      Navigator.push(
                                        currentContext,
                                        MaterialPageRoute(
                                          builder: (_) => BookAppointmentScreen(
                                            doctor: doc,
                                            initialDate: _selectedSlotDate,
                                            initialSlotTime: _selectedSchedule?.startTime,
                                            initialSchedule: _selectedSchedule,
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: Colors.grey.shade300,
                            disabledForegroundColor: Colors.grey.shade600,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              !_hasAvailableSlotInWeek
                                  ? 'No Slots Available'
                                  : 'Book Appointment',
                              style: TextStyle(
                                color: !_hasAvailableSlotInWeek
                                    ? Colors.grey.shade600
                                    : Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
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

            // Consultation availability and appointment slots
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildShiftSlotsCard(),
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
                const Expanded(
                  child: Text(
                    'Patient Reviews',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
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



  void _updateSelectedScheduleForDate(DateTime date, List<DoctorSchedule> allSchedules) {
    final dName = _dayNameFromDate(date);
    final newDaySchedules = allSchedules
        .where((s) => s.dayOfWeek.toLowerCase().trim() == dName && s.isAvailable)
        .toList();
    if (newDaySchedules.isNotEmpty) {
      try {
        _selectedSchedule = newDaySchedules.firstWhere(
          (s) => !_isSlotBooked(s, date) && !_isSlotTimePassed(s, date),
        );
      } catch (_) {
        _selectedSchedule = newDaySchedules.first;
      }
    } else {
      _selectedSchedule = null;
    }
  }

  Widget _buildShiftSlotsCard() {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final allSchedules = _doctorSchedules;
    final selectedDayName = _dayNameFromDate(_selectedSlotDate);
    final daySchedules = allSchedules
        .where((s) => s.dayOfWeek.toLowerCase().trim() == selectedDayName)
        .toList();

    final morningSlots = daySchedules.where((s) => _getShiftCategory(s) == 'Morning').toList();
    final afternoonSlots = daySchedules.where((s) => _getShiftCategory(s) == 'Afternoon').toList();
    final eveningSlots = daySchedules.where((s) => _getShiftCategory(s) == 'Evening').toList();
    final nightSlots = daySchedules.where((s) => _getShiftCategory(s) == 'Night').toList();

    final availableDaysSet = allSchedules.map((s) => s.dayOfWeek.toLowerCase().trim()).toSet();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStartDate = today.add(Duration(days: _slotWeekOffset * 7));
    final weekEndDate = today.add(Duration(days: _slotWeekOffset * 7 + 6));
    final totalDaySlots = daySchedules.where((s) => !_isSlotTimePassed(s, _selectedSlotDate) && !_isSlotBooked(s, _selectedSlotDate)).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Available Appointment Slots',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'All 7 days visible • Select your time',
                      style: TextStyle(
                        color: AppColors.textLight.withValues(alpha: 0.9),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedSchedule != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, size: 12, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                      Text(
                        '₹${_selectedSchedule!.consultationFee.replaceAll('.00', '')}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Week Navigation Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.date_range_rounded, size: 14, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      '${weekStartDate.day} ${months[weekStartDate.month - 1]} - ${weekEndDate.day} ${months[weekEndDate.month - 1]} ${weekEndDate.year}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (_slotWeekOffset > 0) ...[
                      GestureDetector(
                        onTap: () {
                          _slotPageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: const Icon(Icons.chevron_left, size: 16, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    if (_slotWeekOffset < 2)
                      GestureDetector(
                        onTap: () {
                          _slotPageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 7-day row: SLIDER WITH ALL 7 DAYS VISIBLE AT ONCE IN ONE SCREEN
          SizedBox(
            height: 68,
            child: PageView.builder(
              controller: _slotPageController,
              itemCount: 3,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (pageIndex) {
                setState(() {
                  _slotWeekOffset = pageIndex;
                  final weekStart = today.add(Duration(days: pageIndex * 7));
                  final weekEnd = today.add(Duration(days: pageIndex * 7 + 6));
                  final curDate = DateTime(_selectedSlotDate.year, _selectedSlotDate.month, _selectedSlotDate.day);
                  if (curDate.isBefore(weekStart) || curDate.isAfter(weekEnd)) {
                    for (int i = 0; i < 7; i++) {
                      final d = today.add(Duration(days: pageIndex * 7 + i));
                      final diff = DateTime(d.year, d.month, d.day).difference(today).inDays;
                      if (diff >= 0 && diff <= 15) {
                        _selectedSlotDate = d;
                        _updateSelectedScheduleForDate(d, allSchedules);
                        break;
                      }
                    }
                  }
                });
              },
              itemBuilder: (context, pageIndex) {
                return Row(
                  children: List.generate(7, (idx) {
                    final date = today.add(Duration(days: pageIndex * 7 + idx));
                    final normalizedDate = DateTime(date.year, date.month, date.day);
                    final dayDiff = normalizedDate.difference(today).inDays;
                    final isWithin15Days = dayDiff >= 0 && dayDiff <= 15;
                    final isSel = isWithin15Days &&
                        date.year == _selectedSlotDate.year &&
                        date.month == _selectedSlotDate.month &&
                        date.day == _selectedSlotDate.day;
                    final isToday = dayDiff == 0;
                    final dName = _dayNameFromDate(date);
                    final dayScheds = allSchedules
                        .where((s) => s.dayOfWeek.toLowerCase().trim() == dName && s.isAvailable)
                        .toList();
                    final hasAvailableSlots = isWithin15Days && dayScheds.any(
                      (s) => !_isSlotTimePassed(s, date) && !_isSlotBooked(s, date),
                    );
                    final dayLabel = isToday ? 'Today' : weekdays[date.weekday - 1];

                    return Expanded(
                      child: GestureDetector(
                        onTap: isWithin15Days
                            ? () {
                                setState(() {
                                  _selectedSlotDate = date;
                                  _updateSelectedScheduleForDate(date, allSchedules);
                                });
                              }
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 2.0),
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            gradient: isSel
                                ? LinearGradient(
                                    colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  )
                                : null,
                            color: isSel
                                ? null
                                : (isWithin15Days ? Colors.white : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel
                                  ? AppColors.primary
                                  : (isWithin15Days
                                      ? (hasAvailableSlots
                                          ? AppColors.primary.withValues(alpha: 0.35)
                                          : const Color(0xFFE2E8F0))
                                      : const Color(0xFFF1F5F9)),
                              width: isSel ? 1.5 : 1,
                            ),
                            boxShadow: isSel
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.28),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                dayLabel,
                                style: TextStyle(
                                  color: !isWithin15Days
                                      ? Colors.grey.shade400
                                      : (isSel
                                          ? Colors.white70
                                          : (hasAvailableSlots ? AppColors.textDark : AppColors.textLight)),
                                  fontSize: 9.5,
                                  fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${date.day}',
                                style: TextStyle(
                                  color: !isWithin15Days
                                      ? Colors.grey.shade300
                                      : (isSel
                                          ? Colors.white
                                          : (hasAvailableSlots ? AppColors.textDark : Colors.grey.shade400)),
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: (isWithin15Days && hasAvailableSlots)
                                      ? (isSel ? Colors.white : const Color(0xFF10B981))
                                      : Colors.transparent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (pIdx) {
              final isActive = _slotWeekOffset == pIdx;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: isActive ? 16 : 5,
                height: 4,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),

          // Selected date summary banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_available, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${selectedDayName[0].toUpperCase()}${selectedDayName.substring(1)}, ${_selectedSlotDate.day} ${months[_selectedSlotDate.month - 1]} ${_selectedSlotDate.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: totalDaySlots > 0 ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    totalDaySlots > 0 ? '$totalDaySlots Slots Open' : 'No Slots',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: totalDaySlots > 0 ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Slots or Empty state
          if (daySchedules.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.event_busy, color: AppColors.textLight, size: 28),
                    const SizedBox(height: 6),
                    Text(
                      'No slots available on ${selectedDayName[0].toUpperCase()}${selectedDayName.substring(1)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (availableDaysSet.isNotEmpty) ...[
                      const Text(
                        'Tap an available day to view slots:',
                        style: TextStyle(fontSize: 11, color: AppColors.textLight),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: availableDaysSet.map((d) {
                          return ActionChip(
                            label: Text(
                              '${d[0].toUpperCase()}${d.substring(1)}',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            onPressed: () {
                              for (int i = 0; i < 16; i++) {
                                final candidate = DateTime.now().add(Duration(days: i));
                                if (_dayNameFromDate(candidate) == d) {
                                  final targetPage = (i ~/ 7).clamp(0, 2);
                                  setState(() {
                                    _slotWeekOffset = targetPage;
                                    _selectedSlotDate = candidate;
                                    _updateSelectedScheduleForDate(candidate, allSchedules);
                                  });
                                  _slotPageController.animateToPage(
                                    targetPage,
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                  break;
                                }
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ] else ...[
            if (morningSlots.isNotEmpty) ...[
              _buildDoctorShiftSection('Morning', Icons.wb_sunny_rounded, Colors.orange, morningSlots),
              const SizedBox(height: 10),
            ],
            if (afternoonSlots.isNotEmpty) ...[
              _buildDoctorShiftSection('Afternoon', Icons.wb_twilight_rounded, Colors.indigo, afternoonSlots),
              const SizedBox(height: 10),
            ],
            if (eveningSlots.isNotEmpty) ...[
              _buildDoctorShiftSection('Evening', Icons.nights_stay_rounded, Colors.deepPurple, eveningSlots),
              const SizedBox(height: 10),
            ],
            if (nightSlots.isNotEmpty) ...[
              _buildDoctorShiftSection('Night', Icons.bedtime_rounded, Colors.blueGrey, nightSlots),
              const SizedBox(height: 10),
            ],
          ],

          if (!_appState.isDoctorLoggedIn) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: !_hasAvailableSlotInWeek
                    ? null
                    : () async {
                        final currentContext = context;
                        if (await LoginScreen.checkAndNavigate(currentContext)) {
                          if (!mounted) return;
                          if (currentContext.mounted) {
                            Navigator.push(
                              currentContext,
                              MaterialPageRoute(
                                builder: (_) => BookAppointmentScreen(
                                  doctor: _docState,
                                  initialDate: _selectedSlotDate,
                                  initialSlotTime: _selectedSchedule?.startTime,
                                  initialSchedule: _selectedSchedule,
                                ),
                              ),
                            );
                          }
                        }
                      },
                icon: Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: !_hasAvailableSlotInWeek
                      ? Colors.grey.shade500
                      : Colors.white,
                ),
                label: Text(
                  !_hasAvailableSlotInWeek
                      ? 'No Slots Available This Week'
                      : (_selectedSchedule != null
                          ? 'Book Slot (${_formatTime12h(_selectedSchedule!.startTime)} • ₹${_selectedSchedule!.consultationFee.replaceAll('.00', '')})'
                          : 'Book Appointment with this Doctor'),
                  style: TextStyle(
                    color: !_hasAvailableSlotInWeek
                        ? Colors.grey.shade600
                        : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDoctorShiftSection(
    String title,
    IconData icon,
    Color iconColor,
    List<DoctorSchedule> schedules,
  ) {
    final int availableCount = schedules
        .where((s) =>
            !_isSlotBooked(s, _selectedSlotDate) &&
            !_isSlotTimePassed(s, _selectedSlotDate))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: iconColor, size: 14),
            ),
            const SizedBox(width: 8),
            Text(
              '$title Slots',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: availableCount > 0 ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$availableCount available',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: availableCount > 0 ? const Color(0xFF16A34A) : AppColors.textLight,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: schedules.map((sch) {
            final isBooked = _isSlotBooked(sch, _selectedSlotDate);
            final isPassed = _isSlotTimePassed(sch, _selectedSlotDate);
            final canSelect = !isBooked && !isPassed;

            final isSel = _selectedSchedule?.id == sch.id ||
                (_selectedSchedule?.startTime == sch.startTime &&
                    _selectedSchedule?.dayOfWeek == sch.dayOfWeek);
            final timeDisplay = _formatTime12h(sch.startTime);
            final feeDisplay = '₹${sch.consultationFee.replaceAll('.00', '')}';

            return GestureDetector(
              onTap: canSelect
                  ? () {
                      setState(() {
                        _selectedSchedule = sch;
                      });
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  gradient: isSel
                      ? LinearGradient(
                          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSel
                      ? null
                      : (isPassed
                          ? const Color(0xFFF8FAFC)
                          : (isBooked ? const Color(0xFFFEF2F2) : Colors.white)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isPassed
                        ? const Color(0xFFE2E8F0)
                        : (isBooked
                            ? const Color(0xFFFCA5A5)
                            : (isSel
                                ? AppColors.primary
                                : AppColors.border.withValues(alpha: 0.7))),
                    width: isSel ? 1.5 : 1,
                  ),
                  boxShadow: isSel
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.28),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: isPassed
                          ? Colors.grey.shade400
                          : (isBooked
                              ? Colors.red.shade400
                              : (isSel ? Colors.white70 : AppColors.primary)),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      timeDisplay,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                        color: isPassed
                            ? Colors.grey.shade500
                            : (isBooked
                                ? Colors.red.shade700
                                : (isSel ? Colors.white : AppColors.textDark)),
                        decoration: canSelect ? null : TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (isPassed) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Passed',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ] else if (isBooked) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Booked',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isSel
                              ? Colors.white.withValues(alpha: 0.22)
                              : AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          feeDisplay,
                          style: TextStyle(
                            color: isSel ? Colors.white : AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
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
              Expanded(
                child: Text(
                  author,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
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

                                final nav = Navigator.of(context);
                                final messenger = ScaffoldMessenger.of(context);

                                final res = await _appState.submitRating(
                                  targetId: widget.doctor.id,
                                  targetType: 'doctor',
                                  score: selectedScore,
                                  review: reviewController.text.trim(),
                                );

                                if (res.success) {
                                  nav.pop();
                                  messenger.showSnackBar(
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
