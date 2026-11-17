import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class SignaturePad extends StatefulWidget {
  const SignaturePad({super.key});
  @override
  State<SignaturePad> createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
  final List<Offset?> _points = [];
  final GlobalKey _canvasKey = GlobalKey();
  bool get hasSignature => _points.length > 1;

  Future<String?> pngDataUrl() async {
    if (!hasSignature) return null;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 720, 220));
    canvas.drawColor(Colors.white, BlendMode.src);
    _SignaturePainter(_points).paint(canvas, const Size(720, 220));
    final image = await recorder.endRecording().toImage(720, 220);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) return null;
    return 'data:image/png;base64,${base64Encode(data.buffer.asUint8List())}';
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Signature du destinataire'),
        const SizedBox(height: 6),
        GestureDetector(
          onPanStart: (d) => setState(() => _points.add(_scaled(d.localPosition, context))),
          onPanUpdate: (d) => setState(() => _points.add(_scaled(d.localPosition, context))),
          onPanEnd: (_) => setState(() => _points.add(null)),
          child: Container(key: _canvasKey, height: 130, decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
            child: CustomPaint(painter: _SignaturePainter(_points), size: Size.infinite)),
        ),
        Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => setState(_points.clear), child: const Text('Effacer la signature'))),
      ]);

  Offset _scaled(Offset p, BuildContext context) {
    final size = _canvasKey.currentContext?.size ?? const Size(720, 220);
    return Offset(p.dx * 720 / size.width, p.dy * 220 / size.height);
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.points);
  final List<Offset?> points;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black..strokeWidth = 3..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    for (var i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) canvas.drawLine(Offset(points[i]!.dx * size.width / 720, points[i]!.dy * size.height / 220), Offset(points[i + 1]!.dx * size.width / 720, points[i + 1]!.dy * size.height / 220), paint);
    }
  }
  @override
  bool shouldRepaint(covariant _SignaturePainter old) => old.points != points;
}

String base64Encode(List<int> bytes) => const _Base64Encoder().convert(bytes);

class _Base64Encoder {
  const _Base64Encoder();
  static const _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  String convert(List<int> input) {
    final out = StringBuffer();
    for (var i = 0; i < input.length; i += 3) {
      final a = input[i], hasB = i + 1 < input.length, hasC = i + 2 < input.length;
      final b = hasB ? input[i + 1] : 0, c = hasC ? input[i + 2] : 0;
      out.write(_chars[a >> 2]); out.write(_chars[((a & 3) << 4) | (b >> 4)]);
      out.write(hasB ? _chars[((b & 15) << 2) | (c >> 6)] : '='); out.write(hasC ? _chars[c & 63] : '=');
    }
    return out.toString();
  }
}
