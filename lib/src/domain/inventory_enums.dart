enum LabItemType { tool, equipment, utility }

extension LabItemTypeLabel on LabItemType {
  String get label => switch (this) {
    LabItemType.tool => 'Tool',
    LabItemType.equipment => 'Equipment',
    LabItemType.utility => 'Utility',
  };
}

enum ItemCodeType {
  qr,
  code128,
  code39,
  code93,
  codabar,
  ean13,
  ean8,
  upcA,
  upcE,
  dataMatrix,
  itf,
  pdf417,
  aztec,
  unknown,
}

extension ItemCodeTypeLabel on ItemCodeType {
  String get label => switch (this) {
    ItemCodeType.qr => 'QR code',
    ItemCodeType.code128 => 'Code 128',
    ItemCodeType.code39 => 'Code 39',
    ItemCodeType.code93 => 'Code 93',
    ItemCodeType.codabar => 'Codabar',
    ItemCodeType.ean13 => 'EAN-13',
    ItemCodeType.ean8 => 'EAN-8',
    ItemCodeType.upcA => 'UPC-A',
    ItemCodeType.upcE => 'UPC-E',
    ItemCodeType.dataMatrix => 'Data Matrix',
    ItemCodeType.itf => 'ITF',
    ItemCodeType.pdf417 => 'PDF417',
    ItemCodeType.aztec => 'Aztec',
    ItemCodeType.unknown => 'Other code',
  };
}

enum ItemCodeSource { scanned, generated }

enum ItemCodeRole { item, package1P, package1T }

extension ItemCodeRoleLabel on ItemCodeRole {
  String get label => switch (this) {
    ItemCodeRole.item => 'Item code',
    ItemCodeRole.package1P => 'Package 1P',
    ItemCodeRole.package1T => 'Package 1T',
  };
}

enum ItemCodeConfiguration { itemOnly, packageAndItem }

extension ItemCodeConfigurationLabel on ItemCodeConfiguration {
  String get label => switch (this) {
    ItemCodeConfiguration.itemOnly => 'Item code only',
    ItemCodeConfiguration.packageAndItem => 'Package + item codes',
  };
}
