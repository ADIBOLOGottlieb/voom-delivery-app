import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../models/delivery.dart';
import '../../models/product.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/delivery_service.dart';
import '../../utils/colors.dart';
import '../../utils/formatters.dart';
import '../common/location_picker_screen.dart';

/// Formulaire de demande de livraison du point A (récupération) au point B (destination).
/// Avec [product], le point A est l'adresse du vendeur fixée par l'admin.
class NewDeliveryScreen extends StatefulWidget {
  final DeliveryType initialType;
  final Product? product;
  final int quantity;

  const NewDeliveryScreen({super.key, this.initialType = DeliveryType.colis, this.product, this.quantity = 1});

  @override
  State<NewDeliveryScreen> createState() => _NewDeliveryScreenState();
}

class _NewDeliveryScreenState extends State<NewDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickupAddress = TextEditingController();
  final _pickupName = TextEditingController();
  final _pickupPhone = TextEditingController();
  final _dropoffAddress = TextEditingController();
  final _recipientName = TextEditingController();
  final _recipientPhone = TextEditingController();
  final _description = TextEditingController();
  final _notes = TextEditingController();

  late DeliveryType _type = widget.product != null && widget.initialType == DeliveryType.programmee
      ? DeliveryType.colis
      : widget.initialType;
  LatLng? _pickup;
  LatLng? _dropoff;
  DateTime? _scheduledAt;
  DeliveryQuote? _quote;
  bool _quoting = false;
  bool _submitting = false;

  bool get _isOrder => widget.product != null;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().user;
    if (!_isOrder && user != null) {
      _pickupName.text = user.name;
      _pickupPhone.text = user.phoneNumber;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _pickupAddress, _pickupName, _pickupPhone, _dropoffAddress,
      _recipientName, _recipientPhone, _description, _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick({required bool pickup}) async {
    final result = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          title: pickup ? 'Point A · Récupération' : 'Point B · Destination',
          initial: pickup ? _pickup : (_dropoff ?? _pickup),
        ),
      ),
    );
    if (result == null) return;
    setState(() => pickup ? _pickup = result : _dropoff = result);
    _refreshQuote();
  }

  Future<void> _refreshQuote() async {
    // Pour une commande, le devis exact est calculé par le serveur à la création (adresse vendeur).
    if (_isOrder || _pickup == null || _dropoff == null) return;
    setState(() => _quoting = true);
    try {
      final quote = await context.read<DeliveryService>().quote(
            type: _type,
            pickupLat: _pickup!.latitude,
            pickupLng: _pickup!.longitude,
            dropoffLat: _dropoff!.latitude,
            dropoffLng: _dropoff!.longitude,
          );
      if (mounted) setState(() => _quote = quote);
    } on ApiException {
      if (mounted) setState(() => _quote = null);
    } finally {
      if (mounted) setState(() => _quoting = false);
    }
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      initialDate: _scheduledAt ?? now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt ?? now.add(const Duration(hours: 1))),
    );
    if (time == null) return;
    setState(() => _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    void error(String msg) =>
        messenger.showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));

    if (!_formKey.currentState!.validate()) return;
    if (!_isOrder && _pickup == null) return error('Placez le point A (récupération) sur la carte.');
    if (_dropoff == null) return error('Placez le point B (destination) sur la carte.');
    if (_type == DeliveryType.programmee && _scheduledAt == null) {
      return error("Choisissez la date et l'heure de la livraison programmée.");
    }

    String? orNull(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

    final payload = <String, dynamic>{
      'type': _type.value,
      if (_isOrder) ...{
        'product_id': widget.product!.id,
        'quantity': widget.quantity,
      } else ...{
        'pickup_address': _pickupAddress.text.trim(),
        'pickup_lat': _pickup!.latitude,
        'pickup_lng': _pickup!.longitude,
        'pickup_contact_name': orNull(_pickupName),
        'pickup_contact_phone': orNull(_pickupPhone),
      },
      'dropoff_address': _dropoffAddress.text.trim(),
      'dropoff_lat': _dropoff!.latitude,
      'dropoff_lng': _dropoff!.longitude,
      'recipient_name': _recipientName.text.trim(),
      'recipient_phone': _recipientPhone.text.trim(),
      'package_description': orNull(_description),
      'notes': orNull(_notes),
      if (_scheduledAt != null) 'scheduled_at': _scheduledAt!.toUtc().toIso8601String(),
    };

    setState(() => _submitting = true);
    try {
      final delivery = await context.read<DeliveryService>().createDelivery(payload);
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(
        content: Text('Demande créée. Effectuez le paiement pour la confirmer.'),
        backgroundColor: AppColors.success,
      ));
      Navigator.of(context).pop(delivery);
    } on ApiException catch (e) {
      error(e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final types = DeliveryType.values.where((t) => !_isOrder || t != DeliveryType.programmee);

    return Scaffold(
      appBar: AppBar(title: Text(_isOrder ? 'Commander' : 'Nouvelle livraison')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (product != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.shopping_bag, color: AppColors.primaryDark),
                  title: Text('${widget.quantity} × ${product.name}'),
                  subtitle: Text('Retrait : ${product.vendorName ?? product.pickupAddress}'),
                  trailing: Text(formatFcfa(product.price * widget.quantity),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            const SizedBox(height: 8),
            Text('Type de livraison', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final t in types)
                  ChoiceChip(
                    label: Text(t.label),
                    selected: _type == t,
                    selectedColor: AppColors.primary,
                    onSelected: (_) {
                      setState(() => _type = t);
                      _refreshQuote();
                    },
                  ),
              ],
            ),
            if (_type == DeliveryType.programmee) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickSchedule,
                icon: const Icon(Icons.event),
                label: Text(_scheduledAt == null ? 'Choisir date et heure' : formatDateTime(_scheduledAt!)),
              ),
            ],
            const SizedBox(height: 20),
            if (!_isOrder) ...[
              const _SectionTitle(letter: 'A', color: AppColors.success, title: 'Récupération du colis'),
              _MapButton(point: _pickup, onTap: () => _pick(pickup: true)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pickupAddress,
                decoration: const InputDecoration(
                  labelText: 'Adresse / repère (quartier, rue, bâtiment)',
                  prefixIcon: Icon(Icons.my_location),
                ),
                validator: _required("Indiquez l'adresse de récupération"),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pickupName,
                      decoration: const InputDecoration(labelText: 'Contact sur place'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _pickupPhone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Téléphone'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            const _SectionTitle(letter: 'B', color: AppColors.error, title: 'Destination de livraison'),
            _MapButton(point: _dropoff, onTap: () => _pick(pickup: false)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dropoffAddress,
              decoration: const InputDecoration(
                labelText: 'Adresse / repère de livraison',
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: _required("Indiquez l'adresse de livraison"),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _recipientName,
                    decoration: const InputDecoration(labelText: 'Destinataire'),
                    validator: _required('Nom requis'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _recipientPhone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Téléphone'),
                    validator: _required('Téléphone requis'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (!_isOrder)
              TextFormField(
                controller: _description,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description du colis / pli',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Instructions pour le livreur (facultatif)',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 24),
            if (!_isOrder) _QuoteBox(quote: _quote, loading: _quoting),
            if (_isOrder)
              Text(
                'Les frais de livraison seront calculés selon la distance et ajoutés au total.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text(_isOrder ? 'Valider la commande' : 'Créer la demande'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static FormFieldValidator<String> _required(String message) =>
      (v) => (v == null || v.trim().isEmpty) ? message : null;
}

class _SectionTitle extends StatelessWidget {
  final String letter;
  final Color color;
  final String title;

  const _SectionTitle({required this.letter, required this.color, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: color,
            child: Text(letter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final LatLng? point;
  final VoidCallback onTap;

  const _MapButton({required this.point, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final picked = point != null;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(picked ? Icons.check_circle : Icons.map_outlined, color: picked ? AppColors.success : null),
      label: Text(
        picked
            ? 'Position choisie (${point!.latitude.toStringAsFixed(5)}, ${point!.longitude.toStringAsFixed(5)})'
            : 'Choisir sur la carte',
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _QuoteBox extends StatelessWidget {
  final DeliveryQuote? quote;
  final bool loading;

  const _QuoteBox({required this.quote, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : quote == null
              ? const Text('Placez les points A et B pour voir le prix estimé.')
              : Row(
                  children: [
                    Expanded(child: Text('Distance estimée : ${formatKm(quote!.distanceKm)}')),
                    Text(formatFcfa(quote!.deliveryFee),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
    );
  }
}
