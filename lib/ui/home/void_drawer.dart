import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:void_space/data/stores/void_store.dart';
import '../theme/void_theme.dart';
import '../theme/void_design.dart';

import '../../services/haptic_service.dart';
import '../trash/trash_screen.dart';

class VoidDrawer extends StatefulWidget {
  final VoidCallback onReturnFromTrash;

  const VoidDrawer({
    super.key,
    required this.onReturnFromTrash,
  });

  @override
  State<VoidDrawer> createState() => _VoidDrawerState();
}

class _VoidDrawerState extends State<VoidDrawer> {
  int _activeNodesCount = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final items = await VoidStore.all();
      if (mounted) {
        setState(() {
          _activeNodesCount = items.length;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = VoidTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: theme.bgPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Drawer Header (Branding)
          Container(
            padding: const EdgeInsets.fromLTRB(32, 64, 32, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'void',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -2.0,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'DIGITAL VAULT',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: theme.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          // 2. Main Navigation
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.all_inbox_rounded,
                    title: "All Nodes",
                    isSelected: true,
                    theme: theme,
                    onTap: () {
                      HapticService.light();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),

          // 3. Status & Maintenance (Footer)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.bgCard.withValues(alpha: isDark ? 0.4 : 0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.borderSubtle),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00F2AD),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'VAULT SECURE',
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: theme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildStatRow(
                    'Total Nodes', 
                    _isLoadingStats ? '...' : _activeNodesCount.toString(), 
                    theme
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow('State', 'Local Only', theme),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Divider(color: theme.borderSubtle, height: 1),
                  ),

                  // Maintenance Action
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        HapticService.light();
                        Navigator.pop(context);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TrashScreen()),
                        );
                        if (context.mounted) {
                          widget.onReturnFromTrash();
                          _loadStats();
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: theme.textSecondary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Trash Bin",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: theme.textSecondary,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: theme.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, VoidTheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: theme.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 12,
            color: theme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidTheme theme,
    required VoidCallback onTap,
    bool isComingSoon = false,
  }) {
    final activeColor = theme.textPrimary;
    final inactiveColor = isComingSoon ? theme.textMuted : theme.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isComingSoon ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? activeColor.withValues(alpha: 0.05) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? theme.borderSubtle : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? activeColor : inactiveColor,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
