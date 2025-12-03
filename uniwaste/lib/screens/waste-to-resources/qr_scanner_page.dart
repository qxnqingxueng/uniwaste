import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    returnImage: false,
  );

  bool _isScanned = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not launch $urlString")),
        );
      }
    }
  }

  // 2. Logic to process the code
  void _processQrCode(String code) {
    setState(() {
      _isScanned = true; // Use your existing variable name here (_isScanned)
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        // Check if it looks like a URL
        bool isUrl = code.startsWith('http') || code.startsWith('www');

        return AlertDialog(
          title: Text(isUrl ? "Website Found" : "QR Code Text"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(code, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              if (isUrl)
                const Text(
                  "(Click 'Open' to visit)",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
          actions: [
            // 1. SCAN AGAIN BUTTON
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _isScanned = false; // Unlock to scan again
                });
              },
              child: const Text("Scan Again",
                  style: TextStyle(color: Colors.grey)),
            ),

            // 2. OPEN LINK BUTTON
            if (isUrl)
              FilledButton(
                onPressed: () {
                  _launchURL(code);
                },
                child: const Text("Open Link"),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // We define this variable so we can match the Text position to the Box size
    const double scanBoxSize = 300.0;

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    final Rect scanWindow = Rect.fromCenter(
      center: Offset(screenWidth / 2, screenHeight / 2),
      width: scanBoxSize,
      height: scanBoxSize,
    );

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'QR Code Scanner',
          style: TextStyle(
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.grey),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Stack(
        children: [
          // LAYER 1: Camera Feed
          MobileScanner(
            controller: controller,
            scanWindow: scanWindow,
            onDetect: (capture) {
              if (_isScanned) return;

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                final String code = barcodes.first.rawValue!;
                setState(() {
                  _isScanned = true;
                });
                _processQrCode(code);
              }
            },
          ),

          // LAYER 2: The Dark Mask & Scanner Box
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                overlayColor: Colors.black.withValues(alpha: 0.7),
                cutOutSize: scanBoxSize, // Ensure this matches the text spacing
              ),
            ),
          ),

          // LAYER 3: The Text (Aligned perfectly under the box)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min, // Shrink column to fit content
              children: [
                // 1. Invisible box representing the Scanner Area
                const SizedBox(
                  height: scanBoxSize,
                  width: scanBoxSize,
                ),

                // 2. Small gap
                const SizedBox(height: 100),

                const Text(
                  "Align QR code within the frame",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  QrScannerOverlayShape({
    this.borderColor = const Color.fromRGBO(119, 136, 115, 1.0),
    this.borderWidth = 5.0,
    this.overlayColor = Colors.black,
    this.borderRadius = 10,
    this.borderLength = 200,
    this.cutOutSize = 300,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderOffset = borderWidth / 2;
    final mCutOutSize = cutOutSize < width ? cutOutSize : width - borderOffset;
    final mBorderLength = borderLength > mCutOutSize / 2 + borderWidth * 2
        ? borderLength / 2
        : borderLength;
    final mBorderRadius =
        borderRadius > mBorderLength ? mBorderLength : borderRadius;

    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect)
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: rect.center, width: mCutOutSize, height: mCutOutSize),
          Radius.circular(mBorderRadius),
        ),
      );

    final paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final borderRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: rect.center, width: mCutOutSize, height: mCutOutSize),
      Radius.circular(mBorderRadius),
    );

    // Draw corners
    canvas.drawPath(
        Path()
          ..moveTo(borderRect.left, borderRect.top + mBorderLength)
          ..lineTo(borderRect.left, borderRect.top + mBorderRadius)
          ..arcToPoint(Offset(borderRect.left + mBorderRadius, borderRect.top),
              radius: Radius.circular(mBorderRadius))
          ..lineTo(borderRect.left + mBorderLength, borderRect.top),
        borderPaint);

    canvas.drawPath(
        Path()
          ..moveTo(borderRect.right - mBorderLength, borderRect.top)
          ..lineTo(borderRect.right - mBorderRadius, borderRect.top)
          ..arcToPoint(Offset(borderRect.right, borderRect.top + mBorderRadius),
              radius: Radius.circular(mBorderRadius))
          ..lineTo(borderRect.right, borderRect.top + mBorderLength),
        borderPaint);

    canvas.drawPath(
        Path()
          ..moveTo(borderRect.right, borderRect.bottom - mBorderLength)
          ..lineTo(borderRect.right, borderRect.bottom - mBorderRadius)
          ..arcToPoint(
              Offset(borderRect.right - mBorderRadius, borderRect.bottom),
              radius: Radius.circular(mBorderRadius))
          ..lineTo(borderRect.right - mBorderLength, borderRect.bottom),
        borderPaint);

    canvas.drawPath(
        Path()
          ..moveTo(borderRect.left + mBorderLength, borderRect.bottom)
          ..lineTo(borderRect.left + mBorderRadius, borderRect.bottom)
          ..arcToPoint(
              Offset(borderRect.left, borderRect.bottom - mBorderRadius),
              radius: Radius.circular(mBorderRadius))
          ..lineTo(borderRect.left, borderRect.bottom - mBorderLength),
        borderPaint);
  }

  @override
  ShapeBorder scale(double t) => QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
      borderRadius: borderRadius * t,
      borderLength: borderLength * t,
      cutOutSize: cutOutSize * t);
}
