import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_state.dart';
import '../models/clinic_model.dart';
import '../models/doctor_schedule_model.dart';
import '../services/clinic_service.dart';
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
  List<ApiClinic> _myClinics = [];
  List<ApiClinic> _associateClinics = [];

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
    _loadClinics();
  }

  Future<void> _loadClinics() async {
    final token = AppState().doctorToken ?? AppState().activeToken ?? '';
    try {
      final results = await Future.wait([
        token.isNotEmpty
            ? ClinicService.getMyClinics(token: token)
            : Future.value(MyClinicsApiResponse(success: false, clinics: [])),
        ClinicService.getClinics(limit: 100),
      ]);
      final myRes = results[0] as MyClinicsApiResponse;
      final allRes = results[1] as ClinicsApiResponse;

      if (!mounted) return;

      final myClinicsList = myRes.success ? myRes.clinics : <ApiClinic>[];
      final myIds = myClinicsList.map((c) => c.id).toSet();
      final associateClinicsList = allRes.success
          ? allRes.clinics.where((c) => !myIds.contains(c.id)).toList()
          : <ApiClinic>[];

      setState(() {
        _myClinics = myClinicsList;
        _associateClinics = associateClinicsList;
      });
    } catch (_) {}
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
        // Re-fetch from server to keep UI in sync with persisted data
        await _fetchSchedules();
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
        existingDaySessions: _schedulesByDay[_selectedDay] ?? [],
        myClinics: _myClinics,
        associateClinics: _associateClinics,
        onSave: (newItem) async {
          return await _handleSaveSession(
            newItem: newItem,
            existingItem: existingItem,
            editIndex: editIndex,
          );
        },
      ),
    );
  }

  Future<String?> _handleSaveSession({
    required DoctorScheduleItem newItem,
    DoctorScheduleItem? existingItem,
    int? editIndex,
  }) async {
    final token = AppState().doctorToken;
    if (token == null || token.isEmpty) {
      return 'Doctor session not found. Please log in again.';
    }

    final scheduleId = existingItem?.id ?? newItem.id;

    // 1. UPDATE EXISTING SCHEDULE BY ID (PUT /api/schedules/:id)
    if (existingItem != null && scheduleId != null && scheduleId.isNotEmpty) {
      setState(() => _isSaving = true);
      final res = await DoctorScheduleService.updateScheduleById(
        token: token,
        scheduleId: scheduleId,
        schedule: newItem,
      );

      if (!mounted) return res.message.isNotEmpty ? res.message : 'Failed to update session.';
      setState(() => _isSaving = false);

      if (res.success) {
        if (editIndex != null &&
            editIndex >= 0 &&
            editIndex < (_schedulesByDay[_selectedDay]?.length ?? 0)) {
          setState(() {
            _schedulesByDay[_selectedDay]![editIndex] = newItem.copyWith(id: scheduleId);
            _hasUnsavedChanges = false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Session updated successfully!',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
        await _fetchSchedules();
        return null;
      } else {
        return res.message.isNotEmpty ? res.message : 'Failed to update session.';
      }
    }

    // 2. CREATE NEW SCHEDULE (POST /api/schedules)
    setState(() => _isSaving = true);
    final res = await DoctorScheduleService.createSchedules(
      token: token,
      schedules: [newItem],
    );

    if (!mounted) return res.message.isNotEmpty ? res.message : 'Failed to save session.';
    setState(() => _isSaving = false);

    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Session added successfully!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
      await _fetchSchedules();
      return null;
    } else {
      return res.message.isNotEmpty ? res.message : 'Failed to save session.';
    }
  }

  Future<void> _handleToggleAvailability(int index, bool val) async {
    final currentDayList = _schedulesByDay[_selectedDay];
    if (currentDayList == null || index < 0 || index >= currentDayList.length) return;

    final originalItem = currentDayList[index];
    if (originalItem.isAvailable == val) return;

    final updatedItem = originalItem.copyWith(isAvailable: val);

    // 1. Optimistic instant UI update
    setState(() {
      currentDayList[index] = updatedItem;
    });

    final token = AppState().doctorToken;
    if (token == null || token.isEmpty) {
      // Revert if no token
      setState(() {
        currentDayList[index] = originalItem;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFFDC2626),
          content: Text('Doctor session not found. Please log in again.'),
        ),
      );
      return;
    }

    try {
      final scheduleId = originalItem.id;
      if (scheduleId != null && scheduleId.isNotEmpty) {
        final res = await DoctorScheduleService.updateScheduleById(
          token: token,
          scheduleId: scheduleId,
          schedule: updatedItem,
        );
        if (!res.success) {
          // Revert optimistic update on failure
          if (mounted) {
            setState(() {
              currentDayList[index] = originalItem;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFFDC2626),
                behavior: SnackBarBehavior.floating,
                content: Text(res.message.isNotEmpty
                    ? res.message
                    : 'Failed to update availability.'),
              ),
            );
          }
        }
      } else {
        // Fallback if no backend ID: bulk sync without full page reload
        final allItems = _flattenSchedules();
        final res = await DoctorScheduleService.saveSchedules(
          token: token,
          schedules: allItems,
          isUpdate: true,
        );
        if (!res.success) {
          if (mounted) {
            setState(() {
              currentDayList[index] = originalItem;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFFDC2626),
                behavior: SnackBarBehavior.floating,
                content: Text(res.message.isNotEmpty
                    ? res.message
                    : 'Failed to update availability.'),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          currentDayList[index] = originalItem;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            content: Text('Error updating availability: $e'),
          ),
        );
      }
    }
  }

  Future<void> _deleteSession(int index) async {
    final currentDayList = _schedulesByDay[_selectedDay] ?? [];
    if (index < 0 || index >= currentDayList.length) return;
    final itemToDelete = currentDayList[index];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Session', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete this session (${itemToDelete.startTime} - ${itemToDelete.endTime})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final token = AppState().doctorToken;
    if (token == null || token.isEmpty) return;

    setState(() => _isSaving = true);

    // If item has a backend ID, call DELETE /api/schedules/:id directly
    if (itemToDelete.id != null && itemToDelete.id!.isNotEmpty) {
      final res = await DoctorScheduleService.deleteScheduleById(
        token: token,
        scheduleId: itemToDelete.id!,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (res.success) {
        setState(() {
          _schedulesByDay[_selectedDay]?.removeAt(index);
          _hasUnsavedChanges = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            content: Text('Session deleted successfully!'),
          ),
        );
        await _fetchSchedules();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            content: Text(res.message.isNotEmpty ? res.message : 'Failed to delete session.'),
          ),
        );
      }
    } else {
      // If item was newly created locally without an ID, remove and bulk-sync
      final Map<String, List<DoctorScheduleItem>> updatedMap = {};
      for (var day in _daysOfWeek) {
        updatedMap[day] = List.from(_schedulesByDay[day] ?? []);
      }
      updatedMap[_selectedDay]?.removeAt(index);

      final List<DoctorScheduleItem> allItems = [];
      for (var day in _daysOfWeek) {
        allItems.addAll(updatedMap[day] ?? []);
      }

      final res = await DoctorScheduleService.saveSchedules(
        token: token,
        schedules: allItems,
        isUpdate: true,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      if (res.success) {
        setState(() {
          _schedulesByDay = updatedMap;
          _hasUnsavedChanges = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            content: Text('Session deleted successfully!'),
          ),
        );
        await _fetchSchedules();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            content: Text(res.message.isNotEmpty ? res.message : 'Failed to delete session.'),
          ),
        );
      }
    }
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
                    : () async {
                        final Map<String, List<DoctorScheduleItem>> updatedMap = {};
                        for (var day in _daysOfWeek) {
                          updatedMap[day] = List.from(_schedulesByDay[day] ?? []);
                        }
                        for (var target in selectedTargets) {
                          updatedMap[target] = currentDaySessions
                              .map((s) => s.copyWith(dayOfWeek: target))
                              .toList();
                        }
                        Navigator.pop(ctx);

                        final token = AppState().doctorToken;
                        if (token == null || token.isEmpty) return;

                        final List<DoctorScheduleItem> allItems = [];
                        for (var day in _daysOfWeek) {
                          allItems.addAll(updatedMap[day] ?? []);
                        }

                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        setState(() => _isSaving = true);
                        final res = await DoctorScheduleService.saveSchedules(
                          token: token,
                          schedules: allItems,
                          isUpdate: true,
                        );
                        if (!mounted) return;
                        setState(() => _isSaving = false);

                        if (res.success) {
                          setState(() {
                            _schedulesByDay = updatedMap;
                            _hasUnsavedChanges = false;
                          });
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF059669),
                              behavior: SnackBarBehavior.floating,
                              content: Text('Replicated to ${selectedTargets.length} day(s) & saved!'),
                            ),
                          );
                          _fetchSchedules();
                        } else {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFFDC2626),
                              behavior: SnackBarBehavior.floating,
                              content: Text(res.message.isNotEmpty
                                  ? res.message
                                  : 'Failed to replicate schedules.'),
                            ),
                          );
                        }
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

  String _formatSessionDisplayName(String sessionName) {
    final raw = sessionName.trim();
    if (raw.isEmpty) return 'Consultation Session';
    final parts = raw.split('_');
    final base = parts[0];
    final capitalized = base.isNotEmpty
        ? '${base[0].toUpperCase()}${base.substring(1)}'
        : 'Session';

    if (parts.length > 1 && parts[1].length >= 4) {
      final hh = parts[1].substring(0, 2);
      final mm = parts[1].substring(2, 4);
      final hour = int.tryParse(hh) ?? 0;
      final period = hour >= 12 ? 'PM' : 'AM';
      final h12 = hour % 12 == 0 ? 12 : hour % 12;
      return '$capitalized Session ($h12:$mm $period)';
    }
    return '$capitalized Session';
  }

  Color _sessionColor(String name) {
    final s = name.toLowerCase();
    if (s.contains('morning')) return const Color(0xFFEA580C);
    if (s.contains('afternoon')) return const Color(0xFFD97706);
    if (s.contains('evening')) return const Color(0xFF0D9488);
    if (s.contains('night')) return const Color(0xFF4F46E5);
    return AppColors.primary;
  }

  IconData _sessionIcon(String name) {
    final s = name.toLowerCase();
    if (s.contains('morning')) return Icons.wb_sunny_outlined;
    if (s.contains('afternoon')) return Icons.wb_twilight_outlined;
    if (s.contains('evening')) return Icons.nights_stay_outlined;
    if (s.contains('night')) return Icons.bedtime_outlined;
    return Icons.access_time_rounded;
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
                                                  Flexible(
                                                    child: Text(
                                                      _formatSessionDisplayName(item.sessionName),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                        color: AppColors.textDark,
                                                      ),
                                                    ),
                                                  ),
                                                  if (!item.isAvailable) ...[
                                                    const SizedBox(width: 8),
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
                                          activeThumbColor: AppColors.primary,
                                          activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                                          onChanged: (val) => _handleToggleAvailability(index, val),
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
                                                if (item.clinicId != null && item.clinicId!.trim().isNotEmpty) ...[
                                                  const SizedBox(width: 6),
                                                  Builder(builder: (context) {
                                                    final all = [..._myClinics, ..._associateClinics];
                                                    final clinic = all.firstWhere(
                                                      (c) => c.id == item.clinicId,
                                                      orElse: () => ApiClinic(id: '', clinicName: 'Clinic'),
                                                    );
                                                    final cName = clinic.clinicName.isNotEmpty ? clinic.clinicName : 'Clinic';
                                                    return _infoChip(
                                                      Icons.local_hospital_outlined,
                                                      cName,
                                                      const Color(0xFF0D9488),
                                                      const Color(0xFFF0FDFA),
                                                    );
                                                  }),
                                                ],
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
  final List<DoctorScheduleItem> existingDaySessions;
  final List<ApiClinic>? myClinics;
  final List<ApiClinic>? associateClinics;
  final Future<String?> Function(DoctorScheduleItem newItem) onSave;

  const _SessionEditorModal({
    required this.dayOfWeek,
    this.initialItem,
    required this.existingDaySessions,
    this.myClinics,
    this.associateClinics,
    required this.onSave,
  });

  @override
  State<_SessionEditorModal> createState() => _SessionEditorModalState();
}

