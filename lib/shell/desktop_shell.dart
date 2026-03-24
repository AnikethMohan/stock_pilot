/// Desktop shell — NavigationRail sidebar layout.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/core/theme/app_theme.dart';
import 'package:stock_pilot/core/navigation/workspace_manager.dart';
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
  late final WorkspaceBloc _workspaceBloc;

  @override
  void initState() {
    super.initState();
    _workspaceBloc = WorkspaceBloc();
    _workspaceBloc.add(
      WorkspaceItemOpened(
        WorkspaceItem(
          id: UniqueKey().toString(),
          title: 'Dashboard',
          icon: Icons.dashboard_outlined,
          page: DashboardPage(key: UniqueKey()),
        ),
        replaceCurrent: true,
      ),
    );
  }

  @override
  void dispose() {
    _workspaceBloc.close();
    super.dispose();
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return DashboardPage(key: UniqueKey());
      case 1:
        return ProductListPage(key: UniqueKey());
      case 2:
        return TransactionHistoryPage(key: UniqueKey());
      case 3:
        return SalesDocListPage(key: UniqueKey());
      case 4:
        return CustomSeparatePage(key: UniqueKey(), docType: DocType.quotation);
      case 5:
        return CustomSeparatePage(
          key: UniqueKey(),
          docType: DocType.deliveryNote,
        );
      case 6:
        return CustomSeparatePage(key: UniqueKey(), docType: DocType.invoice);
      case 7:
        return CustomSeparatePage(
          key: UniqueKey(),
          docType: DocType.deliveryReturn,
        );
      case 8:
        return CustomSeparatePage(
          key: UniqueKey(),
          docType: DocType.creditNote,
        );
      case 9:
        return CustomSeparatePage(
          key: UniqueKey(),
          docType: DocType.purchaseOrder,
        );
      case 10:
        return CustomSeparatePage(
          key: UniqueKey(),
          docType: DocType.materialReceipt,
        );
      case 11:
        return CustomSeparatePage(
          key: UniqueKey(),
          docType: DocType.purchaseInvoice,
        );
      case 12:
        return SettingsPage(key: UniqueKey());
      case 13:
        return CustomSeparatePage(
          key: UniqueKey(),
          docType: DocType.localPurchaseOrder,
        );
      default:
        return const Center(child: Text('Unknown Page'));
    }
  }

  bool _isModifierPressed() {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    return keys.contains(LogicalKeyboardKey.controlLeft) ||
        keys.contains(LogicalKeyboardKey.controlRight) ||
        keys.contains(LogicalKeyboardKey.metaLeft) ||
        keys.contains(LogicalKeyboardKey.metaRight);
  }

  void _onNavItemTapped(int index, String label, IconData icon) {
    final modPressed = _isModifierPressed();
    final newItem = WorkspaceItem(
      id: UniqueKey().toString(),
      title: label,
      icon: icon,
      page: _getPage(index),
    );
    _workspaceBloc.add(
      WorkspaceItemOpened(newItem, replaceCurrent: !modPressed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExtended = MediaQuery.of(context).size.width > 1100;

    return BlocProvider.value(
      value: _workspaceBloc,
      child: Scaffold(
        body: BlocBuilder<WorkspaceBloc, WorkspaceState>(
          builder: (context, state) {
            final activeTitle = state.activeItem?.title;

            return Row(
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
                              activeTitle,
                            ),
                            _buildNavItem(
                              1,
                              Icons.inventory_2_outlined,
                              'Inventory',
                              isExtended,
                              activeTitle,
                            ),
                            _buildNavItem(
                              2,
                              Icons.receipt_long_outlined,
                              'Transactions',
                              isExtended,
                              activeTitle,
                            ),
                            _buildNavItem(
                              3,
                              Icons.point_of_sale_outlined,
                              'Sales and Purchase',
                              isExtended,
                              activeTitle,
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
                              activeTitle,
                            ),
                            _buildNavItem(
                              5,
                              Icons.local_shipping_outlined,
                              'Delivery Notes',
                              isExtended,
                              activeTitle,
                            ),
                            _buildNavItem(
                              6,
                              Icons.receipt_long_outlined,
                              'Sales Invoices',
                              isExtended,
                              activeTitle,
                            ),
                            _buildNavItem(
                              7,
                              Icons.assignment_return_outlined,
                              'Delivery Returns',
                              isExtended,
                              activeTitle,
                            ),
                            _buildNavItem(
                              8,
                              Icons.account_balance_wallet_outlined,
                              'Credit Notes',
                              isExtended,
                              activeTitle,
                            ),

                            if (isExtended) ...[
                              const Divider(indent: 16, endIndent: 16),
                              _buildSectionHeader('Purchase Documents'),
                            ] else
                              const Divider(),
                            _buildNavItem(
                              13,
                              Icons.shopping_cart_outlined,
                              'Local Purchase Orders',
                              isExtended,
                              activeTitle,
                            ),
                            _buildNavItem(
                              9,
                              Icons.shopping_cart_outlined,
                              'Purchase Orders',
                              isExtended,
                              activeTitle,
                            ),
                            _buildNavItem(
                              10,
                              Icons.inventory_2_outlined,
                              'Material Receipts',
                              isExtended,
                              activeTitle,
                            ),
                            _buildNavItem(
                              11,
                              Icons.request_quote_outlined,
                              'Purchase Invoices',
                              isExtended,
                              activeTitle,
                            ),

                            const Divider(),
                            _buildNavItem(
                              12,
                              Icons.settings_outlined,
                              'Settings',
                              isExtended,
                              activeTitle,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                VerticalDivider(width: 1),
                Expanded(
                  child: state.items.isEmpty
                      ? const Center(child: Text('No tabs open'))
                      : Column(
                          children: [
                            Container(
                              height: 48,
                              color: Theme.of(context).colorScheme.surface,
                              child: ReorderableListView.builder(
                                scrollDirection: Axis.horizontal,
                                buildDefaultDragHandles: false,
                                itemCount: state.items.length,
                                onReorder: (oldIndex, newIndex) {
                                  _workspaceBloc.add(
                                    WorkspaceItemsReordered(oldIndex, newIndex),
                                  );
                                },
                                itemBuilder: (context, index) {
                                  final item = state.items[index];
                                  final isActive = index == state.activeIndex;
                                  return ReorderableDragStartListener(
                                    key: ValueKey(item.id),
                                    index: index,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _workspaceBloc.add(
                                          WorkspaceItemFocused(index),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? Theme.of(context)
                                                      .colorScheme
                                                      .surfaceContainerHighest
                                                : Colors.transparent,
                                            border: Border(
                                              bottom: BorderSide(
                                                color: isActive
                                                    ? AppTheme.highlight
                                                    : Colors.transparent,
                                                width: 2,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (item.icon != null) ...[
                                                Icon(
                                                  item.icon,
                                                  size: 16,
                                                  color: isActive
                                                      ? AppTheme.highlight
                                                      : Colors.grey,
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              Text(
                                                item.title,
                                                style: TextStyle(
                                                  color: isActive
                                                      ? AppTheme.highlight
                                                      : Colors.grey,
                                                  fontWeight: isActive
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              InkWell(
                                                onTap: () {
                                                  _workspaceBloc.add(
                                                    WorkspaceItemClosed(
                                                      item.id,
                                                    ),
                                                  );
                                                },
                                                hoverColor: Colors.red
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: const Padding(
                                                  padding: EdgeInsets.all(4.0),
                                                  child: Icon(
                                                    Icons.close,
                                                    size: 16,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: IndexedStack(
                                index: state.activeIndex,
                                children: state.items
                                    .map((i) => i.page)
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    bool isExtended,
    String? activeTitle,
  ) {
    final isSelected = activeTitle == label;
    final color = isSelected ? AppTheme.highlight : null;

    if (!isExtended) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: IconButton(
          icon: Icon(icon, color: color),
          onPressed: () => _onNavItemTapped(index, label, icon),
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
      onTap: () => _onNavItemTapped(index, label, icon),
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
