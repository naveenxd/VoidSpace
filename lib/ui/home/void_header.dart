import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../profile/profile_screen.dart';
import '../../data/stores/preferences_store.dart';
import '../theme/void_design.dart';
import '../theme/void_theme.dart';

class VoidHeader extends StatelessWidget {
  final double blurOpacity;
  final List<String> availableTags;
  final Set<String> selectedTags;
  final VoidCallback onClearFilters;
  final Function(String) onToggleTag;
  final Color Function(String) getTagColor;
  final VoidCallback onOpenMenu;

  const VoidHeader({
    super.key,
    this.blurOpacity = 0.0,
    this.availableTags = const [],
    this.selectedTags = const {},
    required this.onClearFilters,
    required this.onToggleTag,
    required this.getTagColor,
    required this.onOpenMenu,
  });

  @override
  Widget build(BuildContext context) {
    final theme = VoidTheme.of(context);
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    const double headerContentHeight = 56.0;
    const double tagBarHeight = 52.0;
    final bool hasTags = availableTags.isNotEmpty;
    // Add 1.0 to totalHeight to account for the bottom border which adds padding to the container
    final double totalHeight =
        statusBarHeight +
        headerContentHeight +
        (hasTags ? tagBarHeight : 0) +
        1.0;

    // Always have blur for frosted effect
    final effectiveBlur = 0.4 + (0.6 * blurOpacity);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 15 * effectiveBlur,
          sigmaY: 15 * effectiveBlur,
        ),
        child: Container(
          height: totalHeight,
          decoration: BoxDecoration(
            color: theme.bgPrimary.withValues(alpha: 0.4 + (0.3 * blurOpacity)),
            border: Border(
              bottom: BorderSide(color: theme.borderSubtle, width: 1),
            ),
          ),
          child: Column(
            children: [
              // Status bar space + header content
              Container(
                height: statusBarHeight + headerContentHeight,
                padding: EdgeInsets.fromLTRB(16, statusBarHeight, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.notes_rounded,
                            color: theme.textSecondary,
                            size: 26,
                          ),
                          onPressed: onOpenMenu,
                          splashRadius: 20,
                        ),
                        const SizedBox(width: 4),
                        Hero(
                          tag: 'void_brand',
                          child: Material(
                            type: MaterialType.transparency,
                            child: Text(
                              'void',
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 28,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -1.0,
                                color: theme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    StatefulBuilder(
                      builder: (context, setInnerState) {
                        final String? currentProfilePicPath = PreferencesStore.userProfilePicture;
                        return GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreen(),
                            ),
                          ).then((_) {
                            if (context.mounted) {
                              setInnerState(() {});
                            }
                          }),
                          child: Hero(
                            tag: 'profile_icon_hero',
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.textPrimary.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: theme.textPrimary.withValues(alpha: 0.1),
                                ),
                                image: (currentProfilePicPath != null && File(currentProfilePicPath).existsSync())
                                    ? DecorationImage(
                                        image: FileImage(File(currentProfilePicPath)),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: (currentProfilePicPath == null || !File(currentProfilePicPath).existsSync())
                                  ? Icon(
                                      Icons.person,
                                      size: 18,
                                      color: theme.textSecondary,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      }
                    ),
                  ],
                ),
              ),

              // Tags bar (integrated) - uses remaining space
              if (hasTags) Expanded(child: _buildTagsRow(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagsRow(BuildContext context) {
    final theme = VoidTheme.of(context);
    // Use a SingleChildScrollView + Row to avoid gesture conflicts with
    // the main vertical scroll view and ensure reliable horizontal drag.
    final List<Widget> children = [];

    // "All" chip
    final isAllSelected = selectedTags.isEmpty;
    children.add(Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onClearFilters,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isAllSelected
                ? theme.textPrimary.withValues(alpha: 0.15)
                : theme.textPrimary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(VoidDesign.radiusMD),
            border: Border.all(
              color: isAllSelected
                  ? theme.textPrimary.withValues(alpha: 0.3)
                  : theme.borderSubtle,
            ),
          ),
          child: Text(
            "All",
            style: GoogleFonts.ibmPlexSans(
              color: isAllSelected ? theme.textPrimary : theme.textTertiary,
              fontSize: 13,
              fontWeight: isAllSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    ));

    for (final tag in availableTags) {
      final isSelected = selectedTags.contains(tag);
      final tagColor = getTagColor(tag);

      children.add(Padding(
        padding: const EdgeInsets.only(right: 10),
        child: GestureDetector(
          onTap: () => onToggleTag(tag),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 12 : 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? tagColor.withValues(alpha: 0.15)
                  : theme.textPrimary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? tagColor.withValues(alpha: 0.4)
                    : theme.textPrimary.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tag,
                  style: GoogleFonts.ibmPlexSans(
                    color: isSelected ? tagColor : theme.textTertiary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: tagColor.withValues(alpha: 0.8),
                  ),
                ],
              ],
            ),
          ),
        ),
      ));
    }

    return SizedBox(
      height: 52,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(children: children),
      ),
    );
  }
}
