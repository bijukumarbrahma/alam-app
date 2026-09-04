import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/alarm_model.dart';
import '../services/alarm_service.dart';
import '../services/permission_service.dart';
import '../services/storage_service.dart';
import '../widgets/digital_clock.dart';
import '../widgets/alarm_card.dart';
import 'add_alarm_screen.dart';
import 'alarm_ring_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<AlarmItem> _alarms = [];
  late StreamSubscription<AlarmSettings> _ringingSubscription;
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadAlarms();
    _listenToAlarms();
    _fabController.forward();

    // Check and request screen-off & exact alarm permissions on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PermissionService.checkAndRequestPermissions(context);
    });
  }

  @override
  void dispose() {
    _ringingSubscription.cancel();
    _fabController.dispose();
    super.dispose();
  }

  void _listenToAlarms() {
    // ignore: deprecated_member_use
    _ringingSubscription = Alarm.ringStream.stream.listen((AlarmSettings alarm) {
      final matchingAlarm =
          _alarms.where((a) => a.id == alarm.id).firstOrNull;
      if (mounted) {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                AlarmRingScreen(
              alarmSettings: alarm,
              alarmItem: matchingAlarm,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          ),
        );
      }
    });
  }

  Future<void> _loadAlarms() async {
    final alarms = await StorageService.getAlarms();
    if (mounted) {
      setState(() => _alarms = alarms);
    }
  }

  Future<void> _toggleAlarm(AlarmItem alarm, bool enabled) async {
    final updated = alarm.copyWith(isEnabled: enabled);
    await StorageService.updateAlarm(updated);

    if (enabled) {
      await AlarmService.setAlarm(updated);
    } else {
      await AlarmService.cancelAlarm(alarm.id);
    }

    await _loadAlarms();
  }

  Future<void> _deleteAlarm(AlarmItem alarm) async {
    await AlarmService.cancelAlarm(alarm.id);
    await StorageService.deleteAlarm(alarm.id);
    await _loadAlarms();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Alarm deleted',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1A1A2E),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _showReliabilityDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.shield_rounded, color: Color(0xFF7C4DFF)),
            const SizedBox(width: 10),
            Text(
              'Screen-Off Reliability',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To ensure your alarms ring even when your phone screen is off or locked:',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            _buildReliabilityStep(
              icon: Icons.battery_alert_rounded,
              title: 'Battery Optimization',
              description:
                  'Disable battery optimization for "Wake Up" so Android doesn\'t kill the alarm in sleep mode.',
            ),
            const SizedBox(height: 12),
            _buildReliabilityStep(
              icon: Icons.alarm_on_rounded,
              title: 'Exact Alarms',
              description: 'Allow exact alarms so your alarm triggers at the exact second.',
            ),
            const SizedBox(height: 12),
            _buildReliabilityStep(
              icon: Icons.notifications_active_rounded,
              title: 'Notifications',
              description:
                  'Allow notifications & full-screen intents so the ring screen pops up over the lock screen.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: GoogleFonts.inter(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await PermissionService.checkAndRequestPermissions(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C4DFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Grant Permissions',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReliabilityStep({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF448AFF), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.inter(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToAddAlarm({AlarmItem? existingAlarm}) async {
    final result = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AddAlarmScreen(existingAlarm: existingAlarm),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );

    if (result == true) {
      await _loadAlarms();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App bar
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF7C4DFF).withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C4DFF).withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/icon.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Wake Up',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Screen-Off Reliability',
                      onPressed: () => _showReliabilityDialog(),
                      icon: const Icon(
                        Icons.battery_charging_full_rounded,
                        color: Color(0xFF7C4DFF),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_alarms.where((a) => a.isEnabled).length} active',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF7C4DFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Digital clock
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: DigitalClock(),
              ),
            ),

            // Section header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'My Alarms',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Alarm list or empty state
            if (_alarms.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              const Color(0xFF7C4DFF).withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          Icons.alarm_add_rounded,
                          size: 48,
                          color:
                              const Color(0xFF7C4DFF).withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No alarms set',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white38,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to create your first alarm',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white24,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final alarm = _alarms[index];
                      return AlarmCard(
                        alarm: alarm,
                        onToggle: (enabled) => _toggleAlarm(alarm, enabled),
                        onTap: () =>
                            _navigateToAddAlarm(existingAlarm: alarm),
                        onDelete: () => _deleteAlarm(alarm),
                      );
                    },
                    childCount: _alarms.length,
                  ),
                ),
              ),

            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(
          parent: _fabController,
          curve: Curves.elasticOut,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C4DFF), Color(0xFF448AFF)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: FloatingActionButton(
            onPressed: () => _navigateToAddAlarm(),
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
