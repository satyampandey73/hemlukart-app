import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import 'doctor_profile_screen.dart';

class DoctorListingScreen extends StatefulWidget {
  final String? systemFilter;
  const DoctorListingScreen({super.key, this.systemFilter});

  @override
  State<DoctorListingScreen> createState() => _DoctorListingScreenState();
}

class _DoctorListingScreenState extends State<DoctorListingScreen> {
  final AppState _appState = AppState();
  late String _selectedSystem;
  String _selectedSpecialty = 'All';

  final List<String> _systems = ['All', 'Ayurveda', 'Homeopathy', 'Unani'];
  final List<String> _specialties = [
    'All',
    'Ayurvedic Internist',
    'Homeopathy Specialist',
    'Unani Medicine Expert',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSystem = widget.systemFilter ?? 'All';
  }

  @override
  Widget build(BuildContext context) {
    // Filter logic
    final filteredDoctors = _appState.mockDoctors.where((doc) {
      final matchesSystem =
          _selectedSystem == 'All' || doc.system == _selectedSystem;
      final matchesSpecialty =
          _selectedSpecialty == 'All' || doc.specialty == _selectedSpecialty;
      return matchesSystem && matchesSpecialty;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Find Doctors',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Filter Chips Section
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
                            if (val) setState(() => _selectedSystem = system);
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
            child: filteredDoctors.isEmpty
                ? const Center(
                    child: Text('No doctors match selected filters.'),
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
                    image: AssetImage(doc.image.isNotEmpty ? doc.image : 'assets/doctor_profile.png'),
                    fit: BoxFit.cover,
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
                        Text(
                          doc.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textDark,
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
                        Text(
                          doc.languages.join(', '),
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 11,
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
                  const Text(
                    'Consultation Fee',
                    style: TextStyle(color: AppColors.textLight, fontSize: 10),
                  ),
                  Text(
                    '₹${doc.consultationFee.toInt()}',
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
                  // const SizedBox(width: 8),
                  // ElevatedButton(
                  //   onPressed: () {
                  //     Navigator.push(context, MaterialPageRoute(builder: (_) => BookAppointmentScreen(doctor: doc)));
                  //   },
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: AppColors.primary,
                  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  //   ),
                  //   child: const Text('Book Now', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  // ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
