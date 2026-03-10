/// Mobile shell — BottomNavigationBar layout.
library;

import 'package:flutter/material.dart';
import 'package:stock_pilot/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:stock_pilot/features/inventory/presentation/pages/product_list_page.dart';
import 'package:stock_pilot/features/sales/presentation/pages/sales_doc_list_page.dart';
import 'package:stock_pilot/features/transactions/presentation/pages/transaction_history_page.dart';
import 'package:stock_pilot/features/settings/presentation/pages/settings_page.dart';

class MobileShell extends StatefulWidget {
  const MobileShell({super.key});

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> {
  int _selectedIndex = 0;

  static const _pages = <Widget>[
    DashboardPage(),
    ProductListPage(),
    TransactionHistoryPage(),
    SalesDocListPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale_outlined),
            activeIcon: Icon(Icons.point_of_sale),
            label: 'Sales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
