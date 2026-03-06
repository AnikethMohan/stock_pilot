/// Dashboard page — KPI cards and recent transactions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:stock_pilot/core/theme/app_theme.dart';
import 'package:stock_pilot/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:stock_pilot/features/settings/presentation/bloc/settings_bloc.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state is DashboardLoading || state is DashboardInitial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is DashboardError) {
          return Center(child: Text('Error: ${state.message}'));
        }
        final data = state as DashboardLoaded;

        // Read currency symbol from settings (fallback to $)
        final settingsState = context.watch<SettingsBloc>().state;
        final currencySymbol = settingsState is SettingsLoaded
            ? settingsState.currencySymbol
            : '\$';
        final currencyFormat = NumberFormat.currency(
          symbol: currencySymbol,
          decimalDigits: 2,
        );

        return RefreshIndicator(
          onRefresh: () async {
            context.read<DashboardBloc>().add(const LoadDashboard());
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Dashboard',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),

              // ─── KPI Cards ─────────────────────────────────────
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossCount = constraints.maxWidth > 700 ? 3 : 1;
                  return GridView.count(
                    crossAxisCount: crossCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: crossCount == 1 ? 2.3 : 2.0,
                    children: [
                      _KpiCard(
                        title: 'Total Inventory Value',
                        value: currencyFormat.format(data.totalInventoryValue),
                        icon: Icons.attach_money_rounded,
                        color: AppTheme.highlight,
                      ),
                      _KpiCard(
                        title: 'Low Stock Items',
                        value: data.lowStockCount.toString(),
                        icon: Icons.warning_amber_rounded,
                        color: data.lowStockCount > 0
                            ? AppTheme.warning
                            : AppTheme.success,
                      ),
                      _KpiCard(
                        title: 'Total Products',
                        value: data.totalProducts.toString(),
                        icon: Icons.inventory_2_rounded,
                        color: AppTheme.success,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 28),
              Text(
                'Recent Transactions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),

              // ─── Recent transactions ───────────────────────────
              if (data.recentTransactions.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No transactions yet.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                )
              else
                ...data.recentTransactions.map((txn) {
                  final isPositive = txn.changeAmount >= 0;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isPositive
                            ? AppTheme.success.withValues(alpha: 0.2)
                            : AppTheme.error.withValues(alpha: 0.2),
                        child: Icon(
                          isPositive
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: isPositive ? AppTheme.success : AppTheme.error,
                        ),
                      ),
                      title: Text(
                        txn.sku,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${txn.reason.label} • ${DateFormat.yMMMd().add_jm().format(txn.timestamp)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      trailing: Text(
                        '${isPositive ? "+" : ""}${txn.changeAmount.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isPositive ? AppTheme.success : AppTheme.error,
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
