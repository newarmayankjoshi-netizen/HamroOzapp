import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'auth_page.dart';
import 'services/security_service.dart';
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  String? _selectedState;
  DateTime? _selectedBirthday;
  List<String> _selectedLanguages = [];
  String? _profilePicturePath;
  bool _isLoading = false;
  String? _error;
  String _selectedRole = 'Worker';
  bool _showPhone = false;
  bool _showEmail = false;

  static const List<String> australianStates = [
    'NSW','VIC','QLD','WA','SA','TAS','ACT','NT'
  ];

  static const List<String> availableLanguages = [
    'Nepali','English','Hindi','Newari','Maithili','Bhojpuri','Tharu','Tamang','Magar','Awadhi'
  ];

  static const List<String> _roles = ['Student','Worker','Landlord','Employer','Admin'];

  final ImagePicker _picker = ImagePicker();
  final _security = SecurityService();

  @override
  void initState() {
    super.initState();
    final uid = AuthState.currentUserId;
    if (uid != null) {
      final u = AuthService.getUserById(uid);
      if (u != null) {
        _nameController.text = u.name;
        _phoneController.text = u.phone ?? '';
        _bioController.text = u.bio ?? '';
        _locationController.text = u.location ?? '';
        _selectedRole = u.role;
        _showPhone = u.showPhone;
        _showEmail = u.showEmail;
        _selectedState = u.state;
        _selectedBirthday = u.birthday;
        _profilePicturePath = u.profilePicture;
        _selectedLanguages = u.languages != null ? List.from(u.languages!) : [];
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickPicture() async {
    try {
      final XFile? f = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 85);
      if (f != null) {
        if (!mounted) return;
        setState(() => _profilePicturePath = f.path);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Failed to pick image: $e');
    }
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() => _selectedBirthday = picked);
    }
  }

  void _selectLanguages() async {
    final temp = List<String>.from(_selectedLanguages);
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, s) {
        return AlertDialog(
          title: const Text('Select languages'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
                  children: availableLanguages.map((l) {
                final chosen = temp.contains(l);
                return CheckboxListTile(
                  value: chosen,
                  title: Text(l),
                  onChanged: (v) {
                    s(() {
                      if (v == true) {
                        temp.add(l);
                      } else {
                        temp.remove(l);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () { setState(() => _selectedLanguages = temp); Navigator.pop(ctx); }, child: const Text('Done')),
          ],
        );
      }),
    );
  }

  Future<void> _save() async {
    final uid = AuthState.currentUserId;
    if (uid == null) return;
    setState(() { _isLoading = true; _error = null; });

    final name = _security.sanitizeInput(_nameController.text.trim(), maxLength: 80);
    final bio = _security.sanitizeInput(_bioController.text.trim(), maxLength: 300);
    final phone = _security.sanitizeInput(_phoneController.text.trim(), maxLength: 20);
    final location = _security.sanitizeInput(_locationController.text.trim(), maxLength: 120);

    if (name.isEmpty) { setState(() { _error = 'Name cannot be empty'; _isLoading = false; }); return; }

    final success = await AuthService.updateUserProfile(
      userId: uid,
      name: name,
      phone: phone.isEmpty ? null : phone,
      state: _selectedState,
      location: location.isEmpty ? null : location,
      role: _selectedRole,
      birthday: _selectedBirthday,
      profilePicture: _profilePicturePath,
      bio: bio.isEmpty ? null : bio,
      languages: _selectedLanguages.isEmpty ? null : _selectedLanguages,
      showPhone: _showPhone,
      showEmail: _showEmail,
    );

    if (!success) {
      setState(() { _error = 'Failed to update profile'; _isLoading = false; });
      return;
    }

    // Update AuthState local display name
    AuthState.login(uid, AuthState.currentUser?.email ?? '', name);
    await AuthState.persistSession();

    if (!mounted) return;
    setState(() { _isLoading = false; });
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickPicture,
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: _profilePicturePath == null
                            ? Text(
                                (() {
                                  final n = AuthState.currentUserName ?? '';
                                  return n.trim().isEmpty ? '?' : n.trim()[0].toUpperCase();
                                })(),
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                              )
                            : ClipOval(
                                child: Image.file(
                                  File(_profilePicturePath!),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(onPressed: _pickPicture, child: const Text('Change picture')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 12),
              TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
              const SizedBox(height: 12),
              // Role selection
              DropdownButtonFormField<String>(
                initialValue: _roles.contains(_selectedRole) ? _selectedRole : 'Worker',
                items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) { if (v != null) setState(() => _selectedRole = v); },
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              const SizedBox(height: 12),

              // Location
              TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location (suburb/city, state)')),
              const SizedBox(height: 12),

              // Show phone/email toggles
              SwitchListTile.adaptive(
                value: _showPhone,
                onChanged: (v) => setState(() => _showPhone = v),
                title: const Text('Show phone to other users'),
              ),
              SwitchListTile.adaptive(
                value: _showEmail,
                onChanged: (v) => setState(() => _showEmail = v),
                title: const Text('Show email to other users'),
              ),

              // State
              DropdownButtonFormField<String>(
                initialValue: _selectedState,
                items: australianStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _selectedState = v),
                decoration: const InputDecoration(labelText: 'State'),
              ),
              const SizedBox(height: 12),

              // Birthday selector
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: _pickBirthday, child: Text(_selectedBirthday == null ? 'Select birthday' : '${_selectedBirthday!.day}/${_selectedBirthday!.month}/${_selectedBirthday!.year}'))),
              ]),
              const SizedBox(height: 8),

              // Languages selector below birthday and display selected languages
              OutlinedButton(onPressed: _selectLanguages, child: const Text('Select languages')),
              const SizedBox(height: 8),
              if (_selectedLanguages.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _selectedLanguages.map((lang) => Chip(label: Text(lang))).toList(),
                ),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              TextField(controller: _bioController, maxLines: 4, decoration: const InputDecoration(labelText: 'Bio')),
              const SizedBox(height: 12),
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              FilledButton(onPressed: _isLoading ? null : _save, child: _isLoading ? const CircularProgressIndicator() : const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}
