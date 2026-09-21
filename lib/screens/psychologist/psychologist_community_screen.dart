import 'package:flutter/material.dart';
import '../community/community_screen.dart';

class PsychologistCommunityScreen extends StatelessWidget {
  final VoidCallback onOpenNotifications;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  const PsychologistCommunityScreen({
    super.key,
    required this.onOpenNotifications,
    required this.onToggleTheme,
    required this.isDarkMode,
  });
  @override
  Widget build(BuildContext context) => CommunityScreen(
    management: true,
    onOpenNotifications: onOpenNotifications,
    onToggleTheme: onToggleTheme,
  );
}
