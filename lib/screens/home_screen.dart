import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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

  final List<Map<String, dynamic>> _moods = [
    {'label': 'Great', 'icon': Icons.sentiment_very_satisfied},
    {'label': 'Good', 'icon': Icons.sentiment_satisfied},
    {'label': 'Okay', 'icon': Icons.sentiment_neutral},
    {'label': 'Down', 'icon': Icons.sentiment_dissatisfied},
    {'label': 'Struggling', 'icon': Icons.sentiment_very_dissatisfied},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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

                    // Theme Switcher & Notifications Button
                    Row(
                      children: [
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
                        IconButton(
                          icon: const Icon(Icons.notifications_none),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No new notifications'),
                                behavior: SnackBarBehavior.floating,
                              ),
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
                            shadowColor: Colors.black.withOpacity(0.05),
                          ),
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
                        // Card 1: Join Group Chat
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Joining group community chat...',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
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
                                          'Join Group Chat',
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
                          onPressed: widget.onNavigateToDirectory,
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
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: AppTheme.primary,
                                width: 4.0,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date Block
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
                                      'OCT',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppTheme.textSecondaryDark
                                            : AppTheme.textSecondaryLight,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const Text(
                                      '24',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        height: 1.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Content Block
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dr. Sarah Jenkins',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppTheme.textLight
                                            : AppTheme.textDark,
                                      ),
                                    ),
                                    Text(
                                      'Cognitive Behavioral Therapy',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? AppTheme.textSecondaryDark
                                            : AppTheme.textSecondaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.schedule,
                                          size: 14,
                                          color: isDark
                                              ? AppTheme.textSecondaryDark
                                              : AppTheme.textSecondaryLight,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '10:30 AM',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? AppTheme.textSecondaryDark
                                                : AppTheme.textSecondaryLight,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Icon(
                                          Icons.videocam,
                                          size: 14,
                                          color: isDark
                                              ? AppTheme.textSecondaryDark
                                              : AppTheme.textSecondaryLight,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Online Session',
                                          style: TextStyle(
                                            fontSize: 11,
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
                            ],
                          ),
                        ),
                      ),
                    ),
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
    );
  }
}
