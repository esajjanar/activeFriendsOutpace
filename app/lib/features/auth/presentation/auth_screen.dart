import 'package:activefriends/core/theme/app_colors.dart';
import 'package:activefriends/core/presentation/app_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  final _resetCodeController = TextEditingController();
  var _isSignUp = false;
  var _codeSent = false;
  var _passwordResetCodeSent = false;
  var _isSubmitting = false;
  var _obscurePassword = true;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    _resetCodeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      await Supabase.instance.client.functions.invoke(
        'verify-email',
        body: {'action': 'send', 'email': _emailController.text.trim()},
      );
      if (mounted) {
        setState(() {
          _codeSent = true;
          _codeController.clear();
          _message = 'Code sent to ${_emailController.text.trim()}';
        });
      }
    } on FunctionException catch (e) {
      if (mounted) {
        setState(
          () => _message =
              e.details?.toString() ?? 'Failed to send code. Try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _verifyAndSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      final verifyResult = await Supabase.instance.client.functions.invoke(
        'verify-email',
        body: {
          'action': 'check',
          'email': _emailController.text.trim(),
          'code': _codeController.text.trim(),
        },
      );
      final data = verifyResult.data as Map<String, dynamic>;
      if (data['verified'] != true) {
        if (mounted) {
          setState(
            () => _message = data['error'] as String? ?? 'Invalid code.',
          );
        }
        return;
      }
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Bootstrap stream handles navigation on session creation.
    } on FunctionException catch (e) {
      if (mounted) {
        setState(
          () => _message = e.details?.toString() ?? 'Verification failed.',
        );
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Something went wrong. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(() => _message = 'Enter your email address first.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (mounted) {
        setState(() {
          _passwordResetCodeSent = true;
          _resetCodeController.clear();
          _message = 'If an account exists for $email, an 8-digit code was sent. Check your inbox and spam folder.';
        });
      }
    } on AuthException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _message = 'Could not send reset email. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _verifyResetCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _message = null;
    });
    try {
      await Supabase.instance.client.auth.verifyOTP(
        email: _emailController.text.trim(),
        token: _resetCodeController.text.trim(),
        type: OtpType.recovery,
      );
      // onAuthStateChange fires passwordRecovery → bootstrap shows ResetPasswordScreen
    } on AuthException catch (e) {
      if (mounted) setState(() => _message = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => _message = 'Invalid code. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _cancelReset() {
    setState(() {
      _passwordResetCodeSent = false;
      _resetCodeController.clear();
      _message = null;
    });
  }

  void _resetSignUp() {
    setState(() {
      _codeSent = false;
      _codeController.clear();
      _message = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final showEmailPassword =
        !_passwordResetCodeSent && !(_isSignUp && _codeSent);

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
                    Row(
                      children: [
                        const AppMark(size: 48),
                        const SizedBox(width: 12),
                        Text(
                          'OUTPACE',
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Our club. Our activity. Our pace.',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(color: colors.textMuted),
                    ),
                    const SizedBox(height: 32),

                    // Email + password fields (sign-in / sign-up)
                    if (showEmailPassword) ...[
                      TextFormField(
                        controller: _emailController,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.email],
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_isSubmitting,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (value) =>
                            value != null && value.contains('@')
                            ? null
                            : 'Enter a valid email address.',
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        autofillHints: const [
                          AutofillHints.newPassword,
                          AutofillHints.password,
                        ],
                        enabled: !_isSubmitting,
                        decoration: InputDecoration(
                          labelText: 'Password',
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
                    ],

                    // Sign-up verification code
                    if (_isSignUp && _codeSent) ...[
                      Text(
                        'Sending to: ${_emailController.text.trim()}',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: colors.textMuted),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        autofocus: true,
                        enabled: !_isSubmitting,
                        decoration: const InputDecoration(
                          labelText: 'Verification code',
                          hintText: '4-digit code from your email',
                        ),
                        validator: (value) => value != null && value.length == 4
                            ? null
                            : 'Enter the 4-digit code.',
                      ),
                    ],

                    // Password reset code
                    if (_passwordResetCodeSent) ...[
                      Text(
                        'Sending to: ${_emailController.text.trim()}',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: colors.textMuted),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _resetCodeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(8),
                        ],
                        autofocus: true,
                        enabled: !_isSubmitting,
                        decoration: const InputDecoration(
                          labelText: 'Reset code',
                          hintText: '8-digit code from your email',
                        ),
                        validator: (value) => value != null && value.length == 8
                            ? null
                            : 'Enter the 8-digit code.',
                      ),
                    ],

                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      Text(_message!, style: TextStyle(color: colors.accent)),
                    ],
                    const SizedBox(height: 24),

                    // Primary action button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSubmitting
                            ? null
                            : _passwordResetCodeSent
                            ? _verifyResetCode
                            : _isSignUp
                            ? (_codeSent ? _verifyAndSignUp : _sendCode)
                            : _signIn,
                        style: _isSignUp
                            ? FilledButton.styleFrom(
                                backgroundColor: colors.accent,
                                foregroundColor: Colors.white,
                              )
                            : null,
                        child: Text(
                          _isSubmitting
                              ? 'Please wait…'
                              : _passwordResetCodeSent
                              ? 'Verify code'
                              : _isSignUp
                              ? (_codeSent
                                    ? 'Create account'
                                    : 'Send verification code')
                              : 'Sign in',
                        ),
                      ),
                    ),

                    // Forgot password (sign-in mode only)
                    if (!_isSignUp && !_passwordResetCodeSent) ...[
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: _isSubmitting ? null : _sendPasswordReset,
                          child: const Text('Forgot password?'),
                        ),
                      ),
                    ],

                    // Cancel reset
                    if (_passwordResetCodeSent) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: _isSubmitting ? null : _cancelReset,
                          child: Text(
                            'Use a different email',
                            style: TextStyle(color: colors.textMuted),
                          ),
                        ),
                      ),
                    ],

                    // Sign-up: use different email
                    if (_isSignUp && _codeSent) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: _isSubmitting ? null : _resetSignUp,
                          child: Text(
                            'Use a different email',
                            style: TextStyle(color: colors.textMuted),
                          ),
                        ),
                      ),
                    ],

                    // Sign-in / sign-up toggle
                    if (!_passwordResetCodeSent && !(_isSignUp && _codeSent)) ...[
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          _isSignUp
                              ? 'Already have an account?'
                              : 'Need an account?',
                          style: TextStyle(color: colors.textMuted),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => setState(() {
                                  _isSignUp = !_isSignUp;
                                  _codeSent = false;
                                  _message = null;
                                  _codeController.clear();
                                }),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _isSignUp
                                ? Theme.of(context).colorScheme.primary
                                : colors.accent,
                            side: BorderSide(
                              color: _isSignUp
                                  ? Theme.of(context).colorScheme.primary
                                  : colors.accent,
                            ),
                          ),
                          child: Text(
                            _isSignUp ? 'Sign in instead' : 'Create account',
                          ),
                        ),
                      ),
                    ],
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
