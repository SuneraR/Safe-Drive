import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/auth/auth_textfield.dart';
import '../widgets/auth/auth_button.dart';
import 'signup.dart';
import '../main.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  // 🔥 LOGIN FUNCTION
  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage("Please enter email and password");
      return;
    }

    try {
      setState(() => isLoading = true);

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ✅ ONLY SUCCESS NAVIGATION
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const RootNavigationScreen(),
        ),
      );

    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? "Login failed");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// Logo
                  const Center(
                    child: Column(
                      children: [
                        Icon(Icons.directions_car, color: Colors.white, size: 40),
                        SizedBox(height: 10),
                        Text(
                          "SafeDrive",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Welcome Back",
                          style: TextStyle(color: Colors.grey),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  /// Email
                  const Text("Email", style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  AuthTextField(
                    controller: emailController,
                    hint: "Enter your email",
                    icon: Icons.email,
                  ),

                  const SizedBox(height: 20),

                  /// Password
                  const Text("Password", style: TextStyle(color: Colors.white)),
                  const SizedBox(height: 8),
                  AuthTextField(
                    controller: passwordController,
                    hint: "Enter your password",
                    icon: Icons.lock,
                    isPassword: true,
                  ),

                  const SizedBox(height: 10),

                  /// Forgot Password
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "Forgot Password?",
                      style: TextStyle(color: Colors.green),
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// Login Button / Loader
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : AuthButton(
                          text: "Login",
                          onPressed: login,
                        ),

                  const SizedBox(height: 20),

                  /// OR Divider
                  Row(
                    children: const [
                      Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text("OR", style: TextStyle(color: Colors.grey)),
                      ),
                      Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// Sign Up Link
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Signup(),
                          ),
                        );
                      },
                      child: const Text(
                        "Don't have an account? Sign Up",
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}