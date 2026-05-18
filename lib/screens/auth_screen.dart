import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'package:provider/provider.dart'; // Fixes the 'Provider' error
import '../providers/auth_provider.dart'; // Fixes the 'AuthProvider' error

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFFB2EBF2),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "TravelGo!",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            _input(emailController, "Email", autofillHints: const [AutofillHints.email]),
            const SizedBox(height: 15),
            _input(passController, "Password", isPass: true, autofillHints: const [AutofillHints.password]),
            const SizedBox(height: 25),
            ElevatedButton(
              // Inside your login button onPressed:
              onPressed: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);

                bool success = await auth.login(
                  emailController.text,
                  passController.text,
                );

                if (success) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const Dashboard()),
                  );
                } else {
                  // Show error message if login fails
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(auth.error)));
                }
              },
              child: const Text("Log In"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _input(TextEditingController c, String h, {bool isPass = false, List<String>? autofillHints}) =>
      TextField(
        controller: c,
        obscureText: isPass,
        autofillHints: autofillHints,
        decoration: InputDecoration(
          hintText: h,
          filled: true,
          fillColor: Colors.white70,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      );
}
