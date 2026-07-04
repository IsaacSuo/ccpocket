import 'package:flutter/widgets.dart';

class Barcode {
  const Barcode({this.rawValue});

  final String? rawValue;
}

class BarcodeCapture {
  const BarcodeCapture({this.barcodes = const []});

  final List<Barcode> barcodes;
}

typedef BarcodeCaptureCallback = void Function(BarcodeCapture capture);

class MobileScannerController {
  void dispose() {}
}

class MobileScanner extends StatelessWidget {
  const MobileScanner({
    super.key,
    this.controller,
    this.onDetect,
  });

  final MobileScannerController? controller;
  final BarcodeCaptureCallback? onDetect;

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
