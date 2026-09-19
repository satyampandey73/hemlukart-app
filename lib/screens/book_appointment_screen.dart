import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../models/appointment_slot_model.dart';
import '../services/appointment_service.dart';
import '../services/doctor_service.dart';
import 'appointment_confirmed_screen.dart';

class BookAppointmentScreen extends StatefulWidget {
  final Doctor doctor;
  const BookAppointmentScreen({super.key, required this.doctor});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final AppState _appState = AppState();
  final TextEditingController _notesController = TextEditingController();
  late TextEditingController _patientNameController;
  late TextEditingController _patientMobileController;
  late TextEditingController _patientAgeController;

  String _consultationType = 'in_person';
  DateTime _selectedDate = DateTime.now();
  AppointmentSlot? _selectedSlot;

  bool _isLoadingSlots = false;
  bool _isBooking = false;
  String? _errorMessage;
  List<AppointmentSlot> _slots = [];
  AppointmentSlotDoctor? _doctorInfo;
  late Doctor _docState;

  @override
  void initState() {
    super.initState();
    _docState = widget.doctor;
    _selectedDate = DateTime.now();
    
    final user = _appState.currentUser;
    _patientNameController = TextEditingController(text: user?.fullName ?? '');
    _patientMobileController = TextEditingController(text: user?.mobile ?? '');
    _patientAgeController = TextEditingController(text: '30');

    _updateConsultationTypeSelection();
    _fetchDoctorDetails();
    _fetchSlotsForSelectedDate();
  }

  void _updateConsultationTypeSelection() {
    if (_hasInPerson && !_hasOnline) {
      _consultationType = 'in_person';
    } else if (_hasOnline && !_hasInPerson) {
      _consultationType = 'online';
    }
  }

  Future<void> _fetchDoctorDetails() async {
    if (widget.doctor.id.isEmpty) return;
    final res = await DoctorService.getDoctorById(widget.doctor.id);
    if (!mounted) return;
    if (res.success && res.doctor != null) {
      setState(() {
        _docState = Doctor.fromApiDoctor(res.doctor!);
        _updateConsultationTypeSelection();
      });
    }
  }

  bool get _hasInPerson {
    final cFees = _docState.consultationFees.isNotEmpty
        ? _docState.consultationFees
        : (widget.doctor.consultationFees.isNotEmpty
            ? widget.doctor.consultationFees
            : (_docState.rawApiDoctor?.consultationFees ??
                widget.doctor.rawApiDoctor?.consultationFees));

    if (cFees != null && cFees.isNotEmpty) {
      final hasPerson = cFees.any((f) =>
          f.consultationType.toLowerCase() == 'in_person' ||
          f.consultationType.toLowerCase().contains('person') ||
          f.consultationType.toLowerCase().contains('clinic'));
      final hasOnline = cFees.any((f) =>
          f.consultationType.toLowerCase() == 'online' ||
          f.consultationType.toLowerCase() == 'video' ||
          f.consultationType.toLowerCase().contains('video') ||
          f.consultationType.toLowerCase().contains('online'));

      if (hasPerson || hasOnline) return hasPerson;
    }

    final schedules = _docState.rawApiDoctor?.schedules ?? widget.doctor.rawApiDoctor?.schedules;
    if (schedules != null && schedules.isNotEmpty) {
      final hasPerson = schedules.any((s) =>
          s.consultationType.toLowerCase() == 'in_person' ||
          s.consultationType.toLowerCase().contains('person') ||
          s.consultationType.toLowerCase().contains('clinic'));
      final hasOnline = schedules.any((s) =>
          s.consultationType.toLowerCase() == 'online' ||
          s.consultationType.toLowerCase() == 'video' ||
          s.consultationType.toLowerCase().contains('video') ||
          s.consultationType.toLowerCase().contains('online'));

      if (hasPerson || hasOnline) return hasPerson;
    }

    return true;
  }

