import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/shop_logo.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
// ── Login Screen ──────────────────────────────────────────────────────────────

class LoginScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback? onSuccess;
  final VoidCallback? onGoSignUp;
  final bool isModal; // true when shown as a bottom sheet / dialog

  const LoginScreen({
    super.key,
    required this.appState,
    this.onSuccess,
    this.onGoSignUp,
    this.isModal = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final AuthService _authService = AuthService();
  bool _obscure = true;
  bool _loading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    final err = await widget.appState.login(
      _emailCtrl.text,
      _passCtrl.text,
    );

    if (!mounted) return;

    setState(() => _loading = false);

    if (err != null) {
      setState(() => _errorMsg = err);
    } else {
      widget.onSuccess?.call();
      if (!widget.isModal) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ExploreWithNav(appState: widget.appState),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              if (!widget.isModal)
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                ),
              const SizedBox(height: 24),
              // Header
              Center(
                child: Column(
                  children: [
                    // Shop logo — large & prominent
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.secondary, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.35),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: AppTheme.secondary.withValues(alpha: 0.2),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const ShopLogoImage(size: 90),
                    ),
                    const SizedBox(height: 10),
                    const Text('SIVA SILKS',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryDark,
                            letterSpacing: 3)),
                    const SizedBox(height: 2),
                    const Text("Muniyappan kovil's Finest Fashion",
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 20),
                    const Text('Welcome Back',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryDark,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    const Text('Sign in to your account',
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Error banner
                    if (_errorMsg != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppTheme.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(_errorMsg!,
                                    style: const TextStyle(
                                        color: AppTheme.error, fontSize: 13))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Email
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration:
                          _inputDecor('Email address', Icons.email_outlined),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Password
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration:
                          _inputDecor('Password', Icons.lock_outline_rounded)
                              .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppTheme.textLight,
                              size: 20),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Login',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 1)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Go to sign up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? ",
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 14)),
                        GestureDetector(
                          onTap: widget.onGoSignUp,
                          child: const Text('Sign Up',
                              style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppTheme.textLight),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      );
}

// ── Sign Up Screen ────────────────────────────────────────────────────────────

class SignUpScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback? onSuccess; // called after successful signup → go to login
  final VoidCallback? onGoLogin;
  final bool isModal;

  const SignUpScreen({
    super.key,
    required this.appState,
    this.onSuccess,
    this.onGoLogin,
    this.isModal = false,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  
  final _addrLine1Ctrl = TextEditingController();
  final _addrLine2Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  String _gender = 'Male';
  
  final AuthService _authService = AuthService();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _errorMsg;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _addrLine1Ctrl.dispose();
    _addrLine2Ctrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _stateCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    final err = await widget.appState.signUp(
      name: _nameCtrl.text,
      email: _emailCtrl.text,
      phone: _phoneCtrl.text,
      password: _passCtrl.text,
      dob: _dobCtrl.text,
      gender: _gender,
      addressLine1: _addrLine1Ctrl.text,
      addressLine2: _addrLine2Ctrl.text,
      city: _cityCtrl.text,
      district: _districtCtrl.text,
      state: _stateCtrl.text,
      pincode: _pinCtrl.text,
    );

    setState(() => _loading = false);

    if (err != null) {
      setState(() => _errorMsg = err);
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created! Please login')),
      );

      widget.onSuccess?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              if (!widget.isModal)
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.secondary, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.35),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                          BoxShadow(
                            color: AppTheme.secondary.withValues(alpha: 0.2),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const ShopLogoImage(size: 90),
                    ),
                    const SizedBox(height: 10),
                    const Text('SIVA SILKS',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryDark,
                            letterSpacing: 3)),
                    const SizedBox(height: 2),
                    const Text("Muniyappan kovil's Finest Fashion",
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.secondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 20),
                    const Text('Create Account',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryDark,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    const Text('Join the Siva Silks family',
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_errorMsg != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppTheme.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppTheme.error, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(_errorMsg!,
                                    style: const TextStyle(
                                        color: AppTheme.error, fontSize: 13))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _field(_nameCtrl, 'Full Name', Icons.person_outline_rounded,
                        TextInputType.name, (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Name is required';
                      }
                      if (v.trim().length < 2) return 'Enter a valid name';
                      return null;
                    }),
                    const SizedBox(height: 14),
                    _field(_emailCtrl, 'Email Address', Icons.email_outlined,
                        TextInputType.emailAddress, (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!v.contains('@') || !v.contains('.')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    }),
                    const SizedBox(height: 14),
                    _field(_phoneCtrl, 'Mobile Number', Icons.phone_outlined,
                        TextInputType.phone, (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Phone is required';
                      }
                      if (v.trim().replaceAll(RegExp(r'\D'), '').length < 10) {
                        return 'Enter a valid 10-digit number';
                      }
                      return null;
                    }),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _dobCtrl,
                      readOnly: true,
                      decoration: _inputDecor('Date of Birth', Icons.cake_outlined),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppTheme.primary,
                                  onPrimary: Colors.white,
                                  onSurface: AppTheme.textPrimary,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (date != null) {
                          setState(() {
                            // Example format: 14/02/1998
                            _dobCtrl.text = "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: _inputDecor('Gender', Icons.person_search_outlined),
                      items: ['Male', 'Female', 'Other']
                          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                          .toList(),
                      onChanged: (v) => setState(() => _gender = v!),
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: AppTheme.divider),
                    const SizedBox(height: 14),
                    _field(_addrLine1Ctrl, 'Address Line 1', Icons.home_outlined,
                        TextInputType.streetAddress, (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 14),
                    _field(_addrLine2Ctrl, 'Address Line 2 (Optional)', Icons.add_home_outlined,
                        TextInputType.streetAddress, (v) => null),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _field(_cityCtrl, 'City', Icons.location_city_outlined, TextInputType.text, (v) => v == null || v.trim().isEmpty ? 'Required' : null)),
                        const SizedBox(width: 14),
                        Expanded(child: _field(_districtCtrl, 'District', Icons.map_outlined, TextInputType.text, (v) => v == null || v.trim().isEmpty ? 'Required' : null)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _field(_stateCtrl, 'State', Icons.map_outlined, TextInputType.text, (v) => v == null || v.trim().isEmpty ? 'Required' : null)),
                        const SizedBox(width: 14),
                        Expanded(child: _field(_pinCtrl, 'Pincode', Icons.pin_drop_outlined, TextInputType.number, (v) => v == null || v.trim().isEmpty ? 'Required' : null)),
                      ],
                    ),

                    const Divider(color: AppTheme.divider),
                    const SizedBox(height: 14),
                    // Password
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscurePass,
                      textInputAction: TextInputAction.next,
                      decoration:
                          _inputDecor('Password', Icons.lock_outline_rounded)
                              .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                              _obscurePass
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppTheme.textLight,
                              size: 20),
                          onPressed: () =>
                              setState(() => _obscurePass = !_obscurePass),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password is required';
                        }
                        if (v.length < 6) {
                          return 'At least 6 characters required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    // Confirm password
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: _inputDecor(
                              'Confirm Password', Icons.lock_reset_rounded)
                          .copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppTheme.textLight,
                              size: 20),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (v != _passCtrl.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Create Account',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account? ',
                            style: TextStyle(
                                color: AppTheme.textSecondary, fontSize: 14)),
                        GestureDetector(
                          onTap: widget.onGoLogin,
                          child: const Text('Login',
                              style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, IconData icon,
      TextInputType type, String? Function(String?) validator) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      textInputAction: TextInputAction.next,
      decoration: _inputDecor(hint, icon),
      validator: validator,
    );
  }

  InputDecoration _inputDecor(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: AppTheme.textLight),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.accent, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.error)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.error, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      );
}

