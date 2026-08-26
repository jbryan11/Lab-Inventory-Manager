import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../domain/inventory_enums.dart';
import '../../providers.dart';
import 'barcode_classifier.dart';
import 'code_parser.dart';
import '../../widgets/home_back_button.dart';

enum ScanMode { find, create }

class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({super.key, required this.mode});

  final ScanMode mode;

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
    final classified = BarcodeClassifier.classify(capture);
    if (classified.isEmpty) return;

    if (widget.mode == ScanMode.create &&
        _configuration == ItemCodeConfiguration.packageAndItem &&
        _package1P == null) {
      await _handlePackageCapture(classified);
      return;
    }

    await _handleItemCapture(classified);
  }

  /// Handles package code capture (1P/1T role assignment).
  Future<void> _handlePackageCapture(List<ClassifiedBarcode> classified) async {
    final classified1P =
        classified.where((e) => e.parsed!.role == ItemCodeRole.package1P).firstOrNull;
    final classified1T =
        classified.where((e) => e.parsed!.role == ItemCodeRole.package1T).firstOrNull;
    final unclassified =
        classified.where((e) => e.parsed!.role == null).toList();

    // Try to resolve 1P and 1T from classifiers and/or position.
    final resolved = BarcodeClassifier.resolveMixedRoles(
      classified1P,
      classified1T,
      unclassified,
    );

    if (resolved != null) {
      _handling = true;
      _package1P = _CapturedCode(
        value: resolved.package1P.parsed!.value,
        type: _mapFormat(resolved.package1P.barcode.format),
      );
      _package1T = _CapturedCode(
        value: resolved.package1T.parsed!.value,
        type: _mapFormat(resolved.package1T.barcode.format),
      );
      setState(() {
        _message = 'Package captured. Now scan the code on the item.';
        _handling = false;
      });
      return;
    }

    // Unable to resolve roles.
    setState(() {
      _message = 'Keep both the 1P and 1T barcodes visible in one frame.';
    });
  }

  /// Handles item code capture (find or create mode).
  Future<void> _handleItemCapture(List<ClassifiedBarcode> classified) async {
    // Filter out package codes if in package+item mode.
    final itemCandidates = widget.mode == ScanMode.create &&
            _configuration == ItemCodeConfiguration.packageAndItem
        ? classified
            .where(
              (e) =>
                  e.parsed!.value != _package1P?.value &&
                  e.parsed!.value != _package1T?.value,
            )
            .toList()
        : classified;

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
    final value =
        widget.mode == ScanMode.create ? rawValue : entry.parsed!.value;
    final database = ref.read(inventoryDatabaseProvider);
    var item = await database.itemByCode(value);
    if (item == null && rawValue != value) {
      item = await database.itemByCode(rawValue);
    }
    if (!mounted) return;

    final foundItem = item;
    if (foundItem != null) {
      if (foundItem.item.isArchived) {
        await _handleArchivedItem(foundItem);
        return;
      }
      context.go('/item/${foundItem.item.id}');
      return;
    }

    final type = _mapFormat(barcode.format);
    if (widget.mode == ScanMode.create) {
      _openCreate(value, type);
      return;
    }

    await _handleNotFound(value);
  }

  /// Handles finding an archived item; prompts to restore.
  Future<void> _handleArchivedItem(InventoryEntry item) async {
    final restore = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Archived item'),
        content: Text('${item.item.name} is archived. Restore it?'),
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
          .setArchived(item.item.id, archived: false);
      ref.invalidate(activeItemsProvider);
      if (mounted) context.go('/item/${item.item.id}');
      return;
    }
    await _resume();
  }

  /// Handles item not found in find mode; prompts to create.
  Future<void> _handleNotFound(String value) async {
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
      _openCreate(value, ItemCodeType.unknown);
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
