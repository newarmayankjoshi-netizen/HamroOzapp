import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

import 'auth_page.dart';
import 'services/verification_service.dart';
import 'services/firebase_bootstrap.dart';

class VerifyIdentityPage extends StatefulWidget {
  const VerifyIdentityPage({super.key});

  @override
  State<VerifyIdentityPage> createState() => _VerifyIdentityPageState();
}

class _VerifyIdentityPageState extends State<VerifyIdentityPage> {
  final ImagePicker _picker = ImagePicker();
  String? _selectedType;
  XFile? _pickedFile;
  bool _isSubmitting = false;
  String? _error;
  DocumentSnapshot<Map<String, dynamic>>? _latestSubmission;
  Map<String, dynamic>? _latestData;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _latestSubListener;

  final List<Map<String, String>> _typeOptions = [
    {'value': 'passport', 'label': 'Passport'},
    {'value': 'aus_driver_license', 'label': 'Australian Driver Licence'},
    {'value': 'aus_photo_id', 'label': 'Australian Photo ID'},
    {'value': 'international_passport', 'label': 'International Passport'},
    {'value': 'immicard', 'label': 'ImmiCard'},
    {'value': 'other', 'label': 'Other'},
  ];

  Future<void> _pickImage() async {
    setState(() {
      _error = null;
    });

    try {
      final XFile? f = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 85);
      if (f != null) setState(() => _pickedFile = f);
    } catch (e) {
      setState(() => _error = 'Failed to pick image: $e');
    }
  }

  Future<void> _pickFile() async {
    setState(() {
      _error = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'svg'],
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;
      final filePath = result.files.first.path;
      if (filePath == null) return setState(() => _error = 'Selected file is not available.');

      final ext = filePath.split('.').last.toLowerCase();
      const allowed = ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'svg'];
      if (!allowed.contains(ext)) return setState(() => _error = 'Unsupported file type. Allowed: PDF, JPG, PNG, WEBP, SVG.');

      setState(() => _pickedFile = XFile(filePath));
    } catch (e) {
      setState(() => _error = 'Failed to pick file: $e');
    }
  }

  Future<void> _submit() async {
    if (_selectedType == null) return setState(() => _error = 'Please select a document type.');
    if (_pickedFile == null) return setState(() => _error = 'Please take or choose a photo of your document.');

    if (VerificationService.autoRejectTypes.contains(_selectedType)) {
      return setState(() => _error = 'This document type cannot be used for verification. Please upload a government-issued ID.');
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await FirebaseBootstrap.tryInit();
      await FirebaseBootstrap.ensureSignedIn();

      final userId = AuthState.currentUserId;
      if (userId == null) throw Exception('Not signed in');

      final latest = await VerificationService.getLatestSubmission(userId);
      final latestStatus = latest?.data()?['status'] as String?;
      if (latestStatus == 'pending') throw Exception('A submission is already pending review.');

      await VerificationService.submitDocument(userId: userId, type: _selectedType!, file: File(_pickedFile!.path));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Document submitted for verification. You will be notified when reviewed.')));
      Navigator.pop(context);
    } catch (e) {
      final msg = 'Failed to submit document: $e';
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      setState(() => _error = msg);
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hadRejected = _latestData != null && (_latestData!['status'] == 'rejected' || _latestData!['status'] == 'auto_rejected');
    return Scaffold(
      appBar: AppBar(title: const Text('Become a Contributor')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_latestSubmission != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Last submission', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Type: ${_latestData?['type'] ?? 'Unknown'}'),
                      const SizedBox(height: 4),
                      Text('Status: ${_latestData?['status'] ?? 'unknown'}'),
                      const SizedBox(height: 4),
                      if (_latestData?['createdAt'] != null) Text('Submitted: ${(_latestData!['createdAt'] as Timestamp).toDate().toLocal()}'),
                      if (_latestData?['reviewReason'] != null) ...[
                        const SizedBox(height: 8),
                        Text('Reviewer note: ${_latestData!['reviewReason']}', style: const TextStyle(color: Colors.red)),
                      ],
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Help our Nepalese community in Australia by becoming a contributor. You will be able to add jobs, events, rooms and marketplace after your document has been verified.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Choose the document type you are uploading', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                  items: _typeOptions.map((t) => DropdownMenuItem(value: t['value'], child: Text(t['label']!))).toList(),
                onChanged: (v) => setState(() => _selectedType = v),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const Text('Document photo', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (_pickedFile == null)
                Column(children: [
                  SizedBox(
                    width: double.infinity,
                    height: 88,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Take Photo'),
                      onPressed: _pickImage,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 88,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Document'),
                      onPressed: _pickFile,
                    ),
                  ),
                ])
              else
                Column(children: [
                  if (_pickedFile!.path.toLowerCase().endsWith('.pdf'))
                    ListTile(
                      leading: const Icon(Icons.picture_as_pdf, size: 48),
                      title: Text(_pickedFile!.name),
                      subtitle: const Text('PDF selected'),
                      trailing: TextButton.icon(onPressed: _pickFile, icon: const Icon(Icons.edit), label: const Text('Replace')),
                    )
                  else
                    Image.file(File(_pickedFile!.path), height: 200, fit: BoxFit.contain),
                  if (!_pickedFile!.path.toLowerCase().endsWith('.pdf'))
                    TextButton.icon(onPressed: _pickImage, icon: const Icon(Icons.edit), label: const Text('Retake')),
                ]),

              const SizedBox(height: 12),
              if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),

              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(hadRejected ? 'Re-upload' : 'Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadLatest();
    _startRealtimeListener();
  }

  @override
  void dispose() {
    _latestSubListener?.cancel();
    super.dispose();
  }

  Future<void> _loadLatest() async {
    final userId = AuthState.currentUserId;
    if (userId == null) return;
    try {
      final snap = await VerificationService.getLatestSubmission(userId);
      if (snap != null) {
        setState(() {
          _latestSubmission = snap;
          _latestData = _latestSubmission!.data();
        });
      }
    } catch (_) {}
  }

  void _startRealtimeListener() {
    final userId = AuthState.currentUserId;
    if (userId == null) return;

    final q = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('id_submissions')
        .orderBy('createdAt', descending: true)
        .limit(1);

    _latestSubListener = q.snapshots().listen((snap) {
      if (snap.docs.isEmpty) return;
      final doc = snap.docs.first;
      final data = doc.data();
      final newStatus = data['status'] as String?;

      final oldStatus = _latestData?['status'] as String?;
      if (oldStatus != null && newStatus != null && oldStatus != newStatus) {
        if (mounted) {
          final friendly = newStatus == 'approved'
              ? 'approved'
              : (newStatus == 'rejected' || newStatus == 'auto_rejected')
                  ? 'rejected'
                  : newStatus;
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification status: $friendly')));
        }
      }

      setState(() {
        _latestSubmission = doc;
        _latestData = data;
      });
    });
  }
}
