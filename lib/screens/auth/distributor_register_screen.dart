import 'package:flutter/material.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../services/auth_service.dart';
import '../../state/locale_state.dart';
import '../../widgets/language_picker.dart';
import '../../widgets/bvh_logo_widget.dart';
import '../distributor/distributor_dashboard_screen.dart';

class DistributorRegisterScreen extends StatefulWidget {
  const DistributorRegisterScreen({super.key});

  @override
  State<DistributorRegisterScreen> createState() =>
      _DistributorRegisterScreenState();
}

class _DistributorRegisterScreenState extends State<DistributorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _companyCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _companyCtrl.dispose();
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    // Validate form first.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Hide keyboard.
    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.registerDistributor(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        companyName: _companyCtrl.text.trim(),
        distributorName: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        mobile: _mobileCtrl.text.trim(),
      );

      if (!mounted) return;

      // Registration was successful.
      //
      // AuthService.registerDistributor() has created the Firebase user
      // and stored the distributor information in Firestore.
      //
      // Now explicitly open the distributor dashboard.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DistributorDashboardScreen()),
        (route) => false,
      );
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

    if (raw.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection.';
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
                      'Partner with\nMilkRoute Enterprise',
                      style: AppTextStyles.displayMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Setup your distribution network in minutes. Connect shops, manage products, and streamline morning milk deliveries effortlessly.',
                      style: AppTextStyles.body.copyWith(
                        color: const Color(0xFFD4E6FA),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 36),
                    _heroStep(
                      step: '1',
                      title: 'Register Distributor Profile',
                      desc: 'Enter your business information and dairy brand details.',
                    ),
                    const SizedBox(height: 16),
                    _heroStep(
                      step: '2',
                      title: 'Add Products & Catalog',
                      desc: 'Define pack sizes, rates, and stock availability.',
                    ),
                    const SizedBox(height: 16),
                    _heroStep(
                      step: '3',
                      title: 'Onboard Shops & Start Delivery',
                      desc: 'Approve shop requests and receive automated morning orders.',
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
                          const Icon(Icons.verified_user_outlined, color: Color(0xFF00E5FF)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Enterprise Grade Security • 100% Data Privacy Guaranteed',
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
                  constraints: const BoxConstraints(maxWidth: 620),
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
                                    locale.t('distributor_registration'),
                                    style: AppTextStyles.h3,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    locale.t('create_distributor_account'),
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

                          // 2-Column Grid for Form Fields
                          Row(
                            children: [
                              Expanded(
                                child: _field(
                                  controller: _companyCtrl,
                                  label: locale.t('company_name'),
                                  hint: 'Bhargavi Distributors',
                                  icon: Icons.business_rounded,
                                  validator: (v) => (v == null || v.trim().isEmpty) ? locale.t('required') : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _field(
                                  controller: _nameCtrl,
                                  label: locale.t('distributor_name'),
                                  hint: 'Full Name',
                                  icon: Icons.person_outline,
                                  validator: (v) => (v == null || v.trim().isEmpty) ? locale.t('required') : null,
                                ),
                              ),
                            ],
                          ),

                          Row(
                            children: [
                              Expanded(
                                child: _field(
                                  controller: _mobileCtrl,
                                  label: locale.t('mobile_number'),
                                  hint: '9876543210',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return locale.t('required');
                                    if (v.trim().length < 10) return locale.t('enter_valid_mobile');
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _field(
                                  controller: _emailCtrl,
                                  label: locale.t('email'),
                                  hint: 'distributor@email.com',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return locale.t('required');
                                    if (!v.contains('@')) return locale.t('enter_valid_email');
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          _field(
                            controller: _addressCtrl,
                            label: locale.t('address'),
                            hint: '123, Dairy Road, Pune',
                            icon: Icons.location_on_outlined,
                            maxLines: 2,
                            validator: (v) => (v == null || v.trim().isEmpty) ? locale.t('required') : null,
                          ),

                          Row(
                            children: [
                              Expanded(
                                child: _passwordField(
                                  controller: _passCtrl,
                                  label: locale.t('password'),
                                  obscure: _obscurePass,
                                  onToggle: () => setState(() => _obscurePass = !_obscurePass),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Required';
                                    if (v.length < 6) return 'Min 6 characters';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _passwordField(
                                  controller: _confirmPassCtrl,
                                  label: locale.t('confirm_password'),
                                  obscure: _obscureConfirm,
                                  onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return locale.t('required');
                                    if (v != _passCtrl.text) return locale.t('passwords_not_match');
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

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
                                      locale.t('register_as_distributor'),
                                      style: AppTextStyles.bodyBold.copyWith(color: Colors.white, fontSize: 16),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          Center(
                            child: TextButton(
                              onPressed: _loading ? null : () => Navigator.pop(context),
                              child: Text(
                                locale.t('already_have_account'),
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
        _buildHeader(context, locale),
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
                    controller: _companyCtrl,
                    label: locale.t('company_name'),
                    hint: 'Bhargavi Distributors',
                    icon: Icons.business_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty) ? locale.t('required') : null,
                  ),
                  _field(
                    controller: _nameCtrl,
                    label: locale.t('distributor_name'),
                    hint: 'Your full name',
                    icon: Icons.person_outline,
                    validator: (v) => (v == null || v.trim().isEmpty) ? locale.t('required') : null,
                  ),
                  _field(
                    controller: _addressCtrl,
                    label: locale.t('address'),
                    hint: '123, Dairy Road, Pune',
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                    validator: (v) => (v == null || v.trim().isEmpty) ? locale.t('required') : null,
                  ),
                  _field(
                    controller: _mobileCtrl,
                    label: locale.t('mobile_number'),
                    hint: '9876543210',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return locale.t('required');
                      if (v.trim().length < 10) return locale.t('enter_valid_mobile');
                      return null;
                    },
                  ),
                  _field(
                    controller: _emailCtrl,
                    label: locale.t('email'),
                    hint: 'distributor@email.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return locale.t('required');
                      if (!v.contains('@')) return locale.t('enter_valid_email');
                      return null;
                    },
                  ),
                  _passwordField(
                    controller: _passCtrl,
                    label: locale.t('password'),
                    obscure: _obscurePass,
                    onToggle: () => setState(() => _obscurePass = !_obscurePass),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 6) return 'Min 6 characters';
                      return null;
                    },
                  ),
                  _passwordField(
                    controller: _confirmPassCtrl,
                    label: locale.t('confirm_password'),
                    obscure: _obscureConfirm,
                    onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    validator: (v) {
                      if (v == null || v.isEmpty) return locale.t('required');
                      if (v != _passCtrl.text) return locale.t('passwords_not_match');
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
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
                              locale.t('register_as_distributor'),
                              style: AppTextStyles.bodyBold.copyWith(color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: _loading ? null : () => Navigator.pop(context),
                      child: Text(
                        locale.t('already_have_account'),
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

  Widget _buildHeader(BuildContext context, LocaleState locale) {
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
                  locale.t('distributor_registration'),
                  style: AppTextStyles.h4.copyWith(color: Colors.white),
                ),
                Text(
                  locale.t('create_distributor_account'),
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
        textInputAction: TextInputAction.next,
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

  Widget _errorBanner(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.red100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red500.withValues(alpha: 0.4)),
        gradient: const LinearGradient(
          colors: [Color(0x33E4534F), Color(0x00FFFFFF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
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
        ],
      ),
    );
  }
}
