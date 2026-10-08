import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'premium_bottom_sheet.dart';

class EditNameEmailBottomSheet extends ConsumerStatefulWidget {
  final User user;

  const EditNameEmailBottomSheet({super.key, required this.user});

  @override
  ConsumerState<EditNameEmailBottomSheet> createState() => EditNameEmailBottomSheetState();
}

class EditNameEmailBottomSheetState extends ConsumerState<EditNameEmailBottomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
    _emailController = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _save() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name cannot be empty', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
      return;
    }
    
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email cannot be empty', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
      return;
    }
    
    setState(() => _isLoading = true);
    
    final data = {
      'full_name': name,
      'email': email,
    };
    
    final success = await ref.read(authProvider.notifier).updateProfileDetails(data);
    
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.success));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update profile', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBottomSheetLayout(
      title: 'Edit Profile Details',
      buttonText: _isLoading ? 'Saving...' : 'Save Changes',
      onButtonPressed: _save,
      isButtonEnabled: !_isLoading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Full Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            style: const TextStyle(color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderDark)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderDark)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBrand)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text('Email Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderDark)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderDark)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBrand)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
