/// Desktop shell — NavigationRail sidebar layout.
library;

import 'package:flutter/material.dart';
import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/core/theme/app_theme.dart';
import 'package:stock_pilot/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:stock_pilot/features/inventory/presentation/pages/product_list_page.dart';
import 'package:stock_pilot/features/sales/presentation/pages/custom_seperate_page.dart';
import 'package:stock_pilot/features/sales/presentation/pages/sales_doc_list_page.dart';
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
                icon: Icon(Icons.point_of_sale_outlined),
                selectedIcon: Icon(Icons.point_of_sale),
                label: Text('Sales and Purchase'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.description),
                selectedIcon: Icon(Icons.description),
                label: Text('Quotations'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.local_shipping),
                selectedIcon: Icon(Icons.local_shipping),
                label: Text('Delivery Notes'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.receipt_long),
                selectedIcon: Icon(Icons.receipt_long),
                label: Text('Invoices'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.shopping_cart_outlined),
                selectedIcon: Icon(Icons.shopping_cart),
                label: Text('Purchase Orders'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: Text('Material Receipts'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.request_quote_outlined),
                selectedIcon: Icon(Icons.request_quote),
                label: Text('Purchase Invoices'),
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
