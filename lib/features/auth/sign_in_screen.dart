import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/providers.dart';
import '../../widgets/brand_button.dart';
import '../../widgets/common.dart';

/// Sign-in / sign-up (email + Google). Only shown when the real backend is
/// enabled; in mock mode the app starts straight at Welcome. After a successful
/// sign-in the router's auth gate moves the user on automatically.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isSignUp = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authServiceProvider);

    return Scaffold(
      backgroundColor: BrandColors.indigo,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Eyebrow('AI Memory Concierge'),
                const SizedBox(height: 12),
                const Text('MemoryFlow',
                    style: TextStyle(
                        color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  _isSignUp ? 'Create your account' : 'Welcome back',
                  style: const TextStyle(color: Color(0xFFC9C4E4), fontSize: 15),
                ),
                const SizedBox(height: 28),
                _Field(controller: _email, hint: 'Email', keyboard: TextInputType.emailAddress),
                const SizedBox(height: 12),
                _Field(controller: _password, hint: 'Password', obscure: true),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!,
                      style: const TextStyle(color: BrandColors.coral, fontSize: 13)),
                ],
                const SizedBox(height: 20),
                if (_busy)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  BrandButton(
                    label: _isSignUp ? 'Sign up' : 'Sign in',
                    onPressed: () => _run(() => _isSignUp
                        ? auth.signUpWithEmail(_email.text.trim(), _password.text)
                        : auth.signInWithEmail(_email.text.trim(), _password.text)),
                  ),
                  const SizedBox(height: 12),
                  BrandButton(
                    label: 'Continue with Google',
                    style: BrandButtonStyle.ghost,
                    onPressed: () => _run(auth.signInWithGoogle),
                  ),
                ],
                const SizedBox(height: 18),
                Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _isSignUp = !_isSignUp),
                    child: Text(
                      _isSignUp
                          ? 'Already have an account? Sign in'
                          : "New here? Create an account",
                      style: const TextStyle(color: Color(0xFF9A95B5), fontSize: 13.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '🔒 Your photos stay read-only. We never delete originals.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF7A7690), fontSize: 11.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboard,
  });

  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboard;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF7A7690)),
        filled: true,
        fillColor: BrandColors.indigo2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3A3460)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BrandColors.violet, width: 1.5),
        ),
      ),
    );
  }
}
