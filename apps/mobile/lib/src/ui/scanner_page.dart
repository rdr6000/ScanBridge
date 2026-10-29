import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:scanbridge_domain/scanbridge_domain.dart';
import 'package:scanbridge_ui/scanbridge_ui.dart';

import '../services.dart';
import '../settings/mobile_settings.dart';
import 'capture_flow.dart';
import 'link_banner.dart';

const formatMap = <BarcodeFormat, Symbology>{
  BarcodeFormat.ean8: Symbology.ean8,
  BarcodeFormat.ean13: Symbology.ean13,
  BarcodeFormat.upcA: Symbology.upcA,
  BarcodeFormat.upcE: Symbology.upcE,
  BarcodeFormat.code128: Symbology.code128,
  BarcodeFormat.code39: Symbology.code39,
  BarcodeFormat.code93: Symbology.code93,
  BarcodeFormat.itf14: Symbology.itf,
  BarcodeFormat.codabar: Symbology.codabar,
  BarcodeFormat.qrCode: Symbology.qrCode,
  BarcodeFormat.dataMatrix: Symbology.dataMatrix,
  BarcodeFormat.pdf417: Symbology.pdf417,
  BarcodeFormat.aztec: Symbology.aztec,
};

/// Camera scanning. Single mode returns after one saved code; continuous
/// keeps scanning and ignores the same code for a short cooldown.
class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({super.key, this.single = false});
  final bool single;

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> {
  late final MobileScannerController _controller;
  late final bool _single;
  var _busy = false;
  var _paused = false;
  String? _lastValue;
  DateTime _lastAt = DateTime(0);
  int _count = 0;

  @override
  void initState() {
    super.initState();
    final s = ref.read(servicesProvider).settings.current;
    _single = widget.single || s.scanMode == ScanMode.single;
    final allowed = s.rules.allowedFormats;
    _controller = MobileScannerController(
      formats: [
        for (final e in formatMap.entries)
          if (allowed.isEmpty || allowed.contains(e.value)) e.key,
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy || _paused) return;
    final code = capture.barcodes.where((b) => (b.rawValue ?? '').isNotEmpty).firstOrNull;
    if (code == null) return;
    final value = code.rawValue!;
    final now = DateTime.now();
    if (value == _lastValue && now.difference(_lastAt) < const Duration(milliseconds: 1500)) return;
    _lastValue = value;
    _lastAt = now;
    setState(() => _busy = true);
    await _controller.pause();
    final saved = mounted && await submitCode(context, ref, value, formatMap[code.format] ?? Symbology.unknown, ScanSource.camera);
    if (!mounted) return;
    if (saved) _count++;
    if (saved && _single) return context.pop();
    _lastAt = DateTime.now();
    await _controller.start();
    setState(() => _busy = false);
  }

  Future<void> _togglePause() async {
    _paused ? await _controller.start() : await _controller.pause();
    setState(() => _paused = !_paused);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final size = MediaQuery.sizeOf(context);
    final window = Rect.fromCenter(center: Offset(size.width / 2, size.height * .38), width: size.width * .8, height: size.width * .5);
    return Scaffold(
      appBar: AppBar(
        title: Text(_single ? l.scanSingle : l.scanContinuous),
        actions: [
          IconButton(tooltip: l.torch, onPressed: _controller.toggleTorch, icon: const Icon(Icons.flashlight_on_outlined)),
          IconButton(tooltip: l.switchCamera, onPressed: _controller.switchCamera, icon: const Icon(Icons.cameraswitch_outlined)),
        ],
      ),
      body: Stack(children: [
        MobileScanner(
          controller: _controller,
          scanWindow: window,
          onDetect: _onDetect,
          errorBuilder: (context, error) => EmptyState(
            icon: Icons.no_photography_outlined,
            title: l.cameraUnavailable,
            message: error.errorCode == MobileScannerErrorCode.permissionDenied ? l.cameraPermissionDenied : '${error.errorCode.name} ${error.errorDetails?.message ?? ''}',
          ),
        ),
        IgnorePointer(child: CustomPaint(size: size, painter: _WindowPainter(window, context.colors.primary))),
        Positioned(
          left: Sb.m,
          right: Sb.m,
          top: window.bottom + Sb.m,
          child: Text(
            _paused ? l.scannerPaused : l.scannerHint,
            textAlign: TextAlign.center,
            style: context.text.bodyLarge?.copyWith(color: Colors.white, shadows: const [Shadow(blurRadius: 4)]),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Material(
            color: context.colors.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(Sb.m),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const LinkBanner(compact: true),
                  const SizedBox(height: Sb.s),
                  Row(children: [
                    Expanded(child: Text(l.scannedThisRun(_count), style: context.text.titleMedium)),
                    FilledButton.tonalIcon(
                      onPressed: _togglePause,
                      icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
                      label: Text(_paused ? l.resume : l.pause),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Darkens everything outside the scan window and outlines it.
class _WindowPainter extends CustomPainter {
  _WindowPainter(this.window, this.color);
  final Rect window;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(window, const Radius.circular(Sb.radius));
    canvas.drawPath(
      Path.combine(PathOperation.difference, Path()..addRect(Offset.zero & size), Path()..addRRect(r)),
      Paint()..color = Colors.black54,
    );
    canvas.drawRRect(r, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(_WindowPainter old) => old.window != window || old.color != color;
}
