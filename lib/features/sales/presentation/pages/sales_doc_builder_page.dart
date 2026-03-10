/// Sales Document Builder page — unified interface for creating quotations,
/// delivery notes, and invoices with per-item discount and tax.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/core/theme/app_theme.dart';
import 'package:stock_pilot/core/utils/adaptive_layout.dart';
import 'package:stock_pilot/features/inventory/domain/entities/product.dart';
import 'package:stock_pilot/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:stock_pilot/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:stock_pilot/features/inventory/presentation/bloc/inventory_event.dart';
import 'package:stock_pilot/features/sales/domain/entities/customer.dart';
import 'package:stock_pilot/features/sales/domain/entities/sales_document.dart';
import 'package:stock_pilot/features/sales/presentation/pages/customer_list_page.dart';
import 'package:stock_pilot/features/sales/presentation/bloc/sales_doc_bloc.dart';
import 'package:stock_pilot/features/sales/presentation/bloc/sales_doc_event.dart';
import 'package:stock_pilot/features/sales/presentation/bloc/sales_doc_state.dart';
import 'package:stock_pilot/features/settings/presentation/bloc/settings_bloc.dart';

class SalesDocBuilderPage extends StatefulWidget {
  const SalesDocBuilderPage({super.key, this.document, this.initialType});

  final SalesDocument? document;
  final DocType? initialType;

  @override
  State<SalesDocBuilderPage> createState() => _SalesDocBuilderPageState();
}

class _SalesDocBuilderPageState extends State<SalesDocBuilderPage> {
  TextEditingController? _autoCompleteController;

