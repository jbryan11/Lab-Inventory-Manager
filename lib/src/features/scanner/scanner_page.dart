import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../domain/inventory_enums.dart';
import '../../providers.dart';

enum ScanMode { find, create }

typedef ScanResult = ({String value, ItemCodeType type});

class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({
    super.key,
    required this.mode,
    this.returnResult = false,
  });

  final ScanMode mode;
  final bool returnResult;

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> {
  final _controller = MobileScannerController(
    formats: const [
      BarcodeFormat.qrCode,
      BarcodeFormat.code128,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.dataMatrix,
    ],
  );
  bool _handling = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.mode == ScanMode.find ? 'Scan to find' : 'Scan new item',
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle flashlight',
            onPressed: _controller.toggleTorch,
            icon: const Icon(Icons.flashlight_on),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          IgnorePointer(
            child: Center(
              child: Container(
                width: 280,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'Center a barcode or QR code inside the frame.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    final barcode = capture.barcodes
        .where((item) => item.rawValue?.trim().isNotEmpty ?? false)
        .firstOrNull;
    if (barcode == null) return;
    _handling = true;
    await _controller.stop();

    final value = barcode.rawValue!.trim();
    final type = _mapFormat(barcode.format);
    if (widget.returnResult) {
      context.pop((value: value, type: type));
      return;
    }

    final entry = await ref.read(inventoryDatabaseProvider).itemByCode(value);
    if (!mounted) return;

    if (entry != null) {
      if (entry.item.isArchived) {
        final restore = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Archived item'),
            content: Text('${entry.item.name} is archived. Restore it?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Restore'),
              ),
            ],
          ),
        );
        if (restore == true) {
          await ref
              .read(inventoryDatabaseProvider)
              .setArchived(entry.item.id, archived: false);
          ref.invalidate(activeItemsProvider);
          if (mounted) context.go('/item/${entry.item.id}');
          return;
        }
        await _resume();
        return;
      }
      context.go('/item/${entry.item.id}');
      return;
    }

    if (widget.mode == ScanMode.create) {
      _openCreate(value, type);
      return;
    }

    final create = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Item not found'),
        content: Text('No inventory item uses code "$value".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Scan again'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create item'),
          ),
        ],
      ),
    );
    if (create == true) {
      _openCreate(value, type);
    } else {
      await _resume();
    }
  }

  void _openCreate(String value, ItemCodeType type) {
    final uri = Uri(
      path: '/item/new',
      queryParameters: {'code': value, 'codeType': type.name},
    );
    context.go(uri.toString());
  }

  Future<void> _resume() async {
    if (!mounted) return;
    _handling = false;
    await _controller.start();
  }

  ItemCodeType _mapFormat(BarcodeFormat format) => switch (format) {
    BarcodeFormat.qrCode => ItemCodeType.qr,
    BarcodeFormat.code128 => ItemCodeType.code128,
    BarcodeFormat.ean13 => ItemCodeType.ean13,
    BarcodeFormat.ean8 => ItemCodeType.ean8,
    BarcodeFormat.upcA => ItemCodeType.upcA,
    BarcodeFormat.upcE => ItemCodeType.upcE,
    BarcodeFormat.dataMatrix => ItemCodeType.dataMatrix,
    _ => ItemCodeType.unknown,
  };
}
