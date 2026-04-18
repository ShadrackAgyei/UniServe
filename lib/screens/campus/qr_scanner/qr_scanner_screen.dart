import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../models/check_in_response.dart';
import '../../../services/supabase_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;
  _OverlayState _overlayState = _OverlayState.none;
  String _overlayMessage = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    final token = barcode?.rawValue;
    if (token == null || token.isEmpty) return;

    setState(() => _processing = true);
    await _controller.stop();

    try {
      final response = await SupabaseService.validateAndCheckIn(token);
      switch (response.result) {
        case CheckInResultType.success:
          if (mounted) {
            setState(() {
              _overlayState = _OverlayState.success;
              _overlayMessage =
                  'Checked in${response.name != null ? ' to ${response.name}' : ''}!';
            });
          }
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            setState(() => _processing = false);
            context.pop();
          }

        case CheckInResultType.alreadyCheckedIn:
          if (mounted) {
            setState(() {
              _overlayState = _OverlayState.warning;
              _overlayMessage = 'Already checked in';
            });
          }
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            setState(() {
              _overlayState = _OverlayState.none;
              _processing = false;
            });
            await _controller.start();
          }

        case CheckInResultType.invalid:
          if (mounted) {
            setState(() {
              _overlayState = _OverlayState.error;
              _overlayMessage = 'Invalid QR code';
            });
          }
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            setState(() {
              _overlayState = _OverlayState.none;
              _processing = false;
            });
            await _controller.start();
          }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _overlayState = _OverlayState.error;
          _overlayMessage = 'Error: $e';
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() {
            _overlayState = _OverlayState.none;
            _processing = false;
          });
          await _controller.start();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          Center(
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const Align(
            alignment: Alignment(0, 0.6),
            child: Text(
              'Point camera at a QR code',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          if (_overlayState != _OverlayState.none)
            _ResultOverlay(
                state: _overlayState, message: _overlayMessage),
        ],
      ),
    );
  }
}

enum _OverlayState { none, success, warning, error }

class _ResultOverlay extends StatelessWidget {
  final _OverlayState state;
  final String message;

  const _ResultOverlay({required this.state, required this.message});

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _OverlayState.success => Colors.green.withAlpha(204),
      _OverlayState.warning => Colors.orange.withAlpha(204),
      _OverlayState.error => Colors.red.withAlpha(204),
      _OverlayState.none => Colors.transparent,
    };
    final icon = switch (state) {
      _OverlayState.success => Icons.check_circle,
      _OverlayState.warning => Icons.warning_amber,
      _OverlayState.error => Icons.error_outline,
      _OverlayState.none => Icons.circle,
    };
    return Container(
      color: color,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 80, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
