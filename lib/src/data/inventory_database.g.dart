// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_database.dart';

// ignore_for_file: type=lint
class $InventoryItemsTable extends InventoryItems
    with TableInfo<$InventoryItemsTable, InventoryItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<LabItemType, String> itemType =
      GeneratedColumn<String>(
        'item_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<LabItemType>($InventoryItemsTable.$converteritemType);
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serialNumberMeta = const VerificationMeta(
    'serialNumber',
  );
  @override
  late final GeneratedColumn<String> serialNumber = GeneratedColumn<String>(
    'serial_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ItemCodeConfiguration, String>
  codeConfiguration =
      GeneratedColumn<String>(
        'code_configuration',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('itemOnly'),
      ).withConverter<ItemCodeConfiguration>(
        $InventoryItemsTable.$convertercodeConfiguration,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    itemType,
    category,
    serialNumber,
    codeConfiguration,
    createdAt,
    updatedAt,
    isArchived,
    archivedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('serial_number')) {
      context.handle(
        _serialNumberMeta,
        serialNumber.isAcceptableOrUnknown(
          data['serial_number']!,
          _serialNumberMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventoryItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      itemType: $InventoryItemsTable.$converteritemType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}item_type'],
        )!,
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      serialNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serial_number'],
      ),
      codeConfiguration: $InventoryItemsTable.$convertercodeConfiguration
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.string,
              data['${effectivePrefix}code_configuration'],
            )!,
          ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
    );
  }

  @override
  $InventoryItemsTable createAlias(String alias) {
    return $InventoryItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<LabItemType, String, String> $converteritemType =
      const EnumNameConverter<LabItemType>(LabItemType.values);
  static JsonTypeConverter2<ItemCodeConfiguration, String, String>
  $convertercodeConfiguration = const EnumNameConverter<ItemCodeConfiguration>(
    ItemCodeConfiguration.values,
  );
}

