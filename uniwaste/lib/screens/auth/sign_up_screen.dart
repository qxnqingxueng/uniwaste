import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/sign_up_bloc/sign_up_bloc.dart';
import 'package:user_repository/user_repository.dart';

class SignUpContent extends StatefulWidget {
  final VoidCallback onSignInTap;

  const SignUpContent({super.key, required this.onSignInTap});

  @override
  State<SignUpContent> createState() => _SignUpContentState();
}

class _SignUpContentState extends State<SignUpContent> {
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool obscurePassword = true;
  bool signUpRequired = false;

  // ✅ NEW: field-level firebase/auth error messages
  String? _nameAuthError;
  String? _emailAuthError;
  String? _passwordAuthError;

  @override
  void dispose() {
    _passwordController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final e = email.trim();
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(e);
  }

  void _clearAuthErrors() {
    if (_nameAuthError != null || _emailAuthError != null || _passwordAuthError != null) {
      setState(() {
        _nameAuthError = null;
        _emailAuthError = null;
        _passwordAuthError = null;
      });
    }
  }

  void _applyFriendlyAuthError(String rawMessage) {
    final msg = rawMessage.toLowerCase();

    String? nameErr;
    String? emailErr;
    String? passErr;

    if (msg.contains('email-already-in-use') || msg.contains('already in use')) {
      emailErr = 'This email is already registered.';
    } else if (msg.contains('invalid-email')) {
      emailErr = 'Please enter a valid email address.';
    } else if (msg.contains('weak-password')) {
      passErr = 'Password must be at least 6 characters.';
    } else if (msg.contains('operation-not-allowed')) {
      passErr = 'Sign up is currently unavailable. Please try again later.';
    } else if (msg.contains('network') || msg.contains('socket')) {
      passErr = 'Network error. Please check your connection.';
    } else {
      passErr = 'Sign up failed. Please try again.';
    }

    setState(() {
      _nameAuthError = nameErr;
      _emailAuthError = emailErr;
      _passwordAuthError = passErr;
    });

    // Trigger validation so the red helper text appears immediately
    _formKey.currentState?.validate();
  }

  void _onSignUpPressed() {
    _clearAuthErrors();

    if (_formKey.currentState!.validate()) {
      MyUser myUser = MyUser.empty.copyWith(
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
      );

      context.read<SignUpBloc>().add(
            SignUpRequired(
              myUser,
              _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SignUpBloc, SignUpState>(
      listener: (context, state) {
        if (state is SignUpSuccess) {
          setState(() => signUpRequired = false);

          // ✅ Keep this success snackbar (it's friendly)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created successfully!')),
          );
        } else if (state is SignUpProcess) {
          setState(() => signUpRequired = true);
        } else if (state is SignUpFailure) {
          setState(() => signUpRequired = false);

          // ✅ Replace ugly snackbar error with field-level friendly errors
          final raw = (state.message ?? '').trim();
          if (raw.isNotEmpty) {
            _applyFriendlyAuthError(raw);
          } else {
            _applyFriendlyAuthError('Sign Up Failed');
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
                  height: 80,
                  width: 80,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 15),

              const Text(
                'Create Account',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sign up to get started',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 24),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (_) {
                  if (_nameAuthError != null) {
                    setState(() => _nameAuthError = null);
                    _formKey.currentState?.validate();
                  }
                },
                validator: (val) {
                  if (_nameAuthError != null) return _nameAuthError;

                  final v = (val ?? '').trim();
                  if (v.isEmpty) return 'Please enter your name';
                  if (v.length < 2) return 'Name is too short';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
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
                  if (_emailAuthError != null) {
                    setState(() => _emailAuthError = null);
                    _formKey.currentState?.validate();
                  }
                },
                validator: (val) {
                  if (_emailAuthError != null) return _emailAuthError;

                  final v = (val ?? '').trim();
                  if (v.isEmpty) return 'Please enter your email';
                  if (!_isValidEmail(v)) return 'Please enter a valid email address';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
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
                  if (_passwordAuthError != null) {
                    setState(() => _passwordAuthError = null);
                    _formKey.currentState?.validate();
                  }
                },
                validator: (val) {
                  if (_passwordAuthError != null) return _passwordAuthError;

                  final v = (val ?? '');
                  if (v.isEmpty) return 'Please enter your password';
                  if (v.length < 6) return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: !signUpRequired
                    ? ElevatedButton(
                        onPressed: _onSignUpPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'SIGN UP',
                          style: TextStyle(fontSize: 16, letterSpacing: 1.2),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
              const SizedBox(height: 16),

              Center(
                child: GestureDetector(
                  onTap: widget.onSignInTap,
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(color: Colors.black, fontSize: 14),
                      children: [
                        TextSpan(text: "Already have an account? "),
                        TextSpan(
                          text: "Sign In",
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
