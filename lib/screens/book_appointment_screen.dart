import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
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

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTime = '10:00 AM';

  final List<String> _morningSlots = ['09:00 AM', '09:15 AM', '09:30 AM', '09:45 AM', '10:00 AM', '10:15 AM'];
  final List<String> _afternoonSlots = ['02:00 PM', '02:15 PM', '02:30 PM', '02:45 PM', '03:00 PM'];

  @override
  Widget build(BuildContext context) {
    final doc = widget.doctor;

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
                          backgroundImage: AssetImage(doc.image.isNotEmpty ? doc.image : 'assets/doctor_profile.png'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
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
                  const Text('Select Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 14,
                      itemBuilder: (context, idx) {
                        final date = DateTime.now().add(Duration(days: idx + 1));
                        final isSel = date.year == _selectedDate.year && date.month == _selectedDate.month && date.day == _selectedDate.day;
                        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedDate = date),
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

                  // Slots Selection
                  const Text('Available Slots', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                  const SizedBox(height: 12),

                  // Morning Header
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
                    children: _morningSlots.map((time) => _buildSlotButton(time)).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Afternoon Header
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
                    children: _afternoonSlots.map((time) => _buildSlotButton(time)).toList(),
                  ),

                  const SizedBox(height: 28),

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
                        const Text('Selected Slot', style: TextStyle(color: AppColors.textLight, fontSize: 11)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, color: AppColors.primary, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '${_getFormattedDate(_selectedDate)} • $_selectedTime',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Consultation Fee: ₹${doc.consultationFee.toInt()}', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
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
                      onPressed: () {
                        // Create appointment
                        _appState.addAppointment(
                          doc,
                          _getFormattedDate(_selectedDate),
                          _selectedTime,
                          _notesController.text,
                        );

                        // Route to confirmation screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AppointmentConfirmedScreen(
                              appointment: _appState.appointments.last,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Continue to Payment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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

  Widget _buildSlotButton(String time) {
    final isSel = _selectedTime == time;
    return GestureDetector(
      onTap: () => setState(() => _selectedTime = time),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14,vertical: 10),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSel ? AppColors.primary : AppColors.border.withOpacity(0.5)),
        ),
        child: Text(
          time,
          style: TextStyle(
            color: isSel ? Colors.white : AppColors.textDark,
            fontSize: 12,
            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
          ),
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
