import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../providers/app_state_provider.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.sports, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppConstants.appName,
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          appState.user?.email ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.dashboard_outlined,
              label: 'لوحة التحكم',
              onTap: () => context.go('/dashboard'),
            ),
            _DrawerItem(
              icon: Icons.groups_outlined,
              label: 'الأقسام والتلاميذ',
              onTap: () => context.go('/sections'),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'الإعدادات',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            _DrawerItem(
              icon: Icons.rule_outlined,
              label: 'معايير التقييم',
              onTap: () => context.push('/criteria'),
            ),
            _DrawerItem(
              icon: Icons.bolt_outlined,
              label: 'قواعد النقاط التحفيزية',
              onTap: () => context.push('/motivation-rules'),
            ),
            _DrawerItem(
              icon: Icons.emoji_events_outlined,
              label: 'الشارات والإنجازات',
              onTap: () => context.push('/badges'),
            ),
            const Spacer(),
            const Divider(height: 1),
            _DrawerItem(
              icon: Icons.logout,
              label: 'تسجيل الخروج',
              onTap: () async {
                await appState.signOut();
                if (context.mounted) context.go('/login');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: enabled ? AppColors.textPrimary : Colors.grey),
      title: Text(
        label,
        style: TextStyle(color: enabled ? AppColors.textPrimary : Colors.grey),
      ),
      trailing: enabled
          ? null
          : const Text('قريبًا', style: TextStyle(fontSize: 11, color: Colors.grey)),
      onTap: enabled
          ? () {
              Navigator.of(context).pop();
              onTap();
            }
          : null,
    );
  }
}
