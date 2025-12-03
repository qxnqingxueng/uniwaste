import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/sign_in_bloc/sign_in_bloc.dart';
import 'package:uniwaste/blocs/sign_up_bloc/sign_up_bloc.dart'; // ADD THIS
import 'package:uniwaste/blocs/authentication_bloc/authentication_bloc.dart';
import 'package:uniwaste/screens/auth/sign_in_screen.dart';
import 'package:uniwaste/screens/auth/sign_up_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _goToSignUp() {
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  void _goToSignIn() {
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF1F3E0),
              Color(0xFFD2DCB6),
              Color(0xFFA1BC98),
            ],
          ),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.all(24),
            constraints: BoxConstraints(
              maxHeight: _currentPage == 0 ? 550 : 700,
              maxWidth: 600,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: -80,
                  bottom: -80,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD2DCB6).withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: -60,
                  bottom: -120,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      color: const Color(0xFFA1BC98).withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),

                ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      // Sign In Content
                      BlocProvider<SignInBloc>(
                        create: (context) => SignInBloc(
                          userRepository:
                              context.read<AuthenticationBloc>().userRepository,
                        ),
                        child: SignInContent(onSignUpTap: _goToSignUp),
                      ),

                      // Sign Up Content - ADD BLOCPROVIDER HERE
                      BlocProvider<SignUpBloc>(
                        create: (context) => SignUpBloc(
                          userRepository:
                              context.read<AuthenticationBloc>().userRepository,
                        ),
                        child: SignUpContent(onSignInTap: _goToSignIn),
                      ),
                    ],
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