class InventoryItem extends DataClass implements Insertable<InventoryItem> {
  final String id;
  final String name;
  final LabItemType itemType;
  final String category;
  final String? serialNumber;
  final ItemCodeConfiguration codeConfiguration;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;
  final DateTime? archivedAt;
  const InventoryItem({
    required this.id,
    required this.name,
    required this.itemType,
    required this.category,
    this.serialNumber,
    required this.codeConfiguration,
    required this.createdAt,
    required this.updatedAt,
    required this.isArchived,
    this.archivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    {
      map['item_type'] = Variable<String>(
        $InventoryItemsTable.$converteritemType.toSql(itemType),
      );
    }
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || serialNumber != null) {
      map['serial_number'] = Variable<String>(serialNumber);
    }
    {
      map['code_configuration'] = Variable<String>(
        $InventoryItemsTable.$convertercodeConfiguration.toSql(
          codeConfiguration,
        ),
      );
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_archived'] = Variable<bool>(isArchived);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    return map;
  }

  InventoryItemsCompanion toCompanion(bool nullToAbsent) {
    return InventoryItemsCompanion(
      id: Value(id),
      name: Value(name),
      itemType: Value(itemType),
      category: Value(category),
      serialNumber: serialNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(serialNumber),
      codeConfiguration: Value(codeConfiguration),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isArchived: Value(isArchived),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory InventoryItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryItem(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      itemType: $InventoryItemsTable.$converteritemType.fromJson(
        serializer.fromJson<String>(json['itemType']),
      ),
      category: serializer.fromJson<String>(json['category']),
      serialNumber: serializer.fromJson<String?>(json['serialNumber']),
      codeConfiguration: $InventoryItemsTable.$convertercodeConfiguration
          .fromJson(serializer.fromJson<String>(json['codeConfiguration'])),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'itemType': serializer.toJson<String>(
        $InventoryItemsTable.$converteritemType.toJson(itemType),
      ),
      'category': serializer.toJson<String>(category),
      'serialNumber': serializer.toJson<String?>(serialNumber),
      'codeConfiguration': serializer.toJson<String>(
        $InventoryItemsTable.$convertercodeConfiguration.toJson(
          codeConfiguration,
        ),
      ),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isArchived': serializer.toJson<bool>(isArchived),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
    };
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    LabItemType? itemType,
    String? category,
    Value<String?> serialNumber = const Value.absent(),
    ItemCodeConfiguration? codeConfiguration,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isArchived,
    Value<DateTime?> archivedAt = const Value.absent(),
  }) => InventoryItem(
    id: id ?? this.id,
    name: name ?? this.name,
    itemType: itemType ?? this.itemType,
    category: category ?? this.category,
    serialNumber: serialNumber.present ? serialNumber.value : this.serialNumber,
    codeConfiguration: codeConfiguration ?? this.codeConfiguration,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isArchived: isArchived ?? this.isArchived,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
  );
  InventoryItem copyWithCompanion(InventoryItemsCompanion data) {
    return InventoryItem(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      category: data.category.present ? data.category.value : this.category,
      serialNumber: data.serialNumber.present
          ? data.serialNumber.value
          : this.serialNumber,
      codeConfiguration: data.codeConfiguration.present
          ? data.codeConfiguration.value
          : this.codeConfiguration,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItem(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('itemType: $itemType, ')
          ..write('category: $category, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('codeConfiguration: $codeConfiguration, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isArchived: $isArchived, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    itemType,
    category,
    serialNumber,
    codeConfiguration,
    createdAt,
    updatedAt,
    isArchived,
    archivedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryItem &&
          other.id == this.id &&
          other.name == this.name &&
          other.itemType == this.itemType &&
          other.category == this.category &&
          other.serialNumber == this.serialNumber &&
          other.codeConfiguration == this.codeConfiguration &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isArchived == this.isArchived &&
          other.archivedAt == this.archivedAt);
}

class InventoryItemsCompanion extends UpdateCompanion<InventoryItem> {
  final Value<String> id;
  final Value<String> name;
  final Value<LabItemType> itemType;
  final Value<String> category;
  final Value<String?> serialNumber;
  final Value<ItemCodeConfiguration> codeConfiguration;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isArchived;
  final Value<DateTime?> archivedAt;
  final Value<int> rowid;
  const InventoryItemsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.itemType = const Value.absent(),
    this.category = const Value.absent(),
    this.serialNumber = const Value.absent(),
    this.codeConfiguration = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InventoryItemsCompanion.insert({
    required String id,
    required String name,
    required LabItemType itemType,
    required String category,
    this.serialNumber = const Value.absent(),
    this.codeConfiguration = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.isArchived = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       itemType = Value(itemType),
       category = Value(category),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<InventoryItem> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? itemType,
    Expression<String>? category,
    Expression<String>? serialNumber,
    Expression<String>? codeConfiguration,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isArchived,
    Expression<DateTime>? archivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (itemType != null) 'item_type': itemType,
      if (category != null) 'category': category,
      if (serialNumber != null) 'serial_number': serialNumber,
      if (codeConfiguration != null) 'code_configuration': codeConfiguration,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isArchived != null) 'is_archived': isArchived,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InventoryItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<LabItemType>? itemType,
    Value<String>? category,
    Value<String?>? serialNumber,
    Value<ItemCodeConfiguration>? codeConfiguration,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? isArchived,
    Value<DateTime?>? archivedAt,
    Value<int>? rowid,
  }) {
    return InventoryItemsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      itemType: itemType ?? this.itemType,
      category: category ?? this.category,
      serialNumber: serialNumber ?? this.serialNumber,
      codeConfiguration: codeConfiguration ?? this.codeConfiguration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(
        $InventoryItemsTable.$converteritemType.toSql(itemType.value),
      );
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (serialNumber.present) {
      map['serial_number'] = Variable<String>(serialNumber.value);
    }
    if (codeConfiguration.present) {
      map['code_configuration'] = Variable<String>(
        $InventoryItemsTable.$convertercodeConfiguration.toSql(
          codeConfiguration.value,
        ),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItemsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('itemType: $itemType, ')
          ..write('category: $category, ')
          ..write('serialNumber: $serialNumber, ')
          ..write('codeConfiguration: $codeConfiguration, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isArchived: $isArchived, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InventoryItemCodesTable extends InventoryItemCodes
    with TableInfo<$InventoryItemCodesTable, InventoryItemCode> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventoryItemCodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ItemCodeRole, String> role =
      GeneratedColumn<String>(
        'role',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ItemCodeRole>($InventoryItemCodesTable.$converterrole);
  @override
  late final GeneratedColumnWithTypeConverter<ItemCodeType, String> codeType =
      GeneratedColumn<String>(
        'code_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ItemCodeType>(
        $InventoryItemCodesTable.$convertercodeType,
      );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 500,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  late final GeneratedColumnWithTypeConverter<ItemCodeSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ItemCodeSource>(
        $InventoryItemCodesTable.$convertersource,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    itemId,
    role,
    codeType,
    value,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventory_item_codes';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventoryItemCode> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {itemId, role},
  ];
  @override
  InventoryItemCode map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventoryItemCode(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      role: $InventoryItemCodesTable.$converterrole.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}role'],
        )!,
      ),
      codeType: $InventoryItemCodesTable.$convertercodeType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}code_type'],
        )!,
      ),
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      source: $InventoryItemCodesTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
    );
  }

  @override
  $InventoryItemCodesTable createAlias(String alias) {
    return $InventoryItemCodesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ItemCodeRole, String, String> $converterrole =
      const EnumNameConverter<ItemCodeRole>(ItemCodeRole.values);
  static JsonTypeConverter2<ItemCodeType, String, String> $convertercodeType =
      const EnumNameConverter<ItemCodeType>(ItemCodeType.values);
  static JsonTypeConverter2<ItemCodeSource, String, String> $convertersource =
      const EnumNameConverter<ItemCodeSource>(ItemCodeSource.values);
}

class InventoryItemCode extends DataClass
    implements Insertable<InventoryItemCode> {
  final int id;
  final String itemId;
  final ItemCodeRole role;
  final ItemCodeType codeType;
  final String value;
  final ItemCodeSource source;
  const InventoryItemCode({
    required this.id,
    required this.itemId,
    required this.role,
    required this.codeType,
    required this.value,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['item_id'] = Variable<String>(itemId);
    {
      map['role'] = Variable<String>(
        $InventoryItemCodesTable.$converterrole.toSql(role),
      );
    }
    {
      map['code_type'] = Variable<String>(
        $InventoryItemCodesTable.$convertercodeType.toSql(codeType),
      );
    }
    map['value'] = Variable<String>(value);
    {
      map['source'] = Variable<String>(
        $InventoryItemCodesTable.$convertersource.toSql(source),
      );
    }
    return map;
  }

  InventoryItemCodesCompanion toCompanion(bool nullToAbsent) {
    return InventoryItemCodesCompanion(
      id: Value(id),
      itemId: Value(itemId),
      role: Value(role),
      codeType: Value(codeType),
      value: Value(value),
      source: Value(source),
    );
  }

  factory InventoryItemCode.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventoryItemCode(
      id: serializer.fromJson<int>(json['id']),
      itemId: serializer.fromJson<String>(json['itemId']),
      role: $InventoryItemCodesTable.$converterrole.fromJson(
        serializer.fromJson<String>(json['role']),
      ),
      codeType: $InventoryItemCodesTable.$convertercodeType.fromJson(
        serializer.fromJson<String>(json['codeType']),
      ),
      value: serializer.fromJson<String>(json['value']),
      source: $InventoryItemCodesTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'itemId': serializer.toJson<String>(itemId),
      'role': serializer.toJson<String>(
        $InventoryItemCodesTable.$converterrole.toJson(role),
      ),
      'codeType': serializer.toJson<String>(
        $InventoryItemCodesTable.$convertercodeType.toJson(codeType),
      ),
      'value': serializer.toJson<String>(value),
      'source': serializer.toJson<String>(
        $InventoryItemCodesTable.$convertersource.toJson(source),
      ),
    };
  }

  InventoryItemCode copyWith({
    int? id,
    String? itemId,
    ItemCodeRole? role,
    ItemCodeType? codeType,
    String? value,
    ItemCodeSource? source,
  }) => InventoryItemCode(
    id: id ?? this.id,
    itemId: itemId ?? this.itemId,
    role: role ?? this.role,
    codeType: codeType ?? this.codeType,
    value: value ?? this.value,
    source: source ?? this.source,
  );
  InventoryItemCode copyWithCompanion(InventoryItemCodesCompanion data) {
    return InventoryItemCode(
      id: data.id.present ? data.id.value : this.id,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      role: data.role.present ? data.role.value : this.role,
      codeType: data.codeType.present ? data.codeType.value : this.codeType,
      value: data.value.present ? data.value.value : this.value,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItemCode(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('role: $role, ')
          ..write('codeType: $codeType, ')
          ..write('value: $value, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, itemId, role, codeType, value, source);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventoryItemCode &&
          other.id == this.id &&
          other.itemId == this.itemId &&
          other.role == this.role &&
          other.codeType == this.codeType &&
          other.value == this.value &&
          other.source == this.source);
}

class InventoryItemCodesCompanion extends UpdateCompanion<InventoryItemCode> {
  final Value<int> id;
  final Value<String> itemId;
  final Value<ItemCodeRole> role;
  final Value<ItemCodeType> codeType;
  final Value<String> value;
  final Value<ItemCodeSource> source;
  const InventoryItemCodesCompanion({
    this.id = const Value.absent(),
    this.itemId = const Value.absent(),
    this.role = const Value.absent(),
    this.codeType = const Value.absent(),
    this.value = const Value.absent(),
    this.source = const Value.absent(),
  });
  InventoryItemCodesCompanion.insert({
    this.id = const Value.absent(),
    required String itemId,
    required ItemCodeRole role,
    required ItemCodeType codeType,
    required String value,
    required ItemCodeSource source,
  }) : itemId = Value(itemId),
       role = Value(role),
       codeType = Value(codeType),
       value = Value(value),
       source = Value(source);
  static Insertable<InventoryItemCode> custom({
    Expression<int>? id,
    Expression<String>? itemId,
    Expression<String>? role,
    Expression<String>? codeType,
    Expression<String>? value,
    Expression<String>? source,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (itemId != null) 'item_id': itemId,
      if (role != null) 'role': role,
      if (codeType != null) 'code_type': codeType,
      if (value != null) 'value': value,
      if (source != null) 'source': source,
    });
  }

  InventoryItemCodesCompanion copyWith({
    Value<int>? id,
    Value<String>? itemId,
    Value<ItemCodeRole>? role,
    Value<ItemCodeType>? codeType,
    Value<String>? value,
    Value<ItemCodeSource>? source,
  }) {
    return InventoryItemCodesCompanion(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      role: role ?? this.role,
      codeType: codeType ?? this.codeType,
      value: value ?? this.value,
      source: source ?? this.source,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(
        $InventoryItemCodesTable.$converterrole.toSql(role.value),
      );
    }
    if (codeType.present) {
      map['code_type'] = Variable<String>(
        $InventoryItemCodesTable.$convertercodeType.toSql(codeType.value),
      );
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(
        $InventoryItemCodesTable.$convertersource.toSql(source.value),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventoryItemCodesCompanion(')
          ..write('id: $id, ')
          ..write('itemId: $itemId, ')
          ..write('role: $role, ')
          ..write('codeType: $codeType, ')
          ..write('value: $value, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }
}

abstract class _$InventoryDatabase extends GeneratedDatabase {
  _$InventoryDatabase(QueryExecutor e) : super(e);
  $InventoryDatabaseManager get managers => $InventoryDatabaseManager(this);
  late final $InventoryItemsTable inventoryItems = $InventoryItemsTable(this);
  late final $InventoryItemCodesTable inventoryItemCodes =
      $InventoryItemCodesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    inventoryItems,
    inventoryItemCodes,
  ];
}

typedef $$InventoryItemsTableCreateCompanionBuilder =
    InventoryItemsCompanion Function({
      required String id,
      required String name,
      required LabItemType itemType,
      required String category,
      Value<String?> serialNumber,
      Value<ItemCodeConfiguration> codeConfiguration,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<bool> isArchived,
      Value<DateTime?> archivedAt,
      Value<int> rowid,
    });
typedef $$InventoryItemsTableUpdateCompanionBuilder =
    InventoryItemsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<LabItemType> itemType,
      Value<String> category,
      Value<String?> serialNumber,
      Value<ItemCodeConfiguration> codeConfiguration,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<bool> isArchived,
      Value<DateTime?> archivedAt,
      Value<int> rowid,
    });

class $$InventoryItemsTableFilterComposer
    extends Composer<_$InventoryDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<LabItemType, LabItemType, String>
  get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<
    ItemCodeConfiguration,
    ItemCodeConfiguration,
    String
  >
  get codeConfiguration => $composableBuilder(
    column: $table.codeConfiguration,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InventoryItemsTableOrderingComposer
    extends Composer<_$InventoryDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codeConfiguration => $composableBuilder(
    column: $table.codeConfiguration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InventoryItemsTableAnnotationComposer
    extends Composer<_$InventoryDatabase, $InventoryItemsTable> {
  $$InventoryItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<LabItemType, String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get serialNumber => $composableBuilder(
    column: $table.serialNumber,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ItemCodeConfiguration, String>
  get codeConfiguration => $composableBuilder(
    column: $table.codeConfiguration,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );
}

class $$InventoryItemsTableTableManager
    extends
        RootTableManager<
          _$InventoryDatabase,
          $InventoryItemsTable,
          InventoryItem,
          $$InventoryItemsTableFilterComposer,
          $$InventoryItemsTableOrderingComposer,
          $$InventoryItemsTableAnnotationComposer,
          $$InventoryItemsTableCreateCompanionBuilder,
          $$InventoryItemsTableUpdateCompanionBuilder,
          (
            InventoryItem,
            BaseReferences<
              _$InventoryDatabase,
              $InventoryItemsTable,
              InventoryItem
            >,
          ),
          InventoryItem,
          PrefetchHooks Function()
        > {
  $$InventoryItemsTableTableManager(
    _$InventoryDatabase db,
    $InventoryItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<LabItemType> itemType = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> serialNumber = const Value.absent(),
                Value<ItemCodeConfiguration> codeConfiguration =
                    const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoryItemsCompanion(
                id: id,
                name: name,
                itemType: itemType,
                category: category,
                serialNumber: serialNumber,
                codeConfiguration: codeConfiguration,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isArchived: isArchived,
                archivedAt: archivedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required LabItemType itemType,
                required String category,
                Value<String?> serialNumber = const Value.absent(),
                Value<ItemCodeConfiguration> codeConfiguration =
                    const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> isArchived = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventoryItemsCompanion.insert(
                id: id,
                name: name,
                itemType: itemType,
                category: category,
                serialNumber: serialNumber,
                codeConfiguration: codeConfiguration,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isArchived: isArchived,
                archivedAt: archivedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InventoryItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$InventoryDatabase,
      $InventoryItemsTable,
      InventoryItem,
      $$InventoryItemsTableFilterComposer,
      $$InventoryItemsTableOrderingComposer,
      $$InventoryItemsTableAnnotationComposer,
      $$InventoryItemsTableCreateCompanionBuilder,
      $$InventoryItemsTableUpdateCompanionBuilder,
      (
        InventoryItem,
        BaseReferences<
          _$InventoryDatabase,
          $InventoryItemsTable,
          InventoryItem
        >,
      ),
      InventoryItem,
      PrefetchHooks Function()
    >;
typedef $$InventoryItemCodesTableCreateCompanionBuilder =
    InventoryItemCodesCompanion Function({
      Value<int> id,
      required String itemId,
      required ItemCodeRole role,
      required ItemCodeType codeType,
      required String value,
      required ItemCodeSource source,
    });
typedef $$InventoryItemCodesTableUpdateCompanionBuilder =
    InventoryItemCodesCompanion Function({
      Value<int> id,
      Value<String> itemId,
      Value<ItemCodeRole> role,
      Value<ItemCodeType> codeType,
      Value<String> value,
      Value<ItemCodeSource> source,
    });

class $$InventoryItemCodesTableFilterComposer
    extends Composer<_$InventoryDatabase, $InventoryItemCodesTable> {
  $$InventoryItemCodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ItemCodeRole, ItemCodeRole, String> get role =>
      $composableBuilder(
        column: $table.role,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<ItemCodeType, ItemCodeType, String>
  get codeType => $composableBuilder(
    column: $table.codeType,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ItemCodeSource, ItemCodeSource, String>
  get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$InventoryItemCodesTableOrderingComposer
    extends Composer<_$InventoryDatabase, $InventoryItemCodesTable> {
  $$InventoryItemCodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codeType => $composableBuilder(
    column: $table.codeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InventoryItemCodesTableAnnotationComposer
    extends Composer<_$InventoryDatabase, $InventoryItemCodesTable> {
  $$InventoryItemCodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ItemCodeRole, String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ItemCodeType, String> get codeType =>
      $composableBuilder(column: $table.codeType, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ItemCodeSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);
}

class $$InventoryItemCodesTableTableManager
    extends
        RootTableManager<
          _$InventoryDatabase,
          $InventoryItemCodesTable,
          InventoryItemCode,
          $$InventoryItemCodesTableFilterComposer,
          $$InventoryItemCodesTableOrderingComposer,
          $$InventoryItemCodesTableAnnotationComposer,
          $$InventoryItemCodesTableCreateCompanionBuilder,
          $$InventoryItemCodesTableUpdateCompanionBuilder,
          (
            InventoryItemCode,
            BaseReferences<
              _$InventoryDatabase,
              $InventoryItemCodesTable,
              InventoryItemCode
            >,
          ),
          InventoryItemCode,
          PrefetchHooks Function()
        > {
  $$InventoryItemCodesTableTableManager(
    _$InventoryDatabase db,
    $InventoryItemCodesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InventoryItemCodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InventoryItemCodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InventoryItemCodesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<ItemCodeRole> role = const Value.absent(),
                Value<ItemCodeType> codeType = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<ItemCodeSource> source = const Value.absent(),
              }) => InventoryItemCodesCompanion(
                id: id,
                itemId: itemId,
                role: role,
                codeType: codeType,
                value: value,
                source: source,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String itemId,
                required ItemCodeRole role,
                required ItemCodeType codeType,
                required String value,
                required ItemCodeSource source,
              }) => InventoryItemCodesCompanion.insert(
                id: id,
                itemId: itemId,
                role: role,
                codeType: codeType,
                value: value,
                source: source,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InventoryItemCodesTableProcessedTableManager =
    ProcessedTableManager<
      _$InventoryDatabase,
      $InventoryItemCodesTable,
      InventoryItemCode,
      $$InventoryItemCodesTableFilterComposer,
      $$InventoryItemCodesTableOrderingComposer,
      $$InventoryItemCodesTableAnnotationComposer,
      $$InventoryItemCodesTableCreateCompanionBuilder,
      $$InventoryItemCodesTableUpdateCompanionBuilder,
      (
        InventoryItemCode,
        BaseReferences<
          _$InventoryDatabase,
          $InventoryItemCodesTable,
          InventoryItemCode
        >,
      ),
      InventoryItemCode,
      PrefetchHooks Function()
    >;

class $InventoryDatabaseManager {
  final _$InventoryDatabase _db;
  $InventoryDatabaseManager(this._db);
  $$InventoryItemsTableTableManager get inventoryItems =>
      $$InventoryItemsTableTableManager(_db, _db.inventoryItems);
  $$InventoryItemCodesTableTableManager get inventoryItemCodes =>
      $$InventoryItemCodesTableTableManager(_db, _db.inventoryItemCodes);
}
