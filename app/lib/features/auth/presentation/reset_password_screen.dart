import 'package:activefriends/core/presentation/app_mark.dart';
import 'package:activefriends/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  var _isSubmitting = false;
  var _obscurePassword = true;
  var _obscureConfirm = true;
  String? _message;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );
      if (!mounted) return;
      await Supabase.instance.client.auth.signOut();
      if (mounted)
        setState(() => _message = 'Password updated. You can now sign in.');
    } on AuthException catch (error) {
      if (mounted) setState(() => _message = error.message);
    } catch (_) {
      if (mounted)
        setState(() => _message = 'Could not update password. Try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        AppMark(size: 48),
                        SizedBox(width: 12),
                        Text(
                          'OUTPACE',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Set a new password',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose a new password for your Outpace account.',
                      style: TextStyle(color: colors.textMuted),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enabled: !_isSubmitting,
                      decoration: InputDecoration(
                        labelText: 'New password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (value) => value != null && value.length >= 8
                          ? null
                          : 'Use at least 8 characters.',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmationController,
                      obscureText: _obscureConfirm,
                      enabled: !_isSubmitting,
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      validator: (value) => value == _passwordController.text
                          ? null
                          : 'Passwords do not match.',
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      Text(_message!, style: TextStyle(color: colors.accent)),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _updatePassword,
                        child: Text(
                          _isSubmitting ? 'Updating…' : 'Update password',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
