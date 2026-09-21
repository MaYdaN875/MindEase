import 'package:flutter/material.dart';
import 'community/community_screen.dart';
import '../services/appointment_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'patient_appointments_screen.dart';
import 'patient_notifications_screen.dart';
import 'patient_payment_history_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onNavigateToDirectory;
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    required this.onNavigateToDirectory,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedMood;
  final AppointmentService _appointmentService = AppointmentService();
  final NotificationService _notificationService = NotificationService();
  Map<String, dynamic>? _upcomingAppointment;
  bool _isLoadingAppointment = true;
  int _unreadNotifications = 0;

  final List<Map<String, dynamic>> _moods = [
    {'label': 'Great', 'icon': Icons.sentiment_very_satisfied},
    {'label': 'Good', 'icon': Icons.sentiment_satisfied},
    {'label': 'Okay', 'icon': Icons.sentiment_neutral},
    {'label': 'Down', 'icon': Icons.sentiment_dissatisfied},
    {'label': 'Struggling', 'icon': Icons.sentiment_very_dissatisfied},
  ];

  @override
  void initState() {
    super.initState();
    _fetchUpcomingAppointment();
    _fetchNotificationsCount();
  }

  Future<void> _fetchNotificationsCount() async {
    final res = await _notificationService.getMyNotifications(limit: 1);
    if (mounted && res['success'] == true) {
      setState(() {
        _unreadNotifications = res['unreadCount'] ?? 0;
      });
    }
  }

  Future<void> _fetchUpcomingAppointment() async {
    _fetchNotificationsCount();
    setState(() {
      _isLoadingAppointment = true;
    });

    final res = await _appointmentService.getMyAppointments(asRole: 'patient');
    if (mounted) {
      setState(() {
        _isLoadingAppointment = false;
        if (res['success'] == true) {
          final List<dynamic> list = res['data'] ?? [];
          final now = DateTime.now();
          final upcoming = list.where((a) {
            final status = a['status'];
            final startAtStr = a['startAt'];
            final startAt = startAtStr != null ? DateTime.parse(startAtStr).toLocal() : null;
            return (status == 'CONFIRMED' || status == 'PENDING') &&
                (startAt == null || startAt.isAfter(now.subtract(const Duration(hours: 1))));
          }).toList();

          if (upcoming.isNotEmpty) {
            upcoming.sort((a, b) {
              final aDt = DateTime.tryParse(a['startAt'] ?? '') ?? DateTime.now();
              final bDt = DateTime.tryParse(b['startAt'] ?? '') ?? DateTime.now();
              return aDt.compareTo(bDt);
            });
            _upcomingAppointment = upcoming.first;
          } else {
            _upcomingAppointment = null;
          }
        }
      });
    }
  }

  String _getMonthAbbr(int month) {
    const months = ['ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  void _openAppointments() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PatientAppointmentsScreen(
          onNavigateToDirectory: widget.onNavigateToDirectory,
        ),
      ),
    ).then((_) => _fetchUpcomingAppointment());
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PatientNotificationsScreen(
          onNavigateToDirectory: widget.onNavigateToDirectory,
        ),
      ),
    ).then((_) {
      _fetchNotificationsCount();
      _fetchUpcomingAppointment();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchUpcomingAppointment,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    // Profile Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primary, width: 2),
                        image: const DecorationImage(
                          image: NetworkImage(
                            'https://lh3.googleusercontent.com/aida-public/AB6AXuC4ndZi-BfIgVltO1mL9K7CFwp_OaaCL2l8BCHda94RG3z5E-lIvgVAXDcRvIUNhsThiQLQPlhUJRIhv0V7c3qQYntjIv8rC8YZxz5Fykp1QEdFe0A8XQSWk-HHPNlZj-UKEHkFh_ttSq75W3w8FpUM3a-EFoAAW0Doc_E00aXDpPMCGEi-xmyc2yCZSmU8BcBGYgXIxLzI8GZlJGNECwAP0aPa83tWcyhdne_Mm-knZnk5268zCLeTlzUyyzn5V_P_6y-X5RnS53a0',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Welcome Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good morning,',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Angel Brambila',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppTheme.textLight
                                  : AppTheme.textDark,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Theme Switcher, Payment History & Notifications Button
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.receipt_long_outlined),
                          tooltip: 'Mis Pagos y Recibos',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const PatientPaymentHistoryScreen()),
                            );
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: isDark
                                ? AppTheme.cardDark
                                : Colors.white,
                            foregroundColor: isDark
                                ? AppTheme.textLight
                                : AppTheme.textDark,
                            elevation: 1,
                            shadowColor: Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            widget.isDarkMode
                                ? Icons.light_mode
                                : Icons.dark_mode,
                          ),
                          onPressed: widget.onToggleTheme,
                          style: IconButton.styleFrom(
                            backgroundColor: isDark
                                ? AppTheme.cardDark
                                : Colors.white,
                            foregroundColor: isDark
                                ? AppTheme.textLight
                                : AppTheme.textDark,
                            elevation: 1,
                            shadowColor: Colors.black.withOpacity(0.05),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_none),
                              onPressed: _openNotifications,
                              style: IconButton.styleFrom(
                                backgroundColor: isDark
                                    ? AppTheme.cardDark
                                    : Colors.white,
                                foregroundColor: isDark
                                    ? AppTheme.textLight
                                    : AppTheme.textDark,
                                elevation: 1,
                                shadowColor: Colors.black.withValues(alpha: 0.05),
                              ),
                            ),
                            if (_unreadNotifications > 0)
                              Positioned(
                                right: 2,
                                top: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Mood Tracker
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How are you feeling today?',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        letterSpacing: -0.5,
                        color: isDark ? AppTheme.textLight : AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track your mood to see your progress.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: _moods.map((mood) {
                          final label = mood['label'] as String;
                          final icon = mood['icon'] as IconData;
                          final isSelected = _selectedMood == label;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedMood = label;
                              });
                              ScaffoldMessenger.of(
                                context,
                              ).hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Registered mood: $label! Keep checking in.',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? AppTheme.primary
                                        : AppTheme.primary.withOpacity(0.1),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppTheme.primary
                                                  .withOpacity(0.4),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Icon(
                                    icon,
                                    color: isSelected
                                        ? AppTheme.textDark
                                        : AppTheme.primary,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppTheme.primary
                                        : (isDark
                                              ? AppTheme.textLight
                                              : AppTheme.textMediumLight),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // Quick Support Section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Support',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        color: isDark ? AppTheme.textLight : AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Card 1: Explorar canales
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const CommunityScreen()));
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 180,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                image: const DecorationImage(
                                  image: NetworkImage(
                                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDAw7c0LtiQQFN9-HsCEOTpw-tCTTS7zLTDU5yJGvIwafUKavuU9N-PebBaS_f4gjOF2NPB4sZFBhSlaY2O-FqqIJ4-UHiQ9rFbqx-phPRA6r6ODNw9XGe56iDB2ihifdRHcB9epnebaKE4NKLLg2jaJCFz6wxP-RIDW8095h7HSfbFtLgJj4ngzCC-oUbOY0PXIo5XB91UHJdIqMv2Kw90N7u374emc19MFe5VhU90h3fejniqshHqhNvqbgTNJuRYTL3hsd_ODFxk',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Gradient Overlay
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.1),
                                          Colors.black.withOpacity(0.75),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Free badge
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'FREE',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textDark,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Icon and text
                                  Positioned(
                                    bottom: 12,
                                    left: 12,
                                    right: 12,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.groups,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Explorar canales',
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Card 2: Find a Specialist
                        Expanded(
                          child: InkWell(
                            onTap: widget.onNavigateToDirectory,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: 180,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                image: const DecorationImage(
                                  image: NetworkImage(
                                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCg-j_br9V9JZBfbcF_p_dGFLq3YLHGaTsvAaoYV4MOJ0ci1n_ZlbVd2loTza-8RZNLioYv47p1U7sIkKkh9cPHrjQbD_ZK9JIgrAEqFyyfdJsDR_Qn_hm79YlawrVHmQq9fD0FPWFXghMschhcUhN8WuMbli3bTtJ6-LG9CUqhaOJ2ccE4EC8EDaBDqu3PM6l-baK3NnvhbvxALR4saGyJB0sTjUcuRir0mckICgwbwWq30fg6ooNbu4OkNP5Y3cgYyLz64JazSRdc',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  // Gradient Overlay
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          AppTheme.primary.withOpacity(0.2),
                                          Colors.black.withOpacity(0.85),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Icon and text
                                  Positioned(
                                    bottom: 12,
                                    left: 12,
                                    right: 12,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.psychology,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Find a Specialist',
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Upcoming Session Card
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Upcoming Session',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 18,
                            color: isDark
                                ? AppTheme.textLight
                                : AppTheme.textDark,
                          ),
                        ),
                        TextButton(
                          onPressed: _openAppointments,
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                          ),
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildUpcomingSessionContent(theme, isDark),
                  ],
                ),
              ),

              // Daily Meditation Row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Meditation',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        color: isDark ? AppTheme.textLight : AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          // Play Button
                          ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Playing "5-Min Morning Calm" meditation...',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(12),
                              elevation: 0,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: AppTheme.textDark,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Text Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '5-Min Morning Calm',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppTheme.textLight
                                        : AppTheme.textDark,
                                  ),
                                ),
                                Text(
                                  'Focus on your breathing and reset.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppTheme.textSecondaryDark
                                        : AppTheme.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildUpcomingSessionContent(ThemeData theme, bool isDark) {
    if (_isLoadingAppointment) {
      return Container(
        height: 90,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.borderSubtleDark : AppTheme.borderSubtleLight,
          ),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_upcomingAppointment == null) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.borderSubtleDark : AppTheme.borderSubtleLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 36,
              color: AppTheme.primary.withOpacity(0.8),
            ),
            const SizedBox(height: 10),
            Text(
              'No tienes citas próximas agendadas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textLight : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Encuentra un especialista y programa tu sesión para cuidar de tu bienestar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: widget.onNavigateToDirectory,
              icon: const Icon(Icons.search, size: 16),
              label: const Text('Explorar Especialistas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    final appointment = _upcomingAppointment!;
    DateTime? startAt;
    if (appointment['startAt'] != null) {
      startAt = DateTime.tryParse(appointment['startAt'].toString())?.toLocal();
    }
    final monthStr = startAt != null ? _getMonthAbbr(startAt.month) : '---';
    final dayStr = startAt != null ? startAt.day.toString().padLeft(2, '0') : '--';
    final timeStr = startAt != null
        ? '${startAt.hour.toString().padLeft(2, '0')}:${startAt.minute.toString().padLeft(2, '0')} hrs'
        : '--:--';

    final psychologist = appointment['psychologist'];
    final psyUser = psychologist is Map ? psychologist['user'] : null;
    final psyName = psyUser is Map
        ? 'Dr. ${(psyUser['name'] ?? '').toString().trim()} ${(psyUser['lastName'] ?? '').toString().trim()}'.trim()
        : 'Psicólogo Especialista';
    final specialty = (psychologist is Map && psychologist['specialty'] != null && psychologist['specialty'].toString().isNotEmpty)
        ? psychologist['specialty'].toString()
        : 'Consulta Psicológica';

    final consultation = appointment['consultation'];
    final modality = consultation is Map && consultation['modality'] == 'PRESENCIAL'
        ? 'Presencial'
        : 'En línea';
    final modalityIcon = modality == 'Presencial' ? Icons.location_on_outlined : Icons.videocam;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openAppointments,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppTheme.borderSubtleDark : AppTheme.borderSubtleLight,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 5,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 52,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.borderSubtleDark
                      : AppTheme.borderSubtleLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      monthStr,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppTheme.textSecondaryDark
                            : AppTheme.textSecondaryLight,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      dayStr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        psyName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.textLight : AppTheme.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        specialty,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppTheme.textSecondaryDark
                              : AppTheme.textSecondaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 13,
                            color: isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeStr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            modalityIcon,
                            size: 13,
                            color: isDark
                                ? AppTheme.textSecondaryDark
                                : AppTheme.textSecondaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            modality,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppTheme.textSecondaryDark
                                  : AppTheme.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Icon(
                  Icons.chevron_right,
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
