/// Stock adjustment dialog — select reason, quantity, and notes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:stock_pilot/features/inventory/presentation/bloc/inventory_event.dart';

class StockAdjustDialog extends StatefulWidget {
  const StockAdjustDialog({
    super.key,
    required this.productId,
    required this.sku,
  });

  final int productId;
  final String sku;

  @override
  State<StockAdjustDialog> createState() => _StockAdjustDialogState();
}

class _StockAdjustDialogState extends State<StockAdjustDialog> {
  final _qtyCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  TransactionReason _reason = TransactionReason.restock;
  bool _isNegative = false;

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Adjust Stock — ${widget.sku}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<TransactionReason>(
              initialValue: _reason,
              decoration: const InputDecoration(labelText: 'Reason'),
              items: TransactionReason.values
                  .where((r) => r != TransactionReason.csvImport)
                  .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _reason = v ?? TransactionReason.restock;
                  _isNegative =
                      _reason == TransactionReason.sale ||
                      _reason == TransactionReason.damage;
                });
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _qtyCtrl,
              decoration: InputDecoration(
                labelText: 'Quantity',
                prefixText: _isNegative ? '- ' : '+ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final rawQty = double.tryParse(_qtyCtrl.text) ?? 0;
            if (rawQty == 0) return;
            final change = _isNegative ? -rawQty : rawQty;
            context.read<InventoryBloc>().add(
              AdjustStock(
                productId: widget.productId,
                changeAmount: change,
                reason: _reason,
                notes: _notesCtrl.text.trim(),
              ),
            );
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
