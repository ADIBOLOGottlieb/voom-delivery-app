import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/delivery.dart';
import '../../models/product.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/delivery_service.dart';
import '../../utils/colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/bottom_action_bar.dart';

/// Paiement d'une livraison par Flooz ou Mixx by Yas.
///
/// - Mode « agrégateur » (KKiaPay / PayGate) : paiement en ligne confirmé automatiquement.
/// - Mode « manuel » (secours) : virement au numéro marchand + capture d'écran vérifiée par l'agence.
class PaymentScreen extends StatefulWidget {
  final Delivery delivery;

  const PaymentScreen({super.key, required this.delivery});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with WidgetsBindingObserver {
  static const _pollEvery = Duration(seconds: 4);
  static const _pollFor = Duration(minutes: 5);

  final _formKey = GlobalKey<FormState>();
  final _refController = TextEditingController();
  late final _phoneController = TextEditingController(text: context.read<AuthService>().user?.phoneNumber);

  late final Future<PaymentInfo> _info;
  PaymentInfo? _loaded;
  String? _method;
  XFile? _screenshot;
  bool _sending = false;

  // Paiement en ligne en attente de confirmation.
  CheckoutStart? _pending;
  Timer? _poller;
  DateTime? _pollStarted;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _info = context.read<DeliveryService>().paymentInfo();
    _info.then((info) {
      if (mounted) setState(() => _loaded = info);
    }, onError: (_) {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poller?.cancel();
    _refController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Retour dans l'app après la page de paiement : vérification immédiate.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pending != null) _poll();
  }

  void _error(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));

  // --- Mode agrégateur ------------------------------------------------------

  Future<void> _startGateway() async {
    if (_method == null) return _error('Choisissez Flooz ou Mixx by Yas.');
    if (!_formKey.currentState!.validate()) return;

    setState(() => _sending = true);
    try {
      final start = await context.read<DeliveryService>().checkout(
            deliveryId: widget.delivery.id,
            method: _method!,
            phone: _phoneController.text.trim(),
          );
      if (!mounted) return;
      setState(() => _pending = start);
      _pollStarted = DateTime.now();
      _poller = Timer.periodic(_pollEvery, (_) => _poll());
      if (start.redirectUrl != null) await _openPaymentPage();
    } on ApiException catch (e) {
      _error(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openPaymentPage() async {
    final url = _pending?.redirectUrl;
    if (url == null) return;
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) _error("Impossible d'ouvrir la page de paiement.");
  }

  Future<void> _poll() async {
    final pending = _pending;
    if (pending == null || _checking) return;
    if (_pollStarted != null && DateTime.now().difference(_pollStarted!) > _pollFor) {
      _stopWaiting();
      return _error('Pas de confirmation reçue. Si vous avez payé, la livraison sera mise à jour automatiquement.');
    }

    _checking = true;
    try {
      final (status, delivery) = await context.read<DeliveryService>().paymentStatus(
            deliveryId: widget.delivery.id,
            paymentId: pending.paymentId,
          );
      if (!mounted) return;
      if (status == PaymentStatus.verified) {
        _poller?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Paiement confirmé ! Un livreur va être assigné.'),
          backgroundColor: AppColors.success,
        ));
        Navigator.of(context).pop(delivery);
      } else if (status == 'failed') {
        _stopWaiting();
        _error("Le paiement n'a pas abouti. Vous pouvez réessayer.");
      }
    } on ApiException {
      // Erreur réseau passagère : nouvelle tentative au prochain tour.
    } finally {
      _checking = false;
    }
  }

  void _stopWaiting() {
    _poller?.cancel();
    if (mounted) setState(() => _pending = null);
  }

  // --- Mode manuel ----------------------------------------------------------

  Future<void> _pickScreenshot() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (file != null) setState(() => _screenshot = file);
  }

