// lib/ui/profile/about_screen.dart
// About screen with extracted components

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/void_theme.dart';
import '../painters/custom_painters.dart';
import 'components/social_button.dart';
import 'components/stack_item.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = VoidTheme.of(context);
    return Scaffold(
      backgroundColor: theme.bgPrimary,
      body: Stack(
        children: [
          // Technical Background
          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.white,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: CustomPaint(
                painter: BentoBackgroundPainter(color: theme.textPrimary),
              ),
            ),
          ),

          // Content
          Positioned.fill(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverSafeArea(
                  minimum: const EdgeInsets.only(top: 20),
                  sliver: SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 60),
                          _buildHeroSection(theme),
                          const SizedBox(height: 24),
                          _buildInfoGrid(theme),
                          const SizedBox(height: 16),
                          _buildConnectSection(theme),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildFooter(theme),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Back Button
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, top: 16),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.textPrimary.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: theme.textPrimary.withValues(alpha: 0.1)),
                    ),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        color: theme.textSecondary, size: 18),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(VoidTheme theme) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.bgCard,
              border: Border.all(
                  color: (theme.brightness == Brightness.dark ? Colors.cyanAccent : Colors.cyan).withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.4), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: theme.brightness == Brightness.dark ? 0.1 : 0.05),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Colors.purpleAccent.withValues(alpha: theme.brightness == Brightness.dark ? 0.05 : 0.02),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                "assets/images/dev.jpg",
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.person, size: 60, color: theme.textPrimary.withValues(alpha: 0.1)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Naveen xD",
            style: GoogleFonts.ibmPlexSans(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "A DEVELOPER",
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              color: theme.brightness == Brightness.dark ? Colors.cyanAccent : Colors.cyan[700],
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              "Building intuitive experiences and scalable code.",
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSans(
                fontSize: 13,
                color: theme.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectSection(VoidTheme theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.textPrimary.withValues(alpha: 0.05),
            theme.textPrimary.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.textPrimary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "CONNECT",
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 10,
                  color: theme.textTertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.link_rounded, size: 14, color: theme.textPrimary.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: SocialButton(
                      icon: Icons.code,
                      label: "GitHub",
                      url: "https://github.com/naveenxd",
                      centerContent: true)),
              const SizedBox(width: 12),
              Expanded(
                  child: SocialButton(
                      icon: Icons.alternate_email,
                      label: "Twitter",
                      url: "https://x.com/Naveen__xD",
                      centerContent: true)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: SocialButton(
                      icon: Icons.business,
                      label: "LinkedIn",
                      url: "https://linkedin.com",
                      centerContent: true)),
              const SizedBox(width: 12),
              Expanded(
                  child: SocialButton(
                      icon: Icons.email_outlined,
                      label: "Email",
                      url: "mailto:naveenxd@devh.in",
                      centerContent: true)),
            ],
          ),
          const SizedBox(height: 12),
          SocialButton(
              icon: Icons.language,
              label: "Portfolio",
              url: "https://nxd.devh.in",
              isFullWidth: true,
              centerContent: true),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(VoidTheme theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildAppInfoCard(theme)),
        const SizedBox(width: 16),
        Expanded(child: _buildTechStackCard(theme)),
      ],
    );
  }

  Widget _buildAppInfoCard(VoidTheme theme) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.textPrimary.withValues(alpha: 0.05),
            theme.textPrimary.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.textPrimary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: (theme.brightness == Brightness.dark ? Colors.cyanAccent : Colors.cyan).withValues(alpha: 0.2)),
            ),
            child: Icon(Icons.rocket_launch_rounded,
                color: theme.brightness == Brightness.dark ? Colors.cyanAccent : Colors.cyan, size: 20),
          ),
          const Spacer(),
          Text(
            "VOID SPACE",
            style: GoogleFonts.ibmPlexMono(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                "v1.0.4",
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 11,
                  color: theme.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "STABLE",
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "BUILD 2026.02",
            style: GoogleFonts.ibmPlexMono(
              fontSize: 9,
              color: theme.textTertiary,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechStackCard(VoidTheme theme) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.textPrimary.withValues(alpha: 0.05),
            theme.textPrimary.withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.textPrimary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ">_ STACK",
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 10,
                  color: theme.textTertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(Icons.layers_outlined, size: 14, color: theme.textPrimary.withValues(alpha: 0.24)),
            ],
          ),
          const SizedBox(height: 20),
          StackItem(
              label: "Flutter", version: "v3.19.0", progress: 0.95, isCompact: true),
          const SizedBox(height: 12),
          StackItem(
              label: "Dart", version: "v3.10.7", progress: 0.90, isCompact: true),
          const SizedBox(height: 12),
          StackItem(
              label: "Hive", version: "v2.2.3", progress: 0.85, isCompact: true),
        ],
      ),
    );
  }

  Widget _buildFooter(VoidTheme theme) {
    return Center(
      child: Opacity(
        opacity: 0.8,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Made with ",
              style: GoogleFonts.ibmPlexMono(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: theme.textPrimary.withValues(alpha: 0.5),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child:
                  Icon(Icons.favorite_rounded, size: 14, color: Color(0xFFFF4D4D)),
            ),
            Text(
              " by ",
              style: GoogleFonts.ibmPlexMono(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: theme.textPrimary.withValues(alpha: 0.5),
              ),
            ),
            Text(
              "XD",
              style: GoogleFonts.ibmPlexMono(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textPrimary.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