  bool get _hasOnline {
    final cFees = _docState.consultationFees.isNotEmpty
        ? _docState.consultationFees
        : (widget.doctor.consultationFees.isNotEmpty
            ? widget.doctor.consultationFees
            : (_docState.rawApiDoctor?.consultationFees ??
                widget.doctor.rawApiDoctor?.consultationFees));

    if (cFees != null && cFees.isNotEmpty) {
      final hasPerson = cFees.any((f) =>
          f.consultationType.toLowerCase() == 'in_person' ||
          f.consultationType.toLowerCase().contains('person') ||
          f.consultationType.toLowerCase().contains('clinic'));
      final hasOnline = cFees.any((f) =>
          f.consultationType.toLowerCase() == 'online' ||
          f.consultationType.toLowerCase() == 'video' ||
          f.consultationType.toLowerCase() == 'audio' ||
          f.consultationType.toLowerCase() == 'chat' ||
          f.consultationType.toLowerCase().contains('video') ||
          f.consultationType.toLowerCase().contains('online') ||
          f.consultationType.toLowerCase().contains('audio') ||
          f.consultationType.toLowerCase().contains('chat'));

      if (hasPerson || hasOnline) return hasOnline;
    }

    final schedules = _docState.rawApiDoctor?.schedules ?? widget.doctor.rawApiDoctor?.schedules;
    if (schedules != null && schedules.isNotEmpty) {
      final hasPerson = schedules.any((s) =>
          s.consultationType.toLowerCase() == 'in_person' ||
          s.consultationType.toLowerCase().contains('person') ||
          s.consultationType.toLowerCase().contains('clinic'));
      final hasOnline = schedules.any((s) =>
          s.consultationType.toLowerCase() == 'online' ||
          s.consultationType.toLowerCase() == 'video' ||
          s.consultationType.toLowerCase() == 'audio' ||
          s.consultationType.toLowerCase() == 'chat' ||
          s.consultationType.toLowerCase().contains('video') ||
          s.consultationType.toLowerCase().contains('online') ||
          s.consultationType.toLowerCase().contains('audio') ||
          s.consultationType.toLowerCase().contains('chat'));

      if (hasPerson || hasOnline) return hasOnline;
    }

    return _docState.hasOnline || widget.doctor.hasOnline;
  }

  @override
  void dispose() {
    _notesController.dispose();
    _patientNameController.dispose();
    _patientMobileController.dispose();
    _patientAgeController.dispose();
    super.dispose();
  }

  double get _currentConsultationFee {
    final cFees = _docState.consultationFees.isNotEmpty
        ? _docState.consultationFees
        : (widget.doctor.consultationFees.isNotEmpty
            ? widget.doctor.consultationFees
            : (_docState.rawApiDoctor?.consultationFees ??
                widget.doctor.rawApiDoctor?.consultationFees));

    if (cFees != null && cFees.isNotEmpty) {
      final reqType = _consultationType.toLowerCase().trim();
      final match = cFees.firstWhere(
        (f) {
          final t = f.consultationType.toLowerCase().trim();
          if (reqType == 'in_person' || reqType == 'offline') {
            return t == 'in_person' || t == 'in-person' || t.contains('person') || t.contains('clinic');
          }
          if (reqType == 'video' || reqType == 'online') {
            return t == 'video' || t == 'online' || t.contains('video') || t.contains('online');
          }
          return t == reqType || t.contains(reqType);
        },
        orElse: () => cFees.first,
      );
      final parsed = double.tryParse(match.fee);
      if (parsed != null && parsed > 0) return parsed;
    }

    final apiDoc = _docState.rawApiDoctor ?? widget.doctor.rawApiDoctor;
    if (apiDoc != null && apiDoc.schedules != null && apiDoc.schedules!.isNotEmpty) {
      final reqType = _consultationType.toLowerCase().trim();
      final match = apiDoc.schedules!.firstWhere(
        (s) {
          final t = s.consultationType.toLowerCase().trim();
          if (reqType == 'in_person' || reqType == 'offline') {
            return t == 'in_person' || t == 'in-person' || t.contains('person') || t.contains('clinic');
          }
          if (reqType == 'video' || reqType == 'online') {
            return t == 'video' || t == 'online' || t.contains('video') || t.contains('online');
          }
          return t == reqType || t.contains(reqType);
        },
        orElse: () => apiDoc.schedules!.first,
      );
      final parsed = double.tryParse(match.consultationFee);
      if (parsed != null && parsed > 0) return parsed;
    }

    return _docState.consultationFee;
  }

