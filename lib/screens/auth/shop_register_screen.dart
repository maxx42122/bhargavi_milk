import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../services/auth_service.dart';
import '../../state/locale_state.dart';
import '../../widgets/language_picker.dart';
import '../../widgets/bvh_logo_widget.dart';

class ShopRegisterScreen extends StatefulWidget {
  const ShopRegisterScreen({super.key});

  @override
  State<ShopRegisterScreen> createState() => _ShopRegisterScreenState();
}

class _ShopRegisterScreenState extends State<ShopRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _shopNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;

  bool _loading = false;
  bool _loadingDistributors = true;

  String? _error;
  String? _distributorsError;

  List<Map<String, dynamic>> _distributors = [];

  String? _selectedDistributorId;
  Map<String, dynamic>? _selectedDistributor;

  @override
  void initState() {
    super.initState();
    _loadDistributors();
  }

  // ---------------------------------------------------------------------------
  // LOAD DISTRIBUTORS FROM FIRESTORE
  // ---------------------------------------------------------------------------

  Future<void> _loadDistributors() async {
    if (mounted) {
      setState(() {
        _loadingDistributors = true;
        _distributorsError = null;
      });
    }

    try {
      final distributors = await AuthService.fetchDistributors();

      if (!mounted) return;

      setState(() {
        _distributors = distributors;
        _loadingDistributors = false;
        _distributorsError = null;

        // If a distributor was previously selected, refresh its details from the fetched list
        if (_selectedDistributorId != null) {
          final found = _distributors.where((d) => d['id'] == _selectedDistributorId);
          if (found.isNotEmpty) {
            _selectedDistributor = found.first;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingDistributors = false;
        _distributorsError =
            'Unable to load distributors. Please check your connection and tap retry.';
      });
    }
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _mobileCtrl.dispose();
    _addressCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // REGISTER SHOP
  // ---------------------------------------------------------------------------

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDistributorId == null || _selectedDistributorId!.isEmpty) {
      setState(() {
        _error = 'Please select a distributor.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.registerShop(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        shopName: _shopNameCtrl.text.trim(),
        ownerName: _ownerNameCtrl.text.trim(),
        mobile: _mobileCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        distributorId: _selectedDistributorId!,
      );

      if (!mounted) return;

      // IMPORTANT:
      // registerShop creates the Firebase Auth account.
      // Firebase automatically keeps that account signed in.
      //
      // We do NOT open the shop dashboard here because the distributor
      // still has to approve the request.

      final locale = LocaleScope.of(context);
      await _showPendingDialog(locale);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _error = _firebaseAuthError(e);
      });
    } catch (e) {
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
  // PENDING DIALOG
  // ---------------------------------------------------------------------------

  Future<void> _showPendingDialog(LocaleState locale) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.amber100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: AppColors.amber600,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(locale.t('approval_pending'))),
            ],
          ),
          content: Text(
            locale.t('approval_pending_desc'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(locale.t('ok')),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    // Go back to login screen.
    Navigator.pop(context);
  }

  // ---------------------------------------------------------------------------
  // FIREBASE AUTH ERROR
  // ---------------------------------------------------------------------------

  String _firebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';

      case 'weak-password':
        return 'Password must be at least 6 characters.';

      case 'invalid-email':
        return 'Invalid email address.';

      case 'operation-not-allowed':
        return 'Email/password registration is disabled in Firebase.';

      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';

      default:
        return e.message ?? 'Registration failed. Please try again.';
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('email-already-in-use')) {
      return 'This email is already registered.';
    }

    if (raw.contains('weak-password')) {
      return 'Password must be at least 6 characters.';
    }

    if (raw.contains('invalid-email')) {
      return 'Invalid email address.';
    }

    return 'Registration failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context);
    final isWide = MediaQuery.of(context).size.width >= 960;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isWide
          ? _buildDesktopLayout(context, locale)
          : _buildMobileLayout(context, locale),
    );
  }

  // ---------------------------------------------------------------------------
  // DESKTOP LAYOUT
  // ---------------------------------------------------------------------------

  Widget _buildDesktopLayout(BuildContext context, LocaleState locale) {
    return Row(
      children: [
        // Left Hero Panel
        Expanded(
          flex: 45,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF09223D),
                  Color(0xFF0F3D66),
                  Color(0xFF003087),
                  Color(0xFF0047FF),
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: _loading ? null : () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const BvhLogoWidget(size: 34, showCard: false),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          locale.t('app_name'),
                          style: AppTextStyles.h3.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'Direct Dairy Supply\nFor Your Retail Shop',
                      style: AppTextStyles.displayMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Order fresh milk, curd, paneer, and butter directly from your distributor before daily cut-off. Guaranteed morning delivery.',
                      style: AppTextStyles.body.copyWith(
                        color: const Color(0xFFD4E6FA),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 36),
                    _heroStep(
                      step: '1',
                      title: 'Register Shop Details',
                      desc: 'Enter your shop name, address, and mobile number.',
                    ),
                    const SizedBox(height: 16),
                    _heroStep(
                      step: '2',
                      title: 'Select Your Distributor',
                      desc: 'Choose your local distributor to view products and pricing.',
                    ),
                    const SizedBox(height: 16),
                    _heroStep(
                      step: '3',
                      title: 'Approval & Ordering',
                      desc: 'Once verified, start placing daily milk orders with one click.',
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: Color(0xFF00E5FF)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Direct Distributor Pricing • Accurate Ledgers • Automated UPI',
                              style: AppTextStyles.captionBold.copyWith(
                                color: Colors.white,
                                fontSize: 12,
                              ),
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
        ),

        // Right Form Panel
        Expanded(
          flex: 55,
          child: Container(
            color: const Color(0xFFF8FAFC),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Container(
                    padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.darkNavy.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Shop Registration',
                                    style: AppTextStyles.h3,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Register your shop to order from distributors',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.ink500,
                                    ),
                                  ),
                                ],
                              ),
                              const LanguagePillButton(),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (_error != null) _errorBanner(_error!),

                          // 2-Column Grid for Shop & Owner Name
                          Row(
                            children: [
                              Expanded(
                                child: _field(
                                  controller: _shopNameCtrl,
                                  label: 'Shop Name',
                                  hint: 'Sharma Kirana Store',
                                  icon: Icons.store_outlined,
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Shop name is required' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _field(
                                  controller: _ownerNameCtrl,
                                  label: 'Owner Name',
                                  hint: 'Rajesh Sharma',
                                  icon: Icons.person_outline,
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Owner name is required' : null,
                                ),
                              ),
                            ],
                          ),

                          Row(
                            children: [
                              Expanded(
                                child: _field(
                                  controller: _mobileCtrl,
                                  label: 'Mobile Number',
                                  hint: '9876543210',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Mobile number is required';
                                    if (!RegExp(r'^[0-9]{10}$').hasMatch(v.trim())) return 'Enter valid 10 digit mobile';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _field(
                                  controller: _emailCtrl,
                                  label: 'Email Address',
                                  hint: 'shop@email.com',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Email is required';
                                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) return 'Enter valid email';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          _field(
                            controller: _addressCtrl,
                            label: 'Shop Address',
                            hint: '12, MG Road, Pune',
                            icon: Icons.location_on_outlined,
                            maxLines: 2,
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Address is required' : null,
                          ),

                          _buildDistributorSelector(locale),

                          Row(
                            children: [
                              Expanded(
                                child: _passwordField(
                                  controller: _passCtrl,
                                  label: locale.t('password'),
                                  obscure: _obscurePass,
                                  onToggle: () => setState(() => _obscurePass = !_obscurePass),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Password is required';
                                    if (v.length < 6) return 'Min 6 characters';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _passwordField(
                                  controller: _confirmPassCtrl,
                                  label: 'Confirm Password',
                                  obscure: _obscureConfirm,
                                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Confirm your password';
                                    if (v != _passCtrl.text) return 'Passwords do not match';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppColors.milkBlue50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.milkBlue100),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline, color: AppColors.milkBlue600, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Your registration request will be sent to the selected distributor. Your account will remain pending until the distributor approves it.',
                                    style: AppTextStyles.caption.copyWith(color: AppColors.milkBlue700),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _register,
                              child: _loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : Text(
                                      'Register & Send Request',
                                      style: AppTextStyles.bodyBold.copyWith(color: Colors.white, fontSize: 16),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Center(
                            child: TextButton(
                              onPressed: _loading ? null : () => Navigator.pop(context),
                              child: Text(
                                'Already have an account? Login',
                                style: AppTextStyles.captionBold.copyWith(color: AppColors.milkBlue600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _heroStep({
    required String step,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF00E5FF)),
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Color(0xFFE2F9FF),
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyBold.copyWith(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: AppTextStyles.caption.copyWith(color: const Color(0xFFB0CDEB), fontSize: 12.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // MOBILE LAYOUT (Preserved 100%)
  // ---------------------------------------------------------------------------

  Widget _buildMobileLayout(BuildContext context, LocaleState locale) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) _errorBanner(_error!),
                  _field(
                    controller: _shopNameCtrl,
                    label: 'Shop Name',
                    hint: 'Sharma Kirana Store',
                    icon: Icons.store_outlined,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Shop name is required';
                      return null;
                    },
                  ),
                  _field(
                    controller: _ownerNameCtrl,
                    label: 'Owner Name',
                    hint: 'Rajesh Sharma',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Owner name is required';
                      return null;
                    },
                  ),
                  _field(
                    controller: _mobileCtrl,
                    label: 'Mobile Number',
                    hint: '9876543210',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Mobile number is required';
                      final mobile = value.trim();
                      if (!RegExp(r'^[0-9]{10}$').hasMatch(mobile)) return 'Enter valid 10 digit mobile number';
                      return null;
                    },
                  ),
                  _field(
                    controller: _addressCtrl,
                    label: 'Address',
                    hint: '12, MG Road, Pune',
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Address is required';
                      return null;
                    },
                  ),
                  _field(
                    controller: _emailCtrl,
                    label: 'Email Address',
                    hint: 'shop@email.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'Email is required';
                      final email = value.trim();
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) return 'Enter valid email address';
                      return null;
                    },
                  ),
                  _buildDistributorSelector(locale),
                  _passwordField(
                    controller: _passCtrl,
                    label: locale.t('password'),
                    obscure: _obscurePass,
                    onToggle: () => setState(() => _obscurePass = !_obscurePass),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Password is required';
                      if (value.length < 6) return 'Min 6 characters';
                      return null;
                    },
                  ),
                  _passwordField(
                    controller: _confirmPassCtrl,
                    label: 'Confirm Password',
                    obscure: _obscureConfirm,
                    onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Confirm your password';
                      if (value != _passCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.milkBlue50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.milkBlue100),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.milkBlue600, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your registration request will be sent to the selected distributor. Your account will remain pending until the distributor approves it.',
                            style: AppTextStyles.caption.copyWith(color: AppColors.milkBlue700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              'Register & Send Request',
                              style: AppTextStyles.bodyBold.copyWith(color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: _loading ? null : () => Navigator.pop(context),
                      child: Text(
                        'Already have an account? Login',
                        style: AppTextStyles.captionBold.copyWith(color: AppColors.milkBlue600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: _loading ? null : () => Navigator.pop(context),
          ),
          Container(
            width: 38,
            height: 38,
            padding: const EdgeInsets.all(4),
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const BvhLogoWidget(size: 30, showCard: false),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shop Registration',
                  style: AppTextStyles.h4.copyWith(color: Colors.white),
                ),
                Text(
                  'Register your shop to start ordering',
                  style: AppTextStyles.caption.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),

          const LanguagePillButton(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DISTRIBUTOR SELECTOR FIELD
  // ---------------------------------------------------------------------------

  Widget _buildDistributorSelector(LocaleState locale) {
    return FormField<String>(
      initialValue: _selectedDistributorId,
      validator: (value) {
        if (_selectedDistributorId == null || _selectedDistributorId!.isEmpty) {
          return 'Please select a distributor';
        }
        return null;
      },
      builder: (formFieldState) {
        final bool hasError = formFieldState.hasError;
        final String? errorText = formFieldState.errorText;

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Select Distributor *', style: AppTextStyles.label),
                  if (!_loadingDistributors && _distributors.isNotEmpty)
                    InkWell(
                      onTap: _loading ? null : _loadDistributors,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.refresh,
                              size: 14,
                              color: AppColors.milkBlue600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              locale.t('refresh'),
                              style: AppTextStyles.captionBold.copyWith(
                                color: AppColors.milkBlue600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 6),

              // LOADING STATE
              if (_loadingDistributors)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cardSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        locale.t('loading_distributors'),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.ink500,
                        ),
                      ),
                    ],
                  ),
                )

              // ERROR LOADING DISTRIBUTORS
              else if (_distributorsError != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.red100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.red500.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.red600,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _distributorsError!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.red600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadDistributors,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          locale.t('retry'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                )

              // NO DISTRIBUTORS FOUND
              else if (_distributors.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.amber100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.amber500.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber,
                        color: AppColors.amber600,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No distributors found in system.',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.amber600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadDistributors,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          locale.t('refresh'),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                )

              // DISTRIBUTOR SELECTOR
              else
                GestureDetector(
                  onTap: _loading
                      ? null
                      : () => _showDistributorPicker(context, (selected) {
                            setState(() {
                              _selectedDistributorId =
                                  selected['id']?.toString();
                              _selectedDistributor = selected;
                            });
                            formFieldState.didChange(_selectedDistributorId);
                          }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: hasError
                            ? AppColors.red500
                            : (_selectedDistributorId != null
                                ? AppColors.milkBlue600
                                : AppColors.border),
                        width:
                            hasError || _selectedDistributorId != null
                                ? 1.5
                                : 1,
                      ),
                    ),
                    child: _selectedDistributor != null
                        ? Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.milkBlue700,
                                      AppColors.milkBlue500,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    _getDistributorInitial(
                                      _selectedDistributor!,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getDistributorPrimaryTitle(
                                        _selectedDistributor!,
                                      ),
                                      style: AppTextStyles.bodyBold,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (_getDistributorSubtitle(
                                      _selectedDistributor!,
                                    ).isNotEmpty)
                                      Text(
                                        _getDistributorSubtitle(
                                          _selectedDistributor!,
                                        ),
                                        style: AppTextStyles.caption.copyWith(
                                          color: AppColors.ink500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.milkBlue100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Change',
                                  style: AppTextStyles.captionBold.copyWith(
                                    color: AppColors.milkBlue700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.local_shipping_outlined,
                                  color: AppColors.ink500,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Tap to select distributor',
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.ink300,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.ink500,
                                size: 24,
                              ),
                            ],
                          ),
                  ),
                ),

              // INLINE VALIDATION ERROR
              if (hasError && errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 12),
                  child: Text(
                    errorText,
                    style: const TextStyle(
                      color: AppColors.red500,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // DISTRIBUTOR DETAILS HELPERS
  // ---------------------------------------------------------------------------

  String _getDistributorInitial(Map<String, dynamic> d) {
    final company = (d['companyName'] ?? '').toString().trim();
    if (company.isNotEmpty) return company[0].toUpperCase();
    final name = (d['distributorName'] ?? '').toString().trim();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return 'D';
  }

  String _getDistributorPrimaryTitle(Map<String, dynamic> d) {
    final company = (d['companyName'] ?? '').toString().trim();
    if (company.isNotEmpty) return company;
    final name = (d['distributorName'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;
    final mobile = (d['mobile'] ?? '').toString().trim();
    if (mobile.isNotEmpty) return 'Distributor ($mobile)';
    return 'Distributor (${d['id'] ?? ''})';
  }

  String _getDistributorSubtitle(Map<String, dynamic> d) {
    final company = (d['companyName'] ?? '').toString().trim();
    final name = (d['distributorName'] ?? '').toString().trim();
    final mobile = (d['mobile'] ?? '').toString().trim();
    final address = (d['address'] ?? '').toString().trim();

    final List<String> parts = [];
    if (company.isNotEmpty && name.isNotEmpty) {
      parts.add(name);
    }
    if (mobile.isNotEmpty) {
      parts.add(mobile);
    }
    if (address.isNotEmpty) {
      parts.add(address);
    }
    return parts.join(' • ');
  }

  // ---------------------------------------------------------------------------
  // DISTRIBUTOR PICKER MODAL
  // ---------------------------------------------------------------------------

  void _showDistributorPicker(
    BuildContext context,
    void Function(Map<String, dynamic> selected) onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _DistributorPickerSheet(
          distributors: _distributors,
          selectedId: _selectedDistributorId,
          onSelect: (item) {
            onSelect(item);
            Navigator.pop(sheetContext);
          },
          onRefresh: () async {
            await _loadDistributors();
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // NORMAL FIELD
  // ---------------------------------------------------------------------------

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        textInputAction: maxLines > 1
            ? TextInputAction.newline
            : TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.ink500, size: 20),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PASSWORD FIELD
  // ---------------------------------------------------------------------------

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(
            Icons.lock_outline,
            color: AppColors.ink500,
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: AppColors.ink500,
              size: 20,
            ),
            onPressed: onToggle,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ERROR BANNER
  // ---------------------------------------------------------------------------

  Widget _errorBanner(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.red100,
        borderRadius: BorderRadius.circular(12),
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

          IconButton(
            onPressed: () {
              setState(() {
                _error = null;
              });
            },
            icon: const Icon(Icons.close, size: 18, color: AppColors.red600),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SEARCHABLE DISTRIBUTOR PICKER SHEET
// ---------------------------------------------------------------------------

class _DistributorPickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> distributors;
  final String? selectedId;
  final void Function(Map<String, dynamic> selected) onSelect;
  final Future<void> Function() onRefresh;

  const _DistributorPickerSheet({
    required this.distributors,
    required this.selectedId,
    required this.onSelect,
    required this.onRefresh,
  });

  @override
  State<_DistributorPickerSheet> createState() =>
      _DistributorPickerSheetState();
}

class _DistributorPickerSheetState extends State<_DistributorPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _filtered = widget.distributors;
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(covariant _DistributorPickerSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.distributors != widget.distributors) {
      _applyFilter(_searchCtrl.text);
    }
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilter(_searchCtrl.text);
  }

  void _applyFilter(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = widget.distributors;
      } else {
        _filtered = widget.distributors.where((d) {
          final company =
              (d['companyName'] ?? '').toString().toLowerCase();
          final name =
              (d['distributorName'] ?? '').toString().toLowerCase();
          final mobile = (d['mobile'] ?? '').toString().toLowerCase();
          final address = (d['address'] ?? '').toString().toLowerCase();
          final id = (d['id'] ?? '').toString().toLowerCase();

          return company.contains(q) ||
              name.contains(q) ||
              mobile.contains(q) ||
              address.contains(q) ||
              id.contains(q);
        }).toList();
      }
    });
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _refreshing = true;
    });
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        setState(() {
          _refreshing = false;
        });
      }
    }
  }

  String _getInitial(Map<String, dynamic> d) {
    final company = (d['companyName'] ?? '').toString().trim();
    if (company.isNotEmpty) return company[0].toUpperCase();
    final name = (d['distributorName'] ?? '').toString().trim();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return 'D';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.80,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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

                // TITLE ROW
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Select Distributor', style: AppTextStyles.h4),
                          const SizedBox(height: 2),
                          Text(
                            'Choose who should receive your registration request',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.ink500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: _refreshing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.refresh,
                              color: AppColors.milkBlue600,
                            ),
                      onPressed: _refreshing ? null : _handleRefresh,
                      tooltip: 'Refresh list',
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // SEARCH BAR
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by name, company or mobile...',
                    prefixIcon: const Icon(
                      Icons.search,
                      size: 20,
                      color: AppColors.ink500,
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              size: 18,
                              color: AppColors.ink500,
                            ),
                            onPressed: () {
                              _searchCtrl.clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.cardSurface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.milkBlue600,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // LIST
                Flexible(
                  child: _filtered.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(28),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.search_off,
                                size: 40,
                                color: AppColors.ink300,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _searchCtrl.text.isEmpty
                                    ? 'No distributors found'
                                    : 'No distributors matching "${_searchCtrl.text}"',
                                style: AppTextStyles.bodyBold.copyWith(
                                  color: AppColors.ink700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: _filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, index) {
                            final d = _filtered[index];
                            final id = d['id']?.toString() ?? '';
                            final company =
                                (d['companyName'] ?? '').toString().trim();
                            final name =
                                (d['distributorName'] ?? '').toString().trim();
                            final mobile =
                                (d['mobile'] ?? '').toString().trim();
                            final address =
                                (d['address'] ?? '').toString().trim();

                            final bool selected = widget.selectedId == id;

                            final title = company.isNotEmpty
                                ? company
                                : (name.isNotEmpty
                                    ? name
                                    : 'Distributor ($id)');

                            final subtitleParts = <String>[];
                            if (company.isNotEmpty && name.isNotEmpty) {
                              subtitleParts.add(name);
                            }
                            if (mobile.isNotEmpty) {
                              subtitleParts.add(mobile);
                            }
                            if (address.isNotEmpty) {
                              subtitleParts.add(address);
                            }

                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => widget.onSelect(d),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.milkBlue100
                                      : AppColors.cardSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.milkBlue600
                                        : AppColors.border,
                                    width: selected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // AVATAR
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            AppColors.milkBlue700,
                                            AppColors.milkBlue500,
                                          ],
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Text(
                                          _getInitial(d),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 17,
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    // DATA
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: AppTextStyles.bodyBold,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (subtitleParts.isNotEmpty)
                                            Text(
                                              subtitleParts.join(' • '),
                                              style: AppTextStyles.caption
                                                  .copyWith(
                                                color: AppColors.ink500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),

                                    if (selected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppColors.milkBlue600,
                                        size: 22,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
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
