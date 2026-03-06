import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stock_pilot/core/constants/app_constants.dart';
import 'package:stock_pilot/core/error/failures.dart';
import 'package:stock_pilot/features/inventory/data/datasources/inventory_local_datasource.dart';
import 'package:stock_pilot/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:stock_pilot/features/inventory/domain/entities/product.dart';
import 'package:stock_pilot/features/transactions/domain/entities/stock_transaction.dart';

// ─── Mocks & Fakes ─────────────────────────────────────────────────

class MockDataSource extends Mock implements InventoryLocalDataSource {}

class FakeStockTransaction extends Fake implements StockTransaction {}

void main() {
  late MockDataSource mockDs;
  late InventoryRepositoryImpl repo;

  final testProduct = Product(
    id: 1,
    sku: 'TEST-001',
    name: 'Widget A',
    quantityOnHand: 5.0,
  );

  setUpAll(() {
    registerFallbackValue(FakeStockTransaction());
  });

  setUp(() {
    mockDs = MockDataSource();
    repo = InventoryRepositoryImpl(dataSource: mockDs);
  });

  group('adjustStock — negative stock guard', () {
    test(
      'REJECT reduction below zero when allow_negative_stock = false',
      () async {
        when(
          () => mockDs.getProductById(1),
        ).thenAnswer((_) async => testProduct);
        when(
          () => mockDs.getSetting(SettingsKeys.allowNegativeStock),
        ).thenAnswer((_) async => 'false');

        expect(
          () => repo.adjustStock(
            productId: 1,
            changeAmount: -10.0,
            reason: TransactionReason.sale,
          ),
          throwsA(isA<NegativeStockFailure>()),
        );
      },
    );

    test(
      'ALLOW reduction below zero when allow_negative_stock = true',
      () async {
        // First call returns original, second call returns updated
        var callCount = 0;
        when(() => mockDs.getProductById(1)).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return testProduct; // before adjustment
          return testProduct.copyWith(quantityOnHand: -5.0); // after adjustment
        });
        when(
          () => mockDs.getSetting(SettingsKeys.allowNegativeStock),
        ).thenAnswer((_) async => 'true');
        when(() => mockDs.updateStock(1, -5.0)).thenAnswer((_) async {});
        when(() => mockDs.insertTransaction(any())).thenAnswer((_) async => 1);

        final result = await repo.adjustStock(
          productId: 1,
          changeAmount: -10.0,
          reason: TransactionReason.sale,
        );

        expect(result.quantityOnHand, -5.0);
        verify(() => mockDs.updateStock(1, -5.0)).called(1);
      },
    );

    test('ALLOW reduction to exactly zero regardless of setting', () async {
      var callCount = 0;
      when(() => mockDs.getProductById(1)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return testProduct;
        return testProduct.copyWith(quantityOnHand: 0.0);
      });
      when(
        () => mockDs.getSetting(SettingsKeys.allowNegativeStock),
      ).thenAnswer((_) async => 'false');
      when(() => mockDs.updateStock(1, 0.0)).thenAnswer((_) async {});
      when(() => mockDs.insertTransaction(any())).thenAnswer((_) async => 1);

      final result = await repo.adjustStock(
        productId: 1,
        changeAmount: -5.0,
        reason: TransactionReason.sale,
      );

      expect(result.quantityOnHand, 0.0);
    });

    test('REJECT when product not found', () async {
      when(() => mockDs.getProductById(99)).thenAnswer((_) async => null);

      expect(
        () => repo.adjustStock(
          productId: 99,
          changeAmount: 5.0,
          reason: TransactionReason.restock,
        ),
        throwsA(isA<DatabaseFailure>()),
      );
    });
  });
}
