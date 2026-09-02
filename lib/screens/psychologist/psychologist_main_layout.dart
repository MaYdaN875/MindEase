import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'psychologist_dashboard_screen.dart';
import 'psychologist_schedule_screen.dart';
import 'psychologist_consultations_screen.dart';
import 'psychologist_community_screen.dart';
import 'psychologist_profile_screen.dart';
import 'psychologist_notifications_screen.dart';
import 'psychologist_settings_screen.dart';
import 'psychologist_earnings_screen.dart';
import 'psychologist_stats_screen.dart';

class PsychologistMainLayout extends StatefulWidget {
  final VoidCallback onLogout;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  final Map<String, dynamic>? userProfile;

  const PsychologistMainLayout({
    super.key,
    required this.onLogout,
    required this.onToggleTheme,
    required this.isDarkMode,
    this.userProfile,
  });

  @override
  State<PsychologistMainLayout> createState() => _PsychologistMainLayoutState();
}

class _PsychologistMainLayoutState extends State<PsychologistMainLayout> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PsychologistNotificationsScreen()),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PsychologistSettingsScreen(onLogout: widget.onLogout)),
    );
  }

  void _openEarnings() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PsychologistEarningsScreen()),
    );
  }

  void _openStats() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PsychologistStatsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> screens = [
      PsychologistDashboardScreen(
        onNavigateTab: _onTabTapped,
        onOpenNotifications: _openNotifications,
        onOpenEarnings: _openEarnings,
        onOpenStats: _openStats,
        onCreatePost: () => _onTabTapped(3),
        onToggleTheme: widget.onToggleTheme,
        isDarkMode: widget.isDarkMode,
        userProfile: widget.userProfile,
      ),
      PsychologistScheduleScreen(
        onOpenNotifications: _openNotifications,
        onToggleTheme: widget.onToggleTheme,
        isDarkMode: widget.isDarkMode,
      ),
      PsychologistConsultationsScreen(
        onOpenNotifications: _openNotifications,
        onToggleTheme: widget.onToggleTheme,
        isDarkMode: widget.isDarkMode,
      ),
      PsychologistCommunityScreen(
        onOpenNotifications: _openNotifications,
        onToggleTheme: widget.onToggleTheme,
        isDarkMode: widget.isDarkMode,
      ),
      PsychologistProfileScreen(
        onOpenNotifications: _openNotifications,
        onOpenSettings: _openSettings,
        onLogout: widget.onLogout,
        onToggleTheme: widget.onToggleTheme,
        isDarkMode: widget.isDarkMode,
        userProfile: widget.userProfile,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'Agenda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Consultas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(Icons.group),
              label: 'Community',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
