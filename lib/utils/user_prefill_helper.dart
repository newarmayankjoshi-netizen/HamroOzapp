import 'package:flutter/widgets.dart';
import '../auth_page.dart';

/// Populate provided controllers with the current user's name, phone and email
/// if available. This is best-effort and will not throw on failure.
void populateContactControllers({
  TextEditingController? nameController,
  TextEditingController? phoneController,
  TextEditingController? emailController,
}) {
  try {
    final name = AuthState.currentUserName;
    final email = AuthState.currentUserEmail;
    String? phone;
    final userId = AuthState.currentUserId;
    if (userId != null) {
      final user = AuthService.getUserById(userId);
      phone = user?.phone;
    }

    if (nameController != null && name != null && name.isNotEmpty) {
      nameController.text = name;
    }
    if (emailController != null && email != null && email.isNotEmpty) {
      emailController.text = email;
    }
    if (phoneController != null && phone != null && phone.isNotEmpty) {
      phoneController.text = phone;
    }
  } catch (_) {
    // best-effort: ignore failures
  }
}
