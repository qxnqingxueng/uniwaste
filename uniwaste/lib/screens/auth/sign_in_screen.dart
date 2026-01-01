import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/sign_in_bloc/sign_in_bloc.dart';

class SignInContent extends StatefulWidget {
  final VoidCallback onSignUpTap;

  const SignInContent({super.key, required this.onSignUpTap});

  @override
  State<SignInContent> createState() => _SignInContentState();
}

class _SignInContentState extends State<SignInContent> {
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool signInRequired = false;
  bool obscurePassword = true;

  // ✅ NEW: field-level firebase/auth error messages
  String? _emailAuthError;
  String? _passwordAuthError;

  @override
  void dispose() {
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // ✅ NEW: basic email format check (simple + effective)
  bool _isValidEmail(String email) {
    final e = email.trim();
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(e);
  }

  // ✅ NEW: map ugly firebase/auth error to friendly message
  // We don't rely on exact wording; we match common codes/keywords.
  void _applyFriendlyAuthError(String rawMessage) {
    final msg = rawMessage.toLowerCase();

    String? emailErr;
    String? passErr;

    // Most common in your screenshot:
    // [firebase_auth/invalid-credential]
    if (msg.contains('invalid-credential') ||
        msg.contains('wrong-password') ||
        msg.contains('invalid login credentials') ||
        msg.contains('incorrect') && msg.contains('password')) {
      // Put it under password (best UX)
      passErr = 'Incorrect email or password.';
    } else if (msg.contains('user-not-found')) {
      emailErr = 'No account found for this email.';
    } else if (msg.contains('invalid-email')) {
      emailErr = 'Please enter a valid email address.';
    } else if (msg.contains('too-many-requests')) {
      passErr = 'Too many attempts. Please try again later.';
    } else if (msg.contains('network') || msg.contains('socket')) {
      passErr = 'Network error. Please check your connection.';
    } else {
      // fallback (still user-friendly)
      passErr = 'Login failed. Please try again.';
    }

    setState(() {
      _emailAuthError = emailErr;
      _passwordAuthError = passErr;
    });

    // Trigger re-validation so the red text appears immediately
    _formKey.currentState?.validate();
  }

  void _clearAuthErrors() {
    if (_emailAuthError != null || _passwordAuthError != null) {
      setState(() {
        _emailAuthError = null;
        _passwordAuthError = null;
      });
    }
  }

  void _onLoginPressed() {
    // clear old firebase error text first
    _clearAuthErrors();

    if (_formKey.currentState!.validate()) {
      context.read<SignInBloc>().add(
            SignInRequired(
              _emailController.text.trim(),
              _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignInBloc, SignInState>(
      listener: (context, state) {
        if (state is SignInSuccess) {
          setState(() => signInRequired = false);
        } else if (state is SignInProcess) {
          setState(() => signInRequired = true);
        } else if (state is SignInFailure) {
          setState(() => signInRequired = false);

          // ✅ Replace ugly snackbar error with field-level friendly errors
          final raw = (state.message ?? '').trim();
          if (raw.isNotEmpty) {
            _applyFriendlyAuthError(raw);
          } else {
            _applyFriendlyAuthError('Login failed');
          }
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  'assets/images/calligraphy-monoline-green-leaf-flat-leaf_78370-5799.jpg',
                  height: 120,
                  width: 120,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Welcome to Uniwaste!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Enter your email & password to Login',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 32),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (_) {
                  // ✅ clear firebase error as user edits
                  if (_emailAuthError != null) {
                    setState(() => _emailAuthError = null);
                    _formKey.currentState?.validate();
                  }
                },
                validator: (val) {
                  final v = (val ?? '').trim();

                  // firebase/auth error takes priority if exists
                  if (_emailAuthError != null) return _emailAuthError;

                  if (v.isEmpty) return 'Please enter your email';
                  if (!_isValidEmail(v)) return 'Please enter a valid email address';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (_) {
                  // ✅ clear firebase error as user edits
                  if (_passwordAuthError != null) {
                    setState(() => _passwordAuthError = null);
                    _formKey.currentState?.validate();
                  }
                },
                validator: (val) {
                  // firebase/auth error takes priority if exists
                  if (_passwordAuthError != null) return _passwordAuthError;

                  final v = (val ?? '');
                  if (v.isEmpty) return 'Please enter your password';
                  // optional: you can keep/remove this; it's useful UX
                  if (v.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: !signInRequired
                    ? ElevatedButton(
                        onPressed: _onLoginPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'LOGIN',
                          style: TextStyle(fontSize: 16, letterSpacing: 1.2),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),

              const SizedBox(height: 16),

              Center(
                child: GestureDetector(
                  onTap: widget.onSignUpTap,
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(color: Colors.black, fontSize: 14),
                      children: [
                        TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: "Sign Up",
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
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
    );
  }
}
