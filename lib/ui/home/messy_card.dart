// ui/home/messy_card.dart
import 'dart:io';
import 'dart:ui';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:void_space/data/models/void_item.dart';
import 'package:void_space/services/haptic_service.dart';
import 'package:void_space/ui/detail/item_detail_screen.dart';
import 'package:void_space/ui/theme/void_theme.dart';
import 'package:void_space/ui/utils/type_helpers.dart';
import '../utils/transitions.dart';
import '../painters/custom_painters.dart';

class MessyCard extends StatefulWidget {
  final VoidItem item;
  final VoidCallback onUpdate;
  final bool isSelected;
  final bool isSelectionMode;
  final Function(String) onSelect;
  final FocusNode searchFocusNode;
  final int index;

  const MessyCard({
    super.key,
    required this.item,
    required this.onUpdate,
    this.isSelected = false,
    this.isSelectionMode = false,
    required this.onSelect,
    required this.searchFocusNode,
    this.index = 0,
  });

  @override
  State<MessyCard> createState() => _MessyCardState();
}

class _MessyCardState extends State<MessyCard> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _breathingController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    if (widget.isSelected) {
      _breathingController.repeat(reverse: true);
    }

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
    
    // Subtler entrance delay
    Future.delayed(Duration(milliseconds: 30 * widget.index.clamp(0, 12)), () {
      if (mounted) _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  bool _isLocalPath(String path) {
    return path.startsWith('/') || path.startsWith('file://');
  }

  bool _isFileType(String type) {
    return type == 'image' || type == 'pdf' || type == 'document' || type == 'file' || type == 'video';
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'link':
        return Icons.link;
      case 'image':
        return Icons.image_rounded;
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'document':
        return Icons.description_rounded;
      case 'file':
        return Icons.insert_drive_file_rounded;
      case 'video':
        return Icons.video_file_rounded;
      case 'social':
        return Icons.share_rounded;
      default:
        return Icons.notes_rounded;
    }
  }

  Color _getColorForType(String type) => getColorForType(type);

  Widget _buildImagePreview(String imageUrl, VoidTheme theme) {
    if (widget.item.type == 'link') {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: _buildActualImage(imageUrl, BoxFit.cover, theme),
      );
    }
    return _buildActualImage(imageUrl, BoxFit.fitWidth, theme);
  }

  Widget _buildActualImage(String imageUrl, BoxFit fit, VoidTheme theme) {
    if (_isLocalPath(imageUrl)) {
      final file = File(imageUrl);
      return Image.file(
        file,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFileTypePreview(widget.item.type),
      );
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 300),
        maxWidthDiskCache: 1000,
        maxHeightDiskCache: 2000,
        placeholder: (context, url) => ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 120),
          child: Shimmer.fromColors(
            baseColor: theme.brightness == Brightness.dark 
                ? theme.textPrimary.withValues(alpha: 0.05)
                : theme.textPrimary.withValues(alpha: 0.08),
            highlightColor: theme.brightness == Brightness.dark
                ? theme.textPrimary.withValues(alpha: 0.1)
                : theme.textPrimary.withValues(alpha: 0.03),
            child: Container(
              height: 120,
              color: theme.bgCard,
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildFileTypePreview(widget.item.type),
      );
    }
  }

  Widget _buildFileTypePreview(String type) {
    IconData icon;
    Color color;
    
    switch (type) {
      case 'image':
        icon = Icons.image_rounded;
        color = const Color(0xFF00F2AD);
        break;
      case 'pdf':
        icon = Icons.picture_as_pdf_rounded;
        color = const Color(0xFFFF4D4D);
        break;
      case 'document':
        icon = Icons.description_rounded;
        color = const Color(0xFFFFB34D);
        break;
      case 'video':
        icon = Icons.video_file_rounded;
        color = const Color(0xFFB34DFF);
        break;
      case 'social':
        icon = Icons.share_rounded;
        color = const Color(0xFFFF4D94);
        break;
      default:
        icon = Icons.insert_drive_file_rounded;
        color = Colors.grey;
    }
    
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 40,
          color: color.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = VoidTheme.of(context);
    final rnd = Random(widget.item.id.hashCode);
    final double bottomStagger = 4.0 + rnd.nextInt(8);
    final typeColor = _getColorForType(widget.item.type);

    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onLongPress: () {
          widget.searchFocusNode.unfocus();
          HapticService.medium();
          widget.onSelect(widget.item.id);
        },
        onTap: () {
          widget.searchFocusNode.unfocus();
          if (widget.isSelectionMode) {
            HapticService.light();
            widget.onSelect(widget.item.id);
          } else {
            HapticService.light();
            Navigator.push(
              context,
              SmoothRoute(
                page: ItemDetailScreen(item: widget.item, onDelete: widget.onUpdate),
              ),
            );
          }
        },
        child: AnimatedBuilder(
          animation: _breathingController,
          builder: (context, child) {
            final pulse = _pulseAnimation.value;
            double scale = 1.0;
            if (_isPressed) scale = 0.98;
            if (widget.isSelected) scale = (0.96 + (pulse * 0.01));

            return AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                constraints: const BoxConstraints(minHeight: 100),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: theme.bgCard.withValues(alpha: theme.brightness == Brightness.dark ? 0.7 : 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isSelected
                        ? typeColor.withValues(alpha: 0.6 + (pulse * 0.2))
                        : theme.textPrimary.withValues(alpha: theme.brightness == Brightness.dark ? 0.1 : 0.05),
                    width: widget.isSelected ? 1.5 : 0.5,
                  ),
                  boxShadow: [
                    if (widget.isSelected)
                      BoxShadow(
                        color: typeColor.withValues(alpha: 0.2 + (pulse * 0.1)),
                        blurRadius: 15 + (pulse * 10),
                        spreadRadius: 1 + (pulse * 2),
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.transparent,
              child: Stack(
                children: [
                  // Subtle inner edge glow
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: theme.brightness == Brightness.dark ? 0.05 : 0.2),
                          width: 0.5,
                        ),
                      ),
                    ),
                  ),
                  // Tech background painter
                  Positioned.fill(
                    child: CustomPaint(
                      painter: CardDataPainter(
                        _entranceController.value,
                        color: theme.textPrimary,
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: widget.isSelected ? 0.4 : 1.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if ((widget.item.type == 'image' || widget.item.type == 'link') && widget.item.imageUrl != null && widget.item.imageUrl!.isNotEmpty)
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(11),
                                  topRight: Radius.circular(11),
                                ),
                                child: _buildImagePreview(widget.item.imageUrl!, theme),
                              ),
                              Positioned(
                                top: 10,
                                left: 10,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: theme.brightness == Brightness.dark 
                                            ? Colors.black.withValues(alpha: 0.4)
                                            : theme.bgCard.withValues(alpha: 0.9),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: typeColor.withValues(alpha: theme.brightness == Brightness.dark ? 0.3 : 0.15)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            _getIconForType(widget.item.type),
                                            size: 8,
                                            color: typeColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            widget.item.type.toUpperCase(),
                                            style: GoogleFonts.ibmPlexMono(
                                              color: typeColor,
                                              fontSize: 7,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else if (_isFileType(widget.item.type))
                          _buildFileTypePreview(widget.item.type),
                        
                        // Technical separation line
                        if ((widget.item.imageUrl != null && widget.item.imageUrl!.isNotEmpty) || _isFileType(widget.item.type))
                          Container(
                            height: 0.5,
                            width: double.infinity,
                            color: theme.textPrimary.withValues(alpha: 0.1),
                          ),
                        
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            14, 
                            widget.item.imageUrl != null && widget.item.imageUrl!.isNotEmpty ? 8 : 14, 
                            14, 
                            0
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.item.type == 'link' && (widget.item.imageUrl == null || widget.item.imageUrl!.isEmpty))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: typeColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          Uri.parse(widget.item.content).host.replaceFirst('www.', '').toLowerCase(),
                                          style: GoogleFonts.ibmPlexMono(
                                            color: typeColor.withValues(alpha: 0.5),
                                            fontSize: 8,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              
                              Text(
                                widget.item.title.isEmpty ? "Untitled Source" : widget.item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.ibmPlexSans(
                                  color: theme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.3,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              
                              if (widget.item.tags.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Wrap(
                                    spacing: 5,
                                    runSpacing: 5,
                                    children: [
                                      ...widget.item.tags.take(1).map((tag) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: typeColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '#$tag',
                                          style: GoogleFonts.ibmPlexMono(
                                            color: typeColor.withValues(alpha: 0.6),
                                            fontSize: 7.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )),
                                      if (widget.item.tags.length > 1)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                                          child: Text(
                                            '...',
                                            style: GoogleFonts.ibmPlexMono(
                                              color: theme.textTertiary,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                          child: Row(
                            children: [
                              if (widget.item.imageUrl == null || widget.item.imageUrl!.isEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: typeColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    _getIconForType(widget.item.type),
                                    size: 10,
                                    color: typeColor.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Expanded(
                                child: Text(
                                  _formatDate(widget.item.createdAt),
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.ibmPlexMono(
                                    color: theme.textMuted,
                                    fontSize: 8,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Neural ID / Hash
                              Text(
                                '0x${widget.item.id.substring(widget.item.id.length - 4)}',
                                style: GoogleFonts.ibmPlexMono(
                                  color: theme.textTertiary.withValues(alpha: 0.2),
                                  fontSize: 7,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: bottomStagger),
                      ],
                    ),
                  ),
                  if (widget.isSelected)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: typeColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: typeColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
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

  String _formatDate(DateTime date) => formatLivingDate(date);
}
