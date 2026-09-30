import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../models/doctor_model.dart';
import '../models/my_appointments_model.dart';
import '../services/appointment_service.dart';
import '../services/doctor_service.dart';
import 'appointment_confirmed_screen.dart';
import 'login_screen.dart';

class BookAppointmentScreen extends StatefulWidget {
  final Doctor doctor;
  final DateTime? initialDate;
  final String? initialSlotTime;
  final DoctorSchedule? initialSchedule;

  const BookAppointmentScreen({
    super.key,
    required this.doctor,
    this.initialDate,
    this.initialSlotTime,
    this.initialSchedule,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final AppState _appState = AppState();

  // Multi-step flow: 1 = Slot & Review, 2 = Payment, 3 = Confirmed
  int _currentStep = 1;

  // Step 1: Patient details & symptoms
  final TextEditingController _notesController = TextEditingController();
  late TextEditingController _patientNameController;
  late TextEditingController _patientMobileController;
  late TextEditingController _patientAgeController;

  // Consultation Type: 'video', 'audio', 'in_person'
  String _selectedConsultationType = 'video';
  DateTime _selectedDate = DateTime.now();
  DoctorSchedule? _selectedSchedule;
  List<UserAppointmentItem> _doctorBookedAppointments = [];
  int _calendarWeekOffset = 0;
  late final PageController _calendarPageController;

  bool _isLoadingSlots = false;
  bool _isBooking = false;
  String? _errorMessage;
  late Doctor _docState;

  // Step 2: Payment state
  String _selectedPaymentMethod = 'Card'; // 'Card', 'UPI', 'NetBanking', 'COD'
  final TextEditingController _cardHolderNameController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardExpiryController = TextEditingController();
  final TextEditingController _cardCvvController = TextEditingController();
  final TextEditingController _upiIdController = TextEditingController();
  String _selectedBank = 'HDFC Bank';
  bool _saveCard = false;

  // Coupon state
  final TextEditingController _couponCodeController = TextEditingController();
  double _appliedDiscount = 0.0;
  String? _appliedCouponCode;
  bool _isApplyingCoupon = false;

  // Popular banks for Net Banking
  final List<Map<String, String>> _popularBanks = [
    {'name': 'HDFC Bank', 'code': 'HDFC'},
    {'name': 'State Bank of India', 'code': 'SBI'},
    {'name': 'ICICI Bank', 'code': 'ICICI'},
    {'name': 'Axis Bank', 'code': 'AXIS'},
    {'name': 'Kotak Mahindra', 'code': 'KOTAK'},
    {'name': 'Punjab National', 'code': 'PNB'},
  ];

  // UPI Apps quick select
  final List<Map<String, String>> _upiApps = [
    {'name': 'Google Pay', 'suffix': '@okaxis'},
    {'name': 'PhonePe', 'suffix': '@ybl'},
    {'name': 'Paytm', 'suffix': '@paytm'},
    {'name': 'BHIM UPI', 'suffix': '@upi'},
  ];

  List<DoctorSchedule> get _allSchedules {
    return _docState.rawApiDoctor?.schedules ??
        widget.doctor.rawApiDoctor?.schedules ??
        [];
  }

  bool get isOnlineConsultation =>
      _selectedConsultationType == 'video' || _selectedConsultationType == 'audio';

  String get consultationCategoryBadgeText =>
      isOnlineConsultation ? 'Online Consultation' : 'In-Person Clinic Visit';

  String _getDayOfWeek(DateTime date) {
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

  String _formatTimeRange(DoctorSchedule sch) {
    final start = _formatTime12h(sch.startTime);
    if (sch.endTime.isNotEmpty) {
      final end = _formatTime12h(sch.endTime);
      return '$start - $end';
    }
    return start;
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

  bool _scheduleMatchesType(DoctorSchedule sch, String type) {
    final sType = sch.consultationType.toLowerCase().trim();
    final target = type.toLowerCase().trim();

    if (target == 'video') {
      return sType == 'video' ||
          sType.contains('video') ||
          sType == 'online' ||
          sType.contains('online_video') ||
          sType.contains('video_call');
    } else if (target == 'audio') {
      return sType == 'audio' ||
          sType.contains('audio') ||
          sType.contains('voice') ||
          sType.contains('audio_call') ||
          sType.contains('call');
    } else if (target == 'in_person') {
      return sType == 'in_person' ||
          sType == 'in-person' ||
          sType == 'offline' ||
          sType.contains('person') ||
          sType.contains('clinic') ||
          sType.contains('hospital');
    }
    return sType == target || sType.contains(target);
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

  /// Checks if a schedule slot is already booked on the specified date
  bool _isSlotBooked(DoctorSchedule sch, DateTime date) {
    // 1. If schedule itself was marked unavailable by the doctor in settings
    if (!sch.isAvailable) return true;

    // 2. Check against real-time booked appointments for this doctor
    if (_doctorBookedAppointments.isEmpty) return false;

    for (final apt in _doctorBookedAppointments) {
      final status = apt.status.toLowerCase().trim();
      // Skip cancelled or rejected appointments
      if (status == 'cancelled' || status == 'rejected') continue;
      if (apt.appointmentDate.isEmpty) continue;

      try {
        final aptUtc = DateTime.parse(apt.appointmentDate).toUtc();
        // Backend stores appointments in UTC. For India (IST), add 5 hours 30 minutes.
        final aptIst = aptUtc.add(const Duration(hours: 5, minutes: 30));

        // Must match the exact date (year, month, day)
        if (aptIst.year != date.year ||
            aptIst.month != date.month ||
            aptIst.day != date.day) {
          continue;
        }

        // Schedule start and end in minutes from midnight
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

        // Appointment start and end in minutes from midnight
        final aptStartInMins = aptIst.hour * 60 + aptIst.minute;
        final aptDur = apt.durationMinutes > 0 ? apt.durationMinutes : 30;
        final aptEndInMins = aptStartInMins + aptDur;

        // Interval overlap test: max(start1, start2) < min(end1, end2)
        final overlapStart =
            schStartInMins > aptStartInMins ? schStartInMins : aptStartInMins;
        final overlapEnd =
            schEndInMins < aptEndInMins ? schEndInMins : aptEndInMins;

        if (overlapStart < overlapEnd) {
          return true; // Overlap detected -> This slot is already booked!
        }
      } catch (_) {}
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    _docState = widget.doctor;
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedSchedule = widget.initialSchedule;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initDateNorm = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final diffDays = initDateNorm.difference(today).inDays;
    if (diffDays >= 0 && diffDays <= 15) {
      _calendarWeekOffset = (diffDays / 7).floor().clamp(0, 2);
    } else {
      _selectedDate = today;
      _calendarWeekOffset = 0;
    }
    _calendarPageController = PageController(initialPage: _calendarWeekOffset);

    final user = _appState.currentUser;
    _patientNameController = TextEditingController(text: user?.fullName ?? '');
    _patientMobileController = TextEditingController(text: user?.mobile ?? '');
    _patientAgeController = TextEditingController(text: '30');
    _cardHolderNameController.text = user?.fullName ?? '';

    // Enforce login/registration for public patients
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!_appState.isLoggedIn && mounted) {
        final loggedIn = await LoginScreen.checkAndNavigate(context);
        if (!loggedIn && mounted) {
          Navigator.pop(context);
        } else if (mounted) {
          final u = _appState.currentUser;
          if (u != null) {
            if (_patientNameController.text.isEmpty && u.fullName.isNotEmpty) {
              _patientNameController.text = u.fullName;
            }
            if (_patientMobileController.text.isEmpty && u.mobile.isNotEmpty) {
              _patientMobileController.text = u.mobile;
            }
          }
          setState(() {});
        }
      }
    });

    // Initialize consultation type
    if (widget.initialSchedule != null &&
        widget.initialSchedule!.consultationType.isNotEmpty) {
      final sType = widget.initialSchedule!.consultationType.toLowerCase();
      if (sType.contains('audio')) {
        _selectedConsultationType = 'audio';
      } else if (sType.contains('person') ||
          sType.contains('clinic') ||
          sType.contains('offline')) {
        _selectedConsultationType = 'in_person';
      } else {
        _selectedConsultationType = 'video';
      }
    } else {
      _selectedConsultationType = 'video';
    }

    _fetchDoctorDetails();
  }

  Future<void> _fetchDoctorDetails() async {
    final docId = _docState.id.trim().isNotEmpty
        ? _docState.id.trim()
        : widget.doctor.id.trim();
    if (docId.isEmpty) return;

    // 1. Fetch doctor details (schedules, consultationFees)
    final res = await DoctorService.getDoctorById(docId);
    if (!mounted) return;
    if (res.success && res.doctor != null) {
      setState(() {
        _docState = Doctor.fromApiDoctor(res.doctor!);
      });
    }

    // 2. Fetch doctor booked appointments to verify booked slots
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

    _fetchSlotsForSelectedDate();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _patientNameController.dispose();
    _patientMobileController.dispose();
    _patientAgeController.dispose();
    _cardHolderNameController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _upiIdController.dispose();
    _couponCodeController.dispose();
    _calendarPageController.dispose();
    super.dispose();
  }

  double get _currentConsultationFee {
    if (_selectedSchedule != null) {
      final parsed = double.tryParse(_selectedSchedule!.consultationFee);
      if (parsed != null && parsed > 0) return parsed;
    }

    final cFees = _docState.consultationFees.isNotEmpty
        ? _docState.consultationFees
        : (widget.doctor.consultationFees.isNotEmpty
            ? widget.doctor.consultationFees
            : (_docState.rawApiDoctor?.consultationFees ??
                widget.doctor.rawApiDoctor?.consultationFees));

    if (cFees != null && cFees.isNotEmpty) {
      final reqType = _selectedConsultationType.toLowerCase().trim();
      final match = cFees.firstWhere(
        (f) {
          final t = f.consultationType.toLowerCase().trim();
          if (reqType == 'video') {
            return t == 'video' || t == 'online' || t.contains('video') || t.contains('online');
          } else if (reqType == 'audio') {
            return t == 'audio' || t.contains('audio') || t.contains('call');
          } else if (reqType == 'in_person') {
            return t == 'in_person' || t == 'in-person' || t.contains('person') || t.contains('clinic') || t == 'offline';
          }
          return t == reqType || t.contains(reqType);
        },
        orElse: () => cFees.first,
      );
      final parsed = double.tryParse(match.fee);
      if (parsed != null && parsed > 0) return parsed;
    }

    return _docState.consultationFee > 0 ? _docState.consultationFee : 500.0;
  }

  double _getFeeForConsultationType(String type) {
    final scheds = _allSchedules;
    final matchingSchedule = scheds.firstWhere(
      (s) =>
          _scheduleMatchesType(s, type) &&
          (double.tryParse(s.consultationFee) ?? 0) > 0,
      orElse: () => DoctorSchedule(
        id: '',
        doctorId: '',
        dayOfWeek: '',
        sessionName: '',
        startTime: '',
        endTime: '',
        slotDuration: 30,
        isAvailable: true,
        consultationType: '',
        consultationFee: '0',
      ),
    );
    if (matchingSchedule.id.isNotEmpty) {
      final parsed = double.tryParse(matchingSchedule.consultationFee);
      if (parsed != null && parsed > 0) return parsed;
    }

    final cFees = _docState.consultationFees.isNotEmpty
        ? _docState.consultationFees
        : (widget.doctor.consultationFees.isNotEmpty
            ? widget.doctor.consultationFees
            : (_docState.rawApiDoctor?.consultationFees ??
                widget.doctor.rawApiDoctor?.consultationFees));

    if (cFees != null && cFees.isNotEmpty) {
      final reqType = type.toLowerCase().trim();
      try {
        final match = cFees.firstWhere((f) {
          final t = f.consultationType.toLowerCase().trim();
          if (reqType == 'video') {
            return t == 'video' ||
                t == 'online' ||
                t.contains('video') ||
                t.contains('online');
          } else if (reqType == 'audio') {
            return t == 'audio' || t.contains('audio') || t.contains('call');
          } else if (reqType == 'in_person') {
            return t == 'in_person' ||
                t == 'in-person' ||
                t.contains('person') ||
                t.contains('clinic') ||
                t == 'offline';
          }
          return t == reqType || t.contains(reqType);
        });
        final parsed = double.tryParse(match.fee);
        if (parsed != null && parsed > 0) return parsed;
      } catch (_) {}
    }

    return _docState.consultationFee > 0 ? _docState.consultationFee : 500.0;
  }

  double get _finalTotalAmount {
    final fee = _currentConsultationFee;
    final total = fee - _appliedDiscount;
    return total > 0 ? total : 0.0;
  }

  String _formatDateForHeader(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  List<DoctorSchedule> _getFilteredSchedulesForCurrentType(List<DoctorSchedule> daySchedules) {
    final matching = daySchedules
        .where((s) => _scheduleMatchesType(s, _selectedConsultationType))
        .toList();
    if (matching.isNotEmpty) {
      return matching;
    }
    // If no schedules explicitly specify this consultation type, check if all schedules are untyped
    final anyHasExplicitType =
        daySchedules.any((s) => s.consultationType.trim().isNotEmpty);
    if (!anyHasExplicitType) {
      return daySchedules;
    }
    return [];
  }

  Future<void> _fetchSlotsForSelectedDate() async {
    setState(() {
      _isLoadingSlots = true;
      _errorMessage = null;
    });

    if (!mounted) return;

    final docId = _docState.id.trim().isNotEmpty
        ? _docState.id.trim()
        : widget.doctor.id.trim();
    if (docId.isNotEmpty && _doctorBookedAppointments.isEmpty) {
      final aptRes = await AppointmentService.getDoctorAppointmentsByDoctorId(
        doctorId: docId,
        token: _appState.authToken,
      );
      if (mounted && aptRes.success) {
        setState(() {
          _doctorBookedAppointments = aptRes.appointments;
        });
      }
    }

    if (!mounted) return;

    final allSchedules = _allSchedules;
    final dayName = _getDayOfWeek(_selectedDate);
    final daySchedules = allSchedules
        .where((s) => s.dayOfWeek.toLowerCase().trim() == dayName)
        .toList();

    final filtered = _getFilteredSchedulesForCurrentType(daySchedules);

    setState(() {
      _isLoadingSlots = false;
      if (filtered.isNotEmpty) {
        final bool isCurrentValid = _selectedSchedule != null &&
            _selectedSchedule!.dayOfWeek.toLowerCase().trim() == dayName &&
            _scheduleMatchesType(_selectedSchedule!, _selectedConsultationType) &&
            !_isSlotBooked(_selectedSchedule!, _selectedDate) &&
            !_isSlotTimePassed(_selectedSchedule!, _selectedDate);

        if (!isCurrentValid) {
          DoctorSchedule? match;
          if (widget.initialSchedule != null &&
              widget.initialSchedule!.dayOfWeek.toLowerCase().trim() == dayName &&
              _scheduleMatchesType(widget.initialSchedule!, _selectedConsultationType) &&
              !_isSlotBooked(widget.initialSchedule!, _selectedDate) &&
              !_isSlotTimePassed(widget.initialSchedule!, _selectedDate)) {
            match = widget.initialSchedule;
          } else {
            // Find first available slot whose time has not passed and is NOT booked
            try {
              match = filtered.firstWhere(
                (s) =>
                    !_isSlotBooked(s, _selectedDate) &&
                    !_isSlotTimePassed(s, _selectedDate),
              );
            } catch (_) {
              match = null;
            }
          }
          _selectedSchedule = match;
        }
      } else {
        _selectedSchedule = null;
      }
    });
  }

  void _handleContinueToPayment() {
    if (_selectedSchedule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an available appointment slot.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isSlotBooked(_selectedSchedule!, _selectedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This time slot is already booked. Please choose another available slot.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isSlotTimePassed(_selectedSchedule!, _selectedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected slot time has already passed for today. Please select an upcoming slot.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final name = _patientNameController.text.trim();
    final mobile = _patientMobileController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter patient full name.')),
      );
      return;
    }

    if (mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter patient mobile number.')),
      );
      return;
    }

    if (_cardHolderNameController.text.trim().isEmpty) {
      _cardHolderNameController.text = name;
    }

    // Switch to Step 2: Payment
    setState(() {
      _currentStep = 2;
    });
  }

  void _handleApplyCoupon() {
    final code = _couponCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isApplyingCoupon = true);

    // Coupon logic: support AYUSH10, WELCOME50, FIRST100, etc.
    double discount = 0.0;
    if (code == 'WELCOME50' || code == 'AYUSH50') {
      discount = 50.0;
    } else if (code == 'FIRST100' || code == 'AYUSH100') {
      discount = 100.0;
    } else if (code == 'AYUSH10') {
      discount = _currentConsultationFee * 0.10;
    } else {
      // Default flat ₹50 promotional discount for valid alphanumeric code
      discount = 50.0;
    }

    setState(() {
      _isApplyingCoupon = false;
      _appliedDiscount = discount;
      _appliedCouponCode = code;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Coupon "$code" applied successfully! ₹${discount.toStringAsFixed(0)} saved.'),
        backgroundColor: const Color(0xFF059669),
      ),
    );
  }

  void _handleRemoveCoupon() {
    setState(() {
      _appliedDiscount = 0.0;
      _appliedCouponCode = null;
      _couponCodeController.clear();
    });
  }

  Future<void> _handleBookAppointment() async {
    if (!_appState.isLoggedIn) {
      final loggedIn = await LoginScreen.checkAndNavigate(context);
      if (!loggedIn) return;
    }

    if (_selectedSchedule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an available appointment slot.')),
      );
      return;
    }

    final name = _patientNameController.text.trim();
    final mobile = _patientMobileController.text.trim();

    if (name.isEmpty || mobile.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required patient details.')),
      );
      return;
    }

    // Validate payment method if card
    if (_selectedPaymentMethod == 'Card') {
      final cardNum = _cardNumberController.text.replaceAll(' ', '').trim();
      if (cardNum.isNotEmpty && cardNum.length < 12) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid 16-digit card number.')),
        );
        return;
      }
    }

