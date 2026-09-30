import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../models/doctor_model.dart';
import '../services/doctor_profile_service.dart';

class DoctorEditProfileScreen extends StatefulWidget {
  final ApiDoctor doctor;

  const DoctorEditProfileScreen({super.key, required this.doctor});

  @override
  State<DoctorEditProfileScreen> createState() => _DoctorEditProfileScreenState();
}

class _DoctorEditProfileScreenState extends State<DoctorEditProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSaving = false;
  String? _errorMessage;

  // Controllers - Personal
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pinCodeController;
  String _selectedGender = 'male';
  String? _selectedDob;

  // Controllers - Professional
  late TextEditingController _regNumController;
  late TextEditingController _stateCouncilController;
  late TextEditingController _expController;
  late TextEditingController _clinicController;
  late TextEditingController _designationController;
  String _selectedAyushSystem = 'Ayurveda (BAMS)';

  final List<String> _ayushSystems = [
    'Ayurveda (BAMS)',
    'Homeopathy (BHMS)',
    'Unani (BUMS)',
    'Siddha (BSMS)',
    'Yoga & Naturopathy (BNYS)',
    'Allopathy (MBBS)',
    'Other',
  ];

  // Controllers - Qualifications
  late TextEditingController _gradUniController;
  late TextEditingController _gradYearController;
  late TextEditingController _highDegreeController;
  late TextEditingController _highSpecController;
  late TextEditingController _highUniController;
  late TextEditingController _highYearController;

  // Controllers - Bio & Expertise
  late TextEditingController _aboutController;
  late TextEditingController _philosophyController;
  late TextEditingController _achievementsController;
  late TextEditingController _expertiseController;
  late TextEditingController _languagesController;

  // Controllers - Bank
  late TextEditingController _acHolderController;
  late TextEditingController _bankNameController;
  late TextEditingController _acNumController;
  late TextEditingController _ifscController;
  late TextEditingController _panController;

  final List<String> _tabs = [
    'Personal',
    'Professional',
    'Qualifications',
    'Bio & Skills',
    'Bank',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    final doc = widget.doctor;

    // Personal
    _nameController = TextEditingController(text: doc.fullName);
    _emailController = TextEditingController(text: doc.email ?? '');
    _addressController = TextEditingController(text: doc.address ?? '');
    _cityController = TextEditingController(text: doc.city ?? '');
    _stateController = TextEditingController(text: doc.state ?? '');
    _pinCodeController = TextEditingController(text: doc.pinCode ?? '');
    _selectedGender = (doc.gender != null && doc.gender!.isNotEmpty)
        ? doc.gender!.toLowerCase()
        : 'male';
    if (doc.dateOfBirth != null && doc.dateOfBirth!.isNotEmpty) {
      _selectedDob = doc.dateOfBirth!.split('T').first;
    }

    // Professional
    _regNumController = TextEditingController(text: doc.registrationNumber ?? '');
    _stateCouncilController =
        TextEditingController(text: doc.stateAyushCouncil ?? '');
    _expController = TextEditingController(
        text: doc.totalExperience != null ? doc.totalExperience.toString() : '');
    _clinicController =
        TextEditingController(text: doc.currentClinicOrHospital ?? '');
    _designationController =
        TextEditingController(text: doc.currentDesignation ?? '');
    if (doc.ayushSystem != null && doc.ayushSystem!.isNotEmpty) {
      if (_ayushSystems.contains(doc.ayushSystem)) {
        _selectedAyushSystem = doc.ayushSystem!;
      } else {
        _selectedAyushSystem = doc.ayushSystem!;
        if (!_ayushSystems.contains(_selectedAyushSystem)) {
          _ayushSystems.insert(0, _selectedAyushSystem);
        }
      }
    }

    // Qualifications
    final grad = doc.graduationDetails;
    _gradUniController = TextEditingController(text: grad?.universityName ?? '');
    _gradYearController = TextEditingController(
        text: grad?.yearOfPassing != null ? grad!.yearOfPassing.toString() : '');

    final high = doc.highestQualification;
    _highDegreeController = TextEditingController(text: high?.degree ?? '');
    _highSpecController = TextEditingController(text: high?.specialization ?? '');
    _highUniController = TextEditingController(text: high?.universityName ?? '');
    _highYearController = TextEditingController(
        text: high?.yearOfPassing != null ? high!.yearOfPassing.toString() : '');

    // Bio & Skills
    _aboutController = TextEditingController(text: doc.about ?? '');
    _philosophyController =
        TextEditingController(text: doc.consultationPhilosophy ?? '');
    _achievementsController = TextEditingController(text: doc.achievements ?? '');

    final areas = doc.expertise?.areasOfExpertise ?? [];
    _expertiseController = TextEditingController(text: areas.join(', '));

    final langs = doc.expertise?.consultationLanguages ?? [];
    _languagesController = TextEditingController(text: langs.join(', '));

    // Bank
    final bank = doc.bankDetails;
    _acHolderController =
        TextEditingController(text: bank?.accountHolderName ?? '');
    _bankNameController = TextEditingController(text: bank?.bankName ?? '');
    _acNumController = TextEditingController(text: bank?.accountNumber ?? '');
    _ifscController = TextEditingController(text: bank?.ifscCode ?? '');
    _panController = TextEditingController(text: bank?.panNumber ?? '');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinCodeController.dispose();
    _regNumController.dispose();
    _stateCouncilController.dispose();
    _expController.dispose();
    _clinicController.dispose();
    _designationController.dispose();
    _gradUniController.dispose();
    _gradYearController.dispose();
    _highDegreeController.dispose();
    _highSpecController.dispose();
    _highUniController.dispose();
    _highYearController.dispose();
    _aboutController.dispose();
    _philosophyController.dispose();
    _achievementsController.dispose();
    _expertiseController.dispose();
    _languagesController.dispose();
    _acHolderController.dispose();
    _bankNameController.dispose();
    _acNumController.dispose();
    _ifscController.dispose();
    _panController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    DateTime initial = DateTime(1990, 1, 1);
    if (_selectedDob != null && _selectedDob!.isNotEmpty) {
      try {
        initial = DateTime.parse(_selectedDob!);
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDob =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _saveProfile() async {
    final token = AppState().doctorToken ?? AppState().activeToken;
    if (token == null || token.isEmpty) {
      debugPrint('[DoctorEditProfileScreen] ERROR: Doctor session token is null or empty!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor token not found. Please log in again.')),
      );
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor name cannot be empty.')),
      );
      _tabController.animateTo(0);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    // Parse expertise and languages
    final expertiseList = _expertiseController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final languagesList = _languagesController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final int? expVal = int.tryParse(_expController.text.trim());

    // Payload strictly matching PATCH /api/doctors/profile
    final Map<String, dynamic> data = {
      'fullName': _nameController.text.trim(),
      'gender': _selectedGender,
      if (_selectedDob != null && _selectedDob!.isNotEmpty)
        'dateOfBirth': _selectedDob,
      'email': _emailController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'pinCode': _pinCodeController.text.trim(),
      'ayushSystem': _selectedAyushSystem,
      'registrationNumber': _regNumController.text.trim(),
      'stateAyushCouncil': _stateCouncilController.text.trim(),
      'graduationDetails': {
        'universityName': _gradUniController.text.trim(),
        'yearOfPassing': _gradYearController.text.trim(),
      },
      'highestQualification': {
        'degree': _highDegreeController.text.trim(),
        'specialization': _highSpecController.text.trim(),
        'universityName': _highUniController.text.trim(),
        'yearOfPassing': _highYearController.text.trim(),
      },
      'totalExperience': expVal ?? 0,
      'currentClinicOrHospital': _clinicController.text.trim(),
      'currentDesignation': _designationController.text.trim(),
      'about': _aboutController.text.trim(),
      'consultationPhilosophy': _philosophyController.text.trim(),
      'achievements': _achievementsController.text.trim(),
      'expertise': {
        'areasOfExpertise': expertiseList,
        'consultationLanguages': languagesList,
      },
      'bankDetails': {
        'accountHolderName': _acHolderController.text.trim(),
        'bankName': _bankNameController.text.trim(),
        'accountNumber': _acNumController.text.trim(),
        'ifscCode': _ifscController.text.trim().toUpperCase(),
        'panNumber': _panController.text.trim().toUpperCase(),
      },
    };

    final res = await DoctorProfileService.updateProfile(
      token: token,
      data: data,
    );

    if (!mounted) return;

    debugPrint('[DoctorEditProfileScreen] Profile update result: success=${res.success}, message=${res.message}');

    setState(() {
      _isSaving = false;
    });

    if (res.success && res.doctor != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message.isNotEmpty
              ? res.message
              : 'Profile updated successfully!'),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, res.doctor);
    } else {
      setState(() {
        _errorMessage = res.message.isNotEmpty
            ? res.message
            : 'Failed to update profile. Please try again.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Edit Doctor Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveProfile,
            icon: _isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check_rounded, color: Colors.white),
            label: Text(
              _isSaving ? 'Saving...' : 'Save',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPersonalForm(),
          _buildProfessionalForm(),
          _buildQualificationsForm(),
          _buildBioForm(),
          _buildBankForm(),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Updating Profile...',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Save Changes',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ── Tab 1: Personal & Contact ──────────────────────────────────────────────
  Widget _buildPersonalForm() {
    return _formScroll([
      _sectionHeader('Contact Details', Icons.contact_mail_outlined),
      _inputField('Full Name *', _nameController, Icons.person_rounded),
      _inputField('Email', _emailController, Icons.email_outlined,
          keyboardType: TextInputType.emailAddress),
      const SizedBox(height: 12),
      _sectionHeader('Personal Info', Icons.badge_outlined),
      _buildGenderSelector(),
      const SizedBox(height: 12),
      _buildDobField(),
      const SizedBox(height: 12),
      _sectionHeader('Address Details', Icons.location_on_outlined),
      _inputField('Street Address', _addressController, Icons.home_outlined),
      Row(
        children: [
          Expanded(
            child: _inputField('City', _cityController, Icons.location_city_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _inputField('State', _stateController, Icons.map_outlined),
          ),
        ],
      ),
      _inputField('Pin Code', _pinCodeController, Icons.pin_outlined,
          keyboardType: TextInputType.number),
    ]);
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 6),
        Row(
          children: ['male', 'female', 'other'].map((g) {
            final isSelected = _selectedGender == g;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: ChoiceChip(
                label: Text(
                  g[0].toUpperCase() + g.substring(1),
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textDark,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: const Color(0xFFF1F5F9),
                onSelected: (val) {
                  if (val) setState(() => _selectedGender = g);
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDobField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date of Birth',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickDob,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cake_rounded, size: 20, color: Color(0xFF64748B)),
                    const SizedBox(width: 10),
                    Text(
                      _selectedDob != null && _selectedDob!.isNotEmpty
                          ? _selectedDob!
                          : 'Select Date of Birth',
                      style: TextStyle(
                        fontSize: 14,
                        color: _selectedDob != null && _selectedDob!.isNotEmpty
                            ? AppColors.textDark
                            : AppColors.textLight,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Tab 2: Professional & AYUSH ────────────────────────────────────────────
  Widget _buildProfessionalForm() {
    return _formScroll([
      _sectionHeader('Medical System', Icons.medical_services_outlined),
      _buildAyushDropdown(),
      const SizedBox(height: 12),
      _inputField('Registration Number', _regNumController, Icons.numbers_rounded),
      _inputField('State AYUSH Council', _stateCouncilController, Icons.account_balance_outlined),
      _inputField('Total Experience (Years)', _expController, Icons.work_outline_rounded,
          keyboardType: TextInputType.number),
      const SizedBox(height: 12),
      _sectionHeader('Practice Location', Icons.local_hospital_outlined),
      _inputField('Current Clinic or Hospital', _clinicController, Icons.local_hospital_rounded),
      _inputField('Current Designation', _designationController, Icons.assignment_ind_outlined),
    ]);
  }

  Widget _buildAyushDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AYUSH System',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedAyushSystem,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
              items: _ayushSystems.map((s) {
                return DropdownMenuItem<String>(
                  value: s,
                  child: Text(s, style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedAyushSystem = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  // ── Tab 3: Qualifications ──────────────────────────────────────────────────
  Widget _buildQualificationsForm() {
    return _formScroll([
      _sectionHeader('Graduation Details', Icons.school_outlined),
      _inputField('Graduation University', _gradUniController, Icons.school_rounded),
      _inputField('Graduation Year of Passing', _gradYearController, Icons.calendar_month_rounded,
          keyboardType: TextInputType.number),
      const SizedBox(height: 16),
      _sectionHeader('Highest Qualification', Icons.workspace_premium_outlined),
      _inputField('Degree (e.g. MD, MS, PhD)', _highDegreeController, Icons.military_tech_outlined),
      _inputField('Specialization (e.g. Panchakarma)', _highSpecController, Icons.science_outlined),
      _inputField('University Name', _highUniController, Icons.account_balance_outlined),
      _inputField('Year of Passing', _highYearController, Icons.calendar_month_rounded,
          keyboardType: TextInputType.number),
    ]);
  }

  // ── Tab 4: Bio, Philosophy & Expertise ─────────────────────────────────────
  Widget _buildBioForm() {
    return _formScroll([
      _sectionHeader('About Doctor', Icons.info_outline_rounded),
      _inputField('About (Summary of practice & background)', _aboutController, Icons.notes_rounded,
          maxLines: 4),
      const SizedBox(height: 12),
      _sectionHeader('Philosophy & Recognition', Icons.psychology_outlined),
      _inputField('Consultation Philosophy', _philosophyController, Icons.format_quote_rounded,
          maxLines: 3),
      _inputField('Achievements & Publications', _achievementsController, Icons.emoji_events_outlined,
          maxLines: 3),
      const SizedBox(height: 12),
      _sectionHeader('Expertise & Languages', Icons.stars_rounded),
      _inputField(
        'Areas of Expertise (Comma-separated)',
        _expertiseController,
        Icons.verified_outlined,
        helperText: 'e.g. Panchakarma, Stress Management, Skin Diseases',
      ),
      _inputField(
        'Consultation Languages (Comma-separated)',
        _languagesController,
        Icons.translate_rounded,
        helperText: 'e.g. Hindi, English, Marathi, Gujarati',
      ),
    ]);
  }

  // ── Tab 5: Bank Details ────────────────────────────────────────────────────
  Widget _buildBankForm() {
    return _formScroll([
      _sectionHeader('Bank Account Information', Icons.account_balance_rounded),
      Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Row(
          children: [
            Icon(Icons.lock_outline_rounded, color: Color(0xFFD97706), size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Bank information is encrypted and strictly used for consultation payouts.',
                style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
              ),
            ),
          ],
        ),
      ),
      _inputField('Account Holder Name', _acHolderController, Icons.person_outline),
      _inputField('Bank Name', _bankNameController, Icons.account_balance_outlined),
      _inputField('Account Number', _acNumController, Icons.numbers_rounded,
          keyboardType: TextInputType.number),
      _inputField('IFSC Code', _ifscController, Icons.qr_code_rounded,
          textCapitalization: TextCapitalization.characters),
      _inputField('PAN Number', _panController, Icons.credit_card_rounded,
          textCapitalization: TextCapitalization.characters),
    ]);
  }

  // ── Shared Helpers ─────────────────────────────────────────────────────────
  Widget _formScroll(List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? helperText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            style: const TextStyle(fontSize: 14, color: AppColors.textDark),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              prefixIcon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
              helperText: helperText,
              helperStyle: const TextStyle(fontSize: 11, color: AppColors.textLight),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
