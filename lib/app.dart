/// Root MaterialApp widget — adaptive shell selection and BLoC providers.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stock_pilot/core/theme/app_theme.dart';
import 'package:stock_pilot/core/utils/adaptive_layout.dart';
import 'package:stock_pilot/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:stock_pilot/features/inventory/data/datasources/inventory_local_datasource.dart';
import 'package:stock_pilot/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:stock_pilot/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:stock_pilot/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:stock_pilot/features/inventory/presentation/bloc/inventory_event.dart';
import 'package:stock_pilot/features/sales/data/datasources/sales_local_datasource.dart';
import 'package:stock_pilot/features/sales/data/repositories/sales_repository_impl.dart';
import 'package:stock_pilot/features/sales/domain/repositories/sales_repository.dart';
import 'package:stock_pilot/features/sales/presentation/bloc/sales_doc_bloc.dart';
import 'package:stock_pilot/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:stock_pilot/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:stock_pilot/shell/desktop_shell.dart';
import 'package:stock_pilot/shell/mobile_shell.dart';

class StockPilotApp extends StatelessWidget {
  const StockPilotApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Shared data source → all repos use the same instance
    final dataSource = InventoryLocalDataSource();
    final inventoryRepo = InventoryRepositoryImpl(dataSource: dataSource);
    final transactionRepo = TransactionRepositoryImpl(dataSource: dataSource);
    final settingsRepo = SettingsRepositoryImpl(dataSource: dataSource);

    final salesDataSource = SalesLocalDataSource();
    final salesRepo = SalesRepositoryImpl(dataSource: salesDataSource);

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<InventoryRepository>.value(value: inventoryRepo),
        RepositoryProvider<SalesRepository>.value(value: salesRepo),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) =>
                InventoryBloc(repository: inventoryRepo)
                  ..add(const LoadProducts()),
          ),
          BlocProvider(
            create: (_) => DashboardBloc(
              inventoryRepository: inventoryRepo,
              transactionRepository: transactionRepo,
              salesRepository: salesRepo,
            )..add(const LoadDashboard()),
          ),
          BlocProvider(
            create: (_) =>
                TransactionBloc(repository: transactionRepo)
                  ..add(const LoadTransactions()),
          ),
          BlocProvider(
            create: (_) =>
                SettingsBloc(repository: settingsRepo)
                  ..add(const LoadSettings()),
          ),
          BlocProvider(create: (_) => SalesDocBloc(repository: salesRepo)),
        ],
        child: MaterialApp(
          title: 'Stock Pilot',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: LayoutBuilder(
            builder: (context, constraints) {
              if (AdaptiveLayout.isWideScreen(constraints.maxWidth)) {
                return const DesktopShell();
              }
              return const MobileShell();
            },
          ),
        ),
      ),
    );
  }
}