  @override
  void initState() {
    super.initState();
    if (widget.document != null) {
      context.read<SalesDocBloc>().add(
        StartNewDocument(existing: widget.document),
      );
    } else {
      context.read<SalesDocBloc>().add(
        StartNewDocument(type: widget.initialType ?? DocType.invoice),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Sales Document')),
      body: BlocConsumer<SalesDocBloc, SalesDocState>(
        listener: (context, state) {
          if (state is SalesDocError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.error,
              ),
            );
          } else if (state is SalesDocConfirmed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${state.doc.docType.label} Confirmed!'),
                backgroundColor: AppTheme.success,
              ),
            );
            context.read<InventoryBloc>().add(const LoadProducts());
            Navigator.of(context).pop(state.doc);
          } else if (state is SalesDocSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Draft Saved!'),
                backgroundColor: AppTheme.success,
              ),
            );
            Navigator.of(context).pop(state.doc);
          }
        },
        builder: (context, state) {
          if (state is SalesDocLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final settingsState = context.watch<SettingsBloc>().state;
          final currencySymbol = settingsState is SettingsLoaded
              ? settingsState.currencySymbol
              : '\$';
          final currencyFormat = NumberFormat.currency(
            symbol: currencySymbol,
            decimalDigits: 2,
          );

          if (state is SalesDocBuilding ||
              state is SalesDocSaving ||
              state is SalesDocError) {
            SalesDocument? doc;
            if (state is SalesDocBuilding) doc = state.activeDoc;
            if (state is SalesDocSaving) doc = state.activeDoc;
            if (state is SalesDocError) doc = state.activeDoc;

            if (doc == null) {
              return const Center(child: Text('Failed to load draft'));
            }

            return AdaptiveLayout.isWideScreen(
                  MediaQuery.of(context).size.width,
                )
                ? _buildDesktopLayout(
                    doc,
                    state is SalesDocSaving,
                    currencyFormat,
                  )
                : _buildMobileLayout(
                    doc,
                    state is SalesDocSaving,
                    currencyFormat,
                  );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ─── Layout Builders ─────────────────────────────────────────────

  Widget _buildDesktopLayout(
    SalesDocument doc,
    bool isSaving,
    NumberFormat currencyFormat,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDocTypeSelector(doc),
                const SizedBox(height: 16),
                _buildProductSearch(doc),
                const SizedBox(height: 16),
                Expanded(child: _buildLineItemsTable(doc, currencyFormat)),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: _buildSummaryPane(doc, isSaving, currencyFormat),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    SalesDocument doc,
    bool isSaving,
    NumberFormat currencyFormat,
  ) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDocTypeSelector(doc),
                const SizedBox(height: 16),
                _buildSummaryPane(doc, isSaving, currencyFormat),
                const Divider(height: 32),
                _buildProductSearch(doc),
                const SizedBox(height: 16),
                _buildLineItemsList(doc, currencyFormat),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Document Type Selector ──────────────────────────────────────

  Widget _buildDocTypeSelector(SalesDocument doc) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Document Type',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            SegmentedButton<DocType>(
              segments: DocType.values.map((type) {
                return ButtonSegment<DocType>(
                  value: type,
                  label: Text(type.label),
                  icon: Icon(_getDocTypeIcon(type)),
                );
              }).toList(),
              selected: {doc.docType},
              onSelectionChanged: (newSelection) {
                if (newSelection.first != doc.docType) {
                  context.read<SalesDocBloc>().add(
                    SetDocType(newSelection.first),
                  );
                }
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return AppTheme.highlight.withValues(alpha: 0.2);
                  }
                  return null;
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDocTypeIcon(DocType type) {
    return switch (type) {
      DocType.quotation => Icons.description_outlined,
      DocType.deliveryNote => Icons.local_shipping_outlined,
      DocType.invoice => Icons.receipt_long_outlined,
    };
  }

  // ─── Product Search ──────────────────────────────────────────────

  Widget _buildProductSearch(SalesDocument doc) {
    return Autocomplete<Product>(
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<Product>.empty();
        }
        try {
          final repo = context.read<InventoryRepository>();
          final products = await repo.getProducts(
            searchQuery: textEditingValue.text,
            limit: 20,
          );
          return products;
        } catch (_) {
          return const Iterable<Product>.empty();
        }
      },
      displayStringForOption: (Product option) =>
          '${option.name} (${option.sku})',
      onSelected: (Product selection) {
        context.read<SalesDocBloc>().add(AddDocItem(product: selection));
        _autoCompleteController?.clear();
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        _autoCompleteController = controller;
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Search Product by Name or SKU',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (_) => onFieldSubmitted(),
        );
      },
    );
  }

  // ─── Line Items Table (Desktop) ──────────────────────────────────

  Widget _buildLineItemsTable(SalesDocument doc, NumberFormat currencyFormat) {
    final isDeliveryNote = doc.docType == DocType.deliveryNote;

    if (doc.items.isEmpty) {
      return Center(
        child: Text(
          'No items added. Search for products above.',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.white54),
        ),
      );
    }

    return Card(
      child: ListView(
        children: [
          DataTable(
            columnSpacing: 16,
            columns: [
              const DataColumn(label: Text('Item')),
              const DataColumn(label: Text('Qty')),
              if (!isDeliveryNote) ...[
                const DataColumn(label: Text('Price')),
                const DataColumn(label: Text('Disc %')),
                const DataColumn(label: Text('Tax %')),
                const DataColumn(label: Text('Total')),
              ],
              const DataColumn(label: Text('')),
            ],
            rows: doc.items.map((item) {
              return DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 140,
                      child: Text(
                        item.productName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 100,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () {
                              context.read<SalesDocBloc>().add(
                                UpdateItemQuantity(
                                  sku: item.sku,
                                  quantity: item.quantity - 1,
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.remove_circle_outline,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 40,
                            child: TextField(
                              controller: TextEditingController(
                                text: item.quantity % 1 == 0
                                    ? item.quantity.toInt().toString()
                                    : item.quantity.toString(),
                              ),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 6,
                                ),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (val) {
                                final qty = double.tryParse(val);
                                if (qty != null) {
                                  context.read<SalesDocBloc>().add(
                                    UpdateItemQuantity(
                                      sku: item.sku,
                                      quantity: qty,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              context.read<SalesDocBloc>().add(
                                UpdateItemQuantity(
                                  sku: item.sku,
                                  quantity: item.quantity + 1,
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.add_circle_outline,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isDeliveryNote) ...[
                    DataCell(
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: TextEditingController(
                            text: item.unitPrice.toStringAsFixed(2),
                          ),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (val) {
                            final price = double.tryParse(val);
                            if (price != null) {
                              context.read<SalesDocBloc>().add(
                                UpdateItemPrice(sku: item.sku, price: price),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: TextEditingController(
                            text: item.discountPercent > 0
                                ? item.discountPercent.toStringAsFixed(1)
                                : '',
                          ),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: '0',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (val) {
                            final disc = double.tryParse(val) ?? 0.0;
                            context.read<SalesDocBloc>().add(
                              UpdateItemDiscount(
                                sku: item.sku,
                                discountPercent: disc,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: TextEditingController(
                            text: item.taxPercent > 0
                                ? item.taxPercent.toStringAsFixed(1)
                                : '',
                          ),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            isDense: true,
                            hintText: '0',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (val) {
                            final tax = double.tryParse(val) ?? 0.0;
                            context.read<SalesDocBloc>().add(
                              UpdateItemTax(sku: item.sku, taxPercent: tax),
                            );
                          },
                        ),
                      ),
                    ),
                    DataCell(Text(currencyFormat.format(item.lineTotal))),
                  ],
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppTheme.error),
                      onPressed: () {
                        context.read<SalesDocBloc>().add(
                          RemoveDocItem(item.sku),
                        );
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Line Items List (Mobile) ────────────────────────────────────

  Widget _buildLineItemsList(SalesDocument doc, NumberFormat currencyFormat) {
    final isDeliveryNote = doc.docType == DocType.deliveryNote;

    if (doc.items.isEmpty) {
      return const Text(
        'No items added.',
        style: TextStyle(color: Colors.white54),
      );
    }

    return Column(
      children: doc.items.map((item) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        color: AppTheme.error,
                        size: 20,
                      ),
                      onPressed: () => context.read<SalesDocBloc>().add(
                        RemoveDocItem(item.sku),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Quantity
                    Expanded(
                      child: _buildMobileField(
                        'Qty',
                        item.quantity % 1 == 0
                            ? item.quantity.toInt().toString()
                            : item.quantity.toString(),
                        (val) {
                          final qty = double.tryParse(val);
                          if (qty != null) {
                            context.read<SalesDocBloc>().add(
                              UpdateItemQuantity(sku: item.sku, quantity: qty),
                            );
                          }
                        },
                      ),
                    ),
                    if (!isDeliveryNote) ...[
                      const SizedBox(width: 8),
                      // Price
                      Expanded(
                        child: _buildMobileField(
                          'Price',
                          item.unitPrice.toStringAsFixed(2),
                          (val) {
                            final price = double.tryParse(val);
                            if (price != null) {
                              context.read<SalesDocBloc>().add(
                                UpdateItemPrice(sku: item.sku, price: price),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Discount %
                      Expanded(
                        child: _buildMobileField(
                          'Disc %',
                          item.discountPercent > 0
                              ? item.discountPercent.toStringAsFixed(1)
                              : '',
                          (val) {
                            final disc = double.tryParse(val) ?? 0.0;
                            context.read<SalesDocBloc>().add(
                              UpdateItemDiscount(
                                sku: item.sku,
                                discountPercent: disc,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Tax %
                      Expanded(
                        child: _buildMobileField(
                          'Tax %',
                          item.taxPercent > 0
                              ? item.taxPercent.toStringAsFixed(1)
                              : '',
                          (val) {
                            final tax = double.tryParse(val) ?? 0.0;
                            context.read<SalesDocBloc>().add(
                              UpdateItemTax(sku: item.sku, taxPercent: tax),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                if (!isDeliveryNote) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Total: ${currencyFormat.format(item.lineTotal)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMobileField(
    String label,
    String value,
    ValueChanged<String> onSubmitted,
  ) {
    return TextField(
      controller: TextEditingController(text: value),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      onSubmitted: onSubmitted,
    );
  }

  // ─── Summary Pane ────────────────────────────────────────────────

  Widget _buildSummaryPane(
    SalesDocument doc,
    bool isSaving,
    NumberFormat currencyFormat,
  ) {
    final isDeliveryNote = doc.docType == DocType.deliveryNote;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Document header
            Row(
              children: [
                Icon(_getDocTypeIcon(doc.docType), color: AppTheme.highlight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${doc.docType.label}: ${doc.docNumber}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),

            // Source document reference
            if (doc.sourceDocNumber != null) ...[
              const SizedBox(height: 4),
              Text(
                'Converted from: ${doc.sourceDocNumber}',
                style: TextStyle(
                  color: AppTheme.highlight.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],

            const Divider(height: 24),

            // Customer Selector
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person),
              title: Text(doc.customer?.name ?? 'Select Customer'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final bloc = context.read<SalesDocBloc>();
                final selected = await Navigator.push<Customer>(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const CustomerListPage(isSelectionMode: true),
                  ),
                );
                if (selected != null && mounted) {
                  bloc.add(SelectCustomer(selected));
                }
              },
            ),
            const Divider(height: 24),

            // Summary Totals (hide for delivery notes)
            if (!isDeliveryNote) ...[
              _buildSummaryRow('Subtotal:', doc.subtotal, currencyFormat),
              const SizedBox(height: 8),
              _buildSummaryRow(
                'Discount:',
                -doc.discountAmount,
                currencyFormat,
              ),
              const SizedBox(height: 8),
              _buildSummaryRow('Tax:', doc.taxAmount, currencyFormat),
              const Divider(height: 24),
              _buildSummaryRow(
                'Grand Total:',
                doc.grandTotal,
                currencyFormat,
                isBold: true,
              ),
            ] else ...[
              Text(
                '${doc.items.length} item(s) for delivery',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Draft'),
                    onPressed: isSaving
                        ? null
                        : () {
                            context.read<SalesDocBloc>().add(const SaveDraft());
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(
                      isSaving
                          ? 'Processing...'
                          : 'Confirm ${doc.docType.label}',
                    ),
                    onPressed: isSaving || doc.items.isEmpty
                        ? null
                        : () {
                            context.read<SalesDocBloc>().add(
                              const ConfirmDocument(),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double value,
    NumberFormat currencyFormat, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 14,
          ),
        ),
        Text(
          currencyFormat.format(value),
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 18 : 14,
            color: isBold ? AppTheme.highlight : null,
          ),
        ),
      ],
    );
  }
}
