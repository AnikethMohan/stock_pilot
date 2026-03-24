import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:stock_pilot/features/inventory/domain/entities/inventory_import.dart';
import 'package:stock_pilot/features/inventory/presentation/bloc/import_bloc.dart';

class ImportHistoryPage extends StatefulWidget {
  const ImportHistoryPage({super.key});

  @override
  State<ImportHistoryPage> createState() => _ImportHistoryPageState();
}

class _ImportHistoryPageState extends State<ImportHistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<ImportBloc>().add(LoadImportsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return const ImportHistoryView();
  }
}

class ImportHistoryView extends StatelessWidget {
  const ImportHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('CSV Import History'), elevation: 0),
      body: BlocConsumer<ImportBloc, ImportState>(
        listener: (context, state) {
          if (state is ImportReverseSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Import successfully reversed!'),
                backgroundColor: Colors.green,
              ),
            );
            // Reload the list
            context.read<ImportBloc>().add(LoadImportsEvent());
          } else if (state is ImportError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
            // Reload the list just in case
            context.read<ImportBloc>().add(LoadImportsEvent());
          }
        },
        builder: (context, state) {
          if (state is ImportInitial ||
              state is ImportProcessing ||
              state is ImportReversing &&
                  context.read<ImportBloc>().state is! ImportsLoaded) {
            // Keep showing the list if we are just reversing, or show a loader if it's the first time
            if (state is ImportReversing) {
              // We'll handle the overlay button state instead of full-screen loader,
              // but since the bloc doesn't retain the old state easily here without a custom state,
              // we can just show a simplified view or a loader.
              return const Center(child: CircularProgressIndicator());
            }
            // For processing/initial:
            return const Center(child: CircularProgressIndicator());
          }

          List<InventoryImport> imports = [];
          if (state is ImportsLoaded) {
            imports = state.imports;
          } else if (state is ImportReverseSuccess) {
            // Transient state, will be replaced by ImportsLoaded soon
            return const Center(child: CircularProgressIndicator());
          } else if (state is ImportError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load imports',
                    style: theme.textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () =>
                        context.read<ImportBloc>().add(LoadImportsEvent()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (imports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 64, color: Colors.black26),
                  const SizedBox(height: 16),
                  Text(
                    'No CSV imports found.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: imports.length,
            itemBuilder: (context, index) {
              final record = imports[index];
              final dateFormat = DateFormat('MMM dd, yyyy - HH:mm a');

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.file_present),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.filename,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Imported: ${dateFormat.format(record.date)}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${record.totalRows} row(s) processed',
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.undo, size: 18),
                        label: const Text('Undo Import'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _confirmReversal(context, record),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmReversal(BuildContext context, InventoryImport record) {
    showDialog(
      context: context,
      builder: (dlgContext) {
        return AlertDialog(
          title: const Text('Undo CSV Import?'),
          content: Text(
            'Are you sure you want to reverse the import of "${record.filename}"? '
            'This will deduct the quantities that were added during this import. '
            'If deducting these quantities results in negative stock for any item, the operation will be blocked.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dlgContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dlgContext).pop();
                context.read<ImportBloc>().add(ReverseImportEvent(record.id!));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Undo'),
            ),
          ],
        );
      },
    );
  }
}
