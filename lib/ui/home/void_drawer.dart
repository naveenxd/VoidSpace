import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/void_theme.dart';

import '../../services/haptic_service.dart';
import '../trash/trash_screen.dart';

class VoidDrawer extends StatelessWidget {
  final VoidCallback onReturnFromTrash;

  const VoidDrawer({
    super.key,
    required this.onReturnFromTrash,
  });

  @override
  Widget build(BuildContext context) {
    final theme = VoidTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      backgroundColor: theme.bgCard,
      surfaceTintColor: Colors.transparent,
      elevation: isDark ? 1 : 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 40, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'void',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -1.5,
                      color: theme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.textPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'BETA',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        color: theme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Primary Navigation
            _buildDrawerItem(
              context,
              icon: Icons.all_inbox_rounded,
              title: "All Items",
              isSelected: true,
              theme: theme,
              onTap: () {
                HapticService.light();
                Navigator.pop(context);
              },
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Divider(
                color: theme.borderSubtle.withValues(alpha: 0.5),
                height: 1,
              ),
            ),

            /*
            _buildSectionHeader("ORGANIZATION", theme),

            _buildDrawerItem(
              context,
              icon: Icons.folder_outlined,
              title: "Folders",
              isSelected: false,
              theme: theme,
              onTap: () {
                HapticService.light();
                // TODO: Folders implementation
                Navigator.pop(context);
              },
            ),

            _buildDrawerItem(
              context,
              icon: Icons.star_border_rounded,
              title: "Favorites",
              isSelected: false,
              theme: theme,
              onTap: () {
                HapticService.light();
                // TODO: Favorites implementation
                Navigator.pop(context);
              },
            ),
            */

            const Spacer(),

            // Footer Navigation (Trash, Settings, etc.)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Divider(
                color: theme.borderSubtle.withValues(alpha: 0.5),
                height: 1,
              ),
            ),

            _buildDrawerItem(
              context,
              icon: Icons.delete_outline_rounded,
              title: "Trash",
              isSelected: false,
              theme: theme,
              isDestructive: true,
              onTap: () async {
                HapticService.light();
                Navigator.pop(context); // Close drawer
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrashScreen()),
                );
                // Trigger refresh on the home screen when returning from Trash
                if (context.mounted) {
                   onReturnFromTrash();
                }
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, bottom: 12, top: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          color: theme.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
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
    bool isDestructive = false,
  }) {
    final Color activeColor = isDestructive ? Colors.redAccent : theme.textPrimary;
    final Color inactiveColor = isDestructive 
        ? Colors.redAccent.withValues(alpha: 0.7) 
        : theme.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          highlightColor: theme.textPrimary.withValues(alpha: 0.05),
          splashColor: theme.textPrimary.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? activeColor : inactiveColor,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? activeColor : inactiveColor,
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
