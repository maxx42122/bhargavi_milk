import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../services/product_service.dart';
import '../../state/auth_state.dart';
import '../../state/locale_state.dart';
import '../../widgets/app_badge.dart';
import '../../widgets/app_search_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/gradient_header.dart';

class ProductManagementScreen extends StatefulWidget {
  final String? distributorId;

  const ProductManagementScreen({super.key, this.distributorId});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  String _search = '';
  String _categoryFilter = 'All';
  String _statusFilter = 'All'; // 'All', 'Active', 'Inactive', 'Low Stock'

  final List<String> _categories = [
    'All',
    'Milk',
    'Curd',
    'Butter',
    'Paneer',
    'Ghee',
    'Buttermilk',
    'Other',
  ];

  final List<String> _statusOptions = [
    'All',
    'Active',
    'Inactive',
    'Low Stock',
  ];

  String _resolveDistributorId(BuildContext context) {
    if (widget.distributorId != null && widget.distributorId!.isNotEmpty) {
      return widget.distributorId!;
    }
    try {
      final authState = AuthStateScope.of(context);
      if (authState.distributorId != null &&
          authState.distributorId!.isNotEmpty) {
        return authState.distributorId!;
      }
    } catch (_) {}

    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  List<Product> _filterProducts(List<Product> products) {
    return products.where((p) {
      final q = _search.trim().toLowerCase();
      final matchSearch =
          q.isEmpty ||
          p.name.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q) ||
          p.packSize.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);

      final matchCat =
          _categoryFilter == 'All' || p.category == _categoryFilter;

      final matchStatus = switch (_statusFilter) {
        'Active' => p.active,
        'Inactive' => !p.active,
        'Low Stock' => p.stock <= 10,
        _ => true,
      };

      return matchSearch && matchCat && matchStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    final distributorId = _resolveDistributorId(context);

    if (distributorId.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 48,
                  color: AppColors.ink300,
                ),
                const SizedBox(height: 12),
                Text(
                  'Distributor session not found.',
                  style: AppTextStyles.bodyBold,
                ),
                const SizedBox(height: 6),
                Text(
                  'Please sign in again as a distributor.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.ink500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return StreamBuilder<List<Product>>(
      stream: ProductService.streamProducts(distributorId),
      builder: (context, snapshot) {
        final allProducts = snapshot.data ?? [];
        final filtered = _filterProducts(allProducts);

        final totalCount = allProducts.length;
        final activeCount = allProducts.where((p) => p.active).length;
        final lowStockCount = allProducts.where((p) => p.stock <= 10).length;

        final isLoading =
            snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              // HEADER
              GradientHeader(
                title: locale.t('nav_products'),
                subtitle: totalCount > 0
                    ? '$totalCount ${locale.t("nav_products").toLowerCase()} • $activeCount Active'
                    : locale.t('nav_products'),
                actions: [
                  if (allProducts.isEmpty && !isLoading)
                    IconButton(
                      icon: const Icon(Icons.playlist_add, color: Colors.white),
                      tooltip: locale.t('seed_products'),
                      onPressed: () =>
                          _seedCatalog(context, distributorId, locale),
                    ),
                  _InteractiveHeaderAddBtn(
                    tooltip: locale.t('add_product'),
                    onTap: () => _openProductModal(
                      context: context,
                      distributorId: distributorId,
                      locale: locale,
                    ),
                  ),
                ],
              ),

              // SEARCH & FILTERS
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  children: [
                    AppSearchBar(
                      hint:
                          '${locale.t("search")} ${locale.t("nav_products").toLowerCase()}…',
                      onChanged: (v) => setState(() => _search = v),
                    ),
                    const SizedBox(height: 10),

                    // Categories Bar
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _categories.map((cat) {
                          final active = _categoryFilter == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _FilterChip(
                              label: locale.translateCategory(cat),
                              active: active,
                              onTap: () =>
                                  setState(() => _categoryFilter = cat),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Status Filters Bar
                    SizedBox(
                      height: 32,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _statusOptions.map((st) {
                          final active = _statusFilter == st;
                          Color badgeColor = AppColors.ink500;
                          if (st == 'Active') {
                            badgeColor = AppColors.dairyGreen700;
                          } else if (st == 'Inactive') {
                            badgeColor = AppColors.red500;
                          } else if (st == 'Low Stock') {
                            badgeColor = AppColors.amber600;
                          }

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _statusFilter = st),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppColors.milkBlue100
                                      : AppColors.cardSurface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: active
                                        ? AppColors.milkBlue600
                                        : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (st != 'All') ...[
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: badgeColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                    ],
                                    Text(
                                      st == 'Low Stock'
                                          ? '${locale.translateStatus(st)} ($lowStockCount)'
                                          : locale.translateStatus(st),
                                      style: AppTextStyles.captionBold.copyWith(
                                        color: active
                                            ? AppColors.milkBlue700
                                            : AppColors.ink700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // PRODUCT LIST VIEW
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: AppColors.red500,
                                size: 40,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Error loading products',
                                style: AppTextStyles.bodyBold,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                snapshot.error.toString(),
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.ink500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (allProducts.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              EmptyState(
                                icon: Icons.inventory_2_outlined,
                                title: locale.t('no_data'),
                                subtitle:
                                    'No products in your catalog yet. Add products or load sample dairy catalog.',
                                buttonLabel: locale.t('add_product'),
                                onButton: () => _openProductModal(
                                  context: context,
                                  distributorId: distributorId,
                                  locale: locale,
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () => _seedCatalog(
                                  context,
                                  distributorId,
                                  locale,
                                ),
                                icon: const Icon(Icons.playlist_add),
                                label: Text('Milk'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (filtered.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.search_off,
                                size: 40,
                                color: AppColors.ink300,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                locale.t('no_matching_products'),
                                style: AppTextStyles.bodyBold,
                              ),
                              const SizedBox(height: 6),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _search = '';
                                    _categoryFilter = 'All';
                                    _statusFilter = 'All';
                                  });
                                },
                                child: Text(locale.t('reset_filter')),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final product = filtered[i];
                        return _ProductCard(
                          product: product,
                          distributorId: distributorId,
                          locale: locale,
                          onEdit: () => _openProductModal(
                            context: context,
                            distributorId: distributorId,
                            locale: locale,
                            existingProduct: product,
                          ),
                          onDelete: () => _confirmDeleteProduct(
                            context: context,
                            distributorId: distributorId,
                            product: product,
                            locale: locale,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: _InteractiveAddProductFab(
            onPressed: () => _openProductModal(
              context: context,
              distributorId: distributorId,
              locale: locale,
            ),
            label: locale.t('add_product'),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SEED SAMPLE CATALOG
  // ---------------------------------------------------------------------------

  Future<void> _seedCatalog(
    BuildContext context,
    String distributorId,
    LocaleState locale,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Loading sample dairy products...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      final count = await ProductService.seedInitialProducts(distributorId);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? 'Successfully added $count dairy products to your catalog!'
                : 'Products catalog already has items.',
          ),
          backgroundColor: AppColors.dairyGreen700,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to load sample products: $e'),
          backgroundColor: AppColors.red500,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // OPEN ADD / EDIT MODAL
  // ---------------------------------------------------------------------------

  void _openProductModal({
    required BuildContext context,
    required String distributorId,
    required LocaleState locale,
    Product? existingProduct,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductFormModal(
        distributorId: distributorId,
        locale: locale,
        existingProduct: existingProduct,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CONFIRM DELETE PRODUCT
  // ---------------------------------------------------------------------------

  Future<void> _confirmDeleteProduct({
    required BuildContext context,
    required String distributorId,
    required Product product,
    required LocaleState locale,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline, color: AppColors.red500),
            const SizedBox(width: 8),
            Text(locale.t('delete_product')),
          ],
        ),
        content: Text(
          '${locale.t('confirm_delete_product')} (${locale.translateProduct(product.name)} ${product.packSize})',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(locale.t('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red500,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(locale.t('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ProductService.deleteProduct(
          distributorId: distributorId,
          productId: product.id,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${product.name} deleted successfully.'),
              backgroundColor: AppColors.ink900,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete product: $e'),
              backgroundColor: AppColors.red500,
            ),
          );
        }
      }
    }
  }
}

// ---------------------------------------------------------------------------
// INTERACTIVE SHINING ADD PRODUCT BUTTON (FAB)
// ---------------------------------------------------------------------------

class _InteractiveAddProductFab extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;

  const _InteractiveAddProductFab({
    required this.onPressed,
    required this.label,
  });

  @override
  State<_InteractiveAddProductFab> createState() =>
      _InteractiveAddProductFabState();
}

class _InteractiveAddProductFabState extends State<_InteractiveAddProductFab>
    with TickerProviderStateMixin {
  late final AnimationController _scaleCtrl;
  late final Animation<double> _scaleAnimation;

  late final AnimationController _shineCtrl;
  late final Animation<double> _shineAnimation;

  late final AnimationController _iconCtrl;
  late final Animation<double> _iconAnimation;

  late final AnimationController _ambientGlowCtrl;
  late final Animation<double> _ambientGlowAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // Scale animation on press
    _scaleCtrl = AnimationController(
      duration: const Duration(milliseconds: 140),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOutCubic),
    );

    // Shine sweep light-beam animation
    _shineCtrl = AnimationController(
      duration: const Duration(milliseconds: 850),
      vsync: this,
    );
    _shineAnimation = Tween<double>(
      begin: -1.2,
      end: 2.2,
    ).animate(CurvedAnimation(parent: _shineCtrl, curve: Curves.easeInOutSine));

    // Icon rotation & bounce on touch
    _iconCtrl = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _iconAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut));

    // Subtle breathing ambient pulse glow
    _ambientGlowCtrl = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _ambientGlowAnimation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ambientGlowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _shineCtrl.dispose();
    _iconCtrl.dispose();
    _ambientGlowCtrl.dispose();
    super.dispose();
  }

  void _triggerShineAndFeedback() {
    _shineCtrl.forward(from: 0.0);
    _iconCtrl.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleAnimation,
        _shineAnimation,
        _iconAnimation,
        _ambientGlowAnimation,
      ]),
      builder: (context, child) {
        final scale = _scaleAnimation.value;
        final shineValue = _shineAnimation.value;
        final isShining = _shineCtrl.isAnimating;

        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTapDown: (_) {
              setState(() => _isPressed = true);
              _scaleCtrl.forward();
              _triggerShineAndFeedback();
            },
            onTapUp: (_) {
              setState(() => _isPressed = false);
              _scaleCtrl.reverse();
            },
            onTapCancel: () {
              setState(() => _isPressed = false);
              _scaleCtrl.reverse();
            },
            onTap: widget.onPressed,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2979FF), // Vibrant luminous electric blue
                    Color(0xFF0047FF), // Milk blue 600
                    Color(0xFF0028B5), // Deep royal navy
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: _isPressed ? 0.75 : 0.4,
                  ),
                  width: _isPressed ? 1.8 : 1.2,
                ),
                boxShadow: [
                  // Deep drop shadow
                  BoxShadow(
                    color: const Color(0xFF001F6B).withValues(alpha: 0.4),
                    blurRadius: _isPressed ? 8 : 16,
                    spreadRadius: _isPressed ? 0 : 2,
                    offset: Offset(0, _isPressed ? 3 : 8),
                  ),
                  // Radiant ambient glow halo
                  BoxShadow(
                    color: const Color(0xFF00B0FF).withValues(
                      alpha: _isPressed
                          ? 0.8
                          : _ambientGlowAnimation.value * 0.5,
                    ),
                    blurRadius: _isPressed ? 22 : 14,
                    spreadRadius: _isPressed ? 3 : 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // BUTTON CONTENT (Icon + Text + Sparkle)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.rotate(
                          angle: _iconAnimation.value * (math.pi / 2),
                          child: const Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: 0.3,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedOpacity(
                          opacity: isShining || _isPressed ? 1.0 : 0.7,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.amberAccent,
                            size: 15,
                          ),
                        ),
                      ],
                    ),

                    // SHINING LIGHT BEAM SWEEP OVERLAY
                    if (isShining || _isPressed)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _ShineLightBeamPainter(progress: shineValue),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// SHINE LIGHT BEAM CUSTOM PAINTER
// ---------------------------------------------------------------------------

class _ShineLightBeamPainter extends CustomPainter {
  final double progress;

  _ShineLightBeamPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < -1.0 || progress > 2.0) return;

    final width = size.width;
    final height = size.height;

    final paint = Paint()
      ..shader =
          LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.15),
              Colors.white.withValues(
                alpha: 0.8,
              ), // Bright reflective beam center
              const Color(0xFFB7E2FF).withValues(alpha: 0.9), // Cyan gleam
              Colors.white.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.35, 0.5, 0.55, 0.7, 1.0],
          ).createShader(
            Rect.fromLTWH(
              (progress * width) - (width * 0.4),
              0,
              width * 0.8,
              height,
            ),
          );

    // Angled sweep beam path
    final beamX = progress * (width + height * 0.6) - (height * 0.3);
    final beamWidth = width * 0.45;

    final path = Path()
      ..moveTo(beamX - beamWidth, 0)
      ..lineTo(beamX, 0)
      ..lineTo(beamX + (height * 0.5), height)
      ..lineTo(beamX - beamWidth + (height * 0.5), height)
      ..close();

    canvas.drawPath(path, paint);

    // Sparkle glint star at the crest of the light beam
    if (progress >= 0.1 && progress <= 0.9) {
      final sparkleX = (beamX - beamWidth * 0.2 + (height * 0.25)).clamp(
        10.0,
        width - 10.0,
      );
      final sparkleY = height * 0.3;
      final sparklePaint = Paint()
        ..color = Colors.white.withValues(
          alpha: (1.0 - (progress - 0.5).abs() * 2).clamp(0.0, 1.0) * 0.9,
        )
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(sparkleX, sparkleY), 2.5, sparklePaint);

      // 4-point cross glint
      final crossPaint = Paint()
        ..color = Colors.white.withValues(
          alpha: (1.0 - (progress - 0.5).abs() * 2).clamp(0.0, 1.0) * 0.8,
        )
        ..strokeWidth = 1.2;

      canvas.drawLine(
        Offset(sparkleX - 5, sparkleY),
        Offset(sparkleX + 5, sparkleY),
        crossPaint,
      );
      canvas.drawLine(
        Offset(sparkleX, sparkleY - 5),
        Offset(sparkleX, sparkleY + 5),
        crossPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ShineLightBeamPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ---------------------------------------------------------------------------
// INTERACTIVE HEADER ADD BUTTON
// ---------------------------------------------------------------------------

class _InteractiveHeaderAddBtn extends StatefulWidget {
  final VoidCallback onTap;
  final String tooltip;

  const _InteractiveHeaderAddBtn({required this.onTap, required this.tooltip});

  @override
  State<_InteractiveHeaderAddBtn> createState() =>
      _InteractiveHeaderAddBtnState();
}

class _InteractiveHeaderAddBtnState extends State<_InteractiveHeaderAddBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _rotationAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _rotationAnim = Tween<double>(
      begin: 0.0,
      end: 0.25,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Transform.scale(
          scale: _scaleAnim.value,
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1.2,
                ),
              ),
              child: Transform.rotate(
                angle: _rotationAnim.value * (math.pi * 2),
                child: const Icon(Icons.add, color: Colors.white, size: 20),
              ),
            ),
            tooltip: widget.tooltip,
            onPressed: () {
              _ctrl.forward(from: 0.0).then((_) {
                if (mounted) _ctrl.reverse();
              });
              widget.onTap();
            },
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// FILTER CHIP
// ---------------------------------------------------------------------------

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.milkBlue600 : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: active ? AppColors.milkBlue600 : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.captionBold.copyWith(
            color: active ? Colors.white : AppColors.ink700,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PRODUCT CARD
// ---------------------------------------------------------------------------

class _ProductCard extends StatelessWidget {
  final Product product;
  final String distributorId;
  final LocaleState locale;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.distributorId,
    required this.locale,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLowStock = product.stock <= 10 && product.stock > 0;
    final bool isOutOfStock = product.stock <= 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOutOfStock
              ? AppColors.red500.withValues(alpha: 0.3)
              : (isLowStock
                    ? AppColors.amber500.withValues(alpha: 0.3)
                    : AppColors.border),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EMOJI BADGE
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: product.active
                  ? AppColors.milkBlue50
                  : AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: product.active
                    ? AppColors.milkBlue100
                    : AppColors.border,
              ),
            ),
            child: Center(
              child: Text(
                product.emoji.isNotEmpty ? product.emoji : '🥛',
                style: const TextStyle(fontSize: 26),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // PRODUCT INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TITLE & ACTIVE BADGE
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        locale.translateProduct(product.name),
                        style: AppTextStyles.bodyBold.copyWith(
                          color: product.active
                              ? AppColors.ink900
                              : AppColors.ink500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        ProductService.toggleProductStatus(
                          distributorId: distributorId,
                          productId: product.id,
                          currentStatus: product.active,
                        );
                      },
                      child: AppBadge(
                        label: product.active
                            ? locale.t('product_active')
                            : locale.t('product_inactive'),
                        variant: product.active
                            ? BadgeVariant.success
                            : BadgeVariant.neutral,
                        showDot: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // CATEGORY & PACK SIZE CHIPS
                Row(
                  children: [
                    _chip(
                      locale.translateCategory(product.category),
                      AppColors.milkBlue100,
                      AppColors.milkBlue700,
                    ),
                    const SizedBox(width: 6),
                    _chip(
                      product.packSize,
                      AppColors.background,
                      AppColors.ink700,
                    ),
                    if (product.unit.isNotEmpty && product.unit != 'Pouch') ...[
                      const SizedBox(width: 6),
                      _chip(
                        locale.translateUnit(product.unit),
                        AppColors.background,
                        AppColors.ink500,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),

                // PRICE & STOCK ROW
                Row(
                  children: [
                    Text(
                      '₹${product.price.toStringAsFixed(product.price % 1 == 0 ? 0 : 2)}',
                      style: AppTextStyles.data.copyWith(
                        color: AppColors.milkBlue700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      ' / ${product.unit}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.ink500,
                        fontSize: 11,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Stock Indicator
                    GestureDetector(
                      onTap: () => _showQuickStockDialog(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOutOfStock
                                ? Icons.cancel_outlined
                                : (isLowStock
                                      ? Icons.warning_amber_rounded
                                      : Icons.check_circle_outline),
                            size: 14,
                            color: isOutOfStock
                                ? AppColors.red500
                                : (isLowStock
                                      ? AppColors.amber600
                                      : AppColors.dairyGreen500),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOutOfStock
                                ? 'Out of stock'
                                : '${product.stock} in stock',
                            style: AppTextStyles.caption.copyWith(
                              color: isOutOfStock
                                  ? AppColors.red600
                                  : (isLowStock
                                        ? AppColors.amber600
                                        : AppColors.ink500),
                              fontWeight: isLowStock || isOutOfStock
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.edit_note,
                            size: 14,
                            color: AppColors.ink300,
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // EDIT BUTTON
                    _ActionBtn(
                      icon: Icons.edit_outlined,
                      color: AppColors.milkBlue600,
                      tooltip: 'Edit product',
                      onTap: onEdit,
                    ),

                    const SizedBox(width: 8),

                    // DELETE BUTTON
                    _ActionBtn(
                      icon: Icons.delete_outline,
                      color: AppColors.red500,
                      tooltip: 'Delete product',
                      onTap: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTextStyles.overline.copyWith(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showQuickStockDialog(BuildContext context) {
    final ctrl = TextEditingController(text: product.stock.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Update Stock: ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current stock for ${product.packSize}:',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock Units',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newStock = int.tryParse(ctrl.text.trim());
              if (newStock != null && newStock >= 0) {
                await ProductService.updateStock(
                  distributorId: distributorId,
                  productId: product.id,
                  newStock: newStock,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ACTION BUTTON
// ---------------------------------------------------------------------------

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? tooltip;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final btn = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 17),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}

// ---------------------------------------------------------------------------
// PRODUCT FORM MODAL (ADD & EDIT)
// ---------------------------------------------------------------------------

class _ProductFormModal extends StatefulWidget {
  final String distributorId;
  final LocaleState locale;
  final Product? existingProduct;

  const _ProductFormModal({
    required this.distributorId,
    required this.locale,
    this.existingProduct,
  });

  @override
  State<_ProductFormModal> createState() => _ProductFormModalState();
}

class _ProductFormModalState extends State<_ProductFormModal> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _packSizeCtrl;
  late final TextEditingController _descCtrl;

  late String _selectedCategory;
  late String _selectedUnit;
  late String _selectedEmoji;
  late bool _active;

  bool _saving = false;
  String? _errorMessage;

  final List<String> _categoryOptions = [
    'Milk',
    'Curd',
    'Butter',
    'Paneer',
    'Ghee',
    'Buttermilk',
    'Other',
  ];

  final List<String> _unitOptions = [
    'Pouch',
    'Bottle',
    'Cup',
    'Packet',
    'Jar',
    'Box',
    'Kg',
    'Litre',
  ];

  final List<String> _packSizeSuggestions = [
    '500ml',
    '1L',
    '250ml',
    '500g',
    '1kg',
    '200g',
    '100g',
    '15L Tin',
  ];

  final List<String> _emojiList = [
    '🥛',
    '🥣',
    '🧈',
    '🧀',
    '🫙',
    '🍶',
    '🍦',
    '🍨',
    '🐄',
    '📦',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.existingProduct;

    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _priceCtrl = TextEditingController(
      text: p != null ? p.price.toStringAsFixed(p.price % 1 == 0 ? 0 : 2) : '',
    );
    _stockCtrl = TextEditingController(
      text: p != null ? p.stock.toString() : '100',
    );
    _packSizeCtrl = TextEditingController(text: p?.packSize ?? '500ml');
    _descCtrl = TextEditingController(text: p?.description ?? '');

    _selectedCategory = p?.category ?? 'Milk';
    _selectedUnit = p?.unit ?? 'Pouch';
    _selectedEmoji = p?.emoji ?? _defaultEmojiForCategory(_selectedCategory);
    _active = p?.active ?? true;
  }

  String _defaultEmojiForCategory(String category) {
    return switch (category) {
      'Milk' => '🥛',
      'Curd' => '🥣',
      'Butter' => '🧈',
      'Paneer' => '🧀',
      'Ghee' => '🫙',
      'Buttermilk' => '🍶',
      _ => '📦',
    };
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _packSizeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final price = double.tryParse(_priceCtrl.text.trim());
    if (price == null || price <= 0) {
      setState(() {
        _errorMessage = 'Please enter a valid price greater than 0.';
      });
      return;
    }

    final stock = int.tryParse(_stockCtrl.text.trim()) ?? 0;

    final distId = widget.distributorId.isNotEmpty
        ? widget.distributorId
        : (FirebaseAuth.instance.currentUser?.uid ?? '');

    if (distId.isEmpty) {
      setState(() {
        _errorMessage = 'Distributor ID not found. Please log in again.';
      });
      return;
    }

    setState(() => _saving = true);

    try {
      if (widget.existingProduct != null) {
        // UPDATE EXISTING PRODUCT
        final updated = widget.existingProduct!.copyWith(
          name: _nameCtrl.text.trim(),
          category: _selectedCategory,
          packSize: _packSizeCtrl.text.trim(),
          unit: _selectedUnit,
          price: price,
          stock: stock,
          active: _active,
          description: _descCtrl.text.trim(),
          emoji: _selectedEmoji,
        );

        await ProductService.updateProduct(
          distributorId: distId,
          product: updated,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${updated.name} updated successfully!'),
              backgroundColor: AppColors.dairyGreen700,
            ),
          );
        }
      } else {
        // ADD NEW PRODUCT
        await ProductService.addProduct(
          distributorId: distId,
          name: _nameCtrl.text.trim(),
          category: _selectedCategory,
          packSize: _packSizeCtrl.text.trim(),
          unit: _selectedUnit,
          price: price,
          stock: stock,
          active: _active,
          description: _descCtrl.text.trim(),
          emoji: _selectedEmoji,
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_nameCtrl.text.trim()} added to your catalog!'),
              backgroundColor: AppColors.dairyGreen700,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to save product: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = widget.locale;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.existingProduct != null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // DRAG HANDLE
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // TITLE & CLOSE
                Row(
                  children: [
                    Text(_selectedEmoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isEditing
                            ? locale.t('edit_product')
                            : locale.t('add_product'),
                        style: AppTextStyles.h4,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _saving ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),

                const Divider(height: 16),

                // ERROR BANNER IF ANY
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.red100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.red500.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.red600,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.red600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // FORM BODY
                Flexible(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // EMOJI CHOOSER
                          Text(
                            locale.t('upload_image'),
                            style: AppTextStyles.label,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 44,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _emojiList.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (_, i) {
                                final em = _emojiList[i];
                                final isSel = _selectedEmoji == em;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedEmoji = em),
                                  child: Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? AppColors.milkBlue100
                                          : AppColors.cardSurface,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSel
                                            ? AppColors.milkBlue600
                                            : AppColors.border,
                                        width: isSel ? 2 : 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        em,
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 16),

                          // PRODUCT NAME
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: InputDecoration(
                              labelText: '${locale.t("product_name")} *',
                              hintText: 'e.g. Full Cream Fresh Milk',
                              prefixIcon: const Icon(
                                Icons.inventory_2_outlined,
                                color: AppColors.ink500,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Product name is required';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 14),

                          // CATEGORY & UNIT
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedCategory,
                                  decoration: InputDecoration(
                                    labelText: locale.t('category'),
                                  ),
                                  items: _categoryOptions
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(
                                            locale.translateCategory(c),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() {
                                        _selectedCategory = v;
                                        if (!isEditing) {
                                          _selectedEmoji =
                                              _defaultEmojiForCategory(v);
                                        }
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedUnit,
                                  decoration: InputDecoration(
                                    labelText: locale.t('unit'),
                                  ),
                                  items: _unitOptions
                                      .map(
                                        (u) => DropdownMenuItem(
                                          value: u,
                                          child: Text(locale.translateUnit(u)),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _selectedUnit = v);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // PACK SIZE WITH SUGGESTIONS
                          TextFormField(
                            controller: _packSizeCtrl,
                            decoration: InputDecoration(
                              labelText: '${locale.t("pack_size")} *',
                              hintText: 'e.g. 500ml or 1L',
                              prefixIcon: const Icon(
                                Icons.straighten_outlined,
                                color: AppColors.ink500,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Pack size is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 28,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _packSizeSuggestions.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 6),
                              itemBuilder: (_, i) {
                                final s = _packSizeSuggestions[i];
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _packSizeCtrl.text = s;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _packSizeCtrl.text == s
                                          ? AppColors.milkBlue100
                                          : AppColors.cardSurface,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: _packSizeCtrl.text == s
                                            ? AppColors.milkBlue600
                                            : AppColors.border,
                                      ),
                                    ),
                                    child: Text(
                                      s,
                                      style: AppTextStyles.caption.copyWith(
                                        fontSize: 11,
                                        color: _packSizeCtrl.text == s
                                            ? AppColors.milkBlue700
                                            : AppColors.ink700,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 14),

                          // SELLING PRICE & INITIAL STOCK
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _priceCtrl,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: InputDecoration(
                                    labelText: '${locale.t("selling_price")} *',
                                    prefixText: '₹ ',
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final n = double.tryParse(v.trim());
                                    if (n == null || n <= 0) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _stockCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: '${locale.t("stock_qty")} *',
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final n = int.tryParse(v.trim());
                                    if (n == null || n < 0) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // DESCRIPTION
                          TextFormField(
                            controller: _descCtrl,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: locale.t('description'),
                              hintText:
                                  'Brief notes about freshness, fat % or storage',
                            ),
                          ),

                          const SizedBox(height: 14),

                          // ACTIVE TOGGLE
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      locale.t('status'),
                                      style: AppTextStyles.bodyBold,
                                    ),
                                    Text(
                                      _active
                                          ? 'Available for shops to order'
                                          : 'Hidden / Not taking orders',
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.ink500,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Switch(
                                  value: _active,
                                  activeThumbColor: AppColors.dairyGreen500,
                                  onChanged: (v) => setState(() => _active = v),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // SUBMIT BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.milkBlue600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Text(
                                      locale.t('save'),
                                      style: AppTextStyles.bodyBold.copyWith(
                                        color: Colors.white,
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
          ),
        ),
      ),
    );
  }
}
