import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/alarm_model.dart';

class AlarmCard extends StatelessWidget {
  final AlarmItem alarm;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const AlarmCard({
    super.key,
    required this.alarm,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('alarm_${alarm.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.transparent, Color(0xFFFF1744)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: alarm.isEnabled
                  ? [
                      const Color(0xFF1A1A2E).withValues(alpha: 0.9),
                      const Color(0xFF16213E).withValues(alpha: 0.9),
                    ]
                  : [
                      const Color(0xFF0D0D1A).withValues(alpha: 0.6),
                      const Color(0xFF0D0D1A).withValues(alpha: 0.6),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: alarm.isEnabled
                  ? const Color(0xFF7C4DFF).withValues(alpha: 0.3)
                  : Colors.white10,
              width: 1,
            ),
            boxShadow: alarm.isEnabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              // Time & Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alarm.formattedTime,
                      style: GoogleFonts.orbitron(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color:
                            alarm.isEnabled ? Colors.white : Colors.white30,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (alarm.label.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          alarm.label,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: alarm.isEnabled
                                ? Colors.white70
                                : Colors.white24,
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Icon(
                          Icons.repeat_rounded,
                          size: 14,
                          color: alarm.isEnabled
                              ? const Color(0xFF7C4DFF)
                              : Colors.white24,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          alarm.repeatDaysText,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: alarm.isEnabled
                                ? Colors.white54
                                : Colors.white24,
                          ),
                        ),
                        if (alarm.audioName != null) ...[
                          const SizedBox(width: 12),
                          Icon(
                            Icons.music_note_rounded,
                            size: 14,
                            color: alarm.isEnabled
                                ? const Color(0xFF448AFF)
                                : Colors.white24,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              alarm.audioName!,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: alarm.isEnabled
                                    ? Colors.white54
                                    : Colors.white24,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Toggle switch
              Transform.scale(
                scale: 0.9,
                child: Switch(
                  value: alarm.isEnabled,
                  onChanged: onToggle,
                  activeTrackColor:
                      const Color(0xFF7C4DFF).withValues(alpha: 0.4),
                  activeThumbColor: const Color(0xFF7C4DFF),
                  inactiveThumbColor: Colors.white24,
                  inactiveTrackColor: Colors.white10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
