import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_client.dart';
import '../../services/delivery_service.dart';
import '../../utils/colors.dart';
import '../../widgets/bottom_action_bar.dart';
import '../../widgets/photos.dart';
import 'chat_screen.dart';

/// Commande express des clients habitués : photos des articles + message,
/// l'agence programme la livraison dans la discussion.
class QuickRequestScreen extends StatefulWidget {
  const QuickRequestScreen({super.key});

  static const maxPhotos = 6;

  /// Résultat renvoyé quand le client préfère le formulaire complet.
  static const useForm = 'form';

  @override
  State<QuickRequestScreen> createState() => _QuickRequestScreenState();
}

class _QuickRequestScreenState extends State<QuickRequestScreen> {
  final _message = TextEditingController();
  final _photos = <String>[];
  bool _sending = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _addPhotos() async {
    final remaining = QuickRequestScreen.maxPhotos - _photos.length;
    final camera = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text('Choisir dans la galerie (jusqu\'à $remaining)'),
              onTap: () => Navigator.pop(context, false),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (camera == null) return;

    final picked = camera
        ? await _takePhoto()
        : await pickPhotosFromGallery(limit: remaining);
    if (mounted && picked.isNotEmpty) setState(() => _photos.addAll(picked.take(remaining)));
  }

  Future<List<String>> _takePhoto() async {
    final path = await pickPhotoFromCamera();
    return path == null ? const [] : [path];
  }

  Future<void> _send() async {
    final messenger = ScaffoldMessenger.of(context);
    final text = _message.text.trim();
    if (_photos.isEmpty && text.isEmpty) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Ajoutez au moins une photo de vos articles.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    setState(() => _sending = true);
    try {
      final request = await context.read<DeliveryService>().createChatRequest(photoPaths: _photos, message: text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ChatScreen(requestId: request.id, initial: request)),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Envoi rapide')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt_rounded, color: AppColors.primary, size: 36),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Envoyez les photos de vos articles. L\'agence vous répond dans la discussion et programme la livraison.',
                    style: TextStyle(color: Colors.white, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _Steps(),
          const SizedBox(height: 24),
          Text('Vos articles', style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('${_photos.length}/${QuickRequestScreen.maxPhotos} photos', style: textTheme.bodySmall),
          const SizedBox(height: 12),
          LocalPhotoGrid(
            paths: _photos,
            max: QuickRequestScreen.maxPhotos,
            onAdd: _addPhotos,
            onRemove: (i) => setState(() => _photos.removeAt(i)),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _message,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Message (facultatif)',
              hintText: 'Ex. : récupérer à ma boutique, livrer à Agoè chez Ama (90 00 00 00) avant 17 h',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).pop(QuickRequestScreen.useForm),
              icon: const Icon(Icons.edit_note),
              label: const Text('Préférer le formulaire complet'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        children: [
          ElevatedButton.icon(
            onPressed: _sending ? null : _send,
            icon: _sending ? const ButtonProgress() : const Icon(Icons.send_rounded),
            label: const Text("Envoyer à l'agence"),
          ),
        ],
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (Icons.add_a_photo_outlined, 'Photos'),
      (Icons.chat_bubble_outline, 'Discussion'),
      (Icons.payments_outlined, 'Paiement'),
      (Icons.delivery_dining, 'Livraison'),
    ];
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: i == 0 ? AppColors.primary : AppColors.surface,
                  child: Icon(steps[i].$1, size: 20, color: AppColors.secondary),
                ),
                const SizedBox(height: 6),
                Text(steps[i].$2, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (i < steps.length - 1)
            Container(width: 14, height: 2, margin: const EdgeInsets.only(bottom: 18), color: AppColors.textHint),
        ],
      ],
    );
  }
}
