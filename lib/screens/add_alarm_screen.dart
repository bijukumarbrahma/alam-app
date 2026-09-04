import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';
import '../services/audio_picker_service.dart';
import '../services/permission_service.dart';
import '../services/storage_service.dart';
import '../widgets/day_selector.dart';

class AddAlarmScreen extends StatefulWidget {
  final AlarmItem? existingAlarm;

  const AddAlarmScreen({super.key, this.existingAlarm});

  @override
  State<AddAlarmScreen> createState() => _AddAlarmScreenState();
}

class _AddAlarmScreenState extends State<AddAlarmScreen>
    with SingleTickerProviderStateMixin {
  late int _selectedHour;
  late int _selectedMinute;
  late TextEditingController _labelController;
  late List<int> _selectedDays;
  String? _audioPath;
  String? _audioName;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  bool get _isEditing => widget.existingAlarm != null;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    if (_isEditing) {
      _selectedHour = widget.existingAlarm!.hour;
      _selectedMinute = widget.existingAlarm!.minute;
      _labelController =
          TextEditingController(text: widget.existingAlarm!.label);
      _selectedDays = List<int>.from(widget.existingAlarm!.repeatDays);
      _audioPath = widget.existingAlarm!.audioPath;
      _audioName = widget.existingAlarm!.audioName;
    } else {
      final now = DateTime.now();
      _selectedHour = now.hour;
      _selectedMinute = now.minute;
      _labelController = TextEditingController();
      _selectedDays = [];
    }

    _animController.forward();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    final result = await AudioPickerService.pickAudioFile();
    if (result != null) {
      setState(() {
        _audioPath = result.path;
        _audioName = result.name;
      });
    }
  }

  Future<void> _saveAlarm() async {
    // Ensure all critical screen-off permissions are granted
    await PermissionService.checkAndRequestPermissions(context);

    final id = _isEditing
        ? widget.existingAlarm!.id
        : await StorageService.getNextId();

    final alarm = AlarmItem(
      id: id,
      hour: _selectedHour,
      minute: _selectedMinute,
      label: _labelController.text.trim(),
      isEnabled: true,
      audioPath: _audioPath,
      audioName: _audioName,
      repeatDays: _selectedDays,
    );

    if (_isEditing) {
      await AlarmService.cancelAlarm(id);
      await StorageService.updateAlarm(alarm);
    } else {
      await StorageService.addAlarm(alarm);
    }

    await AlarmService.setAlarm(alarm);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Alarm updated!' : 'Alarm set for ${alarm.formattedTime}',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1A1A2E),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: Colors.white70,
                      iconSize: 26,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isEditing ? 'Edit Alarm' : 'New Alarm',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _saveAlarm,
                      style: TextButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Save',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7C4DFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Time Picker
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF7C4DFF)
                                  .withValues(alpha: 0.12),
                              const Color(0xFF448AFF)
                                  .withValues(alpha: 0.06),
                              Colors.transparent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFF7C4DFF)
                                .withValues(alpha: 0.2),
                          ),
                        ),
                        child: SizedBox(
                          height: 200,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Hours wheel
                              _buildWheel(
                                itemCount: 24,
                                selectedValue: _selectedHour,
                                onChanged: (value) =>
                                    setState(() => _selectedHour = value),
                                labelBuilder: (value) {
                                  final h = value % 12 == 0 ? 12 : value % 12;
                                  return h.toString().padLeft(2, '0');
                                },
                              ),
                              Text(
                                ':',
                                style: GoogleFonts.orbitron(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF7C4DFF),
                                ),
                              ),
                              // Minutes wheel
                              _buildWheel(
                                itemCount: 60,
                                selectedValue: _selectedMinute,
                                onChanged: (value) =>
                                    setState(() => _selectedMinute = value),
                                labelBuilder: (value) =>
                                    value.toString().padLeft(2, '0'),
                              ),
                              const SizedBox(width: 16),
                              // AM/PM indicator
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildPeriodButton('AM', _selectedHour < 12),
                                  const SizedBox(height: 8),
                                  _buildPeriodButton('PM', _selectedHour >= 12),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Label
                      _buildSectionTitle('Label'),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: TextField(
                          controller: _labelController,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            hintText: 'e.g., Wake up, Meeting...',
                            hintStyle: GoogleFonts.inter(
                              color: Colors.white24,
                              fontSize: 16,
                            ),
                            prefixIcon: const Icon(
                              Icons.label_outline_rounded,
                              color: Color(0xFF7C4DFF),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Repeat days
                      _buildSectionTitle('Repeat'),
                      const SizedBox(height: 10),
                      DaySelector(
                        selectedDays: _selectedDays,
                        onChanged: (days) =>
                            setState(() => _selectedDays = days),
                      ),

                      const SizedBox(height: 28),

                      // Alarm tone
                      _buildSectionTitle('Alarm Tone'),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _pickAudio,
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF1A1A2E)
                                    .withValues(alpha: 0.9),
                                const Color(0xFF16213E)
                                    .withValues(alpha: 0.9),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _audioName != null
                                  ? const Color(0xFF448AFF)
                                      .withValues(alpha: 0.4)
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF7C4DFF),
                                      Color(0xFF448AFF)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.music_note_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _audioName ?? 'Default Alarm Sound',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _audioName != null
                                          ? 'Custom audio selected'
                                          : 'Tap to select from storage',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: Colors.white38,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                _audioName != null
                                    ? Icons.check_circle_rounded
                                    : Icons.folder_open_rounded,
                                color: _audioName != null
                                    ? const Color(0xFF00E676)
                                    : Colors.white38,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (_audioName != null) ...[
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _audioPath = null;
                              _audioName = null;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Color(0xFFFF5252),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Remove custom tone',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: const Color(0xFFFF5252),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white70,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildWheel({
    required int itemCount,
    required int selectedValue,
    required ValueChanged<int> onChanged,
    required String Function(int) labelBuilder,
  }) {
    final controller =
        FixedExtentScrollController(initialItem: selectedValue);

    return SizedBox(
      width: 80,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 56,
        physics: const FixedExtentScrollPhysics(),
        diameterRatio: 1.5,
        perspective: 0.003,
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (context, index) {
            final isSelected = index == selectedValue;
            return Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.orbitron(
                  fontSize: isSelected ? 40 : 22,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? Colors.white : Colors.white24,
                ),
                child: Text(labelBuilder(index)),
              ),
            );
          },
          childCount: itemCount,
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (label == 'AM' && _selectedHour >= 12) {
            _selectedHour -= 12;
          } else if (label == 'PM' && _selectedHour < 12) {
            _selectedHour += 12;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
                )
              : null,
          color: isActive ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Colors.white38,
          ),
        ),
      ),
    );
  }
}
