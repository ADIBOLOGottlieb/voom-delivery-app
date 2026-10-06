import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/delivery.dart';
import '../../models/product.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/delivery_service.dart';
import '../../utils/colors.dart';
import '../../utils/formatters.dart';

/// Paiement par mobile money (Flooz / Mixx by Yas) vers le compte marchand de l'agence,
/// puis envoi de la capture d'écran de la transaction pour vérification par l'admin.
class PaymentScreen extends StatefulWidget {
  final Delivery delivery;

  const PaymentScreen({super.key, required this.delivery});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _refController = TextEditingController();
  late final _phoneController = TextEditingController(text: context.read<AuthService>().user?.phoneNumber);

  late Future<PaymentInfo> _info;
  String? _method;
  XFile? _screenshot;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _info = context.read<DeliveryService>().paymentInfo();
  }

  @override
  void dispose() {
    _refController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (file != null) setState(() => _screenshot = file);
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    void error(String msg) =>
        messenger.showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));

    if (_method == null) return error('Choisissez Flooz ou Mixx by Yas.');
    if (!_formKey.currentState!.validate()) return;
    if (_screenshot == null) return error("Ajoutez la capture d'écran de la transaction.");

    setState(() => _sending = true);
    try {
      final updated = await context.read<DeliveryService>().submitPayment(
            deliveryId: widget.delivery.id,
            method: _method!,
            transactionRef: _refController.text.trim(),
            payerPhone: _phoneController.text.trim(),
            screenshotPath: _screenshot!.path,
          );
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(
        content: Text("Preuve envoyée. Vous serez informé dès que l'agence l'aura vérifiée."),
        backgroundColor: AppColors.success,
      ));
      Navigator.of(context).pop(updated);
    } on ApiException catch (e) {
      error(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.delivery.totalAmount;

    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: FutureBuilder<PaymentInfo>(
        future: _info,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString(), style: const TextStyle(color: AppColors.error)));
          }
          final info = snapshot.data!;
          if (info.methods.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "Le paiement mobile n'est pas encore configuré par l'agence. Contactez VOOM Delivery.",
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final selected = info.methods.where((m) => m.method == _method).firstOrNull;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      const Text('Montant à payer', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 4),
                      Text(
                        formatFcfa(amount),
                        style: const TextStyle(color: AppColors.primary, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Livraison ${widget.delivery.reference}', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('1. Choisissez votre moyen de paiement', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final m in info.methods)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: SizedBox(width: double.infinity, child: Text(m.label, textAlign: TextAlign.center)),
                            selected: _method == m.method,
                            selectedColor: AppColors.primary,
                            onSelected: (_) => setState(() => _method = m.method),
                          ),
                        ),
                      ),
                  ],
                ),
                if (selected != null) ...[
                  const SizedBox(height: 16),
                  Text('2. Envoyez le montant au compte marchand', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      title: Text(info.merchantName),
                      subtitle: Text(
                        selected.merchantNumber,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      trailing: IconButton(
                        tooltip: 'Copier le numéro',
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: selected.merchantNumber));
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Numéro copié')));
                        },
                      ),
                    ),
                  ),
                  if (info.instructions != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(info.instructions!, style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  const SizedBox(height: 16),
                  Text('3. Envoyez la preuve de paiement', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _refController,
                    decoration: const InputDecoration(
                      labelText: 'Référence / ID de la transaction',
                      helperText: 'Indiquée dans le SMS de confirmation',
                      prefixIcon: Icon(Icons.receipt_long),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Référence requise' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Numéro ayant effectué le paiement',
                      prefixIcon: Icon(Icons.phone_android),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Numéro requis' : null,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _pickScreenshot,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(_screenshot == null ? "Ajouter la capture d'écran" : 'Changer la capture'),
                  ),
                  if (_screenshot != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(File(_screenshot!.path), height: 260, fit: BoxFit.contain),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _sending ? null : _submit,
                    child: _sending
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                        : const Text('Envoyer la preuve de paiement'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
