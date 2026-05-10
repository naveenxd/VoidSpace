import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:void_space/data/models/void_item.dart';
import 'package:void_space/data/stores/void_store.dart';
import 'package:void_space/services/haptic_service.dart';
import 'package:void_space/ui/theme/void_design.dart';
import 'package:void_space/ui/theme/void_theme.dart';
import 'package:void_space/ui/widgets/void_dialog.dart';

import '../home/messy_card.dart';
import '../widgets/void_snackbar.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  List<VoidItem> _trashItems = [];
  bool _isLoading = true;
  final FocusNode _dummyFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadTrash();
  }

  Future<void> _loadTrash() async {
    setState(() => _isLoading = true);
    final items = await VoidStore.getTrash();
    setState(() {
      _trashItems = items;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _dummyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _restoreItem(VoidItem item) async {
    HapticService.light();
    await VoidStore.restore(item.id);
    _loadTrash();
    if (mounted) {
      VoidSnackBar.show(
        context,
        message: 'Item restored to home view.',
        icon: Icons.restore_rounded,
      );
    }
  }

  Future<void> _deletePermanently(VoidItem item) async {
    HapticService.warning();
    final bool? confirm = await VoidDialog.show(
      context: context,
      title: "PERMANENTLY DELETE?",
      message: "This item will be gone forever.",
      confirmText: "DELETE",
    );

    if (confirm == true) {
      HapticService.heavy();
      await VoidStore.permanentlyDelete(item.id);
      _loadTrash();
      if (mounted) {
        VoidSnackBar.show(
          context,
          message: 'Item was removed forever.',
          icon: Icons.delete_forever_rounded,
          isError: true,
        );
      }
    }
  }

  Future<void> _emptyTrash() async {
    if (_trashItems.isEmpty) return;

    HapticService.warning();
    final bool? confirm = await VoidDialog.show(
      context: context,
      title: "EMPTY TRASH BIN?",
      message:
          "Are you sure? This will permanently delete ${_trashItems.length} items from limbo.",
      confirmText: "EMPTY",
    );

    if (confirm == true) {
      HapticService.heavy();
      final ids = _trashItems.map((e) => e.id).toSet();
      await VoidStore.permanentlyDeleteMany(ids);
      _loadTrash();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = VoidTheme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.bgPrimary,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: theme.bgPrimary.withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 24,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TRASH BIN',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
                color: theme.textPrimary,
              ),
            ),
            Text(
              'NODES IN LIMBO',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
                color: theme.textTertiary,
              ),
            ),
          ],
        ),
        iconTheme: IconThemeData(color: theme.textPrimary),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.6),
                radius: 1.5,
                colors: isDark 
                    ? [const Color(0xFF1A1A1A), const Color(0xFF0A0A0A)]
                    : [const Color(0xFFF1F3F5), const Color(0xFFE9ECEF)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: theme.textSecondary, strokeWidth: 2))
                  : _trashItems.isEmpty
                  ? _buildEmptyState(theme, isDark)
                  : _buildTrashGrid(theme, isDark),
            ),
          ),
          
          // Floating Bulk Action Bar
          if (_trashItems.isNotEmpty && !_isLoading)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 24,
              right: 24,
              child: _buildBulkActionBar(theme, isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildBulkActionBar(VoidTheme theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: theme.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: theme.textTertiary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${_trashItems.length} items in limbo',
              style: GoogleFonts.inter(
                color: theme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: _emptyTrash,
            style: TextButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'PURGE ALL',
              style: GoogleFonts.ibmPlexMono(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(VoidTheme theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: theme.textPrimary.withValues(alpha: 0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_delete_rounded,
              size: 64,
              color: theme.textMuted.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "VOID IS CLEAR",
            style: GoogleFonts.ibmPlexMono(
              color: theme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Limbo is currently empty.",
            style: GoogleFonts.inter(
              color: theme.textTertiary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrashGrid(VoidTheme theme, bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadTrash,
      color: const Color(0xFF00F2AD),
      backgroundColor: theme.bgCard,
      child: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        itemCount: _trashItems.length,
        itemBuilder: (context, index) {
          final item = _trashItems[index];
          
          return GestureDetector(
            onTap: () => _showActionMenu(context, item, theme, isDark),
            child: Opacity(
              opacity: 0.7,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(VoidDesign.radiusMD),
                  border: Border.all(
                    color: theme.borderSubtle,
                    style: BorderStyle.solid,
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(VoidDesign.radiusMD),
                  child: Stack(
                    children: [
                      IgnorePointer(
                        child: MessyCard(
                          key: ValueKey(item.id),
                          item: item,
                          index: index,
                          onUpdate: () async {},
                          onSelect: (_) {},
                          searchFocusNode: _dummyFocusNode,
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'LIMBO',
                            style: GoogleFonts.ibmPlexMono(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showActionMenu(BuildContext context, VoidItem item, VoidTheme theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              decoration: BoxDecoration(
                color: theme.bgCard.withValues(alpha: 0.8),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border(top: BorderSide(color: theme.borderSubtle.withValues(alpha: 0.5))),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.textMuted.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildActionCard(
                      context: context,
                      theme: theme,
                      isDark: isDark,
                      icon: Icons.restore_rounded,
                      iconColor: const Color(0xFF00F2AD),
                      title: 'Restore Node',
                      subtitle: 'Bring this item back to your active nodes.',
                      onTap: () {
                        Navigator.pop(context);
                        _restoreItem(item);
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildActionCard(
                      context: context,
                      theme: theme,
                      isDark: isDark,
                      icon: Icons.delete_forever_rounded,
                      iconColor: Colors.redAccent,
                      title: 'Purge Forever',
                      subtitle: 'This node will be lost to the void.',
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(context);
                        _deletePermanently(item);
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required VoidTheme theme,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: isDark ? const Color(0xFF1E1E1E).withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
             color: isDestructive 
                 ? Colors.redAccent.withValues(alpha: 0.2) 
                 : theme.borderSubtle.withValues(alpha: 0.3)
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: iconColor.withValues(alpha: 0.1),
          highlightColor: iconColor.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          color: isDestructive ? Colors.redAccent : theme.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: theme.textSecondary,
                          fontSize: 13,
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
    );
  }
}
