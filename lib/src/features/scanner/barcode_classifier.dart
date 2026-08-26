import 'package:mobile_scanner/mobile_scanner.dart';

import '../../domain/inventory_enums.dart';
import 'code_parser.dart';

/// Represents a classified barcode with its detected role.
class ClassifiedBarcode {
  const ClassifiedBarcode({
    required this.barcode,
    required this.parsed,
    this.role,
  });

  final Barcode barcode;
  final ParsedCode parsed;
  final ItemCodeRole? role;
}

/// Classifies barcodes detected in a single frame and determines their roles.
class BarcodeClassifier {
  /// Classifies barcodes from a single detection frame.
  ///
  /// For single-code scenarios, returns the parsed code without role assignment.
  /// Returns null if no valid barcodes are found.
  static List<ClassifiedBarcode> classify(BarcodeCapture capture) {
    return capture.barcodes
        .map(
          (barcode) => ClassifiedBarcode(
            barcode: barcode,
            parsed: parseScannedCode(barcode.rawValue),
            role: _roleFromClassifier(barcode.rawValue),
          ),
        )
        .where((e) => e.parsed != null)
        .toList();
  }

  /// Assigns 1P/1T roles to two unclassified barcodes by vertical position.
  ///
  /// Strategy: Top barcode → 1P, bottom barcode → 1T (standard label layout).
  /// Returns null if fewer than 2 barcodes provided.
  static ({
    ClassifiedBarcode package1P,
    ClassifiedBarcode package1T,
  })? assignPackageRolesByPosition(List<ClassifiedBarcode> unclassified) {
    if (unclassified.length < 2) return null;

    final sorted = List<ClassifiedBarcode>.from(unclassified);
    sorted.sort((a, b) {
      final ay = _barcodeY(a.barcode);
      final by = _barcodeY(b.barcode);
      if (ay == null && by == null) return 0;
      if (ay == null) return 1;
      if (by == null) return -1;
      return ay.compareTo(by);
    });

    return (
      package1P: sorted[0],
      package1T: sorted[1],
    );
  }

  /// Attempts to find both 1P and 1T roles from classifiers and position.
  ///
  /// Returns a record with assigned roles, or null if unable to resolve.
  static ({
    ClassifiedBarcode package1P,
    ClassifiedBarcode package1T,
  })? resolveMixedRoles(
    ClassifiedBarcode? classified1P,
    ClassifiedBarcode? classified1T,
    List<ClassifiedBarcode> unclassified,
  ) {
    // Both roles identified from classifiers.
    if (classified1P != null && classified1T != null) {
      return (package1P: classified1P, package1T: classified1T);
    }

    // One role from classifier, one from unclassified.
    if (classified1P != null && unclassified.length == 1) {
      return (package1P: classified1P, package1T: unclassified.first);
    }
    if (classified1T != null && unclassified.length == 1) {
      return (package1P: unclassified.first, package1T: classified1T);
    }

    // Try position-based assignment on unclassified only.
    if (classified1P == null && classified1T == null) {
      return assignPackageRolesByPosition(unclassified);
    }

    return null;
  }

  /// Extracts the role from a barcode's raw value (e.g., GS1-128 classifier).
  static ItemCodeRole? _roleFromClassifier(String? value) {
    if (value == null) return null;
    if (value.startsWith('(01)')) return ItemCodeRole.package1P;
    if (value.startsWith('(21)')) return ItemCodeRole.package1T;
    return null;
  }

  /// Returns the vertical centre of a barcode's bounding box (0.0 = top).
  /// Returns null if positional data is unavailable.
  static double? _barcodeY(Barcode barcode) {
    final corners = barcode.corners;
    if (corners.isEmpty) return null;
    final totalY = corners.fold<double>(0, (sum, p) => sum + p.dy);
    return totalY / corners.length;
  }
}
