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
                  
                  /*
                  _buildSectionHeader("ORGANIZATION", theme),
                  
                  _buildDrawerItem(
                    context,
                    icon: Icons.folder_outlined,
                    title: "Folders",
                    isSelected: false,
                    isComingSoon: true,
                    theme: theme,
                    onTap: () {},
                  ),

                  _buildDrawerItem(
                    context,
                    icon: Icons.star_border_rounded,
                    title: "Favorites",
                    isSelected: false,
                    isComingSoon: true,
                    theme: theme,
                    onTap: () {},
                  ),
                  */

                  _buildSectionHeader("MAINTENANCE", theme),

                  _buildDrawerItem(
                    context,
                    icon: Icons.delete_outline_rounded,
                    title: "Trash Bin",
                    isSelected: false,
                    theme: theme,
                    onTap: () async {
                      HapticService.light();
                      Navigator.pop(context);
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TrashScreen()),
                      );
                      if (context.mounted) {
                        widget.onReturnFromTrash();
                        _loadStats(); // Refresh stats when coming back
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // 3. Vault Status (Footer)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.bgCard.withValues(alpha: 0.5),
              border: Border(top: BorderSide(color: theme.borderSubtle)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 16),
                  _buildStatRow(
                    'Active Nodes', 
                    _isLoadingStats ? '...' : _activeNodesCount.toString(), 
                    theme
                  ),
                  const SizedBox(height: 8),
                  _buildStatRow('Status', 'Synced Locally', theme),
                ],
              ),
            ),
          ),
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

  Widget _buildSectionHeader(String title, VoidTheme theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 24, 12),
      child: Text(
        title,
        style: GoogleFonts.ibmPlexMono(
          color: theme.textTertiary.withValues(alpha: 0.5),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
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
                if (isComingSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.textMuted.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'SOON',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: theme.textMuted,
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