// ── Auth Gate Widget: Login/Signup switcher ───────────────────────────────────
// Shown as a full-screen navigator that starts on Login and can switch to SignUp

class AuthGateScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback? onLoginSuccess;
  final bool isModal;

  const AuthGateScreen({
    super.key,
    required this.appState,
    this.onLoginSuccess,
    this.isModal = false,
  });

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  bool _showLogin = true; // start on login; false = show signup

  @override
  Widget build(BuildContext context) {
    if (_showLogin) {
      return LoginScreen(
        appState: widget.appState,
        isModal: true, // we set this to true so LoginScreen doesn't navigate on its own
        onSuccess: () {
          widget.onLoginSuccess?.call();
          if (widget.isModal) Navigator.pop(context);
        },
        onGoSignUp: () => setState(() => _showLogin = false),
      );
    } else {
      return SignUpScreen(
        appState: widget.appState,
        isModal: true, // we set to true to prevent its default pop
        onSuccess: () =>
            setState(() => _showLogin = true), // after signup → login
        onGoLogin: () => setState(() => _showLogin = true),
      );
    }
  }
}

// ── Helper: show login prompt before ordering ─────────────────────────────────
Future<bool> requireLogin(BuildContext context, AppState appState) async {
  if (appState.isLoggedIn) return true;
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          Expanded(
            child: _ModalAuthGate(appState: appState),
          ),
        ],
      ),
    ),
  );
  return result == true;
}

class _ModalAuthGate extends StatefulWidget {
  final AppState appState;
  const _ModalAuthGate({required this.appState});
  @override
  State<_ModalAuthGate> createState() => _ModalAuthGateState();
}

class _ModalAuthGateState extends State<_ModalAuthGate> {
  bool _showLogin = true;

  @override
  Widget build(BuildContext context) {
    if (_showLogin) {
      return LoginScreen(
        appState: widget.appState,
        isModal: true,
        onSuccess: () => Navigator.pop(context, true),
        onGoSignUp: () => setState(() => _showLogin = false),
      );
    } else {
      return SignUpScreen(
        appState: widget.appState,
        isModal: true,
        onSuccess: () => setState(() => _showLogin = true),
        onGoLogin: () => setState(() => _showLogin = true),
      );
    }
  }
}
