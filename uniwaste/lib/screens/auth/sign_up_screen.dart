import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uniwaste/blocs/sign_up_bloc/sign_up_bloc.dart';
import 'package:user_repository/user_repository.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool obscurePassword = true;
  bool signUpRequired = false;

@override
  Widget build(BuildContext context) {
    return BlocProvider<SignUpBloc>(
      create: (context) => SignUpBloc(
        userRepository: context.read<UserRepository>(),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: BlocListener<SignUpBloc, SignUpState>(
          listener: (context, state) {
            if (state is SignUpSuccess) {
              setState(() {
                signUpRequired = false;
              });
              Navigator.pop(context);
            } else if (state is SignUpProcess) {
              setState(() {
                signUpRequired = true;
              });
            } else if (state is SignUpFailure) {
              setState(() {
                signUpRequired = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message ?? 'Sign Up Failed')),
              );
            }
          },
          // FIX: Wrap the child in a Builder to get the correct context
          child: Builder(
            builder: (context) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Create Account',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 40),
                        
                        // ... [Your Name, Email, Password TextFormFields go here] ...
                        // (Copy them from your previous code)
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
                          validator: (val) => val!.isEmpty ? 'Please enter your name' : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
                          validator: (val) => val!.isEmpty ? 'Please enter your email' : null,
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: obscurePassword,
                          decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock), border: OutlineInputBorder()),
                          validator: (val) => val!.isEmpty ? 'Please enter your password' : null,
                        ),
                        
                        const SizedBox(height: 30),

                        // Sign Up Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: !signUpRequired
                              ? ElevatedButton(
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      MyUser myUser = MyUser.empty;
                                      myUser = myUser.copyWith(
                                        email: _emailController.text,
                                        name: _nameController.text,
                                      );

                                      // Now this 'context' comes from the Builder, so it can find the Bloc!
                                      context.read<SignUpBloc>().add(
                                        SignUpRequired(
                                          myUser,
                                          _passwordController.text,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Sign Up', style: TextStyle(fontSize: 16)),
                                )
                              : const Center(child: CircularProgressIndicator()),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}