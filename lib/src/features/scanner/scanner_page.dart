import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../domain/inventory_enums.dart';
import '../../providers.dart';
import 'code_parser.dart';
import '../../widgets/home_back_button.dart';

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
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.codabar,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.dataMatrix,
      BarcodeFormat.itf14,
      BarcodeFormat.pdf417,
      BarcodeFormat.aztec,
    ],
  );
  bool _handling = false;
  ItemCodeConfiguration _configuration = ItemCodeConfiguration.itemOnly;
  _CapturedCode? _package1P;
  _CapturedCode? _package1T;
  String? _message;
  // Holds a barcode captured when we need the user to confirm its role
  // (single unclassified code, no positional info).
  _CapturedCode? _pendingPackageCode;

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
        leading: const HomeBackButton(),
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
                width: 320,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child:
                    widget.mode == ScanMode.create &&
                        _configuration ==
                            ItemCodeConfiguration.packageAndItem &&
                        _package1P == null
                    ? Column(
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                '1P',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Divider(
                            color: Colors.white.withValues(alpha: 0.4),
                            height: 1,
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                '1T',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
          ),
          if (widget.mode == ScanMode.create)
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: SegmentedButton<ItemCodeConfiguration>(
                style: SegmentedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  selectedBackgroundColor: Theme.of(context)
                      .colorScheme
                      .primary,
                  selectedForegroundColor: Colors.white,
                ),
                segments: const [
                  ButtonSegment(
                    value: ItemCodeConfiguration.itemOnly,
                    label: Text('Item only'),
                  ),
                  ButtonSegment(
                    value: ItemCodeConfiguration.packageAndItem,
                    label: Text('Package + item'),
                  ),
                ],
                selected: {_configuration},
                onSelectionChanged: (selection) {
                  setState(() {
                    _configuration = selection.single;
                    _package1P = null;
                    _package1T = null;
                    _pendingPackageCode = null;
                    _message = null;
                  });
                },
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
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _instruction,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.amber),
                      ),
                    ],
                    if (widget.mode == ScanMode.create &&
                        _configuration ==
                            ItemCodeConfiguration.packageAndItem) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _openManualPackageForm,
                        child: const Text('Enter codes manually'),
                      ),
                    ],
                  ],
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
    final detected = capture.barcodes
        .map(
          (barcode) =>
              (barcode: barcode, parsed: parseScannedCode(barcode.rawValue)),
        )
        .where((entry) => entry.parsed != null)
        .toList();
    if (detected.isEmpty) return;

    if (widget.mode == ScanMode.create &&
        _configuration == ItemCodeConfiguration.packageAndItem &&
        _package1P == null) {
      // --- Determine 1P / 1T roles ---
      // Strategy 1: classifier embedded in raw value (GS1-128 etc.)
      final classified1P = detected
          .where((e) => e.parsed!.role == ItemCodeRole.package1P)
          .firstOrNull;
      final classified1T = detected
          .where((e) => e.parsed!.role == ItemCodeRole.package1T)
          .firstOrNull;

      if (classified1P != null && classified1T != null) {
        // Both roles identified from embedded classifiers — accept immediately.
        _handling = true;
        _package1P = _CapturedCode(
          value: classified1P.parsed!.value,
          type: _mapFormat(classified1P.barcode.format),
        );
        _package1T = _CapturedCode(
          value: classified1T.parsed!.value,
          type: _mapFormat(classified1T.barcode.format),
        );
        setState(() {
          _message = 'Package captured. Now scan the code on the item.';
          _handling = false;
        });
        return;
      }

      // Strategy 2: two unclassified barcodes in one frame — use vertical
      // position (top = 1P, bottom = 1T), matching the standard label layout.
      final unclassified = detected
          .where((e) => e.parsed!.role == null)
          .toList();

      if (unclassified.length >= 2) {
        // Sort by Y centre of the bounding box so top barcode → 1P.
        unclassified.sort((a, b) {
          final ay = _barcodeY(a.barcode);
          final by = _barcodeY(b.barcode);
          if (ay == null && by == null) return 0;
          if (ay == null) return 1;
          if (by == null) return -1;
          return ay.compareTo(by);
        });
        _handling = true;
        _package1P = _CapturedCode(
          value: unclassified[0].parsed!.value,
          type: _mapFormat(unclassified[0].barcode.format),
        );
        _package1T = _CapturedCode(
          value: unclassified[1].parsed!.value,
          type: _mapFormat(unclassified[1].barcode.format),
        );
        setState(() {
          _message =
              'Package captured (top→1P, bottom→1T). '
              'Now scan the code on the item.';
          _handling = false;
        });
        return;
      }

      // Strategy 3: exactly one unclassified barcode — ask the user which role.
      if (unclassified.length == 1) {
        final candidate = unclassified.first;
        final already1P =
            classified1P != null ||
            (_pendingPackageCode != null &&
                _pendingPackageCode!.value == candidate.parsed!.value);
        if (!already1P) {
          setState(() {
            _message =
                'Scanning… keep both 1P and 1T barcodes in the frame together.';
          });
          return;
        }
      }

      // Strategy 4: one role known from classifier, one unknown from position.
      if (classified1P != null && unclassified.length == 1) {
        _handling = true;
        _package1P = _CapturedCode(
          value: classified1P.parsed!.value,
          type: _mapFormat(classified1P.barcode.format),
        );
        _package1T = _CapturedCode(
          value: unclassified.first.parsed!.value,
          type: _mapFormat(unclassified.first.barcode.format),
        );
        setState(() {
          _message = 'Package captured. Now scan the code on the item.';
          _handling = false;
        });
        return;
      }
      if (classified1T != null && unclassified.length == 1) {
        _handling = true;
        _package1P = _CapturedCode(
          value: unclassified.first.parsed!.value,
          type: _mapFormat(unclassified.first.barcode.format),
        );
        _package1T = _CapturedCode(
          value: classified1T.parsed!.value,
          type: _mapFormat(classified1T.barcode.format),
        );
        setState(() {
          _message = 'Package captured. Now scan the code on the item.';
          _handling = false;
        });
        return;
      }

      setState(() {
        _message = 'Keep both the 1P and 1T barcodes visible in one frame.';
      });
      return;
    }

    final itemCandidates =
        widget.mode == ScanMode.create &&
            _configuration == ItemCodeConfiguration.packageAndItem
        ? detected
              .where(
                (entry) =>
                    entry.parsed!.value != _package1P!.value &&
                    entry.parsed!.value != _package1T!.value,
              )
              .toList()
        : detected;
    if (itemCandidates.isEmpty) {
      setState(() {
        _message = 'Move the package away, then scan the code on the item.';
      });
      return;
    }
    final entry = itemCandidates.first;
    final barcode = entry.barcode;
    _handling = true;
    await _controller.stop();

    final rawValue = barcode.rawValue!.trim();
    final value = widget.mode == ScanMode.create
        ? rawValue
        : entry.parsed!.value;
    final database = ref.read(inventoryDatabaseProvider);
    var item = await database.itemByCode(value);
    if (item == null && rawValue != value) {
      item = await database.itemByCode(rawValue);
    }
    if (!mounted) return;

    final foundItem = item;
    if (foundItem != null) {
      if (foundItem.item.isArchived) {
        final restore = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Archived item'),
            content: Text('${foundItem.item.name} is archived. Restore it?'),
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
              .setArchived(foundItem.item.id, archived: false);
          ref.invalidate(activeItemsProvider);
          if (mounted) context.go('/item/${foundItem.item.id}');
          return;
        }
        await _resume();
        return;
      }
      context.go('/item/${foundItem.item.id}');
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
      queryParameters: {
        'code': value,
        'codeType': type.name,
        if (_configuration == ItemCodeConfiguration.packageAndItem)
          'packageMode': 'true',
        if (_package1P != null) 'package1P': _package1P!.value,
        if (_package1P != null) 'package1PType': _package1P!.type.name,
        if (_package1T != null) 'package1T': _package1T!.value,
        if (_package1T != null) 'package1TType': _package1T!.type.name,
      },
    );
    context.go(uri.toString());
  }

  void _openManualPackageForm() {
    _openCreate('', ItemCodeType.unknown);
  }

  String get _instruction {
    if (widget.mode == ScanMode.find) {
      return 'Center a barcode or QR code inside the frame.';
    }
    if (_configuration == ItemCodeConfiguration.itemOnly) {
      return 'Center the item barcode or QR code inside the frame.';
    }
    if (_package1P == null) {
      return 'Frame both package barcodes together.\n'
          'Top barcode will be 1P · Bottom will be 1T.';
    }
    return 'Package 1P + 1T captured ✓\nNow center the item code in the frame.';
  }

  Future<void> _resume() async {
    if (!mounted) return;
    _handling = false;
    await _controller.start();
  }

  /// Returns the vertical centre of a barcode's bounding box (0.0 = top).
  /// Returns null if positional data is unavailable.
  double? _barcodeY(Barcode barcode) {
    final corners = barcode.corners;
    if (corners.isEmpty) return null;
    final totalY = corners.fold<double>(0, (sum, p) => sum + p.dy);
    return totalY / corners.length;
  }

  ItemCodeType _mapFormat(BarcodeFormat format) => switch (format) {
    BarcodeFormat.qrCode => ItemCodeType.qr,
    BarcodeFormat.code128 => ItemCodeType.code128,
    BarcodeFormat.code39 => ItemCodeType.code39,
    BarcodeFormat.code93 => ItemCodeType.code93,
    BarcodeFormat.codabar => ItemCodeType.codabar,
    BarcodeFormat.ean13 => ItemCodeType.ean13,
    BarcodeFormat.ean8 => ItemCodeType.ean8,
    BarcodeFormat.upcA => ItemCodeType.upcA,
    BarcodeFormat.upcE => ItemCodeType.upcE,
    BarcodeFormat.dataMatrix => ItemCodeType.dataMatrix,
    BarcodeFormat.itf14 => ItemCodeType.itf,
    BarcodeFormat.pdf417 => ItemCodeType.pdf417,
    BarcodeFormat.aztec => ItemCodeType.aztec,
    _ => ItemCodeType.unknown,
  };
}

class _CapturedCode {
  const _CapturedCode({required this.value, required this.type});

  final String value;
  final ItemCodeType type;
}
