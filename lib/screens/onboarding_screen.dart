import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinishOnboarding;

  const OnboardingScreen({super.key, required this.onFinishOnboarding});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _heroMotionController;
  late final Animation<double> _headerFade;
  late final Animation<double> _contentFade;
  late final Animation<double> _footerFade;
  late final Animation<Offset> _contentSlide;
  late final Animation<Offset> _footerSlide;
  late final Animation<double> _heroScale;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
    _heroMotionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _headerFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0, 0.5, curve: Curves.easeOut),
    );
    _contentFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.18, 1, curve: Curves.easeOut),
    );
    _footerFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.38, 1, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.18, 1, curve: Curves.easeOutCubic),
          ),
        );
    _footerSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.38, 1, curve: Curves.easeOutCubic),
          ),
        );
    _heroScale = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _heroMotionController.dispose();
    super.dispose();
  }

  void _openRegister() {
    Navigator.push(
      context,
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) =>
            RegisterScreen(onRegisterSuccess: widget.onFinishOnboarding),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          ),
        ),
      ),
    );
  }

  void _openLogin() {
    Navigator.push(
      context,
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) =>
            LoginScreen(onLoginSuccess: widget.onFinishOnboarding),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final foreground = isDark ? AppTheme.textLight : AppTheme.textDark;
    final mutedForeground = isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textMediumLight;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildAnimatedBackdrop(isDark),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                          child: Column(
                            children: [
                              FadeTransition(
                                opacity: _headerFade,
                                child: _buildHeader(context, isDark),
                              ),
                              const SizedBox(height: 14),
                              _buildMobileContent(
                                foreground,
                                mutedForeground,
                                isDark,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _buildActionFooter(isDark, foreground),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackdrop(bool isDark) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _heroMotionController,
        builder: (context, _) {
          final drift = (_heroMotionController.value - 0.5) * 24;
          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [
                            Color(0xFF0B191B),
                            Color(0xFF102C2C),
                            Color(0xFF0A1719),
                          ]
                        : const [
                            Color(0xFFF7FBFA),
                            Color(0xFFE7F5F1),
                            Color(0xFFF3F8F7),
                          ],
                  ),
                ),
              ),
              Positioned(
                top: -115 + drift,
                right: -100,
                child: _buildGlow(
                  300,
                  AppTheme.primary.withValues(alpha: isDark ? 0.13 : 0.17),
                ),
              ),
              Positioned(
                bottom: 60 - drift,
                left: -150,
                child: _buildGlow(
                  320,
                  const Color(
                    0xFF668F8A,
                  ).withValues(alpha: isDark ? 0.12 : 0.1),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGlow(double size, Color color) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _buildAnimatedLogo(width: 104, height: 69),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            'Tu espacio de bienestar',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppTheme.textSecondaryDark
                  : AppTheme.textSecondaryLight,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedLogo({required double width, required double height}) {
    return AnimatedBuilder(
      animation: _heroMotionController,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.98 + _heroMotionController.value * 0.04,
          child: child,
        );
      },
      child: Image.asset(
        'logoT.png',
        width: width,
        height: height,
        fit: BoxFit.contain,
        semanticLabel: 'MindEase',
      ),
    );
  }

  Widget _buildMobileContent(
    Color foreground,
    Color mutedForeground,
    bool isDark,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final heroSize = constraints.maxWidth.clamp(220.0, 280.0).toDouble();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ScaleTransition(
                scale: _heroScale,
                child: _buildHeroIllustration(isDark, heroSize),
              ),
            ),
            const SizedBox(height: 4),
            FadeTransition(
              opacity: _contentFade,
              child: SlideTransition(
                position: _contentSlide,
                child: _buildWelcomeCopy(foreground, mutedForeground, isDark),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeroIllustration(bool isDark, double size) {
    return AnimatedBuilder(
      animation: _heroMotionController,
      builder: (context, _) {
        final lift = 5 * _heroMotionController.value;
        return SizedBox(
          width: size,
          height: size * 0.84,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: (lift - 2.5) / 180,
                child: Container(
                  width: size * 0.76,
                  height: size * 0.76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.14),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              Container(
                width: size * 0.63,
                height: size * 0.63,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: isDark
                        ? const [Color(0xFF245A55), Color(0xFF173634)]
                        : const [Color(0xFFCDEBE3), Color(0xFFA8D6CA)],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.7),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(
                        alpha: isDark ? 0.12 : 0.18,
                      ),
                      blurRadius: 42,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: _buildAnimatedLogo(
                  width: size * 0.58,
                  height: size * 0.58,
                ),
              ),
              Positioned(
                top: size * 0.08 + lift,
                right: size * 0.1,
                child: _buildFloatingSymbol(Icons.auto_awesome_rounded, isDark),
              ),
              Positioned(
                bottom: size * 0.1 - lift,
                left: size * 0.08,
                child: _buildFloatingSymbol(
                  Icons.favorite_border_rounded,
                  isDark,
                ),
              ),
              Positioned(
                bottom: size * 0.11 + lift / 2,
                right: size * 0.12,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingSymbol(IconData icon, bool isDark) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF173634) : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, size: 19, color: AppTheme.primary),
    );
  }

  Widget _buildActionFooter(bool isDark, Color foreground) {
    final theme = Theme.of(context);
    final mutedForeground = isDark
        ? AppTheme.textSecondaryDark
        : AppTheme.textSecondaryLight;
    return FadeTransition(
      opacity: _footerFade,
      child: SlideTransition(
        position: _footerSlide,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: (isDark ? AppTheme.bgDark : AppTheme.bgLight).withValues(
              alpha: 0.9,
            ),
            border: Border(
              top: BorderSide(
                color: isDark ? AppTheme.borderDark : AppTheme.borderLight,
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _heroMotionController,
                    builder: (context, child) {
                      final glow = 0.04 + _heroMotionController.value * 0.07;
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: glow),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _openRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.textDark,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Get Started',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 19),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _openLogin,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: foreground,
                        side: BorderSide(
                          color: isDark
                              ? AppTheme.borderDark
                              : AppTheme.borderLight,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 13,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Al continuar, aceptas nuestros términos y aviso de privacidad.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: mutedForeground.withValues(alpha: 0.85),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCopy(
    Color foreground,
    Color mutedForeground,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: isDark ? 0.12 : 0.16),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.28)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: 15,
                color: AppTheme.primary,
              ),
              SizedBox(width: 7),
              Text(
                'APOYO PROFESIONAL',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Tu bienestar,\na tu ritmo.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: foreground,
            fontSize: 36,
            height: 1.02,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Un espacio seguro para comprender cómo te sientes y conectar con profesionales que pueden acompañarte.',
          textAlign: TextAlign.center,
          style: TextStyle(color: mutedForeground, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 14),
        _buildBenefit(
          Icons.check_circle_outline_rounded,
          'Acompañamiento centrado en ti',
          mutedForeground,
        ),
        const SizedBox(height: 10),
        _buildBenefit(
          Icons.lock_outline_rounded,
          'Tu bienestar y privacidad importan',
          mutedForeground,
        ),
      ],
    );
  }

  Widget _buildBenefit(IconData icon, String text, Color mutedForeground) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 9),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: mutedForeground,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