  Future<void> _submitManual() async {
    if (_method == null) return _error('Choisissez Flooz ou Mixx by Yas.');
    if (!_formKey.currentState!.validate()) return;
    if (_screenshot == null) return _error("Ajoutez la capture d'écran de la transaction.");

    final messenger = ScaffoldMessenger.of(context);
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
      _error(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // --- Interface -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _pending == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _stopWaiting();
      },
      child: Scaffold(
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
            if (_pending != null) return _WaitingView(start: _pending!, onReopen: _openPaymentPage);
            return Form(key: _formKey, child: info.isGateway ? _gatewayForm(info) : _manualForm(info));
          },
        ),
        bottomNavigationBar: _bottomBar(),
      ),
    );
  }

  Widget? _bottomBar() {
    final info = _loaded;
    if (info == null || _method == null) return null;
    final amount = widget.delivery.totalAmount;

    if (_pending != null) {
      return BottomActionBar(children: [
        OutlinedButton(onPressed: _stopWaiting, child: const Text('Annuler / changer de moyen de paiement')),
      ]);
    }

    return BottomActionBar(
      summary: Row(
        children: [
          Expanded(child: Text('Montant', style: Theme.of(context).textTheme.bodyMedium)),
          Text(formatFcfa(amount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      children: [
        ElevatedButton.icon(
          onPressed: _sending ? null : (info.isGateway ? _startGateway : _submitManual),
          icon: _sending ? const ButtonProgress() : Icon(info.isGateway ? Icons.lock : Icons.send),
          label: Text(info.isGateway ? 'Payer ${formatFcfa(amount)}' : 'Envoyer la preuve de paiement'),
        ),
      ],
    );
  }

  Widget _amountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.secondary, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Text('Montant à payer', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(
            formatFcfa(widget.delivery.totalAmount),
            style: const TextStyle(color: AppColors.primary, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('Livraison ${widget.delivery.reference}', style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  List<Widget> _methodChoice(PaymentInfo info, {required bool showNumbers}) => [
        for (final m in info.methods)
          if (!showNumbers || m.merchantNumber != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MethodTile(
                method: m,
                showNumber: showNumbers,
                selected: _method == m.method,
                onTap: () => setState(() => _method = m.method),
              ),
            ),
      ];

  Widget _phoneField(String label) => TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.phone_android)),
        validator: (v) => (v ?? '').replaceAll(RegExp(r'\D'), '').length < 8 ? 'Numéro invalide' : null,
      );

  Widget _gatewayForm(PaymentInfo info) {
    final titles = Theme.of(context).textTheme.titleMedium;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (info.gateway == 'simulation')
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'MODE TEST : paiement simulé, aucun argent ne sera débité.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        _amountCard(),
        const SizedBox(height: 20),
        Text('1. Choisissez votre moyen de paiement', style: titles),
        const SizedBox(height: 8),
        ..._methodChoice(info, showNumbers: false),
        const SizedBox(height: 16),
        Text('2. Numéro qui va payer', style: titles),
        const SizedBox(height: 8),
        _phoneField(_method == 'mixx' ? 'Numéro Mixx by Yas' : 'Numéro Flooz'),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.verified_user, color: AppColors.success, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                [
                  'Paiement sécurisé : vous validez avec votre code secret, la confirmation est automatique.',
                  if (info.feeNote != null) 'Frais : ${info.feeNote}.',
                ].join(' '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _manualForm(PaymentInfo info) {
    final number = info.methods.where((m) => m.method == _method).firstOrNull?.merchantNumber;
    final titles = Theme.of(context).textTheme.titleMedium;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _amountCard(),
        const SizedBox(height: 20),
        Text('1. Choisissez votre moyen de paiement', style: titles),
        const SizedBox(height: 8),
        ..._methodChoice(info, showNumbers: true),
        if (number != null) ...[
          const SizedBox(height: 16),
          Text('2. Envoyez le montant au compte marchand', style: titles),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: Text(info.merchantName),
              subtitle: Text(
                number,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              trailing: IconButton(
                tooltip: 'Copier le numéro',
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: number));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Numéro copié')));
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
          Text('3. Envoyez la preuve de paiement', style: titles),
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
          _phoneField('Numéro ayant effectué le paiement'),
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
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

/// Attente de la confirmation du paiement en ligne.
class _WaitingView extends StatelessWidget {
  final CheckoutStart start;
  final VoidCallback onReopen;

  const _WaitingView({required this.start, required this.onReopen});

  @override
  Widget build(BuildContext context) {
    final isUssd = start.mode == 'ussd';
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isUssd ? Icons.phonelink_ring : Icons.open_in_browser, size: 72, color: AppColors.primaryDark),
            const SizedBox(height: 20),
            Text(
              isUssd ? 'Validez sur votre téléphone' : 'Finalisez le paiement',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(start.message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 28),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 12),
                Text('En attente de confirmation…'),
              ],
            ),
            if (!isUssd) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: onReopen,
                icon: const Icon(Icons.refresh),
                label: const Text('Rouvrir la page de paiement'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Moyen de paiement sélectionnable, libellé complet sur toute la largeur.
class _MethodTile extends StatelessWidget {
  final PaymentMethodInfo method;
  final bool selected;
  final bool showNumber;
  final VoidCallback onTap;

  const _MethodTile({required this.method, required this.selected, required this.showNumber, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary.withValues(alpha: 0.25) : AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? AppColors.secondary : AppColors.textHint, width: selected ? 2 : 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.secondary : AppColors.textHint,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(method.label, style: Theme.of(context).textTheme.titleMedium)),
              if (showNumber && method.merchantNumber != null)
                Text(method.merchantNumber!, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
