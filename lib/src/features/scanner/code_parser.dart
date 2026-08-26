import '../../domain/inventory_enums.dart';

class ParsedCode {
  const ParsedCode({required this.value, this.role});

  final String value;
  final ItemCodeRole? role;
}

ParsedCode? parseScannedCode(String? rawValue) {
  final raw = rawValue?.trim() ?? '';
  if (raw.isEmpty) return null;
  if (RegExp(
    r'^\(?\s*1[PT]\s*\)?\s*[:\-]?\s*$',
    caseSensitive: false,
  ).hasMatch(raw)) {
    return null;
  }

  final match = RegExp(
    r'^\(?\s*(1P|1T)\s*\)?\s*[:\-]?\s*(.+)$',
    caseSensitive: false,
  ).firstMatch(raw);
  if (match == null) return ParsedCode(value: raw);

  final value = match.group(2)!.trim();
  if (value.isEmpty) return null;
  return ParsedCode(
    value: value,
    role: match.group(1)!.toUpperCase() == '1P'
        ? ItemCodeRole.package1P
        : ItemCodeRole.package1T,
  );
}
