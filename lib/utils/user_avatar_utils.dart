import 'dart:convert';

import 'package:flutter/material.dart';

class UserAvatarUtils {
  UserAvatarUtils._();

  static ImageProvider? profileImage(String? data) {
    if (data == null || data.isEmpty) return null;

    if (data.startsWith('data:')) {
      try {
        final base64Data = data.contains(',') ? data.split(',').last : data;
        return MemoryImage(base64Decode(base64Data));
      } catch (_) {
        return null;
      }
    }

    return NetworkImage(data);
  }

  static String roleLabel(String? role) {
    switch (role) {
      case 'student':
        return 'Étudiant';
      case 'teacher':
        return 'Professeur';
      case 'admin':
        return 'Administrateur';
      default:
        return 'Utilisateur';
    }
  }

  static IconData roleIcon(String? role) {
    switch (role) {
      case 'student':
        return Icons.school_outlined;
      case 'teacher':
        return Icons.person_outline;
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.person_outline;
    }
  }
}
