import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:void_space/data/stores/preferences_store.dart';
import 'package:void_space/services/haptic_service.dart';
import 'package:void_space/app/feature_flags.dart';
import 'package:void_space/ui/theme/void_theme.dart';
import 'onboarding_painters.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Animation controllers
  late AnimationController _bgRotateController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late AnimationController _entryController;
  late AnimationController _initialRevealController;

  late final List<OnboardingContent> _contents;

  final TextEditingController _nameController = TextEditingController();
  String? _profileImagePath;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImagePath = image.path;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _contents = [
      OnboardingContent(
        title: "VOID SPACE",
        subtitle: "YOUR DIGITAL VAULT",
        description:
            "A sanctuary for your thoughts,\nlinks, and files.",
        painterBuilder: (progress, pulse, color) => ConcentricRingsPainter(
          progress: progress,
          pulse: pulse,
          color: color,
        ),
      ),
      OnboardingContent(
        title: "ORGANIZE",
        subtitle: "EVERYTHING IN ONE PLACE",
        description:
            "Images, PDFs, Links, and Notes\n— all safe in your void.",
        painterBuilder: (progress, pulse, color) => OrbitGridPainter(
          progress: progress,
          pulse: pulse,
          color: color,
        ),
      ),
      if (isAiEnabled)
        OnboardingContent(
          title: "AI POWERED",
          subtitle: "INTELLIGENT SEARCH",
          description:
              "Semantic search and auto-summarization.\nLet AI understand your content.",
          painterBuilder: (progress, pulse, color) => NeuralNetPainter(
            progress: progress,
            pulse: pulse,
            color: color,
          ),
        ),
/*
      OnboardingContent(
        isProfileSetup: true,
      ),
*/
    ];

    _bgRotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Initial cinematic reveal — screen fades in from black
    _initialRevealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Sequence: reveal first, then entry
    _runInitialSequence();
  }

  Future<void> _runInitialSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _initialRevealController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _entryController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgRotateController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _entryController.dispose();
    _initialRevealController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    HapticService.selection();
    _entryController.reset();
    _entryController.forward();
  }

  void _onNext() {
    HapticService.light();

    if (_currentPage < _contents.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    HapticService.medium();
    
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      await PreferencesStore.setUserName(name);
    }
    if (_profileImagePath != null) {
      await PreferencesStore.setUserProfilePicture(_profileImagePath!);
    }

    await PreferencesStore.completeOnboarding();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = VoidTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.bgPrimary,
      body: AnimatedBuilder(
        animation: _initialRevealController,
        builder: (context, child) {
          final reveal = Curves.easeOut.transform(
              _initialRevealController.value);

          return Opacity(
            opacity: reveal,
            child: Stack(
              children: [
                // ── LAYER 1: Rotating grid background ──
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _bgRotateController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: OnboardingGridPainter(
                          rotation:
                              _bgRotateController.value * 2 * math.pi * 0.02,
                          opacity: isDark ? 0.025 : 0.04,
                          color: theme.textPrimary,
                        ),
                      );
                    },
                  ),
                ),

                // ── LAYER 2: Floating particles ──
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _particleController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: FloatingParticlesPainter(
                          progress: _particleController.value,
                          color: theme.textPrimary,
                        ),
                      );
                    },
                  ),
                ),

                // ── LAYER 3: Top & bottom edge vignettes ──
                Positioned.fill(
                  child: IgnorePointer(
                    child: Column(
                      children: [
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                theme.bgPrimary.withValues(alpha: 0.8),
                                theme.bgPrimary.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                theme.bgPrimary.withValues(alpha: 0.9),
                                theme.bgPrimary.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── LAYER 4: Main content ──
                SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // PageView with hero animations
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: _onPageChanged,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _contents.length,
                          itemBuilder: (context, index) {
                            return _buildPage(
                                theme, _contents[index], isDark);
                          },
                        ),
                      ),

                      // Bottom controls
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 0, 28, 48),
                        child: Column(
                          children: [
                            _buildPageIndicator(theme),
                            const SizedBox(height: 36),
                            _buildCTAButton(theme, isDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPage(
      VoidTheme theme, OnboardingContent content, bool isDark) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _bgRotateController,
        _pulseController,
        _entryController,
      ]),
      builder: (context, child) {
        final pulse = Curves.easeInOut.transform(_pulseController.value);
        final entry = Curves.easeOutCubic.transform(_entryController.value);

        if (content.isProfileSetup) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.translate(
                  offset: Offset(0, -12 * (1 - entry)),
                  child: Opacity(
                    opacity: entry,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.textPrimary.withValues(alpha: 0.1), width: 1),
                          color: theme.textPrimary.withValues(alpha: 0.05),
                          image: _profileImagePath != null
                              ? DecorationImage(
                                  image: FileImage(File(_profileImagePath!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _profileImagePath == null
                            ? Icon(Icons.add_a_photo_outlined, size: 40, color: theme.textSecondary)
                            : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Builder(builder: (context) {
                  final subtitleEntry = Curves.easeOutCubic.transform((entry * 1.2 - 0.15).clamp(0.0, 1.0));
                  return Transform.translate(
                    offset: Offset(0, 12 * (1 - subtitleEntry)),
                    child: Opacity(
                      opacity: subtitleEntry * 0.6,
                      child: Text(
                        "IDENTITY",
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 4, color: theme.textTertiary,
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Transform.translate(
                  offset: Offset(0, 18 * (1 - entry)),
                  child: Opacity(
                    opacity: entry,
                    child: Text(
                      "WHO ARE YOU?",
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: 4, color: theme.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Builder(builder: (context) {
                  final descEntry = Curves.easeOutCubic.transform((entry * 1.4 - 0.4).clamp(0.0, 1.0));
                  return Transform.translate(
                    offset: Offset(0, 14 * (1 - descEntry)),
                    child: Opacity(
                      opacity: descEntry,
                      child: TextField(
                        controller: _nameController,
                        style: GoogleFonts.ibmPlexSans(fontSize: 18, color: theme.textPrimary),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: "Enter your name",
                          hintStyle: GoogleFonts.ibmPlexSans(color: theme.textSecondary.withValues(alpha: 0.5)),
                          filled: true,
                          fillColor: theme.textPrimary.withValues(alpha: 0.05),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: theme.textPrimary.withValues(alpha: 0.1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: theme.textPrimary.withValues(alpha: 0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: theme.textPrimary.withValues(alpha: 0.4)),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Hero visual ──
              Transform.translate(
                offset: Offset(0, -12 * (1 - entry)),
                child: Opacity(
                  opacity: entry,
                  child: Transform.scale(
                    scale: 0.9 + 0.1 * entry,
                    child: SizedBox(
                      width: 280,
                      height: 280,
                      child: Stack(
                        children: [
                          // Multi-layer radial glow
                          Center(
                            child: Container(
                              width: 240 + 30 * pulse,
                              height: 240 + 30 * pulse,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    theme.textPrimary.withValues(
                                        alpha: (isDark ? 0.05 : 0.07) +
                                            0.03 * pulse),
                                    theme.textPrimary.withValues(
                                        alpha: (isDark ? 0.015 : 0.025)),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),

                          // Outer faint ring
                          Center(
                            child: Container(
                              width: 260,
                              height: 260,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.textPrimary
                                      .withValues(alpha: 0.03 + 0.02 * pulse),
                                  width: 0.5,
                                ),
                              ),
                            ),
                          ),

                          // Custom painter
                          if (content.painterBuilder != null)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: content.painterBuilder!(
                                  _bgRotateController.value,
                                  pulse,
                                  theme.textPrimary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 52),

              // ── Subtitle (small label above title) ──
              Builder(builder: (context) {
                final subtitleEntry = Curves.easeOutCubic
                    .transform((entry * 1.2 - 0.15).clamp(0.0, 1.0));
                return Transform.translate(
                  offset: Offset(0, 12 * (1 - subtitleEntry)),
                  child: Opacity(
                    opacity: subtitleEntry * 0.6,
                    child: Text(
                      content.subtitle,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 4,
                        color: theme.textTertiary,
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 12),

              // ── Title ──
              Transform.translate(
                offset: Offset(0, 18 * (1 - entry)),
                child: Opacity(
                  opacity: entry,
                  child: Text(
                    content.title,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 8,
                      color: theme.textPrimary,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // ── Decorative line under title ──
              Builder(builder: (context) {
                final lineEntry = Curves.easeOutCubic
                    .transform((entry * 1.4 - 0.35).clamp(0.0, 1.0));
                return Opacity(
                  opacity: lineEntry * 0.3,
                  child: Container(
                    width: 40 * lineEntry,
                    height: 1,
                    color: theme.textPrimary,
                  ),
                );
              }),

              const SizedBox(height: 20),

              // ── Description ──
              Builder(builder: (context) {
                final descEntry = Curves.easeOutCubic
                    .transform((entry * 1.4 - 0.4).clamp(0.0, 1.0));
                return Transform.translate(
                  offset: Offset(0, 14 * (1 - descEntry)),
                  child: Opacity(
                    opacity: descEntry,
                    child: Text(
                      content.description,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 15,
                        height: 1.7,
                        color: theme.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPageIndicator(VoidTheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _contents.length,
        (index) {
          final isActive = _currentPage == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            height: 3,
            width: isActive ? 32 : 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1.5),
              color: isActive
                  ? theme.textPrimary.withValues(alpha: 0.9)
                  : theme.textPrimary.withValues(alpha: 0.12),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: theme.textPrimary.withValues(alpha: 0.25),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCTAButton(VoidTheme theme, bool isDark) {
    return AnimatedBuilder(
      animation: _nameController,
      builder: (context, child) {
        final isLast = _currentPage == _contents.length - 1;
        final bool isProfileSetupReady = _nameController.text.trim().isNotEmpty && _profileImagePath != null;
        final bool isClickable = !isLast || isProfileSetupReady;
        final bool showSolid = isLast && isProfileSetupReady;

        return GestureDetector(
          onTap: isClickable ? _onNext : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: showSolid
                  ? theme.textPrimary
                  : theme.textPrimary.withValues(alpha: isDark ? 0.06 : 0.08),
              border: Border.all(
                color: theme.textPrimary
                    .withValues(alpha: showSolid ? 0.0 : 0.10),
                width: 1,
              ),
              boxShadow: showSolid
                  ? [
                      BoxShadow(
                        color: theme.textPrimary.withValues(alpha: 0.20),
                        blurRadius: 24,
                        spreadRadius: 0,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: theme.textPrimary.withValues(alpha: 0.08),
                        blurRadius: 60,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: Row(
                  key: ValueKey(isLast),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLast ? "GET STARTED" : "NEXT",
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        color: showSolid ? theme.bgPrimary : theme.textPrimary.withValues(alpha: isClickable ? 1.0 : 0.5),
                      ),
                    ),
                    if (!isLast) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: theme.textPrimary.withValues(alpha: 0.5),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }
}

class OnboardingContent {
  final String title;
  final String subtitle;
  final String description;
  final CustomPainter Function(double progress, double pulse, Color color)?
      painterBuilder;
  final bool isProfileSetup;

  OnboardingContent({
    this.title = '',
    this.subtitle = '',
    this.description = '',
    this.painterBuilder,
    this.isProfileSetup = false,
  });
}
