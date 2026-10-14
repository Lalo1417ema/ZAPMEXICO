import 'package:flutter/material.dart';

class ReviewDialog extends StatefulWidget {
  const ReviewDialog({super.key});

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  double rating = 5;

  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva reseña'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Califica este negocio',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),
          Slider(
            min: 1,
            max: 5,
            divisions: 4,
            value: rating,
            label: rating.toString(),
            onChanged: (value) {
              setState(() {
                rating = value;
              });
            },
          ),
          Text(
            '${rating.toInt()} de 5 estrellas',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),

          TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Escribe tu opinión'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'rating': rating,
              'comment': controller.text,
            });
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
