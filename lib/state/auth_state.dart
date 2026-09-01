import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/shop_service.dart';

/// Holds the resolved role + distributor ID after login.
/// Exposed via [AuthStateScope] InheritedNotifier.
class AuthState extends ChangeNotifier {
  UserRole? _role;
  String? _distributorId;
  String? _status; // 'active' | 'pending' | 'rejected'
  ShopProfile? _shopProfile;
  bool _loading = false;
  String? _error;

  UserRole? get role => _role;
  String? get distributorId => _distributorId;
  String? get status => _status;
  ShopProfile? get shopProfile => _shopProfile;
  bool get loading => _loading;
  String? get error => _error;

  bool get isDistributor => _role == UserRole.distributor;
  bool get isShop => _role == UserRole.shop;
  bool get isApprovedShop => _role == UserRole.shop && _status == 'active';

  void setResolved({
    required UserRole role,
    required String distributorId,
    required String status,
    ShopProfile? shopProfile,
  }) {
    _role = role;
    _distributorId = distributorId;
    _status = status;
    if (shopProfile != null) {
      _shopProfile = shopProfile;
    }
    _error = null;
    notifyListeners();
  }

  void setShopProfile(ShopProfile? profile) {
    _shopProfile = profile;
    notifyListeners();
  }

  void setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  void setError(String? msg) {
    _error = msg;
    notifyListeners();
  }

  void clear() {
    _role = null;
    _distributorId = null;
    _status = null;
    _shopProfile = null;
    _error = null;
    notifyListeners();
  }
}

class AuthStateScope extends InheritedNotifier<AuthState> {
  const AuthStateScope({
    super.key,
    required AuthState state,
    required super.child,
  }) : super(notifier: state);

  static AuthState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthStateScope>();
    assert(scope != null, 'No AuthStateScope in widget tree');
    return scope!.notifier!;
  }
}
