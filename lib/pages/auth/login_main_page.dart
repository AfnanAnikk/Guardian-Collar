import 'package:flutter/material.dart';
import 'package:guardian_collar/pages/dashboard_page.dart';
import '../../widgets/primary_button.dart';
import 'login_page.dart';
import 'signup_page.dart';

class LoginMainPage extends StatelessWidget {
  const LoginMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(color: const Color(0xFFD7FF5F), borderRadius: BorderRadius.circular(32)),
                child: const Icon(Icons.pets_rounded, size: 58, color: Color(0xFF1F2933)),
              ),
              const SizedBox(height: 24),
              const Text('Guardian Collar', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Color(0xFF374957))),
              const SizedBox(height: 10),
              const Text('Track, understand, and care for Mithu.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
              const Spacer(), 
              PrimaryButton(text: 'Log In', onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()))),
              const SizedBox(height: 12),
              PrimaryButton(text: 'Create Account', isOutlined: true, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupPage()))),
              const SizedBox(height: 18),
              const Spacer(), 
              GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const DashboardPage()),
                      );
                    },
                    child: const Text(
                      'Enter',
                      style: TextStyle(
                        color: Color(0xFF7BA800),
                        fontWeight: FontWeight.w800,
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