class _SessionEditorModalState extends State<_SessionEditorModal> {
  late String _baseShift;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late int _slotDuration;
  late String _consultationType;
  late TextEditingController _feeController;
  late bool _isAvailable;
  bool _isSaving = false;
  String? _modalError;

  String? _selectedClinicId;
  List<ApiClinic> _myClinics = [];
  List<ApiClinic> _associateClinics = [];
  bool _isLoadingClinics = false;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    _baseShift = _detectBaseShift(item?.sessionName ?? 'morning');
    _startTime = _parseTime(item?.startTime ?? '09:00');
    _endTime = _parseTime(item?.endTime ?? '13:00');
    _slotDuration = item?.slotDuration ?? 30;

    final rawType = (item?.consultationType ?? 'video').toLowerCase().trim();
    if (rawType == 'online') {
      _consultationType = 'video';
    } else if (rawType == 'offline' || rawType == 'clinic') {
      _consultationType = 'in_person';
    } else if (['video', 'in_person', 'audio'].contains(rawType)) {
      _consultationType = rawType;
    } else {
      _consultationType = 'video';
    }

    _selectedClinicId = item?.clinicId;

    _feeController = TextEditingController(
      text: item != null
          ? item.consultationFee.toString().replaceAll('.00', '').replaceAll('.0', '')
          : '500',
    );
    _isAvailable = item?.isAvailable ?? true;

