import 'package:everafter/services/gallery_admin_auth.dart';
import 'package:everafter/theme/everafter_theme.dart';
import 'package:flutter/material.dart';

class GalleryAdminSignInScreen extends StatefulWidget {
  const GalleryAdminSignInScreen({super.key});

  @override
  State<GalleryAdminSignInScreen> createState() =>
      _GalleryAdminSignInScreenState();
}

class _GalleryAdminSignInScreenState extends State<GalleryAdminSignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate() || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await GalleryAdminAuth.instance.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } on GalleryAdminAuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Exception {
      if (mounted) {
        setState(() => _error = 'Could not sign in. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('gallery-admin-sign-in-screen'),
      backgroundColor: EverAfterColors.ink,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF251915),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF6D5144)),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 28,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const Text(
                          'GALLERY ADMIN',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: EverAfterColors.agedPaper,
                            fontFamily: 'Georgia',
                            fontSize: 24,
                            letterSpacing: 3,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in with an explicitly authorized owner account.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFFC9B8AD)),
                        ),
                        const SizedBox(height: 26),
                        TextFormField(
                          key: const ValueKey('gallery-admin-email'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const <String>[AutofillHints.email],
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: (value) =>
                              value == null || !value.contains('@')
                              ? 'Enter a valid email address.'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const ValueKey('gallery-admin-password'),
                          controller: _passwordController,
                          obscureText: true,
                          enableSuggestions: false,
                          autocorrect: false,
                          autofillHints: const <String>[AutofillHints.password],
                          onFieldSubmitted: (_) => _signIn(),
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Enter your password.'
                              : null,
                        ),
                        if (_error != null) ...<Widget>[
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            key: const ValueKey('gallery-admin-auth-error'),
                            style: const TextStyle(color: Color(0xFFFFA8A8)),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          key: const ValueKey('gallery-admin-sign-in'),
                          onPressed: _submitting ? null : _signIn,
                          icon: _submitting
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.lock_outline),
                          label: Text(_submitting ? 'Signing in…' : 'Sign in'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
