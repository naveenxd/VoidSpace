// lib/ui/profile/profile_screen.dart
// Main profile screen with extracted component imports

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'dart:convert';
import 'package:file_selector/file_selector.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// import 'about_screen.dart';
import '../../data/stores/void_store.dart';
import '../../data/stores/preferences_store.dart';
import '../../data/models/void_item.dart';
import '../../data/database/void_database.dart';
import '../../services/security_service.dart';
import '../../services/haptic_service.dart';
import '../../app/feature_flags.dart';
import '../theme/void_design.dart';
import '../theme/void_theme.dart';
import '../theme/theme_provider.dart';

// Extracted components
import 'components/profile_tiles.dart';
import 'components/glitchy_404.dart';
import '../widgets/glass_card.dart';
import '../painters/custom_painters.dart';
import '../widgets/void_snackbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  bool _isLockEnabled = false;
  int _itemCount = 0;
  int _linkCount = 0;
  int _noteCount = 0;
  String _storageSize = "0 KB";
  
  String _displayName = PreferencesStore.userName;
  String? _profilePicPath = PreferencesStore.userProfilePicture;
  bool _isEditingName = false;
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  late AnimationController _dataStreamController;
  late AnimationController _statsAnimController;

  @override
  void initState() {
    super.initState();
    _dataStreamController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _statsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _loadData();
  }

  @override
  void dispose() {
    _dataStreamController.dispose();
    _statsAnimController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName(String val) async {
    final name = val.trim();
    if (name.isNotEmpty) {
      await PreferencesStore.setUserName(name);
      setState(() {
        _displayName = name;
        _isEditingName = false;
      });
    } else {
      setState(() => _isEditingName = false);
    }
  }

  Future<void> _loadData() async {
    final enabled = await SecurityService.isLockEnabled();
    final items = await VoidStore.all();
    final links = items.where((i) => i.type == 'link').length;
    final notes = items.where((i) => i.type == 'note').length;
    final size = (items.length * 0.45).toStringAsFixed(1);

    if (!mounted) return;
    setState(() {
      _isLockEnabled = enabled;
      _itemCount = items.length;
      _linkCount = links;
      _noteCount = notes;
      _storageSize = "$size KB";
      _displayName = PreferencesStore.userName;
      _profilePicPath = PreferencesStore.userProfilePicture;
      _nameController.text = _displayName;
    });

    _statsAnimController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    final theme = VoidTheme.of(context);
    return Scaffold(
      backgroundColor: theme.bgPrimary,
      body: Stack(
        children: [
          // 1. Animated Data Stream Background
          AnimatedBuilder(
            animation: _dataStreamController,
            builder: (context, child) {
              return CustomPaint(
                painter: DataStreamPainter(_dataStreamController.value),
                size: Size.infinite,
              );
            },
          ),

          // 2. Main Content with scroll
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  VoidDesign.pageHorizontal,
                  statusBarHeight + VoidDesign.spaceMD,
                  VoidDesign.pageHorizontal,
                  VoidDesign.space3XL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, theme),
                  const SizedBox(height: 24),
                  _buildSectionTitle("ACCOUNT", theme),
                  const SizedBox(height: 12),
                  _buildAccountSection(theme),
                  const SizedBox(height: 32),
                  _buildSectionTitle("VAULT METRICS", theme),
                  const SizedBox(height: 12),
                  _buildStatsSection(theme),
                  const SizedBox(height: 32),
                  _buildSectionTitle("SECURITY", theme),
                  const SizedBox(height: 12),
                  _buildSecuritySection(theme),
                  if (isAiEnabled) ...[
                    const SizedBox(height: 28),
                    _buildSectionTitle("AI SETTINGS", theme),
                    const SizedBox(height: 12),
                    _buildAISettingsSection(theme),
                  ],
                  const SizedBox(height: 28),
                  _buildSectionTitle("DATA", theme),
                  const SizedBox(height: 12),
                  _buildDataSection(theme),
                  const SizedBox(height: 28),
                  _buildSectionTitle("DANGER ZONE", theme),
                  const SizedBox(height: 12),
                  _buildDangerSection(theme),
                  /*
                  const SizedBox(height: 32),
                  _buildSectionTitle("SYSTEM", theme),
                  const SizedBox(height: 12),
                  _buildAboutSection(theme),
                  */
                  const SizedBox(height: 48),
                  _buildVersionFooter(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, VoidTheme theme) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.textPrimary.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 16,
          color: theme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildAccountSection(VoidTheme theme) {
    return GlassCard(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
/*
                Hero(
                  tag: 'profile_icon_hero',
                  child: GestureDetector(
                    onTap: () async {
                      HapticService.light();
                      final image = await _picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        await PreferencesStore.setUserProfilePicture(image.path);
                        setState(() => _profilePicPath = image.path);
                      }
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.textPrimary.withValues(alpha: 0.1),
                        border: Border.all(color: theme.textPrimary.withValues(alpha: 0.1)),
                        image: _profilePicPath != null
                            ? DecorationImage(
                                image: FileImage(File(_profilePicPath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _profilePicPath == null ? Icon(Icons.person_rounded, size: 32, color: theme.textSecondary) : null,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (_isEditingName) ... [
                            Expanded(
                              child: TextField(
                                controller: _nameController,
                                autofocus: true,
                                style: GoogleFonts.ibmPlexSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textPrimary,
                                ),
                                onSubmitted: _saveName,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.check, size: 18, color: theme.textPrimary),
                              onPressed: () => _saveName(_nameController.text),
                            ),
                          ] else 
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isEditingName = true),
                                child: Text(
                                  _displayName,
                                  style: GoogleFonts.ibmPlexSans(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (!_isEditingName) ...[
                        const SizedBox(height: 4),
                        Text(
                          'ID: PX-509-ALPHA',
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 10,
                            color: theme.textTertiary,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
*/
                const Expanded(child: SizedBox(height: 64)),
              ],
            ),
          ),
          Divider(color: theme.textPrimary.withValues(alpha: 0.05), height: 1),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return ToggleTile(
                icon: themeProvider.isDarkMode 
                    ? Icons.dark_mode_rounded 
                    : Icons.light_mode_rounded,
                iconColor: themeProvider.isDarkMode ? Colors.purpleAccent : Colors.orangeAccent,
                title: 'Dark Mode',
                value: themeProvider.isDarkMode,
                onChanged: (_) => themeProvider.toggleTheme(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(VoidTheme theme) {
    return GlassCard(
      child: ToggleTile(
        icon: Icons.fingerprint_rounded,
        title: "Biometric Lock",
        subtitle: "Require authentication on startup",
        value: _isLockEnabled,
        onChanged: (val) async {
          HapticService.medium();
          await SecurityService.setLockEnabled(val);
          setState(() => _isLockEnabled = val);
        },
      ),
    );
  }

  Widget _buildAISettingsSection(VoidTheme theme) {
    return GlassCard(
      child: ActionTile(
        icon: Icons.auto_awesome,
        title: 'AI Analysis',
        subtitle: 'Powered by Cloudflare Workers AI',
        onTap: () {
          HapticService.light();
          // No configuration needed - AI is always available
        },
      ),
    );
  }

  Widget _buildDataSection(VoidTheme theme) {
    return GlassCard(
      child: Column(
        children: [
          ActionTile(
            icon: Icons.upload_rounded,
            title: 'Export Vault',
            subtitle: 'Save fragments to file',
            onTap: _exportData,
          ),
          Divider(color: theme.textPrimary.withValues(alpha: 0.05), height: 1),
          ActionTile(
            icon: Icons.download_rounded,
            title: 'Import Vault',
            subtitle: 'Restore from backup',
            onTap: _importData,
          ),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    HapticService.light();
    try {
      final allItems = await VoidStore.all(includeDeleted: true);
      final jsonList = allItems.map((i) => i.toJson()).toList();
      final jsonStr = jsonEncode(jsonList);

      final now = DateTime.now();
      final nameStr = 'backup_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.json';

      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/$nameStr');
        await file.writeAsString(jsonStr);

        final xFile = XFile(file.path, mimeType: 'application/json');
        final result = await SharePlus.instance.share(ShareParams(files: [xFile], text: 'VoidSpace Vault Backup'));

        if (result.status == ShareResultStatus.success && mounted) {
          VoidSnackBar.show(
            context,
            message: 'Vault exported successfully',
            icon: Icons.check_circle_outline,
          );
        }
      } else {
        final location = await getSaveLocation(suggestedName: nameStr);
        if (location != null) {
          final path = location.path;
          final file = File(path);
          await file.writeAsString(jsonStr);
          if (mounted) {
            VoidSnackBar.show(
              context,
              message: 'Vault exported to ${file.path.split('/').last}',
              icon: Icons.check_circle_outline,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        VoidSnackBar.show(
          context,
          message: 'Failed to export vault: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _importData() async {
    HapticService.light();
    const XTypeGroup jsonTypeGroup = XTypeGroup(
      label: 'JSON Data',
      extensions: ['json'],
    );
    try {
      final file = await openFile(acceptedTypeGroups: [jsonTypeGroup]);
      if (file != null) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        final importedItems = jsonList.map((j) => VoidItem.fromJson(j)).toList();

        if (mounted) {
          _showImportBottomSheet(context, VoidTheme.of(context), importedItems);
        }
      }
    } catch (e) {
      if (mounted) {
        VoidSnackBar.show(
          context,
          message: 'Invalid backup file',
          isError: true,
        );
      }
    }
  }

  void _showImportBottomSheet(BuildContext context, VoidTheme theme, List<VoidItem> importedItems) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1C), // Deep premium greyish background
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag indicator pill
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Header
              Text(
                'Import Vault',
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Found ${importedItems.length} items in the backup file.',
                textAlign: TextAlign.center,
                style: GoogleFonts.ibmPlexSans(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              
              // MERGE OPTION
              GestureDetector(
                onTap: () async {
                  HapticService.selection();
                  Navigator.pop(ctx);
                  int added = 0;
                  int skipped = 0;
                  final existingIds = VoidDatabase.box.keys.toSet();
                  for (var item in importedItems) {
                    try {
                      if (!existingIds.contains(item.id)) {
                        await VoidDatabase.insertItem(item);
                        added++;
                      } else {
                        skipped++;
                      }
                    } catch (_) { skipped++; }
                  }
                  if (!context.mounted) return;
                  VoidSnackBar.show(
                    context,
                    message: 'Merged. $added added, $skipped skipped.',
                    icon: Icons.merge_type,
                  );
                  _loadData();
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call_merge_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Merge Keep Existing',
                              style: GoogleFonts.ibmPlexSans(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Safely add new items without overwriting current data.',
                              style: GoogleFonts.ibmPlexSans(
                                color: Colors.white.withValues(alpha: 0.6),
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
              
              const SizedBox(height: 16),
              
              // REPLACE OPTION
              GestureDetector(
                onTap: () async {
                  HapticService.heavy();
                  Navigator.pop(ctx);
                  await VoidStore.clear();
                  for (var item in importedItems) {
                    await VoidDatabase.insertItem(item);
                  }
                  if (!context.mounted) return;
                  VoidSnackBar.show(
                    context,
                    message: 'Data replaced. ${importedItems.length} loaded.',
                    icon: Icons.warning_amber_rounded,
                  );
                  _loadData();
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Erase & Replace All',
                              style: GoogleFonts.ibmPlexSans(
                                color: Colors.redAccent,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Permanently destroy current vault and load backup.',
                              style: GoogleFonts.ibmPlexSans(
                                color: Colors.redAccent.withValues(alpha: 0.8),
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
              
              const SizedBox(height: 24),
              // Cancel Button
              TextButton(
                onPressed: () {
                  HapticService.light();
                  Navigator.pop(ctx);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.ibmPlexSans(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildDangerSection(VoidTheme theme) {
    return GlassCard(
      borderColor: Colors.redAccent.withValues(alpha: 0.2),
      child: ActionTile(
        icon: Icons.delete_forever_rounded,
        iconColor: Colors.redAccent,
        title: 'Purge Vault',
        subtitle: 'Permanently erase all data',
        onTap: () {
          HapticService.heavy();
          // TODO: Implement purge with confirmation
        },
      ),
    );
  }

/*
  Widget _buildAboutSection(VoidTheme theme) {
    return GlassCard(
      child: ActionTile(
        icon: Icons.info_outline_rounded,
        title: 'About Void',
        subtitle: 'System info and developer',
        onTap: () {
          HapticService.light();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AboutScreen()),
          );
        },
      ),
    );
  }
*/

  Widget _buildStatsSection(VoidTheme theme) {
    if (_itemCount == 0) {
      return _buildEmptyStatsPlaceholder();
    }

    return AnimatedBuilder(
      animation: _statsAnimController,
      builder: (context, _) {
        return Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Main Data Core
                  Expanded(
                    flex: 6,
                    child: GlassCard(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.textPrimary.withValues(alpha: 0.08),
                          theme.textPrimary.withValues(alpha: 0.02),
                        ],
                      ),
                      padding: EdgeInsets.zero,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: TechRingPainter(
                                  _dataStreamController.value),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildDataCoreHeader(),
                                _buildItemCountDisplay(theme),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Right Modules
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        Expanded(
                            child: _buildStatModule("Links",
                                _linkCount.toString(), Icons.link_rounded, Colors.cyanAccent, theme)),
                        const SizedBox(height: 12),
                        Expanded(
                            child: _buildStatModule(
                                "Notes",
                                _noteCount.toString(),
                                Icons.sticky_note_2_outlined,
                                Colors.purpleAccent, theme)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildStorageBar(theme),
          ],
        );
      },
    );
  }

  Widget _buildDataCoreHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.cyanAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.hub_rounded, color: Colors.cyanAccent, size: 14),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.cyanAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.cyanAccent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "ACTIVE",
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 9,
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemCountDisplay(VoidTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: _itemCount),
          duration: const Duration(seconds: 1),
          builder: (context, val, _) => Text(
            val.toString(),
            style: GoogleFonts.ibmPlexSans(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: theme.textPrimary,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Total Items",
          style: GoogleFonts.ibmPlexMono(
            fontSize: 11,
            color: theme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatModule(
      String label, String value, IconData icon, Color color, VoidTheme theme) {
    return GlassCard(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                label,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 11,
                  color: theme.textSecondary,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 24,
                  color: theme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStorageBar(VoidTheme theme) {
    return GlassCard(
      gradient: LinearGradient(
        colors: [theme.textPrimary.withValues(alpha: 0.05), Colors.transparent],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.storage_rounded, size: 16, color: Colors.greenAccent),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Storage",
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 11,
                  color: theme.textSecondary,
                ),
              ),
              Text(
                _storageSize,
                style: GoogleFonts.ibmPlexSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              width: 80,
              child: Row(
                children: [
                  Expanded(flex: 3, child: Container(color: Colors.blueAccent)),
                  const SizedBox(width: 2),
                  Expanded(flex: 2, child: Container(color: Colors.cyanAccent)),
                  const SizedBox(width: 2),
                  Expanded(flex: 5, child: Container(color: theme.textPrimary.withValues(alpha: 0.1))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStatsPlaceholder() {
    // This widget doesn't strictly need theme since it's an error state using Glitchy404
    // But for consistency let's update colors if used
    // Actually it uses Colors.white.withValues, let's fix it if passed theme
    return Consumer<ThemeProvider>(
      builder: (context, provider, child) {
         final theme = VoidTheme.of(context);
         return GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: Center(
            child: Column(
              children: [
                const Glitchy404(),
                const SizedBox(height: 32),
                Text(
                  "SIGNAL_LOST",
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 14,
                    letterSpacing: 6,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "METRICS_UNAVAILABLE // RECOVERY_FAILED",
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 9,
                    letterSpacing: 1,
                    color: theme.textTertiary.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildSectionTitle(String title, VoidTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(left: VoidDesign.spaceXS),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 12,
            decoration: BoxDecoration(
              color: theme.textTertiary,
              borderRadius: BorderRadius.circular(VoidDesign.spaceXS),
            ),
          ),
          const SizedBox(width: VoidDesign.spaceMD),
          Text(
            title,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              letterSpacing: 3,
              color: theme.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionFooter(VoidTheme theme) {
    return Center(
      child: Text(
        'void v1.0.0',
        style: GoogleFonts.ibmPlexMono(
          fontSize: 10,
          color: theme.textPrimary.withValues(alpha: 0.1),
          letterSpacing: 2,
        ),
      ),
    );
  }
}