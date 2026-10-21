import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/marketplace_provider.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/registration_required_dialog.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  Future<void> _openCreateForm(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (auth.isVisitor || !auth.isLoggedIn) {
      showRegistrationRequiredDialog(context);
      return;
    }

    final profile = auth.currentUserModel;
    final sellerName = profile?['name']?.toString().trim() ?? '';
    final municipality = profile?['city']?.toString().trim() ?? '';
    if (municipality.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega tu municipio en Mi perfil antes de publicar.'),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _CreateProductSheet(
        sellerName: sellerName,
        municipality: municipality,
      ),
    );
  }

  Future<void> _deleteProduct(
    BuildContext context,
    MarketplaceProduct product,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar publicación'),
        content: Text('¿Quieres eliminar "${product.name}" y sus fotos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !context.mounted) return;

    try {
      await context.read<MarketplaceProvider>().deleteProduct(product);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Publicación eliminada.')));
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'No se pudo eliminar la publicación.'),
        ),
      );
    } on StateError catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final marketplace = context.watch<MarketplaceProvider>();
    final currentUserId = marketplace.currentUserId;

    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(title: const Text('Marketplace')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Publicar'),
      ),
      body: marketplace.isLoading
          ? const Center(child: CircularProgressIndicator())
          : marketplace.errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  marketplace.errorMessage!,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : marketplace.products.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aún no hay productos publicados. ¡Sé la primera persona en compartir uno!',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: marketplace.products.length,
              itemBuilder: (context, index) {
                final product = marketplace.products[index];
                return _ProductCard(
                  product: product,
                  isOwner: product.sellerUid == currentUserId,
                  onDelete: () => _deleteProduct(context, product),
                );
              },
            ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final MarketplaceProduct product;
  final bool isOwner;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.isOwner,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final localDate = product.createdAt.toLocal();
    final time = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(localDate));

    return Card(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProductPhotoCarousel(urls: product.photoUrls),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    if (isOwner)
                      IconButton(
                        tooltip: 'Eliminar publicación',
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                      ),
                  ],
                ),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (product.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(product.description),
                ],
                const SizedBox(height: 10),
                Text('Vende ${product.sellerName} · ${product.municipality}'),
                const SizedBox(height: 4),
                Text(
                  'Publicado ${localDate.day}/${localDate.month}/${localDate.year} a las $time',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.greyText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductPhotoCarousel extends StatefulWidget {
  final List<String> urls;

  const _ProductPhotoCarousel({required this.urls});

  @override
  State<_ProductPhotoCarousel> createState() => _ProductPhotoCarouselState();
}

class _ProductPhotoCarouselState extends State<_ProductPhotoCarousel> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.urls.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Icon(Icons.image_not_supported, size: 52)),
      );
    }
    return SizedBox(
      height: 240,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            itemCount: widget.urls.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) => Image.network(
              widget.urls[index],
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Center(
                child: Icon(Icons.broken_image_outlined, size: 52),
              ),
            ),
          ),
          if (widget.urls.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.urls.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentPage
                          ? AppColors.primary
                          : Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CreateProductSheet extends StatefulWidget {
  final String sellerName;
  final String municipality;

  const _CreateProductSheet({
    required this.sellerName,
    required this.municipality,
  });

  @override
  State<_CreateProductSheet> createState() => _CreateProductSheetState();
}

class _CreateProductSheetState extends State<_CreateProductSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _picker = ImagePicker();
  List<XFile> _images = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectPhotos() async {
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1600,
        limit: 3,
      );
      if (!mounted || images.isEmpty) return;
      setState(() => _images = images.take(3).toList());
    } on PlatformException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'No se pudieron seleccionar fotos.'),
        ),
      );
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    if (name.isEmpty || price == null || price <= 0 || _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa el producto, un precio válido y al menos una foto.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await context.read<MarketplaceProvider>().createProduct(
        name: name,
        description: _descriptionController.text,
        price: price,
        sellerName: widget.sellerName,
        municipality: widget.municipality,
        images: _images,
      );
      if (mounted) Navigator.pop(context);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'No se pudo publicar el producto.'),
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Publicar producto',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre del producto',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Precio',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('Ubicación del perfil'),
              subtitle: Text(widget.municipality),
            ),
            OutlinedButton.icon(
              onPressed: _isSaving ? null : _selectPhotos,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text('Elegir fotos (${_images.length}/3)'),
            ),
            if (_images.isNotEmpty)
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => FutureBuilder(
                    future: _images[index].readAsBytes(),
                    builder: (context, snapshot) => snapshot.hasData
                        ? Image.memory(
                            snapshot.data!,
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                          )
                        : const SizedBox(
                            width: 88,
                            height: 88,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Publicar'),
            ),
          ],
        ),
      ),
    );
  }
}
