import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'firebase_options.dart';

import 'screens/auth/login_screen.dart';
import 'screens/distributor/distributor_dashboard_screen.dart';
import 'screens/shop/shop_home_screen.dart';

import 'services/auth_service.dart';

import 'state/auth_state.dart';
import 'state/locale_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MilkRouteApp());
}

class MilkRouteApp extends StatefulWidget {
  const MilkRouteApp({super.key});

  @override
  State<MilkRouteApp> createState() => _MilkRouteAppState();
}

class _MilkRouteAppState extends State<MilkRouteApp> {
  final _localeState = LocaleState();
  final _authState = AuthState();

  @override
  void dispose() {
    _localeState.dispose();
    _authState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthStateScope(
      state: _authState,
      child: LocaleScope(
        state: _localeState,
        child: ListenableBuilder(
          listenable: _localeState,
          builder: (context, _) {
            return MaterialApp(
              title: 'MilkRoute',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              home: _AuthGate(authState: _authState),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================================
// AUTH GATE
// ============================================================================

class _AuthGate extends StatefulWidget {
  final AuthState authState;

  const _AuthGate({required this.authState});

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges,
      builder: (ctx, snap) {
        // --------------------------------------------------------------------
        // Firebase is checking current authentication state.
        // --------------------------------------------------------------------

        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF4F9FE),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snap.data;

        // --------------------------------------------------------------------
        // USER IS NOT LOGGED IN
        // --------------------------------------------------------------------

        if (user == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            widget.authState.clear();
          });

          return const LoginScreen();
        }

        // --------------------------------------------------------------------
        // IMPORTANT:
        // Registration is still running.
        //
        // Do NOT call resolveCurrentUserRole() yet.
        // Do NOT sign the user out.
        // --------------------------------------------------------------------

        if (AuthService.isRegistering) {
          return const Scaffold(
            backgroundColor: Color(0xFFF4F9FE),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // --------------------------------------------------------------------
        // USER IS LOGGED IN.
        // NOW resolve their role.
        // --------------------------------------------------------------------

        return FutureBuilder<
          ({UserRole role, String distributorId, String status})
        >(
          future: AuthService.resolveCurrentUserRole(),
          builder: (ctx2, roleSnap) {
            // ---------------------------------------------------------------
            // Resolving role...
            // ---------------------------------------------------------------

            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFFF4F9FE),
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // ---------------------------------------------------------------
            // ROLE RESOLUTION FAILED
            //
            // IMPORTANT:
            // DO NOT automatically call signOut().
            // ---------------------------------------------------------------

            if (roleSnap.hasError) {
              return Scaffold(
                backgroundColor: const Color(0xFFF4F9FE),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Unable to load your account.\n\n'
                      '${roleSnap.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            // ---------------------------------------------------------------
            // No role data yet.
            // ---------------------------------------------------------------

            if (!roleSnap.hasData) {
              return const Scaffold(
                backgroundColor: Color(0xFFF4F9FE),
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // ---------------------------------------------------------------
            // ROLE SUCCESSFULLY RESOLVED
            // ---------------------------------------------------------------

            final resolved = roleSnap.data!;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;

              widget.authState.setResolved(
                role: resolved.role,
                distributorId: resolved.distributorId,
                status: resolved.status,
              );
            });

            // ---------------------------------------------------------------
            // DISTRIBUTOR
            // ---------------------------------------------------------------

            if (resolved.role == UserRole.distributor) {
              return const DistributorDashboardScreen();
            }

            // ---------------------------------------------------------------
            // ACTIVE SHOP
            // ---------------------------------------------------------------

            if (resolved.status == 'active') {
              return ShopHomeScreen(distributorId: resolved.distributorId);
            }

            // ---------------------------------------------------------------
            // PENDING / REJECTED SHOP
            // ---------------------------------------------------------------

            return _ShopPendingScreen(status: resolved.status);
          },
        );
      },
    );
  }
}

// ============================================================================
// SHOP PENDING SCREEN
// ============================================================================

class _ShopPendingScreen extends StatelessWidget {
  final String status;

  const _ShopPendingScreen({required this.status});

  @override
  Widget build(BuildContext context) {
    final rejected = status == 'rejected';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FE),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: rejected
                        ? const Color(0xFFFBE7E7)
                        : const Color(0xFFFEF3DD),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    rejected ? Icons.cancel_outlined : Icons.hourglass_top,
                    size: 40,
                    color: rejected
                        ? const Color(0xFFC23A3A)
                        : const Color(0xFFB4740A),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  rejected ? 'Registration Rejected' : 'Awaiting Approval',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF152439),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  rejected
                      ? 'Your registration was not approved by the distributor. '
                            'Please contact them directly.'
                      : 'Your registration request has been sent to the distributor. '
                            'You will be able to log in once they approve your account.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF6B7A8F),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      await AuthService.signOut();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B7BD6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
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
