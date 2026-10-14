import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:typed_data';

import '../../../config/routes/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/business_catalog.dart';
import '../../../data/municipal_events.dart';
import '../../widgets/custom_drawer.dart';
import '../../providers/business_provider.dart';
import '../../widgets/business_card.dart';
import '../../widgets/municipal_events_carousel.dart';

class MunicipalityBusinessesScreen extends StatefulWidget {
  final String? municipality;
  final String visitorName;

  const MunicipalityBusinessesScreen({
    super.key,
    this.municipality,
    this.visitorName = '',
  });

  @override
  State<MunicipalityBusinessesScreen> createState() =>
      _MunicipalityBusinessesScreenState();
}

class _MunicipalityBusinessesScreenState
    extends State<MunicipalityBusinessesScreen> {
  final searchController = TextEditingController();
  String selectedCategory = 'Todos';

  @override
  void initState() {
    super.initState();
    searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final municipality =
        widget.municipality ??
        (arguments is Map
            ? arguments['municipality'] as String?
            : arguments as String?);
    final visitorName = widget.municipality != null
        ? widget.visitorName
        : arguments is Map
        ? (arguments['visitorName'] ?? '').toString()
        : '';
    if (municipality == null || !regionMunicipalities.contains(municipality)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Municipio')),
        body: const Center(
          child: Text('No se seleccionó un municipio válido.'),
        ),
      );
    }

    final municipalBusinesses = context
        .watch<BusinessProvider>()
        .businesses
        .where((business) => business['city'] == municipality);
    final query = searchController.text.trim().toLowerCase();
    final businesses = municipalBusinesses.where((business) {
      final matchesCategory =
          selectedCategory == 'Todos' ||
          business['category'] == selectedCategory;
      final matchesSearch =
          query.isEmpty ||
          (business['name'] ?? '').toString().toLowerCase().contains(query) ||
          (business['description'] ?? '').toString().toLowerCase().contains(
            query,
          );
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(municipality),
            if (visitorName.isNotEmpty)
              Text(
                'Hola, $visitorName',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Elegir otro municipio',
            icon: const Icon(Icons.location_city),
            onPressed: () => _showMunicipalityPicker(context, visitorName),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                controller: searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Buscar en $municipality...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.primary,
                  ),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          tooltip: 'Limpiar búsqueda',
                          icon: const Icon(Icons.clear),
                          onPressed: searchController.clear,
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 45,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: ['Todos', ...businessCategories].map((category) {
                  final isSelected = selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.greyText,
                      ),
                      onSelected: (_) {
                        setState(() => selectedCategory = category);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: MunicipalEventsCarousel(
              municipality: municipality,
              events: municipalEvents[municipality] ?? const [],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
          if (businesses.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No se encontraron negocios con estos filtros.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.greyText),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final business = businesses[index];
                  return BusinessCard(
                    title: (business['name'] ?? 'Negocio').toString(),
                    description: (business['description'] ?? '').toString(),
                    imageUrl: (business['logoUrl'] ?? '').toString(),
                    imageBytes: business['logoBytes'] is Uint8List
                        ? business['logoBytes'] as Uint8List
                        : null,
                    imageIsIllustrative:
                        business['imageIsIllustrative'] == true,
                    rating: ((business['rating'] ?? 0) as num).toDouble(),
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.businessDetail,
                      arguments: business,
                    ),
                  );
                }, childCount: businesses.length),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showMunicipalityPicker(
    BuildContext context,
    String visitorName,
  ) async {
    final municipality = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(
              title: Text(
                'Elige otro municipio',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...regionMunicipalities.map(
              (municipality) => ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(municipality),
                onTap: () => Navigator.pop(context, municipality),
              ),
            ),
          ],
        ),
      ),
    );

    if (municipality == null || !context.mounted) return;
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.municipalityBusinesses,
      arguments: {'municipality': municipality, 'visitorName': visitorName},
    );
  }
}
