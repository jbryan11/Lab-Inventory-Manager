enum LabItemType { tool, equipment, utility }

extension LabItemTypeLabel on LabItemType {
  String get label => switch (this) {
    LabItemType.tool => 'Tool',
    LabItemType.equipment => 'Equipment',
    LabItemType.utility => 'Utility',
  };
}

enum ItemCodeType { qr, code128, ean13, ean8, upcA, upcE, dataMatrix, unknown }

extension ItemCodeTypeLabel on ItemCodeType {
  String get label => switch (this) {
    ItemCodeType.qr => 'QR code',
    ItemCodeType.code128 => 'Code 128',
    ItemCodeType.ean13 => 'EAN-13',
    ItemCodeType.ean8 => 'EAN-8',
    ItemCodeType.upcA => 'UPC-A',
    ItemCodeType.upcE => 'UPC-E',
    ItemCodeType.dataMatrix => 'Data Matrix',
    ItemCodeType.unknown => 'Other code',
  };
}

enum ItemCodeSource { scanned, generated }
