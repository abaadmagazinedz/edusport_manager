import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/student_model.dart';

/// بطاقة بصرية للتلميذ بروح "بطاقة اللاعب" الرياضية — بدل صف بيانات جاف.
/// تُستخدم في قائمة التلاميذ وفي أعلى ملفه الشخصي.
class PlayerCard extends StatelessWidget {
  final Student student;
  final double? attendanceRate; // 0-100، اختياري
  final int? motivationPoints;
  final VoidCallback? onTap;
  final bool compact;

  const PlayerCard({
    super.key,
    required this.student,
    this.attendanceRate,
    this.motivationPoints,
    this.onTap,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: EdgeInsets.all(compact ? 12 : 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [AppColors.secondary, AppColors.primary],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: compact ? 20 : 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  backgroundImage:
                      student.photoUrl != null ? NetworkImage(student.photoUrl!) : null,
                  child: student.photoUrl == null
                      ? Text(
                          student.firstName.isNotEmpty ? student.firstName[0] : '?',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: compact ? 16 : 22),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: compact ? 14 : 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (student.registrationNumber != null)
                        Text(
                          student.registrationNumber!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: compact ? 11 : 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (attendanceRate != null || motivationPoints != null) ...[
              SizedBox(height: compact ? 10 : 16),
              Row(
                children: [
                  if (attendanceRate != null)
                    Expanded(
                      child: _MiniStat(
                        icon: Icons.event_available_outlined,
                        label: 'الحضور',
                        value: '${attendanceRate!.toStringAsFixed(0)}%',
                      ),
                    ),
                  if (motivationPoints != null)
                    Expanded(
                      child: _MiniStat(
                        icon: Icons.bolt_outlined,
                        label: 'النقاط',
                        value: '$motivationPoints',
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.85), size: 16),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
        ),
      ],
    );
  }
}