    if (widget.myClinics != null &&
        (widget.myClinics!.isNotEmpty || (widget.associateClinics ?? []).isNotEmpty)) {
      _myClinics = List.from(widget.myClinics!);
      _associateClinics = List.from(widget.associateClinics ?? []);
      _ensureInitialClinicSelection();
    } else {
      _fetchClinics();
    }
  }

  void _ensureInitialClinicSelection() {
    if (_consultationType == 'in_person' &&
        (_selectedClinicId == null || _selectedClinicId!.trim().isEmpty)) {
      if (_myClinics.isNotEmpty) {
        _selectedClinicId = _myClinics.first.id;
      } else if (_associateClinics.isNotEmpty) {
        _selectedClinicId = _associateClinics.first.id;
      }
    }
  }

  Future<void> _fetchClinics() async {
    setState(() => _isLoadingClinics = true);
    final token = AppState().doctorToken ?? AppState().activeToken ?? '';
    try {
      final results = await Future.wait([
        token.isNotEmpty
            ? ClinicService.getMyClinics(token: token)
            : Future.value(MyClinicsApiResponse(success: false, clinics: [])),
        ClinicService.getClinics(limit: 100),
      ]);
      final myRes = results[0] as MyClinicsApiResponse;
      final allRes = results[1] as ClinicsApiResponse;

      if (!mounted) return;

      final myClinicsList = myRes.success ? myRes.clinics : <ApiClinic>[];
      final myIds = myClinicsList.map((c) => c.id).toSet();
      final associateClinicsList = allRes.success
          ? allRes.clinics.where((c) => !myIds.contains(c.id)).toList()
          : <ApiClinic>[];

      setState(() {
        _myClinics = myClinicsList;
        _associateClinics = associateClinicsList;
        _isLoadingClinics = false;
        _ensureInitialClinicSelection();
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingClinics = false);
      }
    }
  }

  List<int> get _durationOptions {
    final set = <int>{15, 20, 30, 45, 60, _slotDuration};
    final list = set.toList()..sort();
    return list;
  }

  List<String> get _typeOptions {
    final set = <String>{'video', 'in_person', 'audio', _consultationType};
    return set.toList();
  }

  List<String> get _shiftOptions {
    final set = <String>{'morning', 'afternoon', 'evening', 'night', _baseShift};
    return set.toList();
  }

  String _detectBaseShift(String raw) {
    final s = raw.toLowerCase().trim();
    if (s.contains('afternoon')) return 'afternoon';
    if (s.contains('evening')) return 'evening';
    if (s.contains('night')) return 'night';
    return 'morning';
  }

  String _determineSessionName() {
    // 1. If editing an existing session, preserve its sessionName so the backend updates the existing session!
    if (widget.initialItem != null) {
      final oldName = widget.initialItem!.sessionName.toLowerCase().trim();
      final oldBase = _detectBaseShift(oldName);
      // If user kept the same base shift (e.g. morning is still morning), preserve exact sessionName
      if (_baseShift == oldBase) {
        return widget.initialItem!.sessionName;
      }
      // If user explicitly changed the shift (e.g. from morning to afternoon)
      final bool baseTaken = widget.existingDaySessions.any((s) =>
          s.id != widget.initialItem!.id &&
          s.sessionName.toLowerCase().trim() == _baseShift);
      if (!baseTaken) {
        return _baseShift;
      }
      final hh = _startTime.hour.toString().padLeft(2, '0');
      final mm = _startTime.minute.toString().padLeft(2, '0');
      return '${_baseShift}_$hh$mm';
    }

    // 2. If adding a brand new session:
    // If the base shift (e.g. "morning") is not yet used on this day, use plain "morning"
    final bool isBaseShiftTaken = widget.existingDaySessions.any(
      (s) => s.sessionName.toLowerCase().trim() == _baseShift,
    );

    if (!isBaseShiftTaken) {
      return _baseShift; // e.g. "morning", "afternoon", "evening", "night"
    }

    // If "morning" already exists, append start time to distinguish 2nd session
    final hh = _startTime.hour.toString().padLeft(2, '0');
    final mm = _startTime.minute.toString().padLeft(2, '0');
    final candidate = '${_baseShift}_$hh$mm';

    bool isTaken(String name) => widget.existingDaySessions.any(
      (s) => s.sessionName.toLowerCase().trim() == name.toLowerCase().trim(),
    );

    if (!isTaken(candidate)) {
      return candidate;
    }

    int suffix = 2;
    while (isTaken('${candidate}_$suffix')) {
      suffix++;
    }
    return '${candidate}_$suffix';
  }

  Future<void> _submitSession() async {
    final startMin = _startTime.hour * 60 + _startTime.minute;
    final endMin = _endTime.hour * 60 + _endTime.minute;
    if (endMin <= startMin) {
      setState(() => _modalError = 'End Time must be after Start Time');
      return;
    }

    if (_consultationType == 'in_person') {
      if (_selectedClinicId == null || _selectedClinicId!.trim().isEmpty) {
        setState(() => _modalError = 'Please select a clinic for In-Person consultation');
        return;
      }
    }

    final fee = double.tryParse(_feeController.text.trim()) ?? 500;
    if (fee <= 0) {
      setState(() => _modalError = 'Please enter a valid consultation fee');
      return;
    }

    setState(() {
      _isSaving = true;
      _modalError = null;
    });

    final sessionName = _determineSessionName();

    final newItem = DoctorScheduleItem(
      id: widget.initialItem?.id,
      doctorId: widget.initialItem?.doctorId,
      clinicId: _consultationType == 'in_person' ? _selectedClinicId?.trim() : null,
      dayOfWeek: widget.dayOfWeek,
      sessionName: sessionName,
      startTime: _formatTime24(_startTime),
      endTime: _formatTime24(_endTime),
      slotDuration: _slotDuration,
      consultationType: _consultationType,
      consultationFee: fee,
      isAvailable: _isAvailable,
    );

    final errorMsg = await widget.onSave(newItem);
    if (!mounted) return;

    if (errorMsg == null) {
      Navigator.pop(context);
    } else {
      setState(() {
        _isSaving = false;
        _modalError = errorMsg;
      });
    }
  }

  List<DropdownMenuItem<String>> _buildClinicDropdownItems() {
    final List<DropdownMenuItem<String>> items = [];

    if (_myClinics.isNotEmpty) {
      items.add(
        const DropdownMenuItem<String>(
          enabled: false,
          value: '__hdr_my_clinics__',
          child: Row(
            children: [
              Icon(Icons.home_work_rounded, size: 14, color: AppColors.primary),
              SizedBox(width: 6),
              Text(
                '── MY CLINICS ──',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );
      for (final c in _myClinics) {
        items.add(
          DropdownMenuItem<String>(
            value: c.id,
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                '🏥 ${c.clinicName}${c.city != null && c.city!.trim().isNotEmpty ? " (${c.city!.trim()})" : ""}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      }
    }

    if (_associateClinics.isNotEmpty) {
      items.add(
        const DropdownMenuItem<String>(
          enabled: false,
          value: '__hdr_associate_clinics__',
          child: Row(
            children: [
              Icon(Icons.apartment_rounded, size: 14, color: Color(0xFF2563EB)),
              SizedBox(width: 6),
              Text(
                '── ASSOCIATE CLINICS ──',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );
      for (final c in _associateClinics) {
        items.add(
          DropdownMenuItem<String>(
            value: c.id,
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                '🏥 ${c.clinicName}${c.city != null && c.city!.trim().isNotEmpty ? " (${c.city!.trim()})" : ""}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      }
    }

    return items;
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
                  value: _shiftOptions.contains(_baseShift)
                      ? _baseShift
                      : _shiftOptions.first,
                  isExpanded: true,
                  items: _shiftOptions.map((s) {
                    String label;
                    if (s == 'morning') {
                      label = '🌅 Morning Session';
                    } else if (s == 'afternoon') {
                      label = '☀️ Afternoon Session';
                    } else if (s == 'evening') {
                      label = '🌆 Evening Session';
                    } else if (s == 'night') {
                      label = '🌙 Night Session';
                    } else {
                      label = s.toUpperCase();
                    }
                    return DropdownMenuItem<String>(
                      value: s,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _baseShift = val);
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
                            value: _durationOptions.contains(_slotDuration)
                                ? _slotDuration
                                : _durationOptions.first,
                            isExpanded: true,
                            items: _durationOptions
                                .map((d) => DropdownMenuItem<int>(
                                      value: d,
                                      child: Text('$d min'),
                                    ))
                                .toList(),
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
                            value: _typeOptions.contains(_consultationType)
                                ? _consultationType
                                : _typeOptions.first,
                            isExpanded: true,
                            items: _typeOptions.map((t) {
                              String label;
                              if (t == 'video') {
                                label = '📹 Video';
                              } else if (t == 'in_person') {
                                label = '🏥 In-Person';
                              } else if (t == 'audio') {
                                label = '📞 Audio';
                              } else {
                                label = t.toUpperCase();
                              }
                              return DropdownMenuItem<String>(
                                value: t,
                                child: Text(label),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _consultationType = val;
                                  if (val == 'in_person') {
                                    _ensureInitialClinicSelection();
                                  }
                                });
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

            if (_consultationType == 'in_person') ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Select Clinic',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text('*',
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (_isLoadingClinics)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _modalError != null &&
                            (_selectedClinicId == null ||
                                _selectedClinicId!.isEmpty)
                        ? Colors.red
                        : const Color(0xFFCBD5E1),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    menuMaxHeight: 280,
                    borderRadius: BorderRadius.circular(12),
                    dropdownColor: Colors.white,
                    icon: const Icon(Icons.arrow_drop_down_rounded,
                        color: AppColors.primary, size: 26),
                    value: (_myClinics.any((c) => c.id == _selectedClinicId) ||
                            _associateClinics
                                .any((c) => c.id == _selectedClinicId))
                        ? _selectedClinicId
                        : null,
                    hint: Text(
                      _isLoadingClinics
                          ? 'Loading clinics...'
                          : (_myClinics.isEmpty && _associateClinics.isEmpty
                              ? 'No clinics available'
                              : 'Choose clinic for in-person visits *'),
                      style: const TextStyle(
                          color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                    isExpanded: true,
                    items: _buildClinicDropdownItems(),
                    onChanged: (val) {
                      if (val != null && !val.startsWith('__hdr_')) {
                        setState(() {
                          _selectedClinicId = val;
                          _modalError = null;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],

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
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                  onChanged: (val) => setState(() => _isAvailable = val),
                ),
              ],
            ),

            if (_modalError != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Color(0xFFDC2626), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _modalError!,
                        style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submitSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                    : Text(
                        widget.initialItem == null
                            ? 'Add Session'
                            : 'Update Session',
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
