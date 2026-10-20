import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../data/business_catalog.dart';
import '../../../data/michoacan_municipalities.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/municipal_event_provider.dart';
import '../../widgets/municipal_events_carousel.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  String municipality = regionMunicipalities.first;
  bool isLoading = true;
  bool showHiddenEvents = false;
  String? loadError;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadEvents);
  }

  Future<void> _loadEvents() async {
    setState(() {
      isLoading = true;
      loadError = null;
    });
    try {
      await context.read<MunicipalEventProvider>().loadMunicipality(
        municipality,
        includeHidden: showHiddenEvents,
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() => loadError = error.message ?? 'No se pudieron cargar.');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _addMunicipality() async {
    final catalog = context.read<CatalogProvider>();
    final available = catalog.municipalities;
    final candidates = michoacanMunicipalities
        .where((name) => !available.contains(name))
        .toList();
    if (candidates.isEmpty) {
      _showMessage('Todos los municipios ya están disponibles.');
      return;
    }
    var selected = candidates.first;
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agregar municipio'),
          content: DropdownButtonFormField<String>(
            initialValue: selected,
            items: candidates
                .map((city) => DropdownMenuItem(value: city, child: Text(city)))
                .toList(),
            onChanged: (value) {
              if (value != null) setDialogState(() => selected = value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, selected),
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
    if (name == null || !mounted) return;
    try {
      await catalog.addMunicipality(name);
      setState(() {
        municipality = name;
        isLoading = true;
      });
      await _loadEvents();
    } on FirebaseException catch (error) {
      _showMessage(error.message ?? 'No se pudo agregar el municipio.');
    } on ArgumentError catch (error) {
      _showMessage(error.message.toString());
    }
  }

  Future<void> _editEvent([MunicipalEvent? event]) async {
    final eventProvider = context.read<MunicipalEventProvider>();
    final titleController = TextEditingController(text: event?.title ?? '');
    final dateController = TextEditingController(text: event?.date ?? '');
    final descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    final sourceController = TextEditingController(
      text: event?.sourceUrl ?? '',
    );
    final picker = ImagePicker();
    File? imageFile;
    var iconName = _iconNameFor(event?.icon);

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(event == null ? 'Nuevo evento' : 'Editar evento'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Evento'),
                ),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Fecha o temporada',
                  ),
                ),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Información'),
                ),
                TextField(
                  controller: sourceController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Enlace de información (opcional)',
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: iconName,
                  decoration: const InputDecoration(labelText: 'Icono'),
                  items: const [
                    DropdownMenuItem(value: 'event', child: Text('Evento')),
                    DropdownMenuItem(
                      value: 'festival',
                      child: Text('Festival'),
                    ),
                    DropdownMenuItem(
                      value: 'celebration',
                      child: Text('Celebración'),
                    ),
                    DropdownMenuItem(value: 'church', child: Text('Religioso')),
                    DropdownMenuItem(value: 'eco', child: Text('Naturaleza')),
                    DropdownMenuItem(value: 'music', child: Text('Música')),
                    DropdownMenuItem(value: 'sports', child: Text('Deportivo')),
                    DropdownMenuItem(value: 'culture', child: Text('Cultura')),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialogState(() => iconName = value);
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final image = await picker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                      maxWidth: 1600,
                    );
                    if (image != null) {
                      setDialogState(() => imageFile = File(image.path));
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: Text(
                    imageFile == null ? 'Elegir imagen' : 'Cambiar imagen',
                  ),
                ),
                if (imageFile != null)
                  Image.file(imageFile!, height: 110, fit: BoxFit.cover)
                else if ((event?.imageUrl ?? '').isNotEmpty)
                  Image.network(
                    event!.imageUrl!,
                    height: 110,
                    fit: BoxFit.cover,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && mounted) {
      if (titleController.text.trim().isEmpty ||
          dateController.text.trim().isEmpty ||
          descriptionController.text.trim().isEmpty) {
        _showMessage('Completa nombre, fecha e información.');
      } else {
        try {
          await eventProvider.saveEvent(
            municipality: municipality,
            eventId: event?.id,
            title: titleController.text,
            date: dateController.text,
            description: descriptionController.text,
            sourceUrl: sourceController.text,
            iconName: iconName,
            imageFile: imageFile,
            currentImageUrl: event?.imageUrl,
          );
        } on FirebaseException catch (error) {
          _showMessage(error.message ?? 'No se pudo guardar el evento.');
        }
      }
    }

    titleController.dispose();
    dateController.dispose();
    descriptionController.dispose();
    sourceController.dispose();
  }

  Future<void> _hideEvent(MunicipalEvent event) async {
    final eventProvider = context.read<MunicipalEventProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ocultar evento'),
        content: Text('¿Quieres quitar "${event.title}" del carrusel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ocultar'),
          ),
        ],
      ),
    );
    if (confirmed != true || event.id == null || !mounted) return;
    try {
      await eventProvider.hideEvent(
        municipality: municipality,
        eventId: event.id!,
      );
    } on FirebaseException catch (error) {
      _showMessage(error.message ?? 'No se pudo ocultar el evento.');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _iconNameFor(IconData? icon) {
    if (icon == Icons.festival) return 'festival';
    if (icon == Icons.celebration) return 'celebration';
    if (icon == Icons.church) return 'church';
    if (icon == Icons.eco) return 'eco';
    if (icon == Icons.music_note) return 'music';
    if (icon == Icons.sports) return 'sports';
    if (icon == Icons.theater_comedy) return 'culture';
    return 'event';
  }

  @override
  Widget build(BuildContext context) {
    final events = context.watch<MunicipalEventProvider>().eventsFor(
      municipality,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: municipality,
                  decoration: const InputDecoration(
                    labelText: 'Municipio del carrusel',
                    border: OutlineInputBorder(),
                  ),
                  items: context
                      .watch<CatalogProvider>()
                      .municipalities
                      .map(
                        (city) =>
                            DropdownMenuItem(value: city, child: Text(city)),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      municipality = value;
                      isLoading = true;
                    });
                    _loadEvents();
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Agregar evento',
                onPressed: () => _editEvent(),
                icon: const Icon(Icons.add),
              ),
              IconButton(
                tooltip: 'Agregar municipio de Michoacán',
                onPressed: _addMunicipality,
                icon: const Icon(Icons.add_location_alt),
              ),
            ],
          ),
        ),
        SwitchListTile(
          title: const Text('Mostrar eventos ocultos'),
          value: showHiddenEvents,
          onChanged: (value) {
            setState(() => showHiddenEvents = value);
            _loadEvents();
          },
        ),
        if (loadError != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(loadError!, style: const TextStyle(color: Colors.red)),
          ),
        if (isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (events.isEmpty)
          const Expanded(child: Center(child: Text('No hay eventos')))
        else
          Expanded(
            child: ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: event.imageUrl == null || event.imageUrl!.isEmpty
                        ? Icon(event.icon)
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              event.imageUrl!,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                            ),
                          ),
                    title: Text(event.title),
                    subtitle: Text('${event.date}\n${event.description}'),
                    isThreeLine: true,
                    trailing: Wrap(
                      children: [
                        IconButton(
                          tooltip: 'Editar',
                          onPressed: () => _editEvent(event),
                          icon: const Icon(Icons.edit),
                        ),
                        IconButton(
                          tooltip: event.isActive ? 'Ocultar' : 'Restaurar',
                          onPressed: event.isActive
                              ? () => _hideEvent(event)
                              : () => _editEvent(event),
                          icon: Icon(
                            event.isActive
                                ? Icons.visibility_off
                                : Icons.restore,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
