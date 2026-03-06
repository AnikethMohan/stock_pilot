/// Desktop shell — NavigationRail sidebar layout.
library;

import 'package:flutter/material.dart';
import 'package:stock_pilot/core/theme/app_theme.dart';
import 'package:stock_pilot/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:stock_pilot/features/inventory/presentation/pages/product_list_page.dart';
import 'package:stock_pilot/features/transactions/presentation/pages/transaction_history_page.dart';
import 'package:stock_pilot/features/settings/presentation/pages/settings_page.dart';

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int _selectedIndex = 0;

  static const _pages = <Widget>[
    DashboardPage(),
    ProductListPage(),
    TransactionHistoryPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            extended: MediaQuery.of(context).size.width > 1100,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_rounded,
                    color: AppTheme.highlight,
                    size: 28,
                  ),
                  if (MediaQuery.of(context).size.width > 1100) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Stock Pilot',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.highlight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: Text('Inventory'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: Text('Transactions'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _pages[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}