    setState(() => _isBooking = true);

    String doctorId = _docState.id.trim().isNotEmpty
        ? _docState.id.trim()
        : widget.doctor.id.trim();

    final String appointmentDateStr = AppointmentService.formatToIstDate(_selectedDate);
    final String appointmentTimeStr = AppointmentService.formatToIstTime(_selectedSchedule!.startTime);
    final double feeToPay = _finalTotalAmount;

    // Map consultation type strictly: 'video', 'audio', 'in_person'
    final String mappedConsultationType = (_selectedConsultationType == 'in_person')
        ? 'in_person'
        : _selectedConsultationType;

    final response = await AppointmentService.bookAppointment(
      doctorId: doctorId,
      appointmentDate: appointmentDateStr,
      appointmentTime: appointmentTimeStr,
      clinicId: _selectedSchedule!.clinicId,
      durationMinutes: _selectedSchedule!.slotDuration > 0
          ? _selectedSchedule!.slotDuration
          : 30,
      consultationType: mappedConsultationType,
      patientName: name,
      patientMobile: mobile,
      patientAge: int.tryParse(_patientAgeController.text.trim()),
      symptoms: _notesController.text.trim(),
      notes: _notesController.text.trim(),
      consultationFee: feeToPay,
      token: _appState.authToken,
    );

