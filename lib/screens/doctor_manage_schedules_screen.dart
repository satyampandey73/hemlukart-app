import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../models/doctor_schedule_model.dart';
import '../services/doctor_schedule_service.dart';

class DoctorManageSchedulesScreen extends StatefulWidget {
  const DoctorManageSchedulesScreen({super.key});

  @override
  State<DoctorManageSchedulesScreen> createState() =>
      _DoctorManageSchedulesScreenState();
}

class _DoctorManageSchedulesScreenState
    extends State<DoctorManageSchedulesScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Day list
  static const List<String> _daysOfWeek = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  static const Map<String, String> _dayLabels = {
    'monday': 'Monday',
    'tuesday': 'Tuesday',
    'wednesday': 'Wednesday',
    'thursday': 'Thursday',
    'friday': 'Friday',
    'saturday': 'Saturday',
    'sunday': 'Sunday',
  };

  static const Map<String, String> _dayShortLabels = {
    'monday': 'Mon',
    'tuesday': 'Tue',
    'wednesday': 'Wed',
    'thursday': 'Thu',
    'friday': 'Fri',
    'saturday': 'Sat',
    'sunday': 'Sun',
  };

  String _selectedDay = 'monday';

  // Master schedule storage: dayOfWeek -> List<DoctorScheduleItem>
  Map<String, List<DoctorScheduleItem>> _schedulesByDay = {
    'monday': [],
    'tuesday': [],
    'wednesday': [],
    'thursday': [],
    'friday': [],
    'saturday': [],
    'sunday': [],
  };

  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
  }

  Future<void> _fetchSchedules() async {
    final token = AppState().doctorToken;
    if (token == null || token.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Doctor session not found. Please log in again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await DoctorScheduleService.getMySchedules(token: token);
      if (!mounted) return;

      if (res.success) {
        final grouped = res.groupedByDay;
        // Ensure all 7 days have an entry
        final Map<String, List<DoctorScheduleItem>> initialized = {};
        for (var day in _daysOfWeek) {
          initialized[day] = List.from(grouped[day] ?? []);
        }

        setState(() {
          _schedulesByDay = initialized;
          _isLoading = false;
          _hasUnsavedChanges = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          // If no schedule exists yet, we initialize empty list for each day
          _schedulesByDay = {for (var d in _daysOfWeek) d: []};
          _errorMessage = res.message.isNotEmpty ? res.message : null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Network error fetching schedule: $e';
      });
    }
  }

  List<DoctorScheduleItem> _flattenSchedules() {
    final List<DoctorScheduleItem> all = [];
    for (var day in _daysOfWeek) {
      all.addAll(_schedulesByDay[day] ?? []);
    }
    return all;
  }

  Future<void> _saveSchedulesToApi() async {
    final token = AppState().doctorToken;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in again to save schedules.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final allItems = _flattenSchedules();

    try {
      final res = await DoctorScheduleService.saveSchedules(
        token: token,
        schedules: allItems,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (res.success) {
        setState(() => _hasUnsavedChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF059669),
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Schedules saved successfully!'),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text(res.message.isNotEmpty
                ? res.message
                : 'Failed to save schedules.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Text('Error saving schedules: $e'),
        ),
      );
    }
  }

  void _addOrEditSession({DoctorScheduleItem? existingItem, int? editIndex}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SessionEditorModal(
        dayOfWeek: _selectedDay,
        initialItem: existingItem,
        onSave: (newItem) {
          setState(() {
            _hasUnsavedChanges = true;
            final list = _schedulesByDay[_selectedDay] ?? [];
            if (editIndex != null && editIndex >= 0 && editIndex < list.length) {
              list[editIndex] = newItem;
            } else {
              list.add(newItem);
            }
            _schedulesByDay[_selectedDay] = list;
          });
        },
      ),
    );
  }

  void _deleteSession(int index) {
    setState(() {
      _hasUnsavedChanges = true;
      _schedulesByDay[_selectedDay]?.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 2),
        content: Text('Session removed. Tap Save to apply.'),
      ),
    );
  }

  void _showCopyDayDialog() {
    final currentDaySessions = _schedulesByDay[_selectedDay] ?? [];
    if (currentDaySessions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'No sessions in ${_dayLabels[_selectedDay]} to copy. Add sessions first.'),
        ),
      );
      return;
    }

    final targetDays = Set<String>.from(_daysOfWeek)
      ..remove(_selectedDay);
    final selectedTargets = <String>{};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.copy_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Copy ${_dayLabels[_selectedDay]} Schedule',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Replicate ${_dayLabels[_selectedDay]}\'s ${currentDaySessions.length} session(s) to:',
                    style: const TextStyle(fontSize: 13, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          setDialogState(() {
                            selectedTargets.clear();
                            selectedTargets.addAll([
                              'monday',
                              'tuesday',
                              'wednesday',
                              'thursday',
                              'friday',
                            ]..remove(_selectedDay));
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('All Weekdays', style: TextStyle(fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          setDialogState(() {
                            selectedTargets.clear();
                            selectedTargets.addAll(targetDays);
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('All Days', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: targetDays.map((d) {
                          final isChecked = selectedTargets.contains(d);
                          return CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(_dayLabels[d] ?? d,
                                style: const TextStyle(fontSize: 14)),
                            value: isChecked,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  selectedTargets.add(d);
                                } else {
                                  selectedTargets.remove(d);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selectedTargets.isEmpty
                    ? null
                    : () {
                        setState(() {
                          _hasUnsavedChanges = true;
                          for (var target in selectedTargets) {
                            _schedulesByDay[target] = currentDaySessions
                                .map((s) => s.copyWith(dayOfWeek: target))
                                .toList();
                          }
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF059669),
                            content: Text(
                                'Copied to ${selectedTargets.length} day(s). Tap Save to apply.'),
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('Apply Copy',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime12(String hhmm) {
    if (hhmm.isEmpty) return 'N/A';
    try {
      final parts = hhmm.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int min = int.parse(parts[1]);
        final period = hour >= 12 ? 'PM' : 'AM';
        final displayHour = hour % 12 == 0 ? 12 : hour % 12;
        final displayMin = min.toString().padLeft(2, '0');
        return '$displayHour:$displayMin $period';
      }
    } catch (_) {}
    return hhmm;
  }

  Color _sessionColor(String name) {
    switch (name.toLowerCase()) {
      case 'morning':
        return const Color(0xFFEA580C);
      case 'afternoon':
        return const Color(0xFFD97706);
      case 'evening':
        return const Color(0xFF0D9488);
      case 'night':
        return const Color(0xFF4F46E5);
      default:
        return AppColors.primary;
    }
  }

  IconData _sessionIcon(String name) {
    switch (name.toLowerCase()) {
      case 'morning':
        return Icons.wb_sunny_outlined;
      case 'afternoon':
        return Icons.wb_twilight_outlined;
      case 'evening':
        return Icons.nights_stay_outlined;
      case 'night':
        return Icons.bedtime_outlined;
      default:
        return Icons.access_time_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentDaySessions = _schedulesByDay[_selectedDay] ?? [];
    final totalSessionsCount = _flattenSchedules().length;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage Schedules',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            Text(
              'Set consultation timings & fees',
              style: TextStyle(color: Color(0xFFCCFBF1), fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh Schedules',
            onPressed: _fetchSchedules,
          ),
          if (_hasUnsavedChanges)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Unsaved',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16),
                  Text('Loading consultation schedules...',
                      style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 56, color: Color(0xFFDC2626)),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.textDark, fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _fetchSchedules,
                          icon: const Icon(Icons.refresh_rounded,
                              color: Colors.white),
                          label: const Text('Retry',
                              style: TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
              children: [
                // Top Info & Summary Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$totalSessionsCount Active Session${totalSessionsCount == 1 ? '' : 's'} Configured',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Patients can book appointment slots accordingly.',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _showCopyDayDialog,
                        icon: const Icon(Icons.copy_all_rounded, size: 16),
                        label: const Text('Replicate', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Days of week selector bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: _daysOfWeek.map((day) {
                      final isSelected = _selectedDay == day;
                      final count = _schedulesByDay[day]?.length ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => setState(() => _selectedDay = day),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : const Color(0xFFE2E8F0),
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.25),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _dayShortLabels[day] ?? day,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.textDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white24
                                        : (count > 0
                                            ? const Color(0xFFECFDF5)
                                            : const Color(0xFFF1F5F9)),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    count > 0 ? '$count slots' : 'Off',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : (count > 0
                                              ? const Color(0xFF059669)
                                              : AppColors.textLight),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 12),

                // Sessions Header for Selected Day
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_dayLabels[_selectedDay]} Schedule',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _addOrEditSession(),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text(
                          'Add Session',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Session list or empty state
                Expanded(
                  child: currentDaySessions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.event_busy_rounded,
                                  size: 48,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'No sessions on ${_dayLabels[_selectedDay]}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Tap below to add morning, evening, or custom slots.',
                                style: TextStyle(
                                    color: AppColors.textLight, fontSize: 12),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _addOrEditSession(),
                                icon: const Icon(Icons.add_rounded,
                                    color: Colors.white, size: 18),
                                label: const Text('Add First Session',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 11),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 80),
                          itemCount: currentDaySessions.length,
                          itemBuilder: (context, index) {
                            final item = currentDaySessions[index];
                            final sessionCol = _sessionColor(item.sessionName);
                            final sessionIc = _sessionIcon(item.sessionName);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: item.isAvailable
                                      ? const Color(0xFFE2E8F0)
                                      : const Color(0xFFCBD5E1),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        // Session icon
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: sessionCol.withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(sessionIc,
                                              color: sessionCol, size: 22),
                                        ),
                                        const SizedBox(width: 12),
                                        // Session name & Timing
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    '${item.sessionName[0].toUpperCase()}${item.sessionName.substring(1)} Session',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      color: AppColors.textDark,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  if (!item.isAvailable)
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                          horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFF1F5F9),
                                                        borderRadius:
                                                            BorderRadius.circular(6),
                                                      ),
                                                      child: const Text(
                                                        'PAUSED',
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.bold,
                                                          color: AppColors.textLight,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${_formatTime12(item.startTime)} - ${_formatTime12(item.endTime)}',
                                                style: TextStyle(
                                                  color: item.isAvailable
                                                      ? const Color(0xFF0F172A)
                                                      : AppColors.textLight,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Quick Availability Toggle
                                        Switch(
                                          value: item.isAvailable,
                                          activeColor: AppColors.primary,
                                          onChanged: (val) {
                                            setState(() {
                                              _hasUnsavedChanges = true;
                                              _schedulesByDay[_selectedDay]![
                                                  index] = item.copyWith(
                                                isAvailable: val,
                                              );
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                                  // Session Details Bar (Duration, Type, Fee & Action buttons)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Duration chip
                                                _infoChip(
                                                  Icons.timer_outlined,
                                                  '${item.slotDuration} min',
                                                  const Color(0xFF0284C7),
                                                  const Color(0xFFF0F9FF),
                                                ),
                                                const SizedBox(width: 6),
                                                // Type chip
                                                _infoChip(
                                                  item.consultationType.toLowerCase() ==
                                                          'video'
                                                      ? Icons.videocam_outlined
                                                      : Icons.location_on_outlined,
                                                  item.consultationType.toUpperCase(),
                                                  const Color(0xFF7C3AED),
                                                  const Color(0xFFF5F3FF),
                                                ),
                                                const SizedBox(width: 6),
                                                // Fee chip
                                                _infoChip(
                                                  Icons.currency_rupee_rounded,
                                                  '${item.consultationFee.toInt()}',
                                                  const Color(0xFF059669),
                                                  const Color(0xFFECFDF5),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Edit
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined,
                                              size: 18, color: AppColors.primary),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          tooltip: 'Edit Session',
                                          onPressed: () => _addOrEditSession(
                                            existingItem: item,
                                            editIndex: index,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Delete
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                              color: Color(0xFFDC2626)),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          tooltip: 'Delete Session',
                                          onPressed: () => _deleteSession(index),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      // Sticky Bottom Save Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveSchedulesToApi,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Save & Sync Schedules',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(
      IconData icon, String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal sheet for creating/updating a single session
class _SessionEditorModal extends StatefulWidget {
  final String dayOfWeek;
  final DoctorScheduleItem? initialItem;
  final ValueChanged<DoctorScheduleItem> onSave;

  const _SessionEditorModal({
    required this.dayOfWeek,
    this.initialItem,
    required this.onSave,
  });

  @override
  State<_SessionEditorModal> createState() => _SessionEditorModalState();
}

class _SessionEditorModalState extends State<_SessionEditorModal> {
  late String _sessionName;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late int _slotDuration;
  late String _consultationType;
  late TextEditingController _feeController;
  late bool _isAvailable;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _sessionName = item?.sessionName ?? 'morning';
    _startTime = _parseTime(item?.startTime ?? '09:00');
    _endTime = _parseTime(item?.endTime ?? '13:00');
    _slotDuration = item?.slotDuration ?? 30;
    _consultationType = item?.consultationType ?? 'video';
    _feeController =
        TextEditingController(text: item?.consultationFee.toString() ?? '500');
    _isAvailable = item?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _feeController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String hhmm) {
    try {
      final parts = hhmm.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _formatTime24(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatTime12(TimeOfDay t) {
    final period = t.hour >= 12 ? 'PM' : 'AM';
    final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final min = t.minute.toString().padLeft(2, '0');
    return '$hour:$min $period';
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modal Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.initialItem == null
                      ? 'Add Consultation Session'
                      : 'Edit Consultation Session',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Session Name Dropdown
            const Text('Session Name',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFCBD5E1)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sessionName,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                        value: 'morning', child: Text('🌅 Morning Session')),
                    DropdownMenuItem(
                        value: 'afternoon', child: Text('☀️ Afternoon Session')),
                    DropdownMenuItem(
                        value: 'evening', child: Text('🌆 Evening Session')),
                    DropdownMenuItem(
                        value: 'night', child: Text('🌙 Night Session')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _sessionName = val);
                  },
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Start Time & End Time Pickers
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start Time',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickStartTime,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                _formatTime12(_startTime),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('End Time',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickEndTime,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                _formatTime12(_endTime),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Slot Duration & Consultation Type
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Slot Duration',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _slotDuration,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(value: 15, child: Text('15 min')),
                              DropdownMenuItem(value: 20, child: Text('20 min')),
                              DropdownMenuItem(value: 30, child: Text('30 min')),
                              DropdownMenuItem(value: 45, child: Text('45 min')),
                              DropdownMenuItem(value: 60, child: Text('60 min')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _slotDuration = val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Type',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _consultationType,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem(
                                  value: 'video', child: Text('📹 Video')),
                              DropdownMenuItem(
                                  value: 'in_person',
                                  child: Text('🏥 In-Person')),
                              DropdownMenuItem(
                                  value: 'audio', child: Text('📞 Audio')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _consultationType = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Consultation Fee
            const Text('Consultation Fee (₹)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: _feeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 18),
                hintText: 'e.g. 500',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Available toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available for Booking',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Switch(
                  value: _isAvailable,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _isAvailable = val),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final fee = double.tryParse(_feeController.text.trim()) ?? 500;
                  final newItem = DoctorScheduleItem(
                    id: widget.initialItem?.id,
                    doctorId: widget.initialItem?.doctorId,
                    clinicId: widget.initialItem?.clinicId,
                    dayOfWeek: widget.dayOfWeek,
                    sessionName: _sessionName,
                    startTime: _formatTime24(_startTime),
                    endTime: _formatTime24(_endTime),
                    slotDuration: _slotDuration,
                    consultationType: _consultationType,
                    consultationFee: fee,
                    isAvailable: _isAvailable,
                  );

                  widget.onSave(newItem);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.initialItem == null ? 'Add Session' : 'Update Session',
                  style: const TextStyle(
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
  }
}
