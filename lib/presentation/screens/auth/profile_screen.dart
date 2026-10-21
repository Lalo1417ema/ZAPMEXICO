import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/registration_required_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _imagePicker = ImagePicker();
  File? _selectedImage;
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final profile = context.read<AuthProvider>().currentUserModel;
    _nameController.text = profile?['name']?.toString() ?? '';
    _usernameController.text = profile?['username']?.toString() ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _selectPhoto() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (image == null || !mounted) return;
      setState(() => _selectedImage = File(image.path));
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'No se pudo seleccionar la foto.'),
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await context.read<AuthProvider>().updateProfile(
        name: _nameController.text,
        username: _usernameController.text,
        profileImage: _selectedImage,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente.')),
      );
      Navigator.pop(context);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'No se pudo guardar el perfil.'),
        ),
      );
    } on ArgumentError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message.toString())));
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isVisitor) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi perfil')),
        body: Center(
          child: FilledButton(
            onPressed: () => showRegistrationRequiredDialog(context),
            child: const Text('Regístrate para personalizar tu perfil'),
          ),
        ),
      );
    }
    final profile = auth.currentUserModel;
    final photoUrl = profile?['photoUrl']?.toString() ?? '';
    ImageProvider<Object>? avatarImage;
    if (_selectedImage != null) {
      avatarImage = FileImage(_selectedImage!);
    } else if (photoUrl.isNotEmpty) {
      avatarImage = NetworkImage(photoUrl);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 58,
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? const Icon(Icons.person, size: 64)
                      : null,
                ),
                IconButton.filled(
                  tooltip: 'Cambiar foto',
                  onPressed: _selectPhoto,
                  icon: const Icon(Icons.camera_alt),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          CustomTextField(
            hint: 'NOMBRE',
            icon: Icons.person,
            controller: _nameController,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            hint: 'USUARIO',
            icon: Icons.alternate_email,
            controller: _usernameController,
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: profile?['email']?.toString() ?? '',
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Correo electrónico',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 28),
          CustomButton(
            text: 'GUARDAR PERFIL',
            isLoading: _isSaving,
            onPressed: _saveProfile,
          ),
        ],
      ),
    );
  }
}
