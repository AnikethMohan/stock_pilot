/// Sales Document List Page — view all sales documents with type filters
/// and document conversion actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/core/services/pdf_service.dart';
import 'package:stock_pilot/core/theme/app_theme.dart';
import 'package:stock_pilot/core/utils/helper_func_extensions.dart';
import 'package:stock_pilot/features/sales/domain/entities/sales_document.dart';
import 'package:stock_pilot/features/sales/domain/repositories/sales_repository.dart';
import 'package:stock_pilot/features/sales/presentation/bloc/sales_doc_bloc.dart';
import 'package:stock_pilot/features/sales/presentation/bloc/sales_doc_event.dart';
import 'package:stock_pilot/features/sales/presentation/bloc/sales_doc_state.dart';
import 'package:stock_pilot/features/sales/presentation/pages/sales_doc_builder_page.dart';
import 'package:stock_pilot/features/settings/presentation/bloc/settings_bloc.dart';

class CustomSeparatePage extends StatefulWidget {
  const CustomSeparatePage({super.key, required this.docType});

  final DocType docType;

  @override
  State<CustomSeparatePage> createState() => _CustomSeparatePageState();
}

class _CustomSeparatePageState extends State<CustomSeparatePage> {
  @override
  void initState() {
    super.initState();
    context.read<SalesDocBloc>().add(LoadDocuments(typeFilter: widget.docType));
  }

  @override
  void didUpdateWidget(CustomSeparatePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.docType != widget.docType) {
      context.read<SalesDocBloc>().add(
        LoadDocuments(typeFilter: widget.docType),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.docType.value.capitalizeUnderscoreWordsOnlyFirst()),
      ),
      body: BlocBuilder<SalesDocBloc, SalesDocState>(
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
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
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(
          'New ${widget.docType.value.capitalizeUnderscoreWordsOnlyFirst()}',
        ),
        onPressed: () async {
          final bloc = context.read<SalesDocBloc>();
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SalesDocBuilderPage(initialType: widget.docType),
            ),
          );
          if (mounted) {
            bloc.add(LoadDocuments(typeFilter: widget.docType));
          }
        },
      ),
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
      case DocType.purchaseOrder:
        typeIcon = Icons.shopping_cart;
        statusColor = isConfirmed ? AppTheme.success : AppTheme.warning;
        break;
      case DocType.materialReceipt:
        typeIcon = Icons.inventory;
        statusColor = isConfirmed ? AppTheme.success : Colors.blue;
        break;
      case DocType.purchaseInvoice:
        typeIcon = Icons.request_quote;
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
          '${doc.docType == DocType.purchaseOrder || doc.docType == DocType.purchaseInvoice || doc.docType == DocType.materialReceipt ? doc.supplier?.name ?? 'No Supplier' : doc.customer?.name ?? 'No Customer'} • ${doc.items.length} items'
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
            } else if (doc.docType == DocType.purchaseOrder) {
              items.add(
                const PopupMenuItem(
                  value: 'to_material_receipt',
                  child: Text('Convert → Material Receipt'),
                ),
              );
              items.add(
                const PopupMenuItem(
                  value: 'to_purchase_invoice',
                  child: Text('Convert → Purchase Invoice'),
                ),
              );
            } else if (doc.docType == DocType.materialReceipt) {
              items.add(
                const PopupMenuItem(
                  value: 'to_purchase_invoice',
                  child: Text('Convert → Purchase Invoice'),
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
              bloc.add(LoadDocuments(typeFilter: widget.docType));
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
              bloc.add(LoadDocuments(typeFilter: widget.docType));
            }
          }
        }
        break;
      case 'to_material_receipt':
        bloc.add(
          ConvertDocument(
            sourceDocId: doc.id!,
            targetType: DocType.materialReceipt,
          ),
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
              bloc.add(LoadDocuments(typeFilter: widget.docType));
            }
          }
        }
        break;
      case 'to_purchase_invoice':
        bloc.add(
          ConvertDocument(
            sourceDocId: doc.id!,
            targetType: DocType.purchaseInvoice,
          ),
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
              bloc.add(LoadDocuments(typeFilter: widget.docType));
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

    String currencySymbol = '\$';
    String bName = 'Stock Pilot Inc.';
    String bAddress = '123 Business Rd.\nCity, State 12345';
    String? bPhone;
    String? bEmail;
    String? bWebsite;

    if (settingsState is SettingsLoaded) {
      currencySymbol = settingsState.currencySymbol;
      bName = settingsState.businessName;
      bAddress = settingsState.businessAddress;
      bPhone = settingsState.businessPhone;
      bEmail = settingsState.businessEmail;
      bWebsite = settingsState.businessWebsite;
    }

    final currencyFormat = NumberFormat.currency(
      symbol: currencySymbol,
      decimalDigits: 2,
    );

    try {
      final fullDoc = await repo.getDocumentById(doc.id!);
      await PdfService.saveOrSharePdf(
        fullDoc,
        currencyFormat,
        businessName: bName,
        businessAddress: bAddress,
        businessPhone: bPhone,
        businessEmail: bEmail,
        businessWebsite: bWebsite,
      );
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
      bloc.add(LoadDocuments(typeFilter: widget.docType));
    }
  }
}
