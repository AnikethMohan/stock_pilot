/// Product list page — adaptive DataTable (desktop) / ListView (mobile).
library;

import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stock_pilot/core/theme/app_theme.dart';
import 'package:stock_pilot/core/utils/adaptive_layout.dart';
import 'package:stock_pilot/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:stock_pilot/features/inventory/presentation/bloc/inventory_event.dart';
import 'package:stock_pilot/features/inventory/presentation/bloc/inventory_state.dart';
import 'package:stock_pilot/features/inventory/presentation/pages/product_form_page.dart';
import 'package:stock_pilot/features/inventory/presentation/widgets/stock_adjust_dialog.dart';
import 'package:stock_pilot/features/settings/presentation/bloc/settings_bloc.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String? _selectedProductGroup;
  bool _lowStockOnly = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<InventoryBloc>().add(const LoadMoreProducts());
    }
  }

  void _applyFilters() {
    context.read<InventoryBloc>().add(
      LoadProducts(
        searchQuery: _searchController.text.isEmpty
            ? null
            : _searchController.text,
        productGroup: _selectedProductGroup,
        lowStockOnly: _lowStockOnly ? true : null,
      ),
    );
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result == null || result.files.isEmpty) return;
    final file = File(result.files.first.path!);
    final content = await file.readAsString();
    if (mounted) {
      context.read<InventoryBloc>().add(ImportCsv(content));
    }
  }

  Future<void> _exportCsv() async {
    context.read<InventoryBloc>().add(const ExportCsv());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InventoryBloc, InventoryState>(
      listener: (context, state) {
        if (state is InventoryError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
        if (state is InventoryLoaded) {
          if (state.csvImportCount != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Imported ${state.csvImportCount} products.'),
                backgroundColor: AppTheme.success,
              ),
            );
          }
          if (state.csvExportData != null) {
            _saveCsvExport(state.csvExportData!);
          }
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            // ─── Toolbar ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Inventory',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.file_upload_outlined),
                        tooltip: 'Import CSV',
                        onPressed: _importCsv,
                      ),
                      IconButton(
                        icon: const Icon(Icons.file_download_outlined),
                        tooltip: 'Export CSV',
                        onPressed: _exportCsv,
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: () => _openForm(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Product'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFilterBar(context, state),
                ],
              ),
            ),

            // ─── Content ─────────────────────────────────────
            Expanded(child: _buildContent(context, state)),
          ],
        );
      },
    );
  }

  Widget _buildFilterBar(BuildContext context, InventoryState state) {
    final productGroups = state is InventoryLoaded
        ? state.productGroups
        : <String>[];

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search by name, code, brand, description, details',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (_) => _applyFilters(),
          ),
        ),
        const SizedBox(width: 12),
        if (productGroups.isNotEmpty) ...[
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<String>(
              initialValue: _selectedProductGroup,
              decoration: const InputDecoration(
                hintText: 'Product Group',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...productGroups.map(
                  (c) => DropdownMenuItem(value: c, child: Text(c)),
                ),
              ],
              onChanged: (v) {
                setState(() => _selectedProductGroup = v);
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 12),
        ],
        FilterChip(
          label: const Text('Low Stock'),
          selected: _lowStockOnly,
          onSelected: (v) {
            setState(() => _lowStockOnly = v);
            _applyFilters();
          },
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, InventoryState state) {
    // ─── CSV import progress ─────────────────────────────
    if (state is CsvImporting) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_upload_rounded,
                size: 56,
                color: AppTheme.highlight,
              ),
              const SizedBox(height: 24),
              Text(state.stage, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              SizedBox(
                width: 300,
                child: LinearProgressIndicator(
                  value: state.total > 0 ? state.progress : null,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  valueColor: const AlwaysStoppedAnimation(AppTheme.highlight),
                ),
              ),
              const SizedBox(height: 12),
              if (state.total > 0)
                Text(
                  '${state.processed} / ${state.total} products',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        ),
      );
    }

    if (state is InventoryLoading || state is InventoryInitial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is InventoryLoaded && state.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No products found.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Add your first product'),
            ),
          ],
        ),
      );
    }
    if (state is! InventoryLoaded) return const SizedBox.shrink();

    final isWide = AdaptiveLayout.isWideScreen(
      MediaQuery.of(context).size.width,
    );

    if (isWide) {
      return _buildDataTable(context, state);
    }
    return _buildListView(context, state);
  }

  Widget _buildDataTable(BuildContext context, InventoryLoaded state) {
    final settingsState = context.watch<SettingsBloc>().state;
    final sym = settingsState is SettingsLoaded
        ? settingsState.currencySymbol
        : '\$';
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              dataRowMaxHeight: 70,
              columns: const [
                DataColumn(label: Text('Image')),
                DataColumn(label: Text('Item Code')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Description')),
                DataColumn(label: Text('Qty'), numeric: true),
                DataColumn(label: Text('Sales Rate'), numeric: true),
                DataColumn(label: Text('Value'), numeric: true),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: state.products.map((p) {
                return DataRow(
                  cells: [
                    DataCell(
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          height: 50,
                          width: 50,
                          child: buildImageView(
                            p.image,
                            fit: BoxFit.contain,
                            errorIconSize: 20,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(p.itemCode)),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Text(
                          p.itemName,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 250),
                        child: Tooltip(
                          message: p.description,
                          child: Text(
                            p.description,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 3,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(p.quantityOnHand.toStringAsFixed(1))),
                    DataCell(Text('$sym${p.salesRate.toStringAsFixed(2)}')),
                    DataCell(Text('$sym${p.totalValue.toStringAsFixed(2)}')),
                    DataCell(
                      Chip(
                        label: Text(
                          p.isLowStock ? 'LOW' : 'OK',
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: p.isLowStock
                            ? AppTheme.warning.withValues(alpha: 0.25)
                            : AppTheme.success.withValues(alpha: 0.25),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 20,
                            ),
                            tooltip: 'Adjust Stock',
                            onPressed: () =>
                                _showStockDialog(context, p.id!, p.itemCode),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            tooltip: 'Edit',
                            onPressed: () => _openForm(context, product: p),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: AppTheme.error,
                            ),
                            tooltip: 'Delete',
                            onPressed: () =>
                                _confirmDelete(context, p.id!, p.itemName),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          if (state.hasMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          // Show count summary
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Showing ${state.products.length} of ${state.totalProductCount} products',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(BuildContext context, InventoryLoaded state) {
    final settingsState = context.watch<SettingsBloc>().state;
    final sym = settingsState is SettingsLoaded
        ? settingsState.currencySymbol
        : '\$';
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      // Extra item for the "load more" indicator + count summary
      itemCount: state.products.length + 1,
      itemBuilder: (context, index) {
        // Last item: loading indicator or count summary
        if (index == state.products.length) {
          return Column(
            children: [
              if (state.hasMore)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Showing ${state.products.length} of ${state.totalProductCount} products',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          );
        }

        final p = state.products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(10),
              child: SizedBox(
                height: 40,
                width: 40,

                child: buildImageView(
                  p.image,
                  fit: BoxFit.contain,
                  errorIconSize: 20,
                ),
              ),
            ),
            title: Text(
              p.itemName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('${p.itemCode} • ${p.description}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${p.quantityOnHand.toStringAsFixed(1)} ${p.unitOfMeasure.label}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: p.isLowStock ? AppTheme.warning : null,
                      ),
                    ),
                    Text(
                      '$sym${p.salesRate.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    switch (v) {
                      case 'adjust':
                        _showStockDialog(context, p.id!, p.itemCode);
                      case 'edit':
                        _openForm(context, product: p);
                      case 'delete':
                        _confirmDelete(context, p.id!, p.itemName);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'adjust', child: Text('Adjust Stock')),
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openForm(BuildContext context, {product}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<InventoryBloc>(),
          child: ProductFormPage(product: product),
        ),
      ),
    );
  }

  void _showStockDialog(BuildContext context, int productId, String itemCode) {
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: context.read<InventoryBloc>(),
        child: StockAdjustDialog(productId: productId, itemCode: itemCode),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () {
              context.read<InventoryBloc>().add(DeleteProduct(id));
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCsvExport(String csvData) async {
    // 1. Convert your String to Bytes
    final Uint8List bytes = Uint8List.fromList(utf8.encode(csvData));

    try {
      final String? result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Inventory CSV',
        fileName: 'stock_pilot_inventory.csv',
        // This is the missing piece for Mobile:
        bytes: bytes,
      );

      // 2. Handle the result based on Platform
      if (result != null) {
        // On Desktop, saveFile returns a path. We still need to write the file manually.
        // On Mobile, the 'bytes' parameter above usually handles the save,
        // but 'result' might return the path or a confirmation.
        if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
          await File(result).writeAsBytes(bytes);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CSV exported successfully!'),
              backgroundColor:
                  Colors.green, // Ensure this matches your AppTheme
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving file: $e');
    }
  }
}
