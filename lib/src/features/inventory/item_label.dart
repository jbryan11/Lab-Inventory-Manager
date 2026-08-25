import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../data/inventory_database.dart';
import '../../domain/inventory_enums.dart';

class ItemLabel extends StatelessWidget {
  const ItemLabel({super.key, required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (item.codeType == ItemCodeType.qr)
              QrImageView(
                data: item.codeValue,
                size: 180,
                backgroundColor: Colors.white,
              )
            else
              BarcodeWidget(
                barcode: Barcode.code128(),
                data: item.codeValue,
                width: 280,
                height: 120,
                color: Colors.black,
                backgroundColor: Colors.white,
                drawText: true,
                errorBuilder: (context, error) =>
                    Text(error, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 8),
            Text(
              'ID: ${item.id}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
