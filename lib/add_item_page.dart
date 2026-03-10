import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'marketplace_page.dart';
import 'auth_page.dart';
import 'utils/user_prefill_helper.dart';
import 'services/security_service.dart';
import 'services/verification_service.dart';

class AddItemPage extends StatefulWidget {
  final MarketplaceItem? initialItem;

  const AddItemPage({super.key, this.initialItem});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _sellerNameController = TextEditingController();
  final _sellerPhoneController = TextEditingController();
  final _sellerEmailController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _securityService = SecurityService();
  
  String _selectedCategory = 'Electronics';
  String _selectedCondition = 'Good';
  String _selectedLocation = 'Sydney';
  List<String> _images = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    final initial = widget.initialItem;
    if (initial != null) {
      _titleController.text = initial.title;
      _descriptionController.text = initial.description;
      _priceController.text = initial.price.toStringAsFixed(0);
      _selectedCategory = initial.category;
      _selectedCondition = initial.condition;
      _selectedLocation = initial.location;
      _images = List<String>.from(initial.images);
      _sellerNameController.text = initial.sellerName;
      _sellerPhoneController.text = initial.sellerPhone ?? '';
      _sellerEmailController.text = AuthState.currentUserEmail ?? '';
    }
    // Best-effort: prefill seller contact fields from signed-in user
    populateContactControllers(
      nameController: _sellerNameController,
      phoneController: _sellerPhoneController,
      emailController: _sellerEmailController,
    );
  }

  final List<String> _categories = [
    'Electronics',
    'Furniture',
    'Vehicles',
    'Clothing',
    'Books',
    'Sports',
    'Home & Garden',
    'Toys & Games',
    'Other',
  ];

  final List<String> _conditions = [
    'New',
    'Like New',
    'Good',
    'Fair',
    'For Parts',
  ];

  final List<String> _locations = [
    'Sydney',
    'Melbourne',
    'Brisbane',
    'Perth',
    'Adelaide',
    'Canberra',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _sellerNameController.dispose();
    _sellerPhoneController.dispose();
    _sellerEmailController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxHeight: 1024,
        maxWidth: 1024,
        imageQuality: 80,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          final incoming = images.map((e) => e.path).toList();
          final remaining = 5 - _images.length;
          if (remaining > 0) {
            _images = [..._images, ...incoming.take(remaining)];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to pick images'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  static bool _isRemoteUrl(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  static bool _looksLikeLocalFilePath(String value) {
    if (value.isEmpty) return false;
    if (_isRemoteUrl(value)) return false;
    if (value.startsWith('assets/')) return false;
    return true;
  }

  Future<List<String>> _uploadImagesIfNeeded({
    required String itemId,
    required List<String> images,
  }) async {
    final storage = FirebaseStorage.instance;
    final result = <String>[];

    for (var i = 0; i < images.length; i++) {
      final pathOrUrl = images[i];
      if (_looksLikeLocalFilePath(pathOrUrl)) {
        try {
          final file = File(pathOrUrl);
          final ref = storage.ref().child('marketplace_items/$itemId/images/$i');
          await ref.putFile(file);
          final url = await ref.getDownloadURL();
          result.add(url);
          continue;
        } catch (_) {
          // Fall back to original value if upload fails.
        }
      }
      result.add(pathOrUrl);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initialItem != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Item' : 'Sell an Item'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Image Upload Card (matches other post pages)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Images (optional)',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    if (_images.isNotEmpty) ...[
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _images.length + 1,
                        itemBuilder: (context, idx) {
                          if (idx == _images.length) {
                            return InkWell(
                              onTap: _images.length < 5 ? _pickImages : null,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _images.length < 5
                                        ? theme.colorScheme.primary
                                        : Colors.grey.withValues(alpha: 0.3),
                                    width: 2,
                                    style: BorderStyle.solid,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 28,
                                      color: _images.length < 5
                                          ? theme.colorScheme.primary
                                          : Colors.grey.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_images.length}/5',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: _images.length < 5
                                            ? theme.colorScheme.primary
                                            : Colors.grey.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          final value = _images[idx];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _isRemoteUrl(value)
                                    ? Image.network(
                                        value,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder: (context, error, stack) {
                                          return Container(
                                            color: theme.colorScheme.primaryContainer,
                                            child: const Center(
                                              child: Icon(Icons.image_not_supported_outlined),
                                            ),
                                          );
                                        },
                                      )
                                    : Image.file(
                                        File(value),
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder: (context, error, stack) {
                                          return Container(
                                            color: theme.colorScheme.primaryContainer,
                                            child: const Center(
                                              child: Icon(Icons.image_not_supported_outlined),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(idx),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${_images.length} photo${_images.length != 1 ? 's' : ''} added',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ] else ...[
                      OutlinedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Add photo'),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tip: Add a photo to help sell your item faster.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Title Field
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                hintText: 'What are you selling?',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'[<>`"]')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                if (value.length < 3) {
                  return 'Title must be at least 3 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Description Field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Provide details about your item',
                alignLabelWithHint: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'[<>`"]')),
              ],
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                if (value.length < 10) {
                  return 'Description must be at least 10 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Price Field
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price (AUD) *',
                hintText: '0',
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a price';
                }
                final price = int.tryParse(value);
                if (price == null || price <= 0) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category *',
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Condition Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedCondition,
              decoration: const InputDecoration(
                labelText: 'Condition *',
              ),
              items: _conditions.map((condition) {
                return DropdownMenuItem(
                  value: condition,
                  child: Text(condition),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCondition = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Location Dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedLocation,
              decoration: const InputDecoration(
                labelText: 'Location *',
              ),
              items: _locations.map((location) {
                return DropdownMenuItem(
                  value: location,
                  child: Text(location),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLocation = value!;
                });
              },
            ),

            const SizedBox(height: 32),
            // Seller contact fields (prefilled from user when signed in)
            TextFormField(
              controller: _sellerNameController,
              decoration: const InputDecoration(labelText: 'Your name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sellerPhoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sellerEmailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Submit Button (full width)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _submitForm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(isEditing ? 'Update Item' : 'List Item'),
                ),
              ),
            ),

            const SizedBox(height: 12),

            const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // ignore: use_build_context_synchronously
      final messenger = ScaffoldMessenger.of(context);
      final current = AuthState.currentUserId ?? 'guest';
      final allowed = await VerificationService.canPost(current);
      if (!allowed) {
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        messenger.showSnackBar(
          const SnackBar(content: Text('Only verified contributors may list marketplace items.')),
        );
        return;
      }
      final isEditing = widget.initialItem != null;

      // Photos are optional (items can be listed without any images).

      // Sanitize user input to prevent injection
      final sanitizedTitle = _securityService.sanitizeInput(
        _titleController.text,
        maxLength: 120,
      );
      final sanitizedDescription = _securityService.sanitizeInput(
        _descriptionController.text,
        maxLength: 2000,
      );

      // Block prohibited content (scam/spam indicators)
      if (_securityService.containsProhibitedContent(
        '$sanitizedTitle $sanitizedDescription',
      )) {
        // ignore: use_build_context_synchronously
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Your listing contains prohibited content. Please remove it.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      setState(() {
        _isSubmitting = true;
      });

      try {
        final itemsCollection =
            FirebaseFirestore.instance.collection('marketplace_items');
        final now = DateTime.now();

          if (isEditing) {
          final docRef = itemsCollection.doc(widget.initialItem!.id);
          final uploaded = await _uploadImagesIfNeeded(
            itemId: widget.initialItem!.id,
            images: _images,
          );

            await docRef.update({
              'title': sanitizedTitle,
              'description': sanitizedDescription,
              'price': double.parse(_priceController.text),
              'category': _selectedCategory,
              'condition': _selectedCondition,
              'location': _selectedLocation,
              'images': uploaded,
              'sellerName': _sellerNameController.text.trim(),
              'sellerPhone': _sellerPhoneController.text.trim(),
              'sellerEmail': _sellerEmailController.text.trim(),
            });

          if (mounted) {
            // ignore: use_build_context_synchronously
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Item updated successfully!'),
                duration: Duration(seconds: 2),
              ),
            );
            Navigator.pop(context);
          }
        } else {
          final docRef = itemsCollection.doc();
          await docRef.set({
            'title': sanitizedTitle,
            'description': sanitizedDescription,
            'price': double.parse(_priceController.text),
            'category': _selectedCategory,
            'condition': _selectedCondition,
            'location': _selectedLocation,
            'sellerId': AuthState.currentUserId ?? 'guest',
            'sellerName': _sellerNameController.text.trim().isEmpty ? (AuthState.currentUserName ?? 'Guest User') : _sellerNameController.text.trim(),
            'sellerPhone': _sellerPhoneController.text.trim().isEmpty ? null : _sellerPhoneController.text.trim(),
            'sellerEmail': _sellerEmailController.text.trim().isEmpty ? AuthState.currentUserEmail : _sellerEmailController.text.trim(),
            'postedDate': Timestamp.fromDate(now),
            'images': <String>[],
            'viewCount': 0,
            'isClosed': false,
          });

          final uploaded = await _uploadImagesIfNeeded(
            itemId: docRef.id,
            images: _images,
          );
          await docRef.update({'images': uploaded});

          if (mounted) {
            // ignore: use_build_context_synchronously
            messenger.showSnackBar(
              const SnackBar(
                content: Text('Item listed successfully!'),
                duration: Duration(seconds: 2),
              ),
            );
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          // ignore: use_build_context_synchronously
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Failed to save listing. Please try again.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }
}
