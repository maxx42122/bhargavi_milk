import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/colors.dart';
import '../../core/text_styles.dart';
import '../../services/auth_service.dart';
import '../../state/locale_state.dart';
import '../auth/login_screen.dart';

class DistributorProfileScreen extends StatelessWidget {
  const DistributorProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      // Sign out from Firebase
      await AuthService.signOut();

      if (!context.mounted) return;

      // Remove dashboard/profile and all previous screens.
      // User will not be able to press Back and return to dashboard.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed. Please try again.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final locale = LocaleScope.of(context);

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('distributor')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snap) {
          // ─────────────────────────────────────────────────────────────
          // Loading
          // ─────────────────────────────────────────────────────────────
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // ─────────────────────────────────────────────────────────────
          // Error / document not found
          // ─────────────────────────────────────────────────────────────
          if (snap.hasError || !snap.hasData || !snap.data!.exists) {
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.ink900),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_off_outlined,
                      size: 48,
                      color: AppColors.ink300,
                    ),
                    const SizedBox(height: 12),
                    Text('Profile not found', style: AppTextStyles.h4),
                    const SizedBox(height: 6),
                    Text(
                      'Could not load distributor data.',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            );
          }

          // ─────────────────────────────────────────────────────────────
          // Firestore distributor data
          // ─────────────────────────────────────────────────────────────
          final d = snap.data!.data()!;

          final companyName = d['companyName'] as String? ?? '';
          final distributorName = d['distributorName'] as String? ?? '';
          final email = d['email'] as String? ?? '';
          final mobile = d['mobile'] as String? ?? '';
          final address = d['address'] as String? ?? '';
          final role = d['role'] as String? ?? 'distributor';

          final initials = distributorName.trim().isNotEmpty
              ? distributorName
                    .trim()
                    .split(RegExp(r'\s+'))
                    .where((word) => word.isNotEmpty)
                    .map((word) => word[0])
                    .take(2)
                    .join()
                    .toUpperCase()
              : 'D';

          return Column(
            children: [
              // ─────────────────────────────────────────────────────────
              // Gradient header
              // ─────────────────────────────────────────────────────────
              _ProfileHeader(
                initials: initials,
                distributorName: distributorName,
                companyName: companyName,
                locale: locale,
              ),

              // ─────────────────────────────────────────────────────────
              // Scrollable body
              // ─────────────────────────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  children: [
                    // Contact Information
                    const _SectionLabel('Contact Information'),

                    _FieldCard(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: email,
                    ),

                    _FieldCard(
                      icon: Icons.phone_outlined,
                      label: 'Mobile',
                      value: mobile,
                    ),

                    _FieldCard(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: address,
                      multiline: true,
                    ),

                    const SizedBox(height: 16),

                    // Business Details
                    const _SectionLabel('Business Details'),

                    _FieldCard(
                      icon: Icons.business_rounded,
                      label: 'Company Name',
                      value: companyName,
                    ),

                    _FieldCard(
                      icon: Icons.person_outline,
                      label: 'Distributor Name',
                      value: distributorName,
                    ),

                    _FieldCard(
                      icon: Icons.verified_user_outlined,
                      label: 'Role',
                      value: role.isEmpty
                          ? 'Distributor'
                          : role[0].toUpperCase() + role.substring(1),
                    ),

                    _FieldCard(
                      icon: Icons.badge_outlined,
                      label: 'Distributor ID',
                      value: user.uid,
                      copyable: true,
                    ),

                    const SizedBox(height: 24),

                    // ───────────────────────────────────────────────────
                    // Logout
                    // ───────────────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () => _logout(context),
                        icon: const Icon(
                          Icons.logout,
                          color: AppColors.red600,
                          size: 18,
                        ),
                        label: Text(
                          locale.t('logout'),
                          style: AppTextStyles.bodyBold.copyWith(
                            color: AppColors.red600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.red500),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Header
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String initials;
  final String distributorName;
  final String companyName;
  final LocaleState locale;

  const _ProfileHeader({
    required this.initials,
    required this.distributorName,
    required this.companyName,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 28),
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Back button
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  locale.t('nav_profile'),
                  style: AppTextStyles.h4.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            distributorName.isEmpty ? 'Distributor' : distributorName,
            style: AppTextStyles.h4.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          Text(
            companyName.isEmpty ? 'Distributor Account' : companyName,
            style: AppTextStyles.caption.copyWith(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: AppTextStyles.overline.copyWith(
          color: AppColors.milkBlue700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Field Card
// ─────────────────────────────────────────────────────────────────────────────

class _FieldCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool multiline;
  final bool copyable;

  const _FieldCard({
    required this.icon,
    required this.label,
    required this.value,
    this.multiline = false,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.milkBlue100,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: AppColors.milkBlue700, size: 18),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.overline),

                const SizedBox(height: 3),

                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: value.isEmpty
                      ? AppTextStyles.body.copyWith(color: AppColors.ink300)
                      : AppTextStyles.bodyBold,
                  maxLines: multiline ? null : 1,
                  overflow: multiline ? null : TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Copied to clipboard'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.copy_outlined,
                  color: AppColors.ink500,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
