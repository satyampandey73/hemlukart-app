import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../services/doctor_service.dart';
import 'doctor_profile_screen.dart';

class DoctorListingScreen extends StatefulWidget {
  final String? systemFilter;
  final String? consultationTypeFilter;
  const DoctorListingScreen({
    super.key,
    this.systemFilter,
    this.consultationTypeFilter,
  });

  @override
  State<DoctorListingScreen> createState() => _DoctorListingScreenState();
}

class _DoctorListingScreenState extends State<DoctorListingScreen> {
  final AppState _appState = AppState();
  late String _selectedSystem;
  String _selectedSpecialty = 'All';
  late String _selectedConsultationType;

  bool _isLoading = true;
  String? _errorMessage;
  List<Doctor> _doctorsList = [];

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _systems = ['All', 'Ayurveda', 'Homeopathy', 'Unani'];
  final List<String> _specialties = [
    'All',
    'Ayurvedic Internist',
    'Homeopathy Specialist',
    'Unani Medicine Expert',
  ];
  final List<String> _consultationTypes = ['All', 'Offline', 'Online'];

  @override
  void initState() {
    super.initState();
    _selectedSystem = widget.systemFilter ?? 'All';

    final rawType = (widget.consultationTypeFilter ?? '').toLowerCase();
    if (rawType == 'in_person' || rawType == 'offline' || rawType.contains('person') || rawType.contains('clinic') || rawType.contains('offline')) {
      _selectedConsultationType = 'Offline';
    } else if (rawType == 'online' || rawType == 'video' || rawType.contains('video') || rawType.contains('online')) {
      _selectedConsultationType = 'Online';
    } else {
      _selectedConsultationType = 'All';
    }

    _fetchDoctors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await DoctorService.getAllDoctors(
      system: _selectedSystem != 'All' ? _selectedSystem : null,
    );

    if (!mounted) return;

    if (res.success && res.doctors.isNotEmpty) {
      final initialDocs = res.doctors.map((apiDoc) => Doctor.fromApiDoctor(apiDoc)).toList();
      setState(() {
        _isLoading = false;
        _doctorsList = initialDocs;
      });

      final enriched = await DoctorService.enrichDoctorsWithDetails(res.doctors);
      if (mounted) {
        setState(() {
          _doctorsList = enriched.map((apiDoc) => Doctor.fromApiDoctor(apiDoc)).toList();
        });
      }
    } else if (res.success && res.doctors.isEmpty) {
      setState(() {
        _isLoading = false;
        _doctorsList = [];
      });
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = res.message.isNotEmpty ? res.message : 'Failed to load doctors.';
        _doctorsList = _appState.mockDoctors;
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

  @override
  Widget build(BuildContext context) {
    final filteredDoctors = _doctorsList.where((doc) {
      final matchesSystem =
          _selectedSystem == 'All' || doc.system.toLowerCase().contains(_selectedSystem.toLowerCase());
      final matchesSpecialty =
          _selectedSpecialty == 'All' || doc.specialty.toLowerCase().contains(_selectedSpecialty.toLowerCase());

      bool matchesType = true;
      if (_selectedConsultationType == 'Offline') {
        matchesType = doc.hasInPerson;
      } else if (_selectedConsultationType == 'Online') {
        matchesType = doc.hasOnline;
      }

      // Search filter
      bool matchesSearch = true;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        matchesSearch = doc.name.toLowerCase().contains(q) ||
            doc.specialty.toLowerCase().contains(q) ||
            doc.system.toLowerCase().contains(q);
      }

      return matchesSystem && matchesSpecialty && matchesType && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Find Doctors',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchDoctors,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar ──────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by name, specialty or system...',
                hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textLight, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textLight),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
            ),
          ),

          // ── Filter Chips Section ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 16.0,
            ),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Consultation Mode',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _consultationTypes.map((type) {
                      final isSel = _selectedConsultationType == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(type),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) setState(() => _selectedConsultationType = type);
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppColors.textDark,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Medical System',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _systems.map((system) {
                      final isSel = _selectedSystem == system;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(system),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) {
                              setState(() => _selectedSystem = system);
                              _fetchDoctors();
                            }
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppColors.textDark,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Specialization',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _specialties.map((spec) {
                      final isSel = _selectedSpecialty == spec;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(spec),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) setState(() => _selectedSpecialty = spec);
                          },
                          selectedColor: AppColors.secondary,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : AppColors.textDark,
                            fontSize: 11,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.border),

          // Doctor List View
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchDoctors,
                    child: filteredDoctors.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 100),
                              Center(
                                child: Text(
                                  'No doctors match selected filters.',
                                  style: TextStyle(color: AppColors.textLight),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredDoctors.length,
                            itemBuilder: (context, idx) {
                              final doc = filteredDoctors[idx];
                              return _buildDoctorListItem(doc);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorListItem(Doctor doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar box
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: _getDoctorImageProvider(doc.image),
                    fit: BoxFit.cover,
                    onError: (_, __) {},
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            doc.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textDark,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified,
                          color: AppColors.secondary,
                          size: 16,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${doc.degree} (${doc.system})',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        doc.specialty.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.work_outline,
                          size: 12,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${doc.experienceYears} Years Experience',
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.translate,
                          size: 12,
                          color: AppColors.textLight,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            doc.languages.join(', '),
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedConsultationType == 'Offline'
                        ? 'Offline Fee'
                        : (_selectedConsultationType == 'Online' ? 'Online Fee' : 'Consultation Fee'),
                    style: const TextStyle(color: AppColors.textLight, fontSize: 10),
                  ),
                  Text(
                    '₹${doc.getFeeForType(_selectedConsultationType == 'Offline' ? 'in_person' : (_selectedConsultationType == 'Online' ? 'video' : null)).toInt()}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DoctorProfileScreen(doctor: doc),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'View Profile',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
