/// Mobile shell — Drawer layout.
library;

import 'package:flutter/material.dart';
import 'package:stock_pilot/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:stock_pilot/features/inventory/presentation/pages/product_list_page.dart';
import 'package:stock_pilot/features/sales/presentation/pages/sales_doc_list_page.dart';
import 'package:stock_pilot/features/transactions/presentation/pages/transaction_history_page.dart';
import 'package:stock_pilot/features/settings/presentation/pages/settings_page.dart';

import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/core/theme/app_theme.dart';
import 'package:stock_pilot/features/sales/presentation/pages/custom_seperate_page.dart';

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
    CustomSeparatePage(key: ValueKey('quotation'), docType: DocType.quotation),
    CustomSeparatePage(
      key: ValueKey('deliveryNote'),
      docType: DocType.deliveryNote,
    ),
    CustomSeparatePage(key: ValueKey('invoice'), docType: DocType.invoice),
    CustomSeparatePage(
      key: ValueKey('purchaseOrder'),
      docType: DocType.purchaseOrder,
    ),
    CustomSeparatePage(
      key: ValueKey('materialReceipt'),
      docType: DocType.materialReceipt,
    ),
    CustomSeparatePage(
      key: ValueKey('purchaseInvoice'),
      docType: DocType.purchaseInvoice,
    ),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_rounded,
                      color: AppTheme.highlight,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Stock Pilot',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.highlight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(0, Icons.dashboard_outlined, 'Dashboard'),
                  _buildDrawerItem(1, Icons.inventory_2_outlined, 'Inventory'),
                  _buildDrawerItem(
                    2,
                    Icons.receipt_long_outlined,
                    'Transactions',
                  ),
                  _buildDrawerItem(
                    3,
                    Icons.point_of_sale_outlined,
                    'Sales and Purchase',
                  ),
                  const Divider(indent: 16, endIndent: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
                    child: Text(
                      'Sales Documents',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _buildDrawerItem(4, Icons.description_outlined, 'Quotations'),
                  _buildDrawerItem(
                    5,
                    Icons.local_shipping_outlined,
                    'Delivery Notes',
                  ),
                  _buildDrawerItem(6, Icons.receipt_long_outlined, 'Invoices'),
                  const Divider(indent: 16, endIndent: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
                    child: Text(
                      'Purchase documents',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _buildDrawerItem(
                    7,
                    Icons.request_quote_outlined,
                    'Purchase Orders',
                  ),
                  _buildDrawerItem(
                    8,
                    Icons.inventory_2_outlined,
                    'Material Receipts',
                  ),
                  _buildDrawerItem(9, Icons.request_quote, 'Purchase Invoices'),
                  const Divider(indent: 16, endIndent: 16),
                  _buildDrawerItem(10, Icons.settings_outlined, 'Settings'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.highlight : null),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.highlight : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      selected: isSelected,
      onTap: () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context); // Close drawer
      },
    );
  }
}
