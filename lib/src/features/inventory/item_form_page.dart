import 'package:barcode_widget/barcode_widget.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../data/inventory_database.dart';
import '../../domain/inventory_enums.dart';
import '../../providers.dart';
import '../scanner/scanner_page.dart';

class ItemFormPage extends ConsumerStatefulWidget {
  const ItemFormPage({
    super.key,
    this.itemId,
    this.scannedCode,
    this.scannedCodeType,
  });

  final String? itemId;
  final String? scannedCode;
  final ItemCodeType? scannedCodeType;

  @override
  ConsumerState<ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends ConsumerState<ItemFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _serialController = TextEditingController();
  final _codeController = TextEditingController();

  late String _itemId;
  LabItemType _itemType = LabItemType.tool;
  ItemCodeType _codeType = ItemCodeType.qr;
  ItemCodeSource _codeSource = ItemCodeSource.scanned;
  InventoryItem? _existing;
  bool _loading = false;
  bool get _isEditing => widget.itemId != null;

  @override
  void initState() {
    super.initState();
    _itemId = const Uuid().v4();
    if (widget.scannedCode != null) {
      _codeController.text = widget.scannedCode!;
      _codeType = widget.scannedCodeType ?? ItemCodeType.unknown;
    }
    if (_isEditing) _loadItem();
  }

