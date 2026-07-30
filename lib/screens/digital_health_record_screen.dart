import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';

class DigitalHealthRecordScreen extends StatelessWidget {
  const DigitalHealthRecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> healthRecords = [
      {
        'title': 'General Blood Report',
        'date': 'July 10, 2026',
        'lab': 'Dr. Lal PathLabs',
        'status': 'Normal',
        'type': 'Lab Report',
        'color': AppColors.success,
        'icon': Icons.bloodtype_outlined,
      },
      {
        'title': 'Chest X-Ray Diagnostic',
        'date': 'June 15, 2026',
        'lab': 'Apollo Diagnostic Center',
        'status': 'Completed',
        'type': 'Radiology',
        'color': Colors.blue,
        'icon': Icons.image_outlined,
      },
      {
        'title': 'Ayurvedic Consultation Rx',
        'date': 'June 02, 2026',
        'lab': 'Dr. Amit Sharma (BAMS)',
        'status': 'Active',
        'type': 'Prescription',
        'color': AppColors.primary,
        'icon': Icons.description_outlined,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Digital Health Records', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Patient Health Profile Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children:  [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.favorite, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppState().currentUser?.fullName ?? 'User Profile',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: ${AppState().currentUser?.id.substring(0, 8).toUpperCase() ?? 'MHR-8890251'}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildProfileStat('Blood Group', 'O+'),
                      _buildProfileStat('Weight', '72 kg'),
                      _buildProfileStat('Height', '178 cm'),
                      _buildProfileStat('Age', '28 yrs'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Live Vitals Section
            const Text(
              'Recent Vitals',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildVitalCard(
                    'Heart Rate',
                    '72 bpm',
                    'Normal',
                    Icons.favorite,
                    Colors.red[400]!,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildVitalCard(
                    'Blood Pressure',
                    '120/80',
                    'Optimal',
                    Icons.speed,
                    Colors.blue[400]!,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent Reports List Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Medical Records',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.filter_list, size: 14, color: AppColors.primary),
                  label: const Text('Filter', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Column(
              children: healthRecords.map((rec) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: rec['color'].withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(rec['icon'], color: rec['color'], size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rec['title'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${rec['lab']} • ${rec['date']}',
                              style: const TextStyle(color: AppColors.textLight, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: rec['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              rec['status'],
                              style: TextStyle(color: rec['color'], fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 6),
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Opening ${rec['title']} details...')),
                              );
                            },
                            child: Row(
                              children: const [
                                Text('View', style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                                Icon(Icons.arrow_right_alt, color: AppColors.primary, size: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Upload Document dashed box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.3), style: BorderStyle.solid), // dashed style fallback
              ),
              child: Column(
                children: [
                  Icon(Icons.cloud_upload_outlined, size: 36, color: AppColors.primary.withOpacity(0.8)),
                  const SizedBox(height: 10),
                  const Text(
                    'Upload New Medical Record',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Supports PDF, JPG, PNG up to 10MB',
                    style: TextStyle(color: AppColors.textLight, fontSize: 10),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Select file to upload')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text(
                      'Browse Files',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
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

  Widget _buildProfileStat(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 9),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildVitalCard(String title, String val, String status, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.textLight, fontSize: 9)),
                const SizedBox(height: 2),
                Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(status, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
