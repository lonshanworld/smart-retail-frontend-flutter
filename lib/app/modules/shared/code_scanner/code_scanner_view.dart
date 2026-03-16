import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class CodeScannerView extends StatefulWidget {
  const CodeScannerView({super.key, this.title = 'Scan Barcode / QR Code'});

  final String title;

  @override
  State<CodeScannerView> createState() => _CodeScannerViewState();
}

class _CodeScannerViewState extends State<CodeScannerView> {
  late final MobileScannerController _scannerController;
  final TextEditingController _manualInputController = TextEditingController();

  bool _isReturningResult = false;
  bool _isTorchOn = false;

  bool get _supportsCameraScanner {
    return kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      formats: [BarcodeFormat.all],
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  void _finishWithResult(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty || _isReturningResult) {
      return;
    }

    _isReturningResult = true;
    Get.back(result: trimmed);
  }

  Future<void> _toggleTorch() async {
    await _scannerController.toggleTorch();
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: _supportsCameraScanner
            ? [
                IconButton(
                  onPressed: _toggleTorch,
                  icon: Icon(_isTorchOn ? Icons.flash_on : Icons.flash_off),
                ),
              ]
            : null,
      ),
      body: _supportsCameraScanner
          ? Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: (capture) {
                    for (final barcode in capture.barcodes) {
                      if (barcode.rawValue != null &&
                          barcode.rawValue!.isNotEmpty) {
                        _finishWithResult(barcode.rawValue);
                        return;
                      }
                    }
                  },
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: double.infinity,
                    color: Colors.black54,
                    padding: const EdgeInsets.all(16),
                    child: const Text(
                      'Align barcode or QR code inside camera view',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Camera scanning is not available on this platform.\nEnter barcode / QR code manually:',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _manualInputController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Enter code',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _finishWithResult,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _finishWithResult(_manualInputController.text),
                    icon: const Icon(Icons.check),
                    label: const Text('Use Code'),
                  ),
                ],
              ),
            ),
    );
  }
}
