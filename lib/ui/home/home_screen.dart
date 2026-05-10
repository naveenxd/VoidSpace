import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:void_space/services/haptic_service.dart';
import 'package:void_space/ui/home/controllers/home_controller.dart';
import 'empty_state.dart';
import 'messy_card.dart';
import 'void_header.dart';
import 'manual_entry_overlay.dart';
import '../theme/void_design.dart';
import '../theme/void_theme.dart';
import 'components/skeleton_grid.dart';
import 'components/home_bottom_controls.dart';
import 'void_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // CONTROLLERS & NODES
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  final ValueNotifier<double> _headerBlurNotifier = ValueNotifier(0.0);
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late HomeController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = HomeController();

    _searchCtrl.addListener(() {
      _controller.applyFilters(_searchCtrl.text);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _headerBlurNotifier.dispose();
    _searchFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    final double newBlur = (_scrollCtrl.offset / 60).clamp(0.0, 1.0);
    if (_headerBlurNotifier.value != newBlur) {
      _headerBlurNotifier.value = newBlur;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.refresh();
      _searchFocusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<HomeController>(
        builder: (context, controller, child) {
          final theme = VoidTheme.of(context);
          final double keyboardHeight = MediaQuery.of(
            context,
          ).viewInsets.bottom;
          final bool isKeyboardOpen = keyboardHeight > 0;

          return PopScope(
            canPop: !controller.isSelectionMode,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              if (controller.isSelectionMode) {
                controller.clearSelection();
              }
            },
            child: Scaffold(
              key: _scaffoldKey,
              backgroundColor: theme.bgPrimary,
              resizeToAvoidBottomInset: false,
              drawerEnableOpenDragGesture: true,
              drawerEdgeDragWidth: MediaQuery.of(context).size.width * 0.6,
              drawer: VoidDrawer(
                onReturnFromTrash: () {
                  controller.refresh();
                },
              ),
              body: Stack(
                children: [
                  _buildMainContent(controller),

                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: theme.brightness == Brightness.dark ? 240 : 180,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              theme.bgPrimary.withValues(alpha: 0.0),
                              theme.bgPrimary.withValues(
                                alpha: theme.brightness == Brightness.dark
                                    ? 0.8
                                    : 0.2,
                              ),
                              theme.bgPrimary,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  ValueListenableBuilder<double>(
                    valueListenable: _headerBlurNotifier,
                    builder: (context, blurValue, _) {
                      return Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: VoidHeader(
                          blurOpacity: blurValue,
                          availableTags: controller.availableTags,
                          selectedTags: controller.selectedTags,
                          onClearFilters: controller.clearTagFilters,
                          onToggleTag: controller.toggleTag,
                          getTagColor: _getTagColor,
                          onOpenMenu: () =>
                              _scaffoldKey.currentState?.openDrawer(),
                        ),
                      );
                    },
                  ),

                  if (!controller.loading)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutQuart,
                      bottom: (isKeyboardOpen
                          ? keyboardHeight + 16
                          : MediaQuery.of(context).padding.bottom + 24),
                      left: 20,
                      right: 20,
                      child: HomeBottomControls(
                        isKeyboardOpen: isKeyboardOpen,
                        isSelectionMode: controller.isSelectionMode,
                        selectedCount: controller.selectedCount,
                        searchCtrl: _searchCtrl,
                        searchFocusNode: _searchFocusNode,
                        onClearSearch: () {
                          _searchCtrl.clear();
                        },
                        onCancelSelection: controller.clearSelection,
                        onAdd: () => _showManualEntry(context),
                        onDelete: () => controller.deleteSelected(context),
                        isEmptyState:
                            controller.isEmpty && _searchCtrl.text.isEmpty,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent(HomeController controller) {
    final theme = VoidTheme.of(context);
    if (controller.loading) {
      return SkeletonGrid(availableTags: controller.availableTags);
    }

    if (controller.isEmpty && _searchCtrl.text.isEmpty) {
      return const VoidEmptyState();
    }

    if (controller.filteredItems.isEmpty &&
        (_searchCtrl.text.isNotEmpty || controller.selectedTags.isNotEmpty)) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: theme.textMuted),
            const SizedBox(height: 16),
            Text(
              _searchCtrl.text.isNotEmpty
                  ? "NO MATCHES FOR '${_searchCtrl.text}'"
                  : "NO ITEMS WITH SELECTED TAGS",
              style: GoogleFonts.ibmPlexMono(
                color: theme.textTertiary,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
            if (controller.selectedTags.isNotEmpty) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: controller.clearTagFilters,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.borderSubtle),
                  ),
                  child: Text(
                    "CLEAR FILTERS",
                    style: GoogleFonts.ibmPlexMono(
                      color: theme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // Main scrollable content
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final headerHeight =
        statusBarHeight + 56 + (controller.availableTags.isNotEmpty ? 52 : 0);

    return RefreshIndicator(
      onRefresh: () async {
        HapticService.light();
        await controller.refresh();
        HapticService.success();
      },
      color: const Color(0xFF00F2AD),
      backgroundColor: theme.bgCard.withValues(alpha: 0.95),
      strokeWidth: 2.5,
      displacement: 20,
      edgeOffset: headerHeight,
      child: CustomScrollView(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              VoidDesign.pageHorizontal,
              headerHeight + VoidDesign.spaceMD,
              VoidDesign.pageHorizontal,
              VoidDesign.spaceMD,
            ),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: VoidDesign.spaceMD,
              crossAxisSpacing: VoidDesign.spaceMD,
              itemBuilder: (context, index) {
                final item = controller.filteredItems[index];
                return MessyCard(
                  key: ValueKey(item.id),
                  item: item,
                  onUpdate: controller.refresh,
                  isSelected: controller.selectedIds.contains(item.id),
                  isSelectionMode: controller.isSelectionMode,
                  onSelect: (id) {
                    _searchFocusNode.unfocus();
                    controller.toggleSelection(id);
                  },
                  searchFocusNode: _searchFocusNode,
                  index: index,
                );
              },
              childCount: controller.filteredItems.length,
            ),
          ),

          // Abyss Footer
          SliverToBoxAdapter(
            child: GestureDetector(
              onTap: () {
                HapticService.light();
                controller.refresh();
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 160),
                child: Column(
                  children: [
                    Container(
                      width: 2,
                      height: 28,
                      decoration: BoxDecoration(
                        color: theme.textMuted,
                        boxShadow: [
                          BoxShadow(
                            color: theme.textPrimary.withValues(alpha: 0.1),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "VOID SPACE",
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 11,
                        color: theme.textSecondary,
                        letterSpacing: 6.0,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(
                            color: Colors.cyanAccent.withValues(
                              alpha: theme.brightness == Brightness.dark
                                  ? 0.3
                                  : 0.1,
                            ),
                            blurRadius: 8,
                          ),
                        ],
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

  Color _getTagColor(String tag) {
    final hash = tag.hashCode.abs();
    final colors = [
      Colors.blueAccent,
      Colors.tealAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
      Colors.pinkAccent,
      Colors.cyanAccent,
      Colors.greenAccent,
      Colors.amberAccent,
    ];
    return colors[hash % colors.length];
  }

  void _showManualEntry(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ManualEntryOverlay(onSave: _controller.refresh),
    );
  }
}
