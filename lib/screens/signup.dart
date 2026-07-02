import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/auth/auth_textfield.dart';
import '../widgets/auth/auth_button.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {

  // ✅ Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;

  // ✅ Signup Function
  Future<void> signUp() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // 🔴 Validation
    if (email.isEmpty || password.isEmpty) {
      showMessage("Please fill all fields");
      return;
    }

    if (password != confirmPassword) {
      showMessage("Passwords do not match");
      return;
    }

    try {
      setState(() => isLoading = true);

      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      showMessage("Signup Successful ✅");

      // 👉 Go to Home
      Navigator.pushReplacementNamed(context, '/home');

    } on FirebaseAuthException catch (e) {
      showMessage(e.message ?? "Signup failed");
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
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 30),

                // 🔷 Logo + Title
                const Center(
                  child: Column(
                    children: [
                      Icon(Icons.directions_car, color: Colors.white, size: 40),
                      SizedBox(height: 10),
                      Text(
                        "Create Account",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // 🔹 Name
                const Text("Full Name", style: TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                AuthTextField(
                  controller: nameController,
                  hint: "Enter your full name",
                  icon: Icons.person,
                ),

                const SizedBox(height: 20),

                // 🔹 Email
                const Text("Email", style: TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                AuthTextField(
                  controller: emailController,
                  hint: "Enter your email",
                  icon: Icons.email,
                ),

                const SizedBox(height: 20),

                // 🔹 Password
                const Text("Password", style: TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                AuthTextField(
                  controller: passwordController,
                  hint: "Create a password",
                  icon: Icons.lock,
                  isPassword: true,
                ),

                const SizedBox(height: 20),

                // 🔹 Confirm Password
                const Text("Confirm Password", style: TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                AuthTextField(
                  controller: confirmPasswordController,
                  hint: "Confirm your password",
                  icon: Icons.lock,
                  isPassword: true,
                ),

                const SizedBox(height: 30),

                // 🔥 Signup Button
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : AuthButton(
                        text: "Sign Up",
                        onPressed: signUp,
                      ),

                const SizedBox(height: 20),

                // 🔁 Go to Login
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Already have an account? Login",
                      style: TextStyle(color: Colors.grey),
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