// lib/ui/detail/item_detail_screen.dart
// Refactored Item Detail Screen

import 'dart:async';
import 'dart:io';
import 'dart:ui'; // For ImageFilter
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart'; // For sharing
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart'; // For Clipboard

import 'package:void_space/data/models/void_item.dart';
import 'package:void_space/data/stores/void_store.dart';
import 'package:void_space/services/haptic_service.dart';
import 'package:void_space/app/feature_flags.dart';
import 'package:void_space/services/ai_service.dart';
import 'package:void_space/ui/theme/void_design.dart';
import 'package:void_space/ui/theme/void_theme.dart';
import 'package:void_space/ui/utils/type_helpers.dart';
import 'package:void_space/ui/widgets/void_dialog.dart';
import 'package:void_space/ui/widgets/void_snackbar.dart';
import 'package:void_space/services/void_share_service.dart';

// Components

import 'components/detail_metadata.dart';
import 'components/edit_item_form.dart';
import 'components/link_card.dart';
import 'components/summary_section.dart';

class ItemDetailScreen extends StatefulWidget {
  final VoidItem item;
  final VoidCallback onDelete;

  const ItemDetailScreen({
    super.key,
    required this.item,
    required this.onDelete,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late VoidItem _editedItem;
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isEditMode = false;
  bool _isNoteType = false;

  // AI & Similar Items State
  bool _isGeneratingAI = false;

  // Tags State
  late List<String> _editedTags;

  @override
  void initState() {
    super.initState();
    _editedItem = widget.item;
    _isNoteType = _editedItem.type == 'note';
    _editedTags = List.from(_editedItem.tags);

    _titleController = TextEditingController(text: _editedItem.title);
    _contentController = TextEditingController(text: _editedItem.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    if (_isEditMode) {
      _saveChanges();
    } else {
      setState(() => _isEditMode = true);
      HapticService.light();
    }
  }

  Future<void> _saveChanges() async {
    final newTitle = _titleController.text.trim();
    final newContent = _contentController.text.trim();

    if (newTitle.isEmpty) return;

    final updatedItem = _editedItem.copyWith(
      title: newTitle,
      content: newContent,
    );

    await VoidStore.update(updatedItem);

    if (mounted) {
      setState(() {
        _editedItem = updatedItem;
        _isEditMode = false;
      });
      HapticService.success();
    }
  }

  Future<void> _addTag(String tag) async {
    if (!_editedTags.contains(tag)) {
      setState(() => _editedTags.add(tag));
      HapticService.light();
    }
  }

  Future<void> _removeTag(String tag) async {
    setState(() => _editedTags.remove(tag));
  }

  Future<void> _saveTagsOnly(List<String> tags) async {
    // Updates state and persists to store immediately
    // This is used for direct tag manipulation outside full edit mode
    final updatedItem = _editedItem.copyWith(tags: tags);
    await VoidStore.update(updatedItem);
    setState(() {
      _editedItem = updatedItem;
      _editedTags = tags;
    });
    widget.onDelete(); // Trigger refresh on parent
  }

  Future<void> _openFile(String path) async {
    if (path.isEmpty) return;

    try {
      if (_editedItem.type == 'link' || path.startsWith('http')) {
        final Uri uri = Uri.parse(path);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (!mounted) return;
          VoidSnackBar.show(
            context,
            message: 'Could not open link',
            isError: true,
          );
        }
        return;
      }

      // Check if file exists
      if (!File(path).existsSync()) {
        if (!mounted) return;
        VoidSnackBar.show(context, message: 'File not found', isError: true);
        return;
      }

      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) {
        if (!mounted) return;
        VoidSnackBar.show(
          context,
          message: 'Could not open file: ${result.message}',
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('Error opening file: $e');
    }
  }

  Future<void> _confirmTrash(BuildContext context) async {
    HapticService.warning();
    final confirmed = await VoidDialog.show(
      context: context,
      title: 'Move to Trash?',
      message: 'This item will be moved to the Trash bin.',
      confirmText: 'Trash',
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed == true) {
      await VoidStore.delete(widget.item.id);
      HapticService.heavy();

      if (!mounted) return;
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
      widget.onDelete();
    }
  }

  void _showShareMenu() {
    final theme = VoidTheme.of(context);
    HapticService.medium();
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        bool isSharingPdf = false;
        bool isSharingWebsite = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.textPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'SHARE AS',
                    style: GoogleFonts.ibmPlexMono(
                      color: theme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildShareOption(
                    icon: Icons.picture_as_pdf_rounded,
                    label: 'PDF Document',
                    isLoading: isSharingPdf,
                    onTap: () async {
                      if (isSharingPdf || isSharingWebsite) return;
                      setSheetState(() => isSharingPdf = true);
                      await _shareAsPdf(sheetContext);
                      if (context.mounted)
                        setSheetState(() => isSharingPdf = false);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildShareOption(
                    icon: Icons.public_rounded,
                    label: 'Share as Website',
                    isLoading: isSharingWebsite,
                    onTap: () async {
                      if (isSharingPdf || isSharingWebsite) return;
                      setSheetState(() => isSharingWebsite = true);
                      await _shareAsWebsite(sheetContext);
                      if (context.mounted)
                        setSheetState(() => isSharingWebsite = false);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildShareOption(
                    icon: Icons.text_fields_rounded,
                    label: 'Plain Text',
                    onTap: () {
                      Navigator.pop(context);
                      _shareAsText();
                    },
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    final theme = VoidTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.textPrimary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.borderSubtle),
        ),
        child: Row(
          children: [
            if (isLoading)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(theme.textPrimary),
                ),
              )
            else
              Icon(icon, color: theme.textPrimary, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.ibmPlexSans(
                color: theme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: theme.textPrimary.withValues(alpha: 0.24),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareAsPdf(BuildContext sheetContext) async {
    HapticService.light();
    try {
      final pdfFile = await VoidShareService.generatePdfFile(_editedItem);
      HapticService.success();
      if (!mounted) return;
      Navigator.pop(sheetContext);
      // ignore: deprecated_member_use
      await Share.shareXFiles([
        XFile(pdfFile.path),
      ], text: 'Shared from Void Space');
    } catch (e) {
      if (!mounted) return;
      HapticService.heavy();
      Navigator.pop(sheetContext);
      VoidSnackBar.show(context, message: 'Failed to share: $e', isError: true);
    }
  }

  Future<void> _shareAsWebsite(BuildContext sheetContext) async {
    HapticService.light();
    try {
      final shortUrl = await VoidShareService.shareAsWebsite(_editedItem);
      Clipboard.setData(ClipboardData(text: shortUrl));
      HapticService.success();
      if (!mounted) return;
      Navigator.pop(sheetContext);
      VoidSnackBar.show(
        context,
        message: 'Website link copied to clipboard!',
        icon: Icons.check_circle_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      HapticService.heavy();
      Navigator.pop(sheetContext);
      VoidSnackBar.show(context, message: 'Failed to share: $e', isError: true);
    }
  }

  Future<void> _shareAsText() async {
    final String shareText = '${_editedItem.title}\n\n${_editedItem.content}';
    if (_editedItem.type == 'link') {
      // ignore: deprecated_member_use
      await Share.share('${_editedItem.title}\n${_editedItem.content}');
    } else {
      // ignore: deprecated_member_use
      await Share.share(shareText);
    }
  }

  Future<void> _generateAIContext() async {
    if (!isAiEnabled) return;
    setState(() => _isGeneratingAI = true);
    HapticService.medium();

    try {
      final context = await AIService.analyze(
        _editedItem.title,
        _editedItem.content,
        // Only pass image path if it's local
        imagePath: isLocalPath(_editedItem.imageUrl ?? '')
            ? _editedItem.imageUrl
            : null,
        url: _editedItem.type == 'link' ? _editedItem.content : null,
      );

      final updatedItem = _editedItem.copyWith(
        title: context.title.isNotEmpty
            ? context.title
            : _editedItem.title, // Update title!
        summary: context.summary,
        tldr: context.tldr,
        // Only update content for notes, preserve path/url for files/links
        content: _editedItem.type == 'note'
            ? context.summary
            : _editedItem.content,
        tags: context.tags, // Refresh tags as well
      );

      await VoidStore.update(updatedItem);

      if (mounted) {
        setState(() {
          _editedItem = updatedItem;
          _titleController.text =
              updatedItem.title; // Also update text controller
          _editedTags = List.from(updatedItem.tags); // Update local tags state
          _isGeneratingAI = false;
        });
        widget
            .onDelete(); // Trigger refresh on parent so home screen is updated
        HapticService.success();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingAI = false);
        HapticService.heavy();

        VoidSnackBar.show(
          context,
          message: 'AI Generation Failed: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = VoidTheme.of(context);
    return Scaffold(
      backgroundColor: theme.bgPrimary,
      body: Stack(
        children: [
          // 1. Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              if (_editedItem.imageUrl != null &&
                  _editedItem.imageUrl!.isNotEmpty)
                SliverAppBar(
                  expandedHeight: 400,
                  stretch: true,
                  pinned: false, // Revert to standard scrolling behaviors
                  // backgroundColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    stretchModes: const [StretchMode.zoomBackground],
                    background: _buildHeaderImageContent(),
                  ),
                ),

              // When there's no image, add top padding so content clears the floating header
              if (_editedItem.imageUrl == null || _editedItem.imageUrl!.isEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.top + 56,
                  ),
                ),

              // Explicit Separator Line
              SliverToBoxAdapter(
                child: Container(
                  height: 1,
                  color: theme.textPrimary.withValues(alpha: 0.15),
                ),
              ),

              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.bgPrimary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  // Removed overlap to allow separator to be distinct
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: 24, // Reduced from 120
                      top: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Section
                        if (_isEditMode)
                          EditItemForm(
                            titleController: _titleController,
                            contentController: _contentController,
                            isNoteType: _isNoteType,
                          )
                        else
                          Text(
                            _editedItem.title,
                            style: GoogleFonts.ibmPlexSans(
                              color: theme.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              letterSpacing: -0.5,
                            ),
                          ),

                        const SizedBox(height: VoidDesign.spaceLG),

                        // Metadata & Tags
                        DetailMetadata(
                          item: _editedItem,
                          tags: _editedTags,
                          onAddTag: (tag) async {
                            await _addTag(tag);
                            await _saveTagsOnly(_editedTags);
                          },
                          onRemoveTag: _removeTag,
                          onSaveTags: _saveTagsOnly,
                        ),

                        const SizedBox(height: VoidDesign.space2XL),

                        // Dynamic Content Area
                        if (_isEditMode && _isNoteType)
                          // Content handled in EditItemForm above
                          const SizedBox.shrink()
                        else if (_editedItem.type == 'link') ...[
                          LinkCard(item: _editedItem),
                          if ((_editedItem.summary?.isNotEmpty ?? false) ||
                              (_editedItem.tldr?.isNotEmpty ?? false)) ...[
                            const SizedBox(height: VoidDesign.spaceXL),
                            SummarySection(
                              item: _editedItem,
                              isGenerating: _isGeneratingAI,
                              onGenerate: _generateAIContext,
                            ),
                          ],
                        ] else ...[
                          // Show AI Summary if available (TLDR, etc.)
                          if ((_editedItem.summary?.isNotEmpty ?? false) ||
                              (_editedItem.tldr?.isNotEmpty ?? false)) ...[
                            SummarySection(
                              item: _editedItem,
                              isGenerating: _isGeneratingAI,
                              onGenerate: _generateAIContext,
                            ),
                            const SizedBox(height: VoidDesign.spaceXL),
                          ],

                          // Only show raw content if it's not identical to the summary/tldr
                          // (Usually for images, the 'content' field is just a duplicate of summary)
                          if (_shouldShowContentSection())
                            _buildContentSection(),
                        ],

                        /* 
                         Moved Open File button to bottom actions row 
                         for better reachability and cleaner UI 
                      */

                        // Actions (View, Share, Delete) - Only visible when not editing
                        if (!_isEditMode) ...[
                          const SizedBox(height: 24), // Reduced from 60
                          _buildBottomActions(context),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // 2. Floating Header Actions
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticService.light();
                        Navigator.pop(context);
                        widget.onDelete(); // Trigger refresh on parent
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.2),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _toggleEditMode,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isEditMode
                                  ? Colors.greenAccent.withValues(alpha: 0.2)
                                  : Colors.black.withValues(alpha: 0.2),
                              border: Border.all(
                                color: _isEditMode
                                    ? Colors.greenAccent
                                    : Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Icon(
                              _isEditMode
                                  ? Icons.check_rounded
                                  : Icons.edit_rounded,
                              size: 20,
                              color: _isEditMode
                                  ? Colors.greenAccent
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderImageContent() {
    final theme = VoidTheme.of(context);
    if (_editedItem.imageUrl != null && _editedItem.imageUrl!.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(color: theme.bgCard.withValues(alpha: 0.2)),
        child: isLocalPath(_editedItem.imageUrl!)
            ? Image.file(File(_editedItem.imageUrl!), fit: BoxFit.cover)
            : CachedNetworkImage(
                imageUrl: _editedItem.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: theme.textPrimary.withValues(alpha: 0.05)),
                errorWidget: (context, url, error) => Center(
                  child: Icon(
                    Icons.image_not_supported_rounded,
                    color: theme.textPrimary.withValues(alpha: 0.24),
                    size: 40,
                  ),
                ),
              ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildContentSection() {
    final theme = VoidTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: theme.textPrimary.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'CONTENT',
              style: GoogleFonts.ibmPlexMono(
                color: theme.textPrimary.withValues(alpha: 0.24),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.textPrimary.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.borderSubtle),
          ),
          child: Text(
            _editedItem.content,
            style: GoogleFonts.ibmPlexSans(
              color: theme.textSecondary,
              fontSize: 15,
              height: 1.7,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final theme = VoidTheme.of(context);
    final isFile = isFileType(_editedItem.type);

    return Column(
      children: [
        Row(
          children: [
            // Share Button (Secondary)
            GestureDetector(
              onTap: () {
                HapticService.light();
                _showShareMenu();
              },
              child: Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: theme.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.borderSubtle),
                ),
                child: Icon(
                  Icons.ios_share_rounded,
                  color: theme.textPrimary,
                  size: 22,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // View / Open File / Copy (Primary Action)
            if (isFile ||
                _editedItem.type == 'link' ||
                _editedItem.type == 'note') ...[
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticService.medium();
                      if (_editedItem.type == 'note') {
                        Clipboard.setData(
                          ClipboardData(text: _editedItem.content),
                        );
                        VoidSnackBar.show(
                          context,
                          message: 'Copied to clipboard',
                          icon: Icons.check_circle_outline_rounded,
                        );
                      } else {
                        // Use imageUrl for images, otherwise content (files/links)
                        String path = _editedItem.type == 'image'
                            ? (_editedItem.imageUrl ?? _editedItem.content)
                            : _editedItem.content;
                        _openFile(path);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.textPrimary,
                      foregroundColor: theme.bgPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _editedItem.type == 'note'
                              ? Icons.copy_rounded
                              : (_editedItem.type == 'link'
                                    ? Icons.open_in_new_rounded
                                    : Icons.open_in_full_rounded),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _editedItem.type == 'note'
                              ? "Copy Text"
                              : (_editedItem.type == 'link'
                                    ? "Open Link"
                                    : "Open File"),
                          style: GoogleFonts.ibmPlexSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],

            // Trash Button
            GestureDetector(
              onTap: () {
                HapticService.light();
                _confirmTrash(context);
              },
              child: Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: theme.textPrimary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.borderSubtle),
                ),
                child: Center(
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: theme.textSecondary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),

        // Extra bottom padding for scrolling
        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ],
    );
  }

  bool _shouldShowContentSection() {
    if (_editedItem.type == 'note') return true;
    if (_editedItem.content.isEmpty) return false;

    // For images/files, if content is same as summary or tldr, it's redundant
    if (_editedItem.imageUrl != null) {
      if (_editedItem.content == _editedItem.summary) return false;
      if (_editedItem.content == _editedItem.tldr) return false;
    }

    return true;
  }
}
