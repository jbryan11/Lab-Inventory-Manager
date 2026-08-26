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
import '../../widgets/home_back_button.dart';
import '../scanner/code_parser.dart';

class ItemFormPage extends ConsumerStatefulWidget {
  const ItemFormPage({
    super.key,
    this.itemId,
    this.scannedCode,
    this.scannedCodeType,
    this.package1P,
    this.package1PType,
    this.package1T,
    this.package1TType,
    this.packageMode = false,
  });

  final String? itemId;
  final String? scannedCode;
  final ItemCodeType? scannedCodeType;
  final String? package1P;
  final ItemCodeType? package1PType;
  final String? package1T;
  final ItemCodeType? package1TType;
  final bool packageMode;

  @override
  ConsumerState<ItemFormPage> createState() => _ItemFormPageState();
}

class _ItemFormPageState extends ConsumerState<ItemFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _serialController = TextEditingController();
  final _codeController = TextEditingController();
  final _package1PController = TextEditingController();
  final _package1TController = TextEditingController();

  late String _itemId;
  LabItemType _itemType = LabItemType.tool;
  ItemCodeType _codeType = ItemCodeType.qr;
  ItemCodeSource _codeSource = ItemCodeSource.scanned;
  ItemCodeConfiguration _configuration = ItemCodeConfiguration.itemOnly;
  ItemCodeType _package1PType = ItemCodeType.code128;
  ItemCodeType _package1TType = ItemCodeType.code128;
  InventoryEntry? _existing;
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
    _configuration = widget.packageMode
        ? ItemCodeConfiguration.packageAndItem
        : ItemCodeConfiguration.itemOnly;
    _package1PController.text = widget.package1P ?? '';
    _package1TController.text = widget.package1T ?? '';
    _package1PType = widget.package1PType ?? ItemCodeType.code128;
    _package1TType = widget.package1TType ?? ItemCodeType.code128;
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
    _itemId = item.item.id;
    _nameController.text = item.item.name;
    _categoryController.text = item.item.category;
    _serialController.text = item.item.serialNumber ?? '';
    _itemType = item.item.itemType;
    _configuration = item.item.codeConfiguration;
    final itemCode = item.codeFor(ItemCodeRole.item);
    final package1P = item.codeFor(ItemCodeRole.package1P);
    final package1T = item.codeFor(ItemCodeRole.package1T);
    _codeController.text = itemCode?.value ?? '';
    _codeType = itemCode?.codeType ?? ItemCodeType.unknown;
    _codeSource = itemCode?.source ?? ItemCodeSource.scanned;
    _package1PController.text = package1P?.value ?? '';
    _package1PType = package1P?.codeType ?? ItemCodeType.code128;
    _package1TController.text = package1T?.value ?? '';
    _package1TType = package1T?.codeType ?? ItemCodeType.code128;
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _serialController.dispose();
    _codeController.dispose();
    _package1PController.dispose();
    _package1TController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories =
        ref
            .watch(activeItemsProvider)
            .valueOrNull
            ?.map((entry) => entry.item.category)
            .toSet()
            .toList()
          ?..sort();
    return Scaffold(
      appBar: AppBar(
        leading: const HomeBackButton(),
        title: Text(_isEditing ? 'Edit item' : 'New inventory item'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.label),
                            ),
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
                    Text(
                      'Codes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<ItemCodeConfiguration>(
                      segments: ItemCodeConfiguration.values
                          .map(
                            (configuration) => ButtonSegment(
                              value: configuration,
                              label: Text(configuration.label),
                            ),
                          )
                          .toList(),
                      selected: {_configuration},
                      onSelectionChanged: (selection) {
                        setState(() => _configuration = selection.single);
                      },
                    ),
                    if (_configuration ==
                        ItemCodeConfiguration.packageAndItem) ...[
                      const SizedBox(height: 20),
                      _packageCodeFields(
                        label: 'Package 1P',
                        controller: _package1PController,
                        type: _package1PType,
                        onTypeChanged: (type) =>
                            setState(() => _package1PType = type),
                        role: ItemCodeRole.package1P,
                      ),
                      const SizedBox(height: 16),
                      _packageCodeFields(
                        label: 'Package 1T',
                        controller: _package1TController,
                        type: _package1TType,
                        onTypeChanged: (type) =>
                            setState(() => _package1TType = type),
                        role: ItemCodeRole.package1T,
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'Item code',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
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
                                  widget.scannedCodeType ??
                                  ItemCodeType.unknown;
                              _codeController.text = widget.scannedCode ?? '';
                            }
                          });
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
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ItemCodeType>(
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _codeController,
                      readOnly: _codeSource == ItemCodeSource.generated,
                      decoration: InputDecoration(
                        labelText: 'Barcode / QR value',
                        suffixIcon:
                            !_isEditing && _codeSource == ItemCodeSource.scanned
                            ? IconButton(
                                tooltip: 'Scan code',
                                onPressed: () => context.push('/scan/create'),
                                icon: const Icon(Icons.qr_code_scanner),
                              )
                            : null,
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
  Widget _packageCodeFields({
    required String label,
    required TextEditingController controller,
    required ItemCodeType type,
    required ValueChanged<ItemCodeType> onTypeChanged,
    required ItemCodeRole role,
  }) {
    return Column(
      children: [
        DropdownButtonFormField<ItemCodeType>(
          initialValue: type,
          decoration: InputDecoration(labelText: '$label type'),
          items: ItemCodeType.values
              .map(
                (value) =>
                    DropdownMenuItem(value: value, child: Text(value.label)),
              )
              .toList(),
          onChanged: (value) => onTypeChanged(value!),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '$label value',
            hintText: 'Classifier is optional for manual entry',
          ),
          validator: (value) => _packageCodeValidator(value, role),
        ),
      ],
    );
  }

  String? _packageCodeValidator(String? value, ItemCodeRole expectedRole) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final parsed = parseScannedCode(value);
    if (parsed == null) return 'Enter a code value';
    if (parsed.role != null && parsed.role != expectedRole) {
      return 'This value has the ${parsed.role!.label} classifier';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final database = ref.read(inventoryDatabaseProvider);
    final codeValue = normalizeCodeValue(_codeController.text);
    final package1P = _configuration == ItemCodeConfiguration.packageAndItem
        ? parseScannedCode(_package1PController.text)!.value
        : null;
    final package1T = _configuration == ItemCodeConfiguration.packageAndItem
        ? parseScannedCode(_package1TController.text)!.value
        : null;
    final values = [codeValue, ?package1P, ?package1T];
    if (values.toSet().length != values.length) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Each code value must be unique.')),
      );
      return;
    }
    for (final value in values) {
      final duplicate = await database.itemByCode(value);
      if (duplicate != null && duplicate.item.id != _itemId) {
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Code "$value" belongs to ${duplicate.item.name}.'),
          ),
        );
        return;
      }
    }

    final now = DateTime.now().toUtc();
    try {
      final codes = <InventoryItemCodesCompanion>[
        InventoryItemCodesCompanion.insert(
          itemId: _itemId,
          role: ItemCodeRole.item,
          codeType: _codeType,
          value: codeValue,
          source: _codeSource,
        ),
        if (package1P != null)
          InventoryItemCodesCompanion.insert(
            itemId: _itemId,
            role: ItemCodeRole.package1P,
            codeType: _package1PType,
            value: package1P,
            source: ItemCodeSource.scanned,
          ),
        if (package1T != null)
          InventoryItemCodesCompanion.insert(
            itemId: _itemId,
            role: ItemCodeRole.package1T,
            codeType: _package1TType,
            value: package1T,
            source: ItemCodeSource.scanned,
          ),
      ];
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
          codeConfiguration: Value(_configuration),
          createdAt: Value(_existing?.item.createdAt ?? now),
          updatedAt: Value(now),
          isArchived: Value(_existing?.item.isArchived ?? false),
          archivedAt: Value(_existing?.item.archivedAt),
        ),
        codes,
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
