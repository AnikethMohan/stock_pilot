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
    // Sales
    CustomSeparatePage(key: ValueKey('quotation'), docType: DocType.quotation),
    CustomSeparatePage(
      key: ValueKey('deliveryNote'),
      docType: DocType.deliveryNote,
    ),
    CustomSeparatePage(key: ValueKey('invoice'), docType: DocType.invoice),
    CustomSeparatePage(
      key: ValueKey('deliveryReturn'),
      docType: DocType.deliveryReturn,
    ),
    CustomSeparatePage(
      key: ValueKey('creditNote'),
      docType: DocType.creditNote,
    ),

    // Purchases
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
    final isExtended = MediaQuery.of(context).size.width > 1100;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: isExtended ? 280 : 80,
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                // Logo section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: isExtended
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_rounded,
                        color: AppTheme.highlight,
                        size: 32,
                      ),
                      if (isExtended) ...[
                        const SizedBox(width: 12),
                        Text(
                          'Stock Pilot',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppTheme.highlight,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildNavItem(
                        0,
                        Icons.dashboard_outlined,
                        'Dashboard',
                        isExtended,
                      ),
                      _buildNavItem(
                        1,
                        Icons.inventory_2_outlined,
                        'Inventory',
                        isExtended,
                      ),
                      _buildNavItem(
                        2,
                        Icons.receipt_long_outlined,
                        'Transactions',
                        isExtended,
                      ),
                      _buildNavItem(
                        3,
                        Icons.point_of_sale_outlined,
                        'Sales and Purchase',
                        isExtended,
                      ),

                      if (isExtended) ...[
                        const Divider(indent: 16, endIndent: 16),
                        _buildSectionHeader('Sales Documents'),
                      ] else
                        const Divider(),

                      _buildNavItem(
                        4,
                        Icons.description_outlined,
                        'Quotations',
                        isExtended,
                      ),
                      _buildNavItem(
                        5,
                        Icons.local_shipping_outlined,
                        'Delivery Notes',
                        isExtended,
                      ),
                      _buildNavItem(
                        6,
                        Icons.receipt_long_outlined,
                        'Sales Invoices',
                        isExtended,
                      ),
                      _buildNavItem(
                        7,
                        Icons.assignment_return_outlined,
                        'Delivery Returns',
                        isExtended,
                      ),
                      _buildNavItem(
                        8,
                        Icons.account_balance_wallet_outlined,
                        'Credit Notes',
                        isExtended,
                      ),

                      if (isExtended) ...[
                        const Divider(indent: 16, endIndent: 16),
                        _buildSectionHeader('Purchase Documents'),
                      ] else
                        const Divider(),

                      _buildNavItem(
                        9,
                        Icons.shopping_cart_outlined,
                        'Purchase Orders',
                        isExtended,
                      ),
                      _buildNavItem(
                        10,
                        Icons.inventory_2_outlined,
                        'Material Receipts',
                        isExtended,
                      ),
                      _buildNavItem(
                        11,
                        Icons.request_quote_outlined,
                        'Purchase Invoices',
                        isExtended,
                      ),

                      const Divider(),
                      _buildNavItem(
                        12,
                        Icons.settings_outlined,
                        'Settings',
                        isExtended,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          VerticalDivider(width: 1),
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

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    bool isExtended,
  ) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? AppTheme.highlight : null;

    if (!isExtended) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: IconButton(
          icon: Icon(icon, color: color),
          onPressed: () => setState(() => _selectedIndex = index),
          tooltip: label,
        ),
      );
    }

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      selected: isSelected,
      onTap: () => setState(() => _selectedIndex = index),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.grey,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
