/// Settings page — toggles and configuration.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/core/theme/app_theme.dart';
import 'package:stock_pilot/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:stock_pilot/features/settings/presentation/pages/business_info_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        if (state is SettingsInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is SettingsError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        final data = state as SettingsLoaded;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),

            // ─── Business Information ──────────────────────────
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  child: Icon(Icons.business_rounded, size: 20),
                ),
                title: const Text('Business Information'),
                subtitle: const Text(
                  'Name, Address, and Contact info for PDF documents.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BusinessInfoPage()),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: SwitchListTile(
                title: const Text('Allow Negative Stock'),
                subtitle: const Text(
                  'If enabled, stock can go below zero for items sold on backorder.',
                ),
                value: data.allowNegativeStock,
                activeThumbColor: AppTheme.highlight,
                onChanged: (v) => context.read<SettingsBloc>().add(
                  ToggleAllowNegativeStock(v),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Card(
              child: ListTile(
                title: const Text('Default Low Stock Threshold'),
                subtitle: Text(
                  'New products will default to this threshold: ${data.defaultLowStockThreshold.toStringAsFixed(0)}',
                ),
                trailing: SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: data.defaultLowStockThreshold.toStringAsFixed(
                      0,
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(isDense: true),
                    onFieldSubmitted: (v) {
                      final val = double.tryParse(v);
                      if (val != null) {
                        context.read<SettingsBloc>().add(
                          UpdateDefaultThreshold(val),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ─── Default Currency Picker ────────────────────────
            Card(
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.highlight.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    data.currencySymbol,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.highlight,
                    ),
                  ),
                ),
                title: const Text('Default Currency'),
                subtitle: Text(
                  'Used for displaying prices across the app',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: DropdownButton<String>(
                  value: data.currencyCode,
                  underline: const SizedBox.shrink(),
                  borderRadius: BorderRadius.circular(12),
                  dropdownColor: Theme.of(context).cardColor,
                  items: SupportedCurrency.all
                      .map(
                        (c) => DropdownMenuItem<String>(
                          value: c.code,
                          child: Text(
                            '${c.code}  ${c.symbol}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (code) {
                    if (code != null) {
                      context.read<SettingsBloc>().add(
                        UpdateDefaultCurrency(code),
                      );
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About Stock Pilot',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Version 1.0.0\n'
                      'A universal, offline-first Inventory Management System.\n',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
