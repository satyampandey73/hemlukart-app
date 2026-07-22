import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';

class AppointmentConfirmedScreen extends StatefulWidget {
  final Appointment appointment;
  const AppointmentConfirmedScreen({super.key, required this.appointment});

  @override
  State<AppointmentConfirmedScreen> createState() => _AppointmentConfirmedScreenState();
}

class _AppointmentConfirmedScreenState extends State<AppointmentConfirmedScreen> {
  final List<String> _uploadedFiles = ['blood_test_july_2024.pdf'];

  @override
  Widget build(BuildContext context) {
    final appt = widget.appointment;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight.withOpacity(0.2),
      appBar: AppBar(
        title: const Text('Confirmed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Success Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFFD1FAE5),
                    child: Icon(Icons.check_circle, color: AppColors.secondary, size: 48),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Appointment Confirmed',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your video consultation has been successfully scheduled.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textLight, fontSize: 12),
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // Appointment Details
                  _buildDetailRow('APPOINTMENT ID', appt.id, isAction: true),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: const Icon(Icons.person, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(appt.doctor.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark)),
                            Text(appt.doctor.specialty, style: const TextStyle(color: AppColors.textLight, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildIconDetailRow(Icons.calendar_today_outlined, appt.date),
                  const SizedBox(height: 10),
                  _buildIconDetailRow(Icons.access_time, '${appt.time} (EST)'),
                  const SizedBox(height: 10),
                  _buildIconDetailRow(Icons.video_camera_back_outlined, 'Secure Video Meeting Link'),

                  const SizedBox(height: 24),

                  // Meeting Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Join button will activate 10 minutes prior to session.')),
                        );
                      },
                      icon: const Icon(Icons.video_call, color: AppColors.textLight),
                      label: const Text('Join Meeting (Disabled)', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.border.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'The join button will be active 10 minutes before the session starts.',
                    style: TextStyle(fontSize: 10, color: AppColors.textLight),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Upload Medical Documents
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Upload Medical Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  const Text('Upload your past reports, prescriptions, or files to assist your doctor.', style: TextStyle(color: AppColors.textLight, fontSize: 11)),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _uploadedFiles.add('patient_report_${_uploadedFiles.length + 1}.pdf');
                      });
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mock medical record uploaded successfully!')));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLight.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2), style: BorderStyle.solid),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        children: const [
                          Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 36),
                          SizedBox(height: 8),
                          Text('Medical Reports & Prescriptions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark)),
                          SizedBox(height: 4),
                          Text('Tap to select files (Max 10MB each)', style: TextStyle(color: AppColors.textLight, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),

                  // Uploaded Files list
                  if (_uploadedFiles.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('RECENTLY UPLOADED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
                    const SizedBox(height: 8),
                    Column(
                      children: _uploadedFiles.map((file) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            children: [
                              const Icon(Icons.picture_as_pdf, color: Colors.red, size: 18),
                              const SizedBox(width: 8),
                              Expanded(child: Text(file, style: const TextStyle(fontSize: 12, color: AppColors.textDark))),
                              GestureDetector(
                                onTap: () => setState(() => _uploadedFiles.remove(file)),
                                child: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Next Steps mobile adaptation
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Next Steps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
                  const SizedBox(height: 16),
                  _buildNextStepRow(Icons.check_circle, 'Confirm Appointment', 'Completed via email verification', isDone: true),
                  _buildNextStepRow(Icons.upload_file, 'Upload Medical Records', 'Helps Dr. Sarah understand your history', isDone: false),
                  _buildNextStepRow(Icons.description, 'Pre-consultation Form', 'Quick survey about current symptoms', isDone: false),
                  _buildNextStepRow(Icons.network_check, 'Test Connection', 'Ensure your mic and camera are ready', isDone: false),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Need assistance
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Need Assistance?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  const Text('If you need to reschedule or have technical issues, our support is here 24/7.', style: TextStyle(color: AppColors.textLight, fontSize: 11)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 16),
                          label: const Text('Live Chat', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.mail_outline, color: AppColors.primary, size: 16),
                          label: const Text('Email Support', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.primary)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bottom Navigation back
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Return to Home', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isAction = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textLight)),
        Row(
          children: [
            Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            if (isAction) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(4)),
                child: const Text('Online Consultation', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildIconDetailRow(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textLight, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textDark))),
      ],
    );
  }

  Widget _buildNextStepRow(IconData icon, String title, String desc, {required bool isDone}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: isDone ? AppColors.secondary : AppColors.textLight, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark, decoration: isDone ? TextDecoration.lineThrough : null)),
                Text(desc, style: const TextStyle(color: AppColors.textLight, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
