import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
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
  String? _selectedMunicipality;
  bool _initialized = false;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final profile = context.read<AuthProvider>().currentUserModel;
    final municipalities = context.read<CatalogProvider>().municipalities;
    _nameController.text = profile?['name']?.toString() ?? '';
    _usernameController.text = profile?['username']?.toString() ?? '';
    final city = profile?['city']?.toString();
    if (municipalities.contains(city)) _selectedMunicipality = city;
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
        municipality: _selectedMunicipality,
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

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
          'Se eliminarán permanentemente tu cuenta y perfil, tus favoritos, '
          'notificaciones, negocios y publicaciones de Marketplace, así como '
          'sus imágenes. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar cuenta'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      final messenger = ScaffoldMessenger.of(context);
      await context.read<AuthProvider>().deleteAccount();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tu cuenta y sus datos fueron eliminados.'),
        ),
      );
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'No se pudo eliminar la cuenta.'),
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'No se pudo eliminar la cuenta.'),
        ),
      );
    } on StateError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _openPrivacyPolicy() async {
    try {
      final opened = await launchUrl(
        Uri.parse('https://zap2026-382a1.web.app/privacy-policy.html'),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir la política de privacidad.'),
          ),
        );
      }
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? 'No se pudo abrir la política de privacidad.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isVisitor) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mi perfil')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton(
                onPressed: () => showRegistrationRequiredDialog(context),
                child: const Text('Regístrate para personalizar tu perfil'),
              ),
              TextButton(
                onPressed: _openPrivacyPolicy,
                child: const Text('Política de privacidad'),
              ),
            ],
          ),
        ),
      );
    }
    final profile = auth.currentUserModel;
    final municipalities = context.watch<CatalogProvider>().municipalities;
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
                InkWell(
                  onTap: _isSaving ? null : _selectPhoto,
                  customBorder: const CircleBorder(),
                  child: CircleAvatar(
                    radius: 58,
                    backgroundImage: avatarImage,
                    child: avatarImage == null
                        ? const Icon(Icons.person, size: 64)
                        : null,
                  ),
                ),
                IconButton.filled(
                  tooltip: 'Cambiar foto',
                  onPressed: _isSaving ? null : _selectPhoto,
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
          DropdownButtonFormField<String>(
            initialValue: municipalities.contains(_selectedMunicipality)
                ? _selectedMunicipality
                : null,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Municipio de origen',
              prefixIcon: Icon(Icons.location_on),
              border: OutlineInputBorder(),
            ),
            hint: const Text('Selecciona tu municipio'),
            items: municipalities
                .map(
                  (municipality) => DropdownMenuItem(
                    value: municipality,
                    child: Text(municipality, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: _isSaving
                ? null
                : (municipality) {
                    setState(() => _selectedMunicipality = municipality);
                  },
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
            isLoading: _isSaving || _isDeleting,
            onPressed: _saveProfile,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _isSaving || _isDeleting ? null : _deleteAccount,
            icon: _isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_forever_outlined),
            label: Text(
              _isDeleting ? 'ELIMINANDO CUENTA...' : 'ELIMINAR CUENTA',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _openPrivacyPolicy,
            child: const Text('Política de privacidad'),
          ),
        ],
      ),
    );
  }
}
