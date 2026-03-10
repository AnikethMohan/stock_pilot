/// Sales Document List Page — view all sales documents with type filters
/// and document conversion actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/core/services/pdf_service.dart';
import 'package:stock_pilot/core/theme/app_theme.dart';
import 'package:stock_pilot/features/sales/domain/entities/sales_document.dart';
import 'package:stock_pilot/features/sales/domain/repositories/sales_repository.dart';
import 'package:stock_pilot/features/sales/presentation/bloc/sales_doc_bloc.dart';
import 'package:stock_pilot/features/sales/presentation/bloc/sales_doc_event.dart';
import 'package:stock_pilot/features/sales/presentation/bloc/sales_doc_state.dart';
import 'package:stock_pilot/features/sales/presentation/pages/sales_doc_builder_page.dart';
import 'package:stock_pilot/features/settings/presentation/bloc/settings_bloc.dart';

class SalesDocListPage extends StatefulWidget {
  const SalesDocListPage({super.key});

  @override
  State<SalesDocListPage> createState() => _SalesDocListPageState();
}

class _SalesDocListPageState extends State<SalesDocListPage> {
  DocType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    context.read<SalesDocBloc>().add(const LoadDocuments());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales Documents')),
      body: Column(
        children: [
          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', null),
                  const SizedBox(width: 8),
                  _buildFilterChip('Quotations', DocType.quotation),
                  const SizedBox(width: 8),
                  _buildFilterChip('Delivery Notes', DocType.deliveryNote),
                  const SizedBox(width: 8),
                  _buildFilterChip('Invoices', DocType.invoice),
                ],
              ),
            ),
          ),

          // Document List
          Expanded(
            child: BlocBuilder<SalesDocBloc, SalesDocState>(
              buildWhen: (prev, curr) =>
                  curr is SalesDocListLoaded || curr is SalesDocLoading,
              builder: (context, state) {
                final settingsState = context.watch<SettingsBloc>().state;
                final currencySymbol = settingsState is SettingsLoaded
                    ? settingsState.currencySymbol
                    : '\$';
                final currencyFormat = NumberFormat.currency(
                  symbol: currencySymbol,
                  decimalDigits: 2,
                );

                if (state is SalesDocLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is SalesDocListLoaded) {
                  if (state.documents.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 16),
                          const Text('No documents found.'),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.documents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final doc = state.documents[index];
                      return _buildDocCard(doc, currencyFormat);
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Document'),
        onPressed: () async {
          final bloc = context.read<SalesDocBloc>();
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SalesDocBuilderPage()),
          );
          if (mounted) {
            bloc.add(LoadDocuments(typeFilter: _selectedFilter));
          }
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, DocType? type) {
    final isSelected = _selectedFilter == type;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: AppTheme.highlight.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.highlight,
      onSelected: (_) {
        setState(() => _selectedFilter = type);
        context.read<SalesDocBloc>().add(LoadDocuments(typeFilter: type));
      },
    );
  }

  Widget _buildDocCard(SalesDocument doc, NumberFormat currencyFormat) {
    final isConfirmed = doc.status == DocStatus.confirmed;

    Color statusColor;
    IconData typeIcon;
    switch (doc.docType) {
      case DocType.quotation:
        typeIcon = Icons.description;
        statusColor = isConfirmed ? AppTheme.success : AppTheme.warning;
        break;
      case DocType.deliveryNote:
        typeIcon = Icons.local_shipping;
        statusColor = isConfirmed ? AppTheme.success : Colors.blue;
        break;
      case DocType.invoice:
        typeIcon = Icons.receipt_long;
        statusColor = isConfirmed ? AppTheme.success : AppTheme.warning;
        break;
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.2),
          foregroundColor: statusColor,
          child: Icon(typeIcon),
        ),
        title: Row(
          children: [
            Text(doc.docNumber),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                doc.status.label,
                style: TextStyle(
                  fontSize: 11,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          '${doc.customer?.name ?? 'No Customer'} • ${doc.items.length} items'
          '${doc.docType != DocType.deliveryNote ? ' • ${currencyFormat.format(doc.grandTotal)}' : ''}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _onMenuAction(value, doc),
          itemBuilder: (context) {
            final items = <PopupMenuEntry<String>>[];

            if (isConfirmed) {
              items.add(
                const PopupMenuItem(value: 'pdf', child: Text('Generate PDF')),
              );
            } else {
              items.add(
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
              );
            }

            // Conversion options
            if (doc.docType == DocType.quotation) {
              items.add(
                const PopupMenuItem(
                  value: 'to_delivery',
                  child: Text('Convert → Delivery Note'),
                ),
              );
              items.add(
                const PopupMenuItem(
                  value: 'to_invoice',
                  child: Text('Convert → Invoice'),
                ),
              );
            } else if (doc.docType == DocType.deliveryNote) {
              items.add(
                const PopupMenuItem(
                  value: 'to_invoice',
                  child: Text('Convert → Invoice'),
                ),
              );
            }

            return items;
          },
        ),
        onTap: () async {
          if (isConfirmed) {
            _generatePdf(doc);
          } else {
            _editDocument(doc);
          }
        },
      ),
    );
  }

  Future<void> _onMenuAction(String action, SalesDocument doc) async {
    final bloc = context.read<SalesDocBloc>();

    switch (action) {
      case 'pdf':
        await _generatePdf(doc);
        break;
      case 'edit':
        await _editDocument(doc);
        break;
      case 'to_delivery':
        bloc.add(
          ConvertDocument(
            sourceDocId: doc.id!,
            targetType: DocType.deliveryNote,
          ),
        );
        // Navigate to builder with converted doc
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
          final state = bloc.state;
          if (state is SalesDocBuilding && mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SalesDocBuilderPage(document: state.activeDoc),
              ),
            );
            if (mounted) {
              bloc.add(LoadDocuments(typeFilter: _selectedFilter));
            }
          }
        }
        break;
      case 'to_invoice':
        bloc.add(
          ConvertDocument(sourceDocId: doc.id!, targetType: DocType.invoice),
        );
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 300));
          final state = bloc.state;
          if (state is SalesDocBuilding && mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SalesDocBuilderPage(document: state.activeDoc),
              ),
            );
            if (mounted) {
              bloc.add(LoadDocuments(typeFilter: _selectedFilter));
            }
          }
        }
        break;
    }
  }

  Future<void> _generatePdf(SalesDocument doc) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = context.read<SalesRepository>();
    final settingsState = context.read<SettingsBloc>().state;
    final currencySymbol = settingsState is SettingsLoaded
        ? settingsState.currencySymbol
        : '\$';
    final currencyFormat = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 2,
    );

    try {
      final fullDoc = await repo.getDocumentById(doc.id!);
      await PdfService.saveOrSharePdf(fullDoc, currencyFormat);
      if (mounted) {
        messenger.showSnackBar(const SnackBar(content: Text('PDF Generated')));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  Future<void> _editDocument(SalesDocument doc) async {
    final bloc = context.read<SalesDocBloc>();
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SalesDocBuilderPage(document: doc)),
    );
    if (mounted) {
      bloc.add(LoadDocuments(typeFilter: _selectedFilter));
    }
  }
}
