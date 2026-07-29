import 'package:flutter/material.dart';
import 'models/psychologist.dart';
import 'screens/directory_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/profile_screen.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode =
      ThemeMode.dark; // Default to dark mode as it highlights the premium look

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindEase - Mental Health Support',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: AppRoot(
        isDarkMode: _themeMode == ThemeMode.dark,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class AppRoot extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const AppRoot({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _showOnboarding = true;
  bool _isLoading = true;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _currentUser;
  int _currentNavIndex =
      0; // 0 = Home, 1 = Explore/Directory, 2 = Community, 3 = Profile
  Psychologist? _selectedPsychologist;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final authService = AuthService();
    final hasToken = await authService.hasToken();
    if (hasToken) {
      final result = await authService.getProfile();
      if (result['success'] == true) {
        if (mounted) {
          setState(() {
            _currentUser = result['data'];
            _isAuthenticated = true;
            _showOnboarding = false;
            _isLoading = false;
          });
        }
        return;
      }
    }
    if (mounted) {
      setState(() {
        _isAuthenticated = false;
        _showOnboarding = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (!_isAuthenticated || _showOnboarding) {
      return OnboardingScreen(
        onFinishOnboarding: () {
          _checkAuthStatus();
        },
      );
    }

    final isDark = widget.isDarkMode;

    // Core screens matching bottom nav
    final List<Widget> screens = [
      HomeScreen(
        onNavigateToDirectory: () {
          setState(() {
            _currentNavIndex = 1; // Go to Explore/Directory tab
            _selectedPsychologist = null;
          });
        },
        onToggleTheme: widget.onToggleTheme,
        isDarkMode: widget.isDarkMode,
      ),
      DirectoryScreen(
        onSelectPsychologist: (doctor) {
          setState(() {
            _selectedPsychologist = doctor;
          });
        },
      ),
      _buildCommunityScreen(context),
      _buildUserProfileScreen(context),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Current Main Tab
          IndexedStack(index: _currentNavIndex, children: screens),

          // Detailed Psychologist Profile Page Overlay (Slide transition)
          if (_selectedPsychologist != null)
            Positioned.fill(
              child: Container(
                color: isDark ? AppTheme.bgDark : AppTheme.bgLight,
                child: ProfileScreen(
                  psychologist: _selectedPsychologist!,
                  onBack: () {
                    setState(() {
                      _selectedPsychologist = null;
                    });
                  },
                ),
              ),
            ),
        ],
      ),

      // Global Bottom Navigation Bar
      bottomNavigationBar: _selectedPsychologist == null
          ? Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
                    width: 0.5,
                  ),
                ),
              ),
              child: BottomNavigationBar(
                currentIndex: _currentNavIndex,
                onTap: (index) {
                  setState(() {
                    _currentNavIndex = index;
                    _selectedPsychologist =
                        null; // Clear selection when changing tabs
                  });
                },
                backgroundColor: isDark
                    ? const Color(0xFF0F172A)
                    : Colors.white,
                selectedItemColor: AppTheme.primary,
                unselectedItemColor: Colors.grey,
                type: BottomNavigationBarType.fixed,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 10,
                ),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home, color: AppTheme.primary),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.explore_outlined),
                    activeIcon: Icon(Icons.explore, color: AppTheme.primary),
                    label: 'Explore',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.forum_outlined),
                    activeIcon: Icon(Icons.forum, color: AppTheme.primary),
                    label: 'Community',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person, color: AppTheme.primary),
                    label: 'Profile',
                  ),
                ],
              ),
            )
          : null,
    );
  }

  // Premium Dummy Community Screen
  Widget _buildCommunityScreen(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Discussion'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card with Gradient
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF0EA5E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MindEase Safe Space',
                    style: TextStyle(
                      color: AppTheme.bgDark,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Share your feelings, read supportive stories, and find comfort in a fully anonymous peer-to-peer network.',
                    style: TextStyle(
                      color: AppTheme.bgDark.withOpacity(0.8),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Subtitle
            Text(
              'Trending Topics',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Topic Card 1
            _buildTopicCard(
              context,
              'Anxiety coping techniques that actually work',
              'Anxiety',
              '240 active users',
              Icons.healing,
              isDark,
            ),
            // Topic Card 2
            _buildTopicCard(
              context,
              'Morning routine checklist for mindfulness',
              'Mindfulness',
              '189 active users',
              Icons.wb_sunny_outlined,
              isDark,
            ),
            // Topic Card 3
            _buildTopicCard(
              context,
              'Overcoming imposter syndrome at work',
              'Self-Care',
              '312 active users',
              Icons.work_outline,
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard(
    BuildContext context,
    String title,
    String tag,
    String activeUsers,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppTheme.borderSubtleDark
              : AppTheme.borderSubtleLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  activeUsers,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  // Premium Dummy User Profile Screen
  Widget _buildUserProfileScreen(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Avatar Section
            const SizedBox(height: 12),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary, width: 3),
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuC4ndZi-BfIgVltO1mL9K7CFwp_OaaCL2l8BCHda94RG3z5E-lIvgVAXDcRvIUNhsThiQLQPlhUJRIhv0V7c3qQYntjIv8rC8YZxz5Fykp1QEdFe0A8XQSWk-HHPNlZj-UKEHkFh_ttSq75W3w8FpUM3a-EFoAAW0Doc_E00aXDpPMCGEi-xmyc2yCZSmU8BcBGYgXIxLzI8GZlJGNECwAP0aPa83tWcyhdne_Mm-knZnk5268zCLeTlzUyyzn5V_P_6y-X5RnS53a0',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _currentUser?['name'] ?? 'Alex Rivers',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              _currentUser?['email'] ?? 'Member since Oct 2025',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppTheme.textSecondaryDark
                    : AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),

            // Statistics Card Row
            Row(
              children: [
                _buildProfileStatCard('Mood Check-ins', '18', isDark),
                const SizedBox(width: 12),
                _buildProfileStatCard('Minutes Listened', '140', isDark),
                const SizedBox(width: 12),
                _buildProfileStatCard('Sessions Had', '4', isDark),
              ],
            ),
            const SizedBox(height: 24),

            // Settings Items List
            _buildSettingTile(
              Icons.shield_outlined,
              'Privacy & Safety',
              isDark,
            ),
            _buildSettingTile(
              Icons.notifications_none_outlined,
              'Notification Settings',
              isDark,
            ),
            _buildSettingTile(
              Icons.payment_outlined,
              'Subscription & Billing',
              isDark,
            ),
            _buildSettingTile(Icons.help_outline, 'Help & Support', isDark),

            const SizedBox(height: 20),

            // Log Out Button
            TextButton(
              onPressed: () async {
                await AuthService().logout();
                if (mounted) {
                  setState(() {
                    _isAuthenticated = false;
                    _showOnboarding = true;
                    _currentUser = null;
                    _currentNavIndex = 0;
                  });
                }
              },
              child: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStatCard(String label, String value, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.borderSubtleDark
              : AppTheme.borderSubtleLight,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}
