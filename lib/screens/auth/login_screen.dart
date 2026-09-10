import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../services/auth_service.dart';
import '../../state/auth_state.dart';
import '../../state/locale_state.dart';
import '../../widgets/language_picker.dart';
import '../../widgets/bvh_logo_widget.dart';
import '../distributor/distributor_dashboard_screen.dart';
import '../shop/shop_home_screen.dart';
import 'distributor_register_screen.dart';
import 'shop_register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _isShopRole = true;
  bool _rememberMe = false;
  bool _obscure = true;
  bool _loading = false;

  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // EMAIL / PASSWORD LOGIN
  // ---------------------------------------------------------------------------

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final resolved = await AuthService.loginWithEmail(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      if (!mounted) return;

      // Check selected role against actual Firestore role.
      if (_isShopRole && resolved.role != UserRole.shop) {
        await AuthService.signOut();

        setState(() {
          _error =
              'This account is a distributor account. Please select Distributor.';
        });

        return;
      }

      if (!_isShopRole && resolved.role != UserRole.distributor) {
        await AuthService.signOut();

        setState(() {
          _error = 'This account is a shop account. Please select Shop.';
        });

        return;
      }

      // Store resolved authentication information.
      final authState = AuthStateScope.of(context);

      authState.setResolved(
        role: resolved.role,
        distributorId: resolved.distributorId,
        status: resolved.status,
      );

      // Navigate according to actual account status.
      await _handleNavigation(role: resolved.role, status: resolved.status);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _friendlyFirebaseError(e);
      });
    } on Exception catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _friendlyError(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // GOOGLE LOGIN
  // ---------------------------------------------------------------------------

  Future<void> _googleLogin() async {
    // Google login is only for distributors in your current AuthService.
    if (_isShopRole) {
      setState(() {
        _error = 'Google Sign-In is available for distributor accounts only.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await AuthService.signInWithGoogle();

      // New Google account.
      if (result.isNew) {
        // Sign out because distributor registration needs to create/
        // complete the distributor profile.
        await AuthService.signOut();

        if (!mounted) return;

        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DistributorRegisterScreen()),
        );

        return;
      }

      // Existing Google account.
      final resolved = await AuthService.resolveCurrentUserRole();

      if (!mounted) return;

      if (resolved.role != UserRole.distributor) {
        await AuthService.signOut();

        setState(() {
          _error = 'This Google account is not registered as a distributor.';
        });

        return;
      }

      final authState = AuthStateScope.of(context);

      authState.setResolved(
        role: resolved.role,
        distributorId: resolved.distributorId,
        status: resolved.status,
      );

      await _handleNavigation(role: resolved.role, status: resolved.status);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _friendlyFirebaseError(e);
      });
    } on Exception catch (e) {
      if (!mounted) return;

      final message = e.toString();

      if (!message.toLowerCase().contains('cancelled')) {
        setState(() {
          _error = _friendlyError(message);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // NAVIGATION
  // ---------------------------------------------------------------------------

  Future<void> _handleNavigation({
    required UserRole role,
    required String status,
  }) async {
    if (!mounted) return;
    final locale = LocaleScope.of(context);

    // ---------------------------------------------------------
    // DISTRIBUTOR
    // ---------------------------------------------------------

    if (role == UserRole.distributor) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DistributorDashboardScreen()),
        (route) => false,
      );

      return;
    }

    // ---------------------------------------------------------
    // SHOP
    // ---------------------------------------------------------

    if (role == UserRole.shop) {
      if (status == 'active') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ShopHomeScreen()),
          (route) => false,
        );

        return;
      }

      if (status == 'pending') {
        await _showPendingDialog(locale);
        return;
      }

      if (status == 'rejected') {
        await _showRejectedDialog(locale);
        return;
      }

      setState(() {
        _error =
            'Your account status is "$status". Please contact your distributor.';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // PENDING DIALOG
  // ---------------------------------------------------------------------------

  Future<void> _showPendingDialog(LocaleState locale) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.amber100,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: AppColors.amber600,
              size: 32,
            ),
          ),
          title: Text(
            locale.t('approval_pending'),
            textAlign: TextAlign.center,
          ),
          content: Text(
            locale.t('approval_pending_desc'),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(locale.t('ok')),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // REJECTED DIALOG
  // ---------------------------------------------------------------------------

  Future<void> _showRejectedDialog(LocaleState locale) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.red100,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.cancel_outlined,
              color: AppColors.red600,
              size: 32,
            ),
          ),
          title: Text(locale.t('reg_rejected'), textAlign: TextAlign.center),
          content: Text(
            locale.t('reg_rejected_desc'),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(locale.t('ok')),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // FIREBASE ERROR
  // ---------------------------------------------------------------------------

  String _friendlyFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email. Please register first.';

      case 'wrong-password':
        return 'Invalid email or password.';

      case 'invalid-credential':
        return 'Invalid email or password.';

      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      case 'operation-not-allowed':
        return 'Email/password login is not enabled in Firebase.';

      default:
        return e.message ?? 'Login failed. Please try again.';
    }
  }

  String _friendlyError(String raw) {
    final message = raw.toLowerCase();

    if (message.contains('user-not-found') ||
        message.contains('wrong-password') ||
        message.contains('invalid-credential')) {
      return 'Invalid email or password.';
    }

    if (message.contains('user-disabled')) {
      return 'This account has been disabled.';
    }

    if (message.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }

    if (message.contains('not found')) {
      return 'No account found. Please register first.';
    }

    if (message.contains('cancelled')) {
      return 'Login cancelled.';
    }

    return 'Login failed. Please check your credentials.';
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isWide
          ? _buildWideLayout(context, locale)
          : _buildNarrowLayout(context, locale),
    );
  }

  // ---------------------------------------------------------------------------
  // WIDE LAYOUT
  // ---------------------------------------------------------------------------

  Widget _buildWideLayout(BuildContext context, LocaleState locale) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
            child: _buildHeroPanel(locale),
          ),
        ),
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(48),
            child: _buildFormCard(context, locale),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE LAYOUT
  // ---------------------------------------------------------------------------

  Widget _buildNarrowLayout(BuildContext context, LocaleState locale) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 220,
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 12,
                    right: 16,
                    child: const LanguagePillButton(),
                  ),
                  Center(child: _buildBrandBlock(locale, centered: true)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: _buildFormCard(context, locale),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HERO PANEL
  // ---------------------------------------------------------------------------

  Widget _buildHeroPanel(LocaleState locale) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Align(
              alignment: Alignment.topRight,
              child: LanguagePillButton(),
            ),
            const Spacer(),
            _buildBrandBlock(locale),
            const SizedBox(height: 48),
            Row(
              children: [
                _trustStat('500+', locale.t('trust_shops')),
                const SizedBox(width: 32),
                _trustStat('12', locale.t('trust_cities')),
                const SizedBox(width: 32),
                _trustStat('4.8★', locale.t('trust_rating')),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BRAND
  // ---------------------------------------------------------------------------

  Widget _buildBrandBlock(LocaleState locale, {bool centered = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const BvhLogoWidget(size: 36, showCard: false),
            ),
            const SizedBox(width: 12),
            Text(
              locale.t('app_name'),
              style: AppTextStyles.h2.copyWith(color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          locale.t('login_tagline'),
          textAlign: centered ? TextAlign.center : TextAlign.left,
          style: AppTextStyles.body.copyWith(
            color: Colors.white70,
            fontSize: 17,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TRUST STAT
  // ---------------------------------------------------------------------------

  Widget _trustStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTextStyles.h3.copyWith(color: Colors.white)),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: Colors.white60),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // FORM CARD
  // ---------------------------------------------------------------------------

  Widget _buildFormCard(BuildContext context, LocaleState locale) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.milkBlue900.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(locale.t('login'), style: AppTextStyles.h3),

            const SizedBox(height: 20),

            // ROLE
            _buildRoleToggle(locale),

            const SizedBox(height: 24),

            // ERROR
            if (_error != null) _errorBanner(_error!),

            // EMAIL
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              enabled: !_loading,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return locale.t('enter_email');
                }

                if (!value.trim().contains('@')) {
                  return locale.t('enter_valid_email');
                }

                return null;
              },
              decoration: InputDecoration(
                labelText: locale.t('mobile_email'),
                hintText: 'example@email.com',
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: AppColors.ink500,
                  size: 20,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // PASSWORD
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              enabled: !_loading,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!_loading) {
                  _login();
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return locale.t('enter_password');
                }

                return null;
              },
              decoration: InputDecoration(
                labelText: locale.t('password'),
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: AppColors.ink500,
                  size: 20,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.ink500,
                    size: 20,
                  ),
                  onPressed: _loading
                      ? null
                      : () {
                          setState(() {
                            _obscure = !_obscure;
                          });
                        },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // REMEMBER + FORGOT
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: _loading
                        ? null
                        : (value) {
                            setState(() {
                              _rememberMe = value ?? false;
                            });
                          },
                    activeColor: AppColors.milkBlue600,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(locale.t('remember_me'), style: AppTextStyles.caption),
                const Spacer(),
                TextButton(
                  onPressed: _loading ? null : _forgotPassword,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    locale.t('forgot_password'),
                    style: AppTextStyles.captionBold.copyWith(
                      color: AppColors.milkBlue600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // LOGIN BUTTON
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.milkBlue600,
                  disabledBackgroundColor: AppColors.milkBlue600.withValues(
                    alpha: 0.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        locale.t('login'),
                        style: AppTextStyles.bodyBold.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),

            // GOOGLE
            if (!_isShopRole) ...[
              const SizedBox(height: 14),

              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(locale.t('or'), style: AppTextStyles.caption),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 14),

              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _loading ? null : _googleLogin,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Text(
                            'G',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4285F4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        locale.t('continue_with_google'),
                        style: AppTextStyles.bodyBold.copyWith(
                          color: AppColors.ink700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // REGISTER
            Center(
              child: TextButton(
                onPressed: _loading
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _isShopRole
                                ? const ShopRegisterScreen()
                                : const DistributorRegisterScreen(),
                          ),
                        );
                      },
                child: Text(
                  locale.t('create_account'),
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.milkBlue600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ROLE TOGGLE
  // ---------------------------------------------------------------------------

  Widget _buildRoleToggle(LocaleState locale) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _roleTab(locale.t('role_shop'), _isShopRole, () {
            if (_loading) return;

            setState(() {
              _isShopRole = true;
              _error = null;
            });
          }),
          _roleTab(locale.t('role_distributor'), !_isShopRole, () {
            if (_loading) return;

            setState(() {
              _isShopRole = false;
              _error = null;
            });
          }),
        ],
      ),
    );
  }

  Widget _roleTab(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? AppColors.cardSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.milkBlue900.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.bodyBold.copyWith(
                color: active ? AppColors.milkBlue700 : AppColors.ink500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FORGOT PASSWORD
  // ---------------------------------------------------------------------------

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _error = 'Enter your email address first.';
      });
      return;
    }

    try {
      await AuthService.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent. Please check your inbox.'),
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _friendlyError(e.toString());
      });
    }
  }

  // ---------------------------------------------------------------------------
  // ERROR BANNER
  // ---------------------------------------------------------------------------

  Widget _errorBanner(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.red100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.red500.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.red600, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              msg,
              style: AppTextStyles.caption.copyWith(color: AppColors.red600),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _error = null;
              });
            },
            child: const Icon(Icons.close, color: AppColors.ink500, size: 16),
          ),
        ],
      ),
    );
  }
}