  Future<void> _loadItem() async {
    setState(() => _loading = true);
    final item = await ref
        .read(inventoryDatabaseProvider)
        .itemById(widget.itemId!);
    if (!mounted) return;
    if (item == null) {
      context.pop();
      return;
    }
    _existing = item;
    _itemId = item.id;
    _nameController.text = item.name;
    _categoryController.text = item.category;
    _serialController.text = item.serialNumber ?? '';
    _codeController.text = item.codeValue;
    _itemType = item.itemType;
    _codeType = item.codeType;
    _codeSource = item.codeSource;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _serialController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final categories =
        ref
            .watch(activeItemsProvider)
            .valueOrNull
            ?.map((item) => item.category)
            .toSet()
            .toList()
          ?..sort();
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit item' : 'New inventory item'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Item name',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              validator: _required,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<LabItemType>(
              initialValue: _itemType,
              decoration: const InputDecoration(labelText: 'Item type'),
              items: LabItemType.values
                  .map(
                    (type) =>
                        DropdownMenuItem(value: type, child: Text(type.label)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _itemType = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _categoryController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'For example: Hand tools',
              ),
              validator: _required,
            ),
            if (categories != null && categories.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: categories
                    .map(
                      (category) => ActionChip(
                        label: Text(category),
                        onPressed: () {
                          _categoryController.text = category;
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _serialController,
              decoration: const InputDecoration(
                labelText: 'Serial number (optional)',
              ),
            ),
            const SizedBox(height: 24),
            Text('Item code', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (!_isEditing)
              SegmentedButton<ItemCodeSource>(
                segments: const [
                  ButtonSegment(
                    value: ItemCodeSource.scanned,
                    icon: Icon(Icons.qr_code_scanner),
                    label: Text('Existing'),
                  ),
                  ButtonSegment(
                    value: ItemCodeSource.generated,
                    icon: Icon(Icons.auto_awesome),
                    label: Text('Generate'),
                  ),
                ],
                selected: {_codeSource},
                onSelectionChanged: (selection) {
                  final source = selection.single;
                  setState(() {
                    _codeSource = source;
                    if (source == ItemCodeSource.generated) {
                      _codeType = ItemCodeType.qr;
                      _codeController.text = _itemId;
                    } else {
                      _codeType =
                          widget.scannedCodeType ?? ItemCodeType.unknown;
                      _codeController.text = widget.scannedCode ?? '';
                    }
                  });
                },
              ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: DropdownButtonFormField<ItemCodeType>(
                    key: ValueKey(_codeType),
                    initialValue: _codeType,
                    decoration: const InputDecoration(labelText: 'Code type'),
                    items:
                        (_codeSource == ItemCodeSource.generated
                                ? [ItemCodeType.qr, ItemCodeType.code128]
                                : ItemCodeType.values)
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.label),
                              ),
                            )
                            .toList(),
                    onChanged: _isEditing
                        ? null
                        : (value) => setState(() => _codeType = value!),
                  ),
                ),
                if (!_isEditing &&
                    _codeSource == ItemCodeSource.scanned) ...[
                  const SizedBox(width: 12),
                  SizedBox.square(
                    dimension: 56,
                    child: IconButton.outlined(
                      tooltip: 'Scan code',
                      onPressed: _scanCode,
                      icon: const Icon(Icons.qr_code_scanner),
                    ),
                  ),
                ],
              ],
            ),
            if (_codeController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _CodePreview(
                type: _codeType,
                value: _codeController.text.trim(),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeController,
              readOnly: _codeSource == ItemCodeSource.generated || _isEditing,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Barcode / QR value',
              ),
              validator: _required,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _loading ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(_isEditing ? 'Save changes' : 'Create item'),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Required' : null;
  }

  Future<void> _scanCode() async {
    final result = await context.push<ScanResult>(
      '/scan/create?returnResult=true',
    );
    if (result == null || !mounted) return;
    setState(() {
      _codeType = result.type;
      _codeController.text = result.value;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final database = ref.read(inventoryDatabaseProvider);
    final codeValue = _codeController.text.trim();
    final duplicate = await database.itemByCode(codeValue);
    if (duplicate != null && duplicate.id != _itemId) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('This code belongs to ${duplicate.name}.')),
      );
      return;
    }

    final now = DateTime.now().toUtc();
    try {
      await database.saveItem(
        InventoryItemsCompanion(
          id: Value(_itemId),
          name: Value(_nameController.text.trim()),
          itemType: Value(_itemType),
          category: Value(_categoryController.text.trim()),
          serialNumber: Value(
            _serialController.text.trim().isEmpty
                ? null
                : _serialController.text.trim(),
          ),
          codeType: Value(_codeType),
          codeValue: Value(codeValue),
          codeSource: Value(_codeSource),
          createdAt: Value(_existing?.createdAt ?? now),
          updatedAt: Value(now),
          isArchived: Value(_existing?.isArchived ?? false),
          archivedAt: Value(_existing?.archivedAt),
        ),
      );
      ref.invalidate(activeItemsProvider);
      ref.invalidate(itemProvider(_itemId));
      if (!mounted) return;
      if (_isEditing) {
        context.pop();
      } else {
        context.go('/item/$_itemId');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save item: $error')));
    }
  }
}

class _CodePreview extends StatelessWidget {
  const _CodePreview({required this.type, required this.value});

  final ItemCodeType type;
  final String value;

  @override
  Widget build(BuildContext context) {
    final preview = type == ItemCodeType.qr
        ? QrImageView(
            data: value,
            size: 160,
            backgroundColor: Colors.white,
          )
        : BarcodeWidget(
            barcode: _barcodeFor(type),
            data: value,
            width: 280,
            height: 110,
            color: Colors.black,
            backgroundColor: Colors.white,
            drawText: true,
            errorBuilder: (context, error) => Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          );

    return Semantics(
      label: '${type.label} preview',
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: preview,
          ),
        ),
      ),
    );
  }

  Barcode _barcodeFor(ItemCodeType type) => switch (type) {
    ItemCodeType.ean13 => Barcode.ean13(),
    ItemCodeType.ean8 => Barcode.ean8(),
    ItemCodeType.upcA => Barcode.upcA(),
    ItemCodeType.upcE => Barcode.upcE(),
    ItemCodeType.dataMatrix => Barcode.dataMatrix(),
    ItemCodeType.qr || ItemCodeType.code128 || ItemCodeType.unknown =>
      Barcode.code128(),
  };
}
