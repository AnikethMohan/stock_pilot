/// Product add/edit form with dynamic metadata fields.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/features/inventory/domain/entities/product.dart';
import 'package:stock_pilot/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:stock_pilot/features/inventory/presentation/bloc/inventory_event.dart';

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, this.product});
  final Product? product;

  bool get isEditing => product != null;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _skuCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _moreDescriptionCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _thresholdCtrl;
  late final TextEditingController _aisleCtrl;
  late final TextEditingController _shelfCtrl;
  late final TextEditingController _binCtrl;
  late UnitOfMeasure _selectedUnit;
  late List<_MetaRow> _metaRows;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _skuCtrl = TextEditingController(text: p?.sku ?? '');
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _brandCtrl = TextEditingController(text: p?.brand ?? '');
    _categoryCtrl = TextEditingController(text: p?.category ?? '');
    _moreDescriptionCtrl = TextEditingController(
      text: p?.moreDescription ?? '',
    );
    _descriptionCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl = TextEditingController(
      text: p != null ? p.unitPrice.toString() : '0.00',
    );
    _qtyCtrl = TextEditingController(
      text: p != null ? p.quantityOnHand.toString() : '0',
    );
    _thresholdCtrl = TextEditingController(
      text: p != null ? p.lowStockThreshold.toString() : '10',
    );
    _aisleCtrl = TextEditingController(text: p?.locationAisle ?? '');
    _shelfCtrl = TextEditingController(text: p?.locationShelf ?? '');
    _binCtrl = TextEditingController(text: p?.locationBin ?? '');
    _selectedUnit = p?.unitOfMeasure ?? UnitOfMeasure.pieces;
    _metaRows =
        p?.metadata
            .map(
              (m) => _MetaRow(
                keyCtrl: TextEditingController(text: m.key),
                valueCtrl: TextEditingController(text: m.value),
              ),
            )
            .toList() ??
        [];
  }

  @override
  void dispose() {
    _skuCtrl.dispose();
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _categoryCtrl.dispose();
    _moreDescriptionCtrl.dispose();
    _descriptionCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _thresholdCtrl.dispose();
    _aisleCtrl.dispose();
    _shelfCtrl.dispose();
    _binCtrl.dispose();
    for (final m in _metaRows) {
      m.keyCtrl.dispose();
      m.valueCtrl.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final metadata = _metaRows
        .where((m) => m.keyCtrl.text.trim().isNotEmpty)
        .map(
          (m) => ProductMetadata(
            key: m.keyCtrl.text.trim(),
            value: m.valueCtrl.text.trim(),
          ),
        )
        .toList();

    final product = Product(
      id: widget.product?.id,
      sku: _skuCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      brand: _brandCtrl.text.trim(),
      category: _categoryCtrl.text.trim(),
      moreDescription: _moreDescriptionCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      unitPrice: double.tryParse(_priceCtrl.text) ?? 0.0,
      quantityOnHand: double.tryParse(_qtyCtrl.text) ?? 0.0,
      unitOfMeasure: _selectedUnit,
      lowStockThreshold: double.tryParse(_thresholdCtrl.text) ?? 10.0,
      locationAisle: _aisleCtrl.text.trim(),
      locationShelf: _shelfCtrl.text.trim(),
      locationBin: _binCtrl.text.trim(),
      metadata: metadata,
    );

    if (widget.isEditing) {
      context.read<InventoryBloc>().add(UpdateProduct(product));
    } else {
      context.read<InventoryBloc>().add(AddProduct(product));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Product' : 'New Product'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SectionHeader('Basic Information'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _skuCtrl,
                    decoration: const InputDecoration(labelText: 'SKU *'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                    enabled: !widget.isEditing,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Product Name *',
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _brandCtrl,
                    decoration: const InputDecoration(labelText: 'Brand'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _categoryCtrl,
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _moreDescriptionCtrl,
              decoration: const InputDecoration(labelText: 'More Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            _SectionHeader('Stock & Pricing'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceCtrl,
                    decoration: const InputDecoration(labelText: 'Unit Price'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _qtyCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Quantity on Hand',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<UnitOfMeasure>(
                    initialValue: _selectedUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit of Measure',
                    ),
                    items: UnitOfMeasure.values
                        .map(
                          (u) =>
                              DropdownMenuItem(value: u, child: Text(u.label)),
                        )
                        .toList(),
                    onChanged: (v) => setState(
                      () => _selectedUnit = v ?? UnitOfMeasure.pieces,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _thresholdCtrl,
              decoration: const InputDecoration(
                labelText: 'Low Stock Threshold',
              ),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 24),
            _SectionHeader('Physical Location'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _aisleCtrl,
                    decoration: const InputDecoration(labelText: 'Aisle'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _shelfCtrl,
                    decoration: const InputDecoration(labelText: 'Shelf'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _binCtrl,
                    decoration: const InputDecoration(labelText: 'Bin'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _SectionHeader('Custom Attributes'),
            const SizedBox(height: 12),
            ..._metaRows.asMap().entries.map((entry) {
              final i = entry.key;
              final m = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: m.keyCtrl,
                        decoration: const InputDecoration(labelText: 'Key'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: m.valueCtrl,
                        decoration: const InputDecoration(labelText: 'Value'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => setState(() => _metaRows.removeAt(i)),
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: () => setState(
                () => _metaRows.add(
                  _MetaRow(
                    keyCtrl: TextEditingController(),
                    valueCtrl: TextEditingController(),
                  ),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Attribute'),
            ),

            const SizedBox(height: 32),
            FilledButton(
              onPressed: _submit,
              child: Text(widget.isEditing ? 'Save Changes' : 'Create Product'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _MetaRow {
  _MetaRow({required this.keyCtrl, required this.valueCtrl});
  final TextEditingController keyCtrl;
  final TextEditingController valueCtrl;
}
