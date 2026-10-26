import 'dart:io';

import 'package:activefriends/features/home/presentation/app_shell.dart'
    as activefriends_shell;
import 'package:activefriends/core/presentation/app_mark.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onComplete});

  /// Called after the profile is saved so that the parent can re-fetch.
  final VoidCallback? onComplete;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _picker = ImagePicker();
  XFile? _selectedImage;
  var _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dlg) => AlertDialog(
        title: const Text('Sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlg).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dlg).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await Supabase.instance.client.auth.signOut();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser!;
      String? avatarUrl;
      final image = _selectedImage;
      if (image != null) {
        final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await Supabase.instance.client.storage
            .from('avatars')
            .uploadBinary(
              path,
              await image.readAsBytes(),
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: false,
              ),
            );
        avatarUrl = Supabase.instance.client.storage
            .from('avatars')
            .getPublicUrl(path);
      }
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'display_name': _displayNameController.text.trim(),
        if (avatarUrl != null) ...{'avatar_url': avatarUrl},
      });
      if (!mounted) return;
      // Signal parent (_ProfileBootstrap) to re-fetch the profile.
      // It will now find the profile and render AppShell (with bottom bar).
      final onComplete = widget.onComplete;
      if (onComplete != null) {
        onComplete();
      } else {
        // Fallback for standalone use — navigate to AppShell directly.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const activefriends_shell.AppShell(),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Your profile could not be saved. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppMark(size: 48),
              const SizedBox(height: 18),
              Text(
                'What should friends call you?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: _isSubmitting
                      ? null
                      : () async {
                          final image = await _picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 82,
                            maxWidth: 640,
                          );
                          if (mounted && image != null) {
                            setState(() => _selectedImage = image);
                          }
                        },
                  child: CircleAvatar(
                    radius: 44,
                    backgroundImage: _selectedImage == null
                        ? null
                        : FileImage(File(_selectedImage!.path)),
                    child: _selectedImage == null
                        ? const Icon(Icons.add_a_photo_outlined, size: 30)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _displayNameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Display name'),
                validator: (value) => value != null && value.trim().isNotEmpty
                    ? null
                    : 'Enter a display name.',
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _save,
                  child: Text(_isSubmitting ? 'Saving' : 'Continue'),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
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
