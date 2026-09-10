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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
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
                    // Error banner
                    if (_error != null) _errorBanner(_error!),

                    // Company Name
                    _field(
                      controller: _companyCtrl,
                      label: locale.t('company_name'),
                      hint: 'Bhargavi Distributors',
                      icon: Icons.business_rounded,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return locale.t('required');
                        }
                        return null;
                      },
                    ),

                    // Distributor Name
                    _field(
                      controller: _nameCtrl,
                      label: locale.t('distributor_name'),
                      hint: 'Your full name',
                      icon: Icons.person_outline,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return locale.t('required');
                        }
                        return null;
                      },
                    ),

                    // Address
                    _field(
                      controller: _addressCtrl,
                      label: locale.t('address'),
                      hint: '123, Dairy Road, Pune',
                      icon: Icons.location_on_outlined,
                      maxLines: 2,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return locale.t('required');
                        }
                        return null;
                      },
                    ),

                    // Mobile
                    _field(
                      controller: _mobileCtrl,
                      label: locale.t('mobile_number'),
                      hint: '9876543210',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return locale.t('required');
                        }

                        final mobile = v.trim();

                        if (mobile.length < 10) {
                          return locale.t('enter_valid_mobile');
                        }

                        return null;
                      },
                    ),

                    // Email
                    _field(
                      controller: _emailCtrl,
                      label: locale.t('email'),
                      hint: 'distributor@email.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return locale.t('required');
                        }

                        final email = v.trim();

                        if (!email.contains('@')) {
                          return locale.t('enter_valid_email');
                        }

                        return null;
                      },
                    ),

                    // Password
                    _passwordField(
                      controller: _passCtrl,
                      label: locale.t('password'),
                      obscure: _obscurePass,
                      onToggle: () {
                        setState(() {
                          _obscurePass = !_obscurePass;
                        });
                      },
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Required';
                        }

                        if (v.length < 6) {
                          return 'Min 6 characters';
                        }

                        return null;
                      },
                    ),

                    // Confirm Password
                    _passwordField(
                      controller: _confirmPassCtrl,
                      label: locale.t('confirm_password'),
                      obscure: _obscureConfirm,
                      onToggle: () {
                        setState(() {
                          _obscureConfirm = !_obscureConfirm;
                        });
                      },
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return locale.t('required');
                        }

                        if (v != _passCtrl.text) {
                          return locale.t('passwords_not_match');
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 8),

                    // Register Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _register,
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
                                locale.t('register_as_distributor'),
                                style: AppTextStyles.bodyBold.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Login
                    Center(
                      child: TextButton(
                        onPressed: _loading
                            ? null
                            : () => Navigator.pop(context),
                        child: Text(
                          locale.t('already_have_account'),
                          style: AppTextStyles.captionBold.copyWith(
                            color: AppColors.milkBlue600,
                          ),
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
      ),
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