    if (!mounted) return;
    setState(() => _isBooking = false);

    if (response.success) {
      final customId = response.appointment?.id;

      _appState.addAppointment(
        widget.doctor,
        _getFormattedDate(_selectedDate),
        _formatTime12h(_selectedSchedule!.startTime),
        _notesController.text,
        customId: customId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message.isNotEmpty
              ? response.message
              : 'Payment confirmed & Appointment booked successfully!'),
          backgroundColor: const Color(0xFF059669),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AppointmentConfirmedScreen(
            appointmentId: response.appointment?.id ?? customId ?? '',
            bookedAppointment: response.appointment,
            doctor: widget.doctor,
          ),
        ),
      );
    } else {
      _showBookingErrorDialog(response.message, name, mobile);
    }
  }

  void _showBookingErrorDialog(String serverMsg, String name, String mobile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.info_outline, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Booking Notice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          serverMsg.contains('Unauthorized')
              ? '$serverMsg\n\nWould you like to proceed with local appointment confirmation?'
              : serverMsg,
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _appState.addAppointment(
                widget.doctor,
                _getFormattedDate(_selectedDate),
                _selectedSchedule != null
                    ? _formatTime12h(_selectedSchedule!.startTime)
                    : '',
                _notesController.text,
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => AppointmentConfirmedScreen(
                    appointmentId: _appState.appointments.last.id,
                    doctor: widget.doctor,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Confirm Locally', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // BUILD
  // -------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentStep == 2) {
          setState(() => _currentStep = 1);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            _currentStep == 1 ? 'Book Appointment' : 'Payment & Checkout',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (_currentStep == 2) {
                setState(() => _currentStep = 1);
              } else {
                Navigator.pop(context);
              }
            },
          ),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Stepper Progress Tracker (Review -> Payment -> Confirmation)
              _buildProgressTracker(),

              // Step Content
              if (_currentStep == 1)
                _buildSlotSelectionStep()
              else
                _buildPaymentStep(),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // STEPPER PROGRESS TRACKER
  // -------------------------------------------------------------
  Widget _buildProgressTracker() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        children: [
          _buildStepBubble('1', 'Review', isDone: _currentStep > 1, isActive: _currentStep == 1),
          _buildStepConnector(_currentStep >= 2),
          _buildStepBubble('2', 'Payment', isDone: _currentStep > 2, isActive: _currentStep == 2),
          _buildStepConnector(_currentStep >= 3),
          _buildStepBubble('3', 'Confirmation', isDone: false, isActive: _currentStep == 3),
        ],
      ),
    );
  }

  Widget _buildStepBubble(String step, String label, {bool isDone = false, bool isActive = false}) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: (isDone || isActive) ? const Color(0xFF0F4C47) : Colors.grey.shade300,
          child: isDone
              ? const Icon(Icons.check, color: Colors.white, size: 14)
              : Text(
                  step,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: (isDone || isActive) ? const Color(0xFF0F4C47) : Colors.grey.shade500,
            fontSize: 12,
            fontWeight: (isDone || isActive) ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        height: 2,
        color: isActive ? const Color(0xFF0F4C47) : Colors.grey.shade200,
      ),
    );
  }

  // -------------------------------------------------------------
  // STEP 1: CONSULTATION TYPE TABS, CALENDAR & SLOTS
  // -------------------------------------------------------------
  Widget _buildSlotSelectionStep() {
    final doc = widget.doctor;

    final allSchedules = _allSchedules;
    final dayName = _getDayOfWeek(_selectedDate);
    final daySchedules = allSchedules
        .where((s) => s.dayOfWeek.toLowerCase().trim() == dayName)
        .toList();

    // Filter schedules by the selected consultation type
    final filteredSchedules = _getFilteredSchedulesForCurrentType(daySchedules);

    final morningSchedules = filteredSchedules
        .where((s) => _getShiftCategory(s) == 'Morning')
        .toList();
    final afternoonSchedules = filteredSchedules
        .where((s) => _getShiftCategory(s) == 'Afternoon')
        .toList();
    final eveningSchedules = filteredSchedules
        .where((s) => _getShiftCategory(s) == 'Evening')
        .toList();
    final nightSchedules = filteredSchedules
        .where((s) => _getShiftCategory(s) == 'Night')
        .toList();

    final availableDaysSet = allSchedules
        .where((s) => _scheduleMatchesType(s, _selectedConsultationType))
        .map((s) => s.dayOfWeek.toLowerCase().trim())
        .toSet();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Mini Doctor Card & Date Picker Row
          _buildDoctorHeaderCard(doc),

          const SizedBox(height: 16),

          // 2. Calendar Date Picker
          _buildCalendarDatePicker(availableDaysSet),

          const SizedBox(height: 18),

          // 3. Consultation Mode Selection Card (Positioned directly above Available Slots!)
          _buildConsultationTypeSelector(),

          const SizedBox(height: 6),

          // 4. Slots Header with Active Consultation Type Badge
          _buildAvailableSlotsHeader(),

          const SizedBox(height: 12),

          // 5. Slots Content Area
          if (_isLoadingSlots)
            _buildSlotsLoadingState()
          else if (_errorMessage != null)
            _buildSlotsErrorState()
          else if (filteredSchedules.isEmpty)
            _buildSlotsEmptyState(dayName, availableDaysSet)
          else ...[
            if (morningSchedules.isNotEmpty)
              _buildShiftSection('Morning', Icons.wb_sunny_outlined, Colors.orange, morningSchedules),
            if (afternoonSchedules.isNotEmpty)
              _buildShiftSection('Afternoon', Icons.wb_twilight, Colors.indigo, afternoonSchedules),
            if (eveningSchedules.isNotEmpty)
              _buildShiftSection('Evening', Icons.nights_stay_outlined, Colors.deepPurple, eveningSchedules),
            if (nightSchedules.isNotEmpty)
              _buildShiftSection('Night', Icons.bedtime_outlined, Colors.blueGrey, nightSchedules),
          ],

          const SizedBox(height: 20),

          // 6. Selected Slot Summary Panel
          _buildSelectedSlotCard(),

          const SizedBox(height: 20),

          // 7. Patient Details Form
          _buildPatientDetailsForm(),

          const SizedBox(height: 20),

          // 8. Reason / Symptoms Note
          const Text(
            'Why are you booking this appointment?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: 'Describe your symptoms, or what you\'d like to discuss with the doctor...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.all(12),
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 28),

          // 9. Continue to Payment Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedSchedule == null || _isLoadingSlots)
                  ? null
                  : _handleContinueToPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F4C47),
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Continue to Payment',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // CONSULTATION MODE SELECTOR (Professional Cards Above Slots)
  // -------------------------------------------------------------
  Widget _buildConsultationTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F4C47).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.medical_services_outlined,
                  color: Color(0xFF0F4C47),
                  size: 15,
                ),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Consultation Mode',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOnlineConsultation
                      ? const Color(0xFFE6F4F1)
                      : const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  consultationCategoryBadgeText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isOnlineConsultation
                        ? const Color(0xFF0F4C47)
                        : const Color(0xFF6D28D9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildConsultationTypeCard(
                type: 'video',
                title: 'Video Call',
                subtitle: 'Online',
                icon: Icons.videocam_rounded,
                accentColor: const Color(0xFF0F4C47),
                activeBg: const Color(0xFFE8F5F1),
                fee: _getFeeForConsultationType('video'),
              ),
              const SizedBox(width: 10),
              _buildConsultationTypeCard(
                type: 'audio',
                title: 'Audio Call',
                subtitle: 'Voice Call',
                icon: Icons.phone_in_talk_rounded,
                accentColor: const Color(0xFF1D4ED8),
                activeBg: const Color(0xFFEFF6FF),
                fee: _getFeeForConsultationType('audio'),
              ),
              const SizedBox(width: 10),
              _buildConsultationTypeCard(
                type: 'in_person',
                title: 'Clinic Visit',
                subtitle: 'In-Person',
                icon: Icons.local_hospital_rounded,
                accentColor: const Color(0xFF6D28D9),
                activeBg: const Color(0xFFF5F3FF),
                fee: _getFeeForConsultationType('in_person'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationTypeCard({
    required String type,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required Color activeBg,
    required double fee,
  }) {
    final bool isSel = _selectedConsultationType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSel) {
            setState(() {
              _selectedConsultationType = type;
              _selectedSchedule = null;
            });
            _fetchSlotsForSelectedDate();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: isSel ? activeBg : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSel ? accentColor : Colors.grey.shade200,
              width: isSel ? 1.8 : 1,
            ),
            boxShadow: isSel
                ? [
                    BoxShadow(
                      color: accentColor.withOpacity(0.14),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.015),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (isSel)
                Positioned(
                  top: -4,
                  right: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 11,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isSel ? accentColor : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 18,
                        color: isSel ? Colors.white : Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                        color: isSel ? accentColor : AppColors.textDark,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: isSel
                            ? accentColor.withOpacity(0.85)
                            : Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSel
                            ? accentColor.withOpacity(0.12)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '₹${fee.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSel ? accentColor : AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // MINI DOCTOR HEADER CARD
  // -------------------------------------------------------------
  Widget _buildDoctorHeaderCard(Doctor doc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: (doc.image.startsWith('http://') || doc.image.startsWith('https://'))
                ? NetworkImage(doc.image) as ImageProvider
                : AssetImage(doc.image.isNotEmpty ? doc.image : 'assets/doctor_profile.png'),
            onBackgroundImageError: (doc.image.startsWith('http')) ? (_, __) {} : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _docState.name.isNotEmpty ? _docState.name : doc.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  '${doc.specialty} • ${doc.experienceYears} Years',
                  style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                ),
              ],
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 3),
              Text(
                '${doc.rating}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // HORIZONTAL 14-DAYS CALENDAR PICKER
  // -------------------------------------------------------------
  Widget _buildCalendarDatePicker(Set<String> availableDaysSet) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStartDate = today.add(Duration(days: _calendarWeekOffset * 7));
    final weekEndDate = today.add(Duration(days: _calendarWeekOffset * 7 + 6));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F4C47).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    size: 16,
                    color: Color(0xFF0F4C47),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Select Date',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                ),
              ],
            ),
            Row(
              children: [
                if (_calendarWeekOffset > 0) ...[
                  GestureDetector(
                    onTap: () {
                      _calendarPageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(Icons.chevron_left, size: 18, color: Color(0xFF0F4C47)),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F4C47).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${weekStartDate.day} ${months[weekStartDate.month - 1]} - ${weekEndDate.day} ${months[weekEndDate.month - 1]}',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0F4C47)),
                  ),
                ),
                const SizedBox(width: 4),
                if (_calendarWeekOffset < 2)
                  GestureDetector(
                    onTap: () {
                      _calendarPageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(Icons.chevron_right, size: 18, color: Color(0xFF0F4C47)),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 68,
          child: PageView.builder(
            controller: _calendarPageController,
            itemCount: 3,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (pageIndex) {
              setState(() {
                _calendarWeekOffset = pageIndex;
                final weekStart = today.add(Duration(days: pageIndex * 7));
                final weekEnd = today.add(Duration(days: pageIndex * 7 + 6));
                final curDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
                if (curDate.isBefore(weekStart) || curDate.isAfter(weekEnd)) {
                  for (int i = 0; i < 7; i++) {
                    final d = today.add(Duration(days: pageIndex * 7 + i));
                    final diff = DateTime(d.year, d.month, d.day).difference(today).inDays;
                    if (diff >= 0 && diff <= 15) {
                      _selectedDate = d;
                      _selectedSchedule = null;
                      break;
                    }
                  }
                }
              });
              _fetchSlotsForSelectedDate();
            },
            itemBuilder: (context, pageIndex) {
              return Row(
                children: List.generate(7, (idx) {
                  final date = today.add(Duration(days: pageIndex * 7 + idx));
                  final normalizedDate = DateTime(date.year, date.month, date.day);
                  final dayDiff = normalizedDate.difference(today).inDays;
                  final isWithin15Days = dayDiff >= 0 && dayDiff <= 15;
                  final isSel = isWithin15Days &&
                      date.year == _selectedDate.year &&
                      date.month == _selectedDate.month &&
                      date.day == _selectedDate.day;
                  final isToday = dayDiff == 0;
                  final hasSlotsOnDay = isWithin15Days && availableDaysSet.contains(_getDayOfWeek(date));
                  final dayLabel = isToday ? 'Today' : weekdays[date.weekday - 1];

                  return Expanded(
                    child: GestureDetector(
                      onTap: isWithin15Days
                          ? () {
                              if (!isSel) {
                                setState(() {
                                  _selectedDate = date;
                                  _selectedSchedule = null;
                                });
                                _fetchSlotsForSelectedDate();
                              }
                            }
                          : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 2.0),
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          color: isSel
                              ? const Color(0xFF0F4C47)
                              : (isWithin15Days ? Colors.white : const Color(0xFFF8FAFC)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSel
                                ? const Color(0xFF0F4C47)
                                : (isWithin15Days
                                    ? (hasSlotsOnDay
                                        ? const Color(0xFF0F4C47).withValues(alpha: 0.3)
                                        : const Color(0xFFE2E8F0))
                                    : const Color(0xFFF1F5F9)),
                            width: isSel ? 1.5 : 1,
                          ),
                          boxShadow: isSel
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF0F4C47).withValues(alpha: 0.25),
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
                                        : (hasSlotsOnDay ? AppColors.textDark : AppColors.textLight)),
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
                                        : (hasSlotsOnDay ? AppColors.textDark : Colors.grey.shade400)),
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
                                color: (isWithin15Days && hasSlotsOnDay)
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
            final isActive = _calendarWeekOffset == pIdx;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              width: isActive ? 16 : 5,
              height: 4,
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF0F4C47)
                    : const Color(0xFF0F4C47).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.event_available_outlined, size: 14, color: Color(0xFF0F4C47)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${_getDayOfWeek(_selectedDate).toUpperCase()} • ${_getFormattedDate(_selectedDate)}',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F4C47)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: availableDaysSet.contains(_getDayOfWeek(_selectedDate))
                          ? const Color(0xFF10B981)
                          : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    availableDaysSet.contains(_getDayOfWeek(_selectedDate)) ? 'Slots Open' : 'No Slots',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: availableDaysSet.contains(_getDayOfWeek(_selectedDate))
                          ? const Color(0xFF10B981)
                          : AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // SLOTS HEADER WITH BADGE
  // -------------------------------------------------------------
  Widget _buildAvailableSlotsHeader() {
    IconData badgeIcon;
    String badgeTitle;

    if (_selectedConsultationType == 'audio') {
      badgeIcon = Icons.phone_in_talk_rounded;
      badgeTitle = 'Audio Call';
    } else if (_selectedConsultationType == 'in_person') {
      badgeIcon = Icons.local_hospital_rounded;
      badgeTitle = 'In-Person Visit';
    } else {
      badgeIcon = Icons.videocam_rounded;
      badgeTitle = 'Video Consultation';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'Available Slots for ${_formatDateForHeader(_selectedDate)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF059669),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(badgeIcon, color: Colors.white, size: 12),
              const SizedBox(width: 4),
              Text(
                badgeTitle,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShiftSection(
    String title,
    IconData icon,
    Color iconColor,
    List<DoctorSchedule> schedules,
  ) {
    final int availableCount = schedules
        .where((s) =>
            !_isSlotBooked(s, _selectedDate) &&
            !_isSlotTimePassed(s, _selectedDate))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(icon, color: iconColor, size: 15),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '($availableCount available)',
              style: const TextStyle(fontSize: 11, color: AppColors.textLight),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: schedules.map((sch) => _buildScheduleSlotItem(sch)).toList(),
        ),
      ],
    );
  }

  Widget _buildScheduleSlotItem(DoctorSchedule schedule) {
    final bool isBooked = _isSlotBooked(schedule, _selectedDate);
    final bool isPassed = _isSlotTimePassed(schedule, _selectedDate);
    final bool isSel = _selectedSchedule?.id == schedule.id ||
        (_selectedSchedule?.startTime == schedule.startTime &&
            _selectedSchedule?.dayOfWeek == schedule.dayOfWeek);

    final timeRangeText = _formatTimeRange(schedule);

    // If passed or booked, disable click
    final bool canSelect = !isBooked && !isPassed;

    return GestureDetector(
      onTap: canSelect
          ? () {
              setState(() {
                _selectedSchedule = schedule;
              });
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isPassed
              ? Colors.grey.shade100
              : (isBooked
                  ? Colors.red.shade50
                  : (isSel ? const Color(0xFF0F4C47) : Colors.white)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPassed
                ? Colors.grey.shade200
                : (isBooked
                    ? Colors.red.shade300
                    : (isSel ? const Color(0xFF0F4C47) : Colors.grey.shade300)),
            width: isSel ? 1.5 : 1,
          ),
          boxShadow: isSel
              ? [
                  BoxShadow(
                    color: const Color(0xFF0F4C47).withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              timeRangeText,
              style: TextStyle(
                color: isPassed
                    ? Colors.grey.shade500
                    : (isBooked
                        ? Colors.red.shade700
                        : (isSel ? Colors.white : AppColors.textDark)),
                fontSize: 12,
                fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            if (isPassed)
              Text(
                '(Time Passed)',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              )
            else if (isBooked)
              Text(
                '(Booked)',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Text(
                isSel ? 'Selected' : 'Available',
                style: TextStyle(
                  fontSize: 10,
                  color: isSel
                      ? Colors.white.withOpacity(0.9)
                      : const Color(0xFF059669),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // SLOTS EMPTY / LOADING / ERROR STATES
  // -------------------------------------------------------------
  Widget _buildSlotsLoadingState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: const [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 12),
          Text('Fetching appointment slots...', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildSlotsErrorState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Failed to load slots', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          Text(_errorMessage!, style: const TextStyle(color: AppColors.textDark, fontSize: 12)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _fetchSlotsForSelectedDate,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsEmptyState(String dayName, Set<String> availableDaysSet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.event_busy, color: AppColors.textLight, size: 36),
          const SizedBox(height: 8),
          Text(
            'No ${_selectedConsultationType == "in_person" ? "In-Person" : (_selectedConsultationType == "audio" ? "Audio Call" : "Video")} slots available on ${dayName[0].toUpperCase()}${dayName.substring(1)}.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          const Text(
            'Please select another date or consultation type above.',
            style: TextStyle(fontSize: 12, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SELECTED SLOT CARD
  // -------------------------------------------------------------
  Widget _buildSelectedSlotCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Selected Slot', style: TextStyle(color: AppColors.textLight, fontSize: 12, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isOnlineConsultation ? const Color(0xFFE6F4F1) : const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  consultationCategoryBadgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isOnlineConsultation ? const Color(0xFF0F4C47) : const Color(0xFF6D28D9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_month, color: Color(0xFF0F4C47), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedSchedule != null
                      ? '${_getFormattedDate(_selectedDate)} • ${_formatTimeRange(_selectedSchedule!)}'
                      : '${_getFormattedDate(_selectedDate)} • No slot selected',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Consultation Fee: ₹${_currentConsultationFee.toStringAsFixed(2)}',
            style: const TextStyle(color: Color(0xFF0F4C47), fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // PATIENT DETAILS FORM
  // -------------------------------------------------------------
  Widget _buildPatientDetailsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Patient Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
        const SizedBox(height: 12),
        TextField(
          controller: _patientNameController,
          decoration: const InputDecoration(
            labelText: 'Patient Full Name',
            hintText: 'e.g. Rahul Kumar',
            prefixIcon: Icon(Icons.person_outline, size: 20),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _patientMobileController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  hintText: 'e.g. 9876543210',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: TextField(
                controller: _patientAgeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age',
                  hintText: 'e.g. 32',
                  prefixIcon: Icon(Icons.cake_outlined, size: 20),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // STEP 2: PAYMENT & CHECKOUT SCREEN (Matching Image 4)
  // -------------------------------------------------------------
  Widget _buildPaymentStep() {
    final doc = widget.doctor;
    final fee = _currentConsultationFee;
    final total = _finalTotalAmount;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Select Payment Method Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Payment Method',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                ),
                const SizedBox(height: 16),

                // Method Tabs (Card, UPI, Net Banking, COD)
                Row(
                  children: [
                    _buildPaymentMethodButton('Card', Icons.credit_card_rounded, 'Card'),
                    const SizedBox(width: 8),
                    _buildPaymentMethodButton('UPI', Icons.phone_android_rounded, 'UPI'),
                    const SizedBox(width: 8),
                    _buildPaymentMethodButton('NetBanking', Icons.account_balance_rounded, 'Net Banking'),
                    const SizedBox(width: 8),
                    _buildPaymentMethodButton('COD', Icons.payments_rounded, 'COD'),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                // Active Method Details Panel
                if (_selectedPaymentMethod == 'Card')
                  _buildCardPaymentForm()
                else if (_selectedPaymentMethod == 'UPI')
                  _buildUpiPaymentForm()
                else if (_selectedPaymentMethod == 'NetBanking')
                  _buildNetBankingForm()
                else
                  _buildCodPaymentForm(),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                // Security Badges Footer
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runAlignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 15),
                        SizedBox(width: 4),
                        Text('SSL SECURED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.lock_rounded, color: Color(0xFF0F4C47), size: 15),
                        SizedBox(width: 4),
                        Text('256-BIT ENCRYPTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F4C47))),
                      ],
                    ),
                    Text(
                      'VISA • MasterCard • PCI-DSS',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Order Summary Card (Matching Image 4 right section)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Order Summary',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                    ),
                    Icon(Icons.shield_outlined, color: Color(0xFF059669), size: 20),
                  ],
                ),
                const SizedBox(height: 14),

                // Doctor mini row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: (doc.image.startsWith('http://') || doc.image.startsWith('https://'))
                          ? NetworkImage(doc.image) as ImageProvider
                          : AssetImage(doc.image.isNotEmpty ? doc.image : 'assets/doctor_profile.png'),
                      onBackgroundImageError: (doc.image.startsWith('http')) ? (_, __) {} : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _docState.name.isNotEmpty ? _docState.name : doc.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                          ),
                          Text(
                            '${doc.specialty} • ${doc.experienceYears} Years',
                            style: const TextStyle(color: AppColors.textLight, fontSize: 11),
                          ),
                          if (_selectedSchedule != null)
                            Text(
                              'Slot: ${_formatTime12h(_selectedSchedule!.startTime)}',
                              style: const TextStyle(color: AppColors.textLight, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Online/Offline Consultation Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F4C47),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    consultationCategoryBadgeText,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Price breakdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Consultation Fee', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                    Text('₹${fee.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Shipping / Booking', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                    Text('FREE', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),

                if (_appliedDiscount > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Coupon (${_appliedCouponCode ?? "PROMO"})', style: const TextStyle(color: Color(0xFF059669), fontSize: 13)),
                      Text('-₹${_appliedDiscount.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ],

                const SizedBox(height: 14),

                // Coupon code input & apply button
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: TextField(
                          controller: _couponCodeController,
                          decoration: InputDecoration(
                            hintText: 'Enter coupon code',
                            hintStyle: const TextStyle(fontSize: 12, color: AppColors.textLight),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          enabled: _appliedDiscount == 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: _appliedDiscount > 0 ? _handleRemoveCoupon : _handleApplyCoupon,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _appliedDiscount > 0 ? Colors.red.shade700 : const Color(0xFF0F4C47),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          elevation: 0,
                        ),
                        child: _isApplyingCoupon
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(
                                _appliedDiscount > 0 ? 'Remove' : 'Apply',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                    Text(
                      '₹${total.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F4C47)),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Pay Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isBooking ? null : _handleBookAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F4C47),
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    child: _isBooking
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                              SizedBox(width: 12),
                              Text('Processing Payment & Booking...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Pay ₹${total.toStringAsFixed(2)} Securely',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 12),

                // Terms Notice
                Center(
                  child: Text(
                    "By proceeding, you agree to AYUSH Care's Terms of Service and Privacy Policy",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ),

                const SizedBox(height: 12),

                // 100% Secure Checkout Badge
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4F1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.verified_rounded, color: Color(0xFF0F4C47), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '100% SECURE CHECKOUT\nYour data is always encrypted',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F4C47)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Back to Step 1 Button
                Center(
                  child: TextButton.icon(
                    onPressed: () => setState(() => _currentStep = 1),
                    icon: const Icon(Icons.arrow_back, size: 16, color: Color(0xFF0F4C47)),
                    label: const Text('Change Slot or Date', style: TextStyle(color: Color(0xFF0F4C47), fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodButton(String method, IconData icon, String label) {
    final isSel = _selectedPaymentMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPaymentMethod = method),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFFE6F4F1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSel ? const Color(0xFF0F4C47) : Colors.grey.shade200,
              width: isSel ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isSel ? const Color(0xFF0F4C47) : Colors.grey.shade600),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                  color: isSel ? const Color(0xFF0F4C47) : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // CARD FORM (Credit / Debit Card)
  // -------------------------------------------------------------
  Widget _buildCardPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Credit / Debit Card', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
        const SizedBox(height: 12),
        TextField(
          controller: _cardHolderNameController,
          decoration: InputDecoration(
            labelText: 'Cardholder Name',
            hintText: 'John Doe',
            hintStyle: const TextStyle(fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Card Number',
            hintText: 'XXXX XXXX XXXX XXXX',
            hintStyle: const TextStyle(fontSize: 13),
            suffixIcon: const Icon(Icons.credit_card, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _cardExpiryController,
                decoration: InputDecoration(
                  labelText: 'Expiry Date',
                  hintText: 'MM / YY',
                  hintStyle: const TextStyle(fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _cardCvvController,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'CVV',
                  hintText: '***',
                  hintStyle: const TextStyle(fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: _saveCard,
              activeColor: const Color(0xFF0F4C47),
              onChanged: (val) => setState(() => _saveCard = val ?? false),
            ),
            const Text('Save card securely for future payments', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
          ],
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // UPI FORM
  // -------------------------------------------------------------
  Widget _buildUpiPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('UPI Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
        const SizedBox(height: 12),
        TextField(
          controller: _upiIdController,
          decoration: InputDecoration(
            labelText: 'Enter UPI ID',
            hintText: 'e.g. mobile@okhdfcbank / name@upi',
            prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Popular UPI Apps:', style: TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _upiApps.map((app) {
            return ActionChip(
              label: Text(app['name']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F4C47))),
              backgroundColor: const Color(0xFFE6F4F1),
              side: const BorderSide(color: Color(0xFF0F4C47), width: 0.5),
              onPressed: () {
                final base = _patientMobileController.text.trim().isNotEmpty
                    ? _patientMobileController.text.trim()
                    : 'user';
                _upiIdController.text = '$base${app['suffix']}';
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // NET BANKING FORM
  // -------------------------------------------------------------
  Widget _buildNetBankingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Net Banking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
        const SizedBox(height: 12),
        const Text('Popular Banks:', style: TextStyle(fontSize: 11, color: AppColors.textLight, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _popularBanks.map((bank) {
            final isBankSel = _selectedBank == bank['name'];
            return ChoiceChip(
              label: Text(bank['name']!, style: TextStyle(fontSize: 11, fontWeight: isBankSel ? FontWeight.bold : FontWeight.normal, color: isBankSel ? Colors.white : AppColors.textDark)),
              selected: isBankSel,
              selectedColor: const Color(0xFF0F4C47),
              backgroundColor: Colors.white,
              side: BorderSide(color: isBankSel ? const Color(0xFF0F4C47) : Colors.grey.shade300),
              onSelected: (_) => setState(() => _selectedBank = bank['name']!),
            );
          }).toList(),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // COD / PAY AT CLINIC FORM
  // -------------------------------------------------------------
  Widget _buildCodPaymentForm() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.storefront_rounded, color: Color(0xFF0F4C47), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Pay at Clinic / Cash on Delivery',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                ),
                SizedBox(height: 4),
                Text(
                  'You can pay the consultation fee directly at the clinic reception via Cash, Card, or UPI upon your arrival.',
                  style: TextStyle(fontSize: 11, color: AppColors.textLight, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getFormattedDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}