  String _formatDateForApi(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _fetchSlotsForSelectedDate() async {
    setState(() {
      _isLoadingSlots = true;
      _errorMessage = null;
      _slots = [];
      _selectedSlot = null;
    });

    String doctorId = widget.doctor.id.trim();
    if (doctorId.isEmpty || doctorId.length < 10) {
      doctorId = 'a78cb806-93db-46e2-b9ea-9fd8409ef29f';
    }

    final String dateStr = _formatDateForApi(_selectedDate);

    try {
      final response = await AppointmentService.getAppointmentSlots(
        doctorId: doctorId,
        date: dateStr,
        token: _appState.authToken,
      );

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _slots = response.slots;
          _doctorInfo = response.doctor;
          _isLoadingSlots = false;
          final availableSlots = response.slots.where((s) => s.available).toList();
          if (availableSlots.isNotEmpty) {
            _selectedSlot = availableSlots.first;
          }
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load slots';
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred: $e';
        _isLoadingSlots = false;
      });
    }
  }

  Future<void> _handleBookAppointment() async {
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an available appointment slot.')),
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

    setState(() => _isBooking = true);

    String doctorId = widget.doctor.id.trim();
    if (doctorId.isEmpty || doctorId.length < 10) {
      doctorId = 'a78cb806-93db-46e2-b9ea-9fd8409ef29f';
    }

    String? clinicId;
    int durationMinutes = 30;
    final apiDoc = widget.doctor.rawApiDoctor;
    if (apiDoc != null && apiDoc.schedules != null && apiDoc.schedules!.isNotEmpty) {
      final match = apiDoc.schedules!.firstWhere(
        (s) => s.consultationType == _consultationType,
        orElse: () => apiDoc.schedules!.first,
      );
      clinicId = match.clinicId;
      durationMinutes = match.slotDuration;
    }

    final String mappedConsultationType =
        _consultationType == 'online' ? 'video' : _consultationType;

    final response = await AppointmentService.bookAppointment(
      doctorId: doctorId,
      appointmentDate: _selectedSlot!.time,
      clinicId: clinicId,
      durationMinutes: durationMinutes,
      consultationType: mappedConsultationType,
      patientName: name,
      patientMobile: mobile,
      patientAge: int.tryParse(_patientAgeController.text.trim()),
      symptoms: _notesController.text.trim(),
      notes: _notesController.text.trim(),
      consultationFee: _currentConsultationFee,
      token: _appState.authToken,
    );

    if (!mounted) return;
    setState(() => _isBooking = false);

    if (response.success) {
      final customId = response.appointment?.id;

      _appState.addAppointment(
        widget.doctor,
        _getFormattedDate(_selectedDate),
        _selectedSlot!.displayTime,
        _notesController.text,
        customId: customId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message.isNotEmpty ? response.message : 'Appointment booked successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.push(
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
      // Handle fallback or display error
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
                _selectedSlot!.displayTime,
                _notesController.text,
              );
              Navigator.push(
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

  @override
  Widget build(BuildContext context) {
    final doc = widget.doctor;

    final morningSlots = _slots.where((s) => s.periodCategory == 'Morning').toList();
    final afternoonSlots = _slots.where((s) => s.periodCategory == 'Afternoon').toList();
    final eveningSlots = _slots.where((s) => s.periodCategory == 'Evening').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Process Header
            Container(
              color: AppColors.backgroundLight.withOpacity(0.4),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: Row(
                children: [
                  _buildStepBubble('1', 'Slot', true),
                  _buildStepConnector(true),
                  _buildStepBubble('2', 'Payment', false),
                  _buildStepConnector(false),
                  _buildStepBubble('3', 'Confirmed', false),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mini Doctor Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: (doc.image.startsWith('http://') || doc.image.startsWith('https://'))
                              ? NetworkImage(doc.image) as ImageProvider
                              : AssetImage(doc.image.isNotEmpty ? doc.image : 'assets/doctor_profile.png'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _doctorInfo?.fullName.isNotEmpty == true
                                    ? 'Dr. ${_doctorInfo!.fullName}'
                                    : doc.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                              ),
                              Text('${doc.specialty} • ${doc.experienceYears} Yrs Exp', style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 12),
                            const SizedBox(width: 2),
                            Text('${doc.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Calendar Picker Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Select Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                      Text(
                        _formatDateForApi(_selectedDate),
                        style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 14,
                      itemBuilder: (context, idx) {
                        final date = DateTime.now().add(Duration(days: idx));
                        final isSel = date.year == _selectedDate.year && date.month == _selectedDate.month && date.day == _selectedDate.day;
                        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return GestureDetector(
                          onTap: () {
                            if (!isSel) {
                              setState(() => _selectedDate = date);
                              _fetchSlotsForSelectedDate();
                            }
                          },
                          child: Container(
                            width: 60,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSel ? AppColors.primary : AppColors.border.withOpacity(0.5)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(weekdays[date.weekday - 1], style: TextStyle(color: isSel ? Colors.white70 : AppColors.textLight, fontSize: 11)),
                                const SizedBox(height: 6),
                                Text('${date.day}', style: TextStyle(color: isSel ? Colors.white : AppColors.textDark, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Slots Selection Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Available Slots', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                      if (_isLoadingSlots)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Slot contents depending on loading/error/data state
                  if (_isLoadingSlots)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: Column(
                        children: const [
                          CircularProgressIndicator(color: AppColors.primary),
                          SizedBox(height: 12),
                          Text('Fetching available appointment slots...', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                        ],
                      ),
                    )
                  else if (_errorMessage != null)
                    Container(
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
                    )
                  else if (_slots.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: const [
                          Icon(Icons.event_busy, color: AppColors.textLight, size: 36),
                          SizedBox(height: 8),
                          Text('No appointment slots available for this date.', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                        ],
                      ),
                    )
                  else ...[
                    // Morning Slots
                    if (morningSlots.isNotEmpty) ...[
                      Row(
                        children: const [
                          Icon(Icons.wb_sunny_outlined, color: Colors.orange, size: 16),
                          SizedBox(width: 6),
                          Text('Morning', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textLight)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: morningSlots.map((slot) => _buildSlotItem(slot)).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Afternoon Slots
                    if (afternoonSlots.isNotEmpty) ...[
                      Row(
                        children: const [
                          Icon(Icons.wb_twilight, color: Colors.indigo, size: 16),
                          SizedBox(width: 6),
                          Text('Afternoon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textLight)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: afternoonSlots.map((slot) => _buildSlotItem(slot)).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Evening Slots
                    if (eveningSlots.isNotEmpty) ...[
                      Row(
                        children: const [
                          Icon(Icons.nights_stay_outlined, color: Colors.deepPurple, size: 16),
                          SizedBox(width: 6),
                          Text('Evening', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textLight)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: eveningSlots.map((slot) => _buildSlotItem(slot)).toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                  // Consultation Type Selector
                  const Text(
                    'Consultation Type',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if (_hasInPerson)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _consultationType = 'in_person'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              decoration: BoxDecoration(
                                color: _consultationType == 'in_person'
                                    ? AppColors.primary.withOpacity(0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _consultationType == 'in_person'
                                      ? AppColors.primary
                                      : AppColors.border.withOpacity(0.5),
                                  width: _consultationType == 'in_person' ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    color: _consultationType == 'in_person'
                                        ? AppColors.primary
                                        : AppColors.textLight,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'In-Person Visit',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        Text(
                                          'Clinic / Hospital',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (_hasInPerson && _hasOnline) const SizedBox(width: 12),
                      if (_hasOnline)
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _consultationType = 'online'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              decoration: BoxDecoration(
                                color: _consultationType == 'online'
                                    ? AppColors.primary.withOpacity(0.1)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _consultationType == 'online'
                                      ? AppColors.primary
                                      : AppColors.border.withOpacity(0.5),
                                  width: _consultationType == 'online' ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.video_call_outlined,
                                    color: _consultationType == 'online'
                                        ? AppColors.primary
                                        : AppColors.textLight,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Online Video',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                        Text(
                                          'Video Consult',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textLight,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Patient Details Section
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

                  const SizedBox(height: 24),

                  // Selected Summary Panel
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Selected Slot', style: TextStyle(color: AppColors.textLight, fontSize: 11)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _consultationType == 'in_person' ? 'In-Person Visit' : 'Online Video',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, color: AppColors.primary, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              _selectedSlot != null
                                  ? '${_getFormattedDate(_selectedDate)} • ${_selectedSlot!.displayTime}'
                                  : 'No slot selected',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Consultation Fee: ₹${_currentConsultationFee.toInt()}', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Message reason
                  const Text('Why are you booking this appointment?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      hintText: 'Describe your symptoms, or what you\'d like to discuss with the doctor...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 32),

                  // Proceed button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_selectedSlot == null || _isLoadingSlots || _isBooking)
                          ? null
                          : _handleBookAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.border,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isBooking
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                ),
                                SizedBox(width: 12),
                                Text('Booking Appointment...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                              ],
                            )
                          : const Text('Continue to Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepBubble(String step, String label, bool isActive) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isActive ? AppColors.primary : AppColors.border,
          child: Text(step, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: isActive ? AppColors.primary : AppColors.textLight, fontSize: 11, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        height: 2,
        color: isActive ? AppColors.primary : AppColors.border,
      ),
    );
  }

  Widget _buildSlotItem(AppointmentSlot slot) {
    final bool isAvailable = slot.available;
    final bool isSel = _selectedSlot?.time == slot.time;

    return GestureDetector(
      onTap: isAvailable
          ? () {
              setState(() => _selectedSlot = slot);
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: !isAvailable
              ? Colors.grey.shade200
              : (isSel ? AppColors.primary : Colors.white),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: !isAvailable
                ? Colors.grey.shade300
                : (isSel ? AppColors.primary : AppColors.border.withOpacity(0.5)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              slot.displayTime,
              style: TextStyle(
                color: !isAvailable
                    ? Colors.grey.shade500
                    : (isSel ? Colors.white : AppColors.textDark),
                fontSize: 12,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                decoration: !isAvailable ? TextDecoration.lineThrough : null,
              ),
            ),
            if (!isAvailable) ...[
              const SizedBox(width: 4),
              Text(
                'Booked',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getFormattedDate(DateTime date) {
    final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}
