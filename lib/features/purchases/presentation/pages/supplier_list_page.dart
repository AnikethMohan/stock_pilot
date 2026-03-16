/// Supplier List Page — view all suppliers and quickly add new ones.
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stock_pilot/features/purchases/domain/entities/supplier.dart';
import 'package:stock_pilot/features/sales/domain/repositories/sales_repository.dart';

class SupplierListPage extends StatefulWidget {
  const SupplierListPage({super.key, this.isSelectionMode = false});
  final bool isSelectionMode;

  @override
  State<SupplierListPage> createState() => _SupplierListPageState();
}

class _SupplierListPageState extends State<SupplierListPage> {
  List<Supplier> _suppliers = [];
  bool _isLoading = true;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers({String? search}) async {
    setState(() => _isLoading = true);
    final repo = context.read<SalesRepository>();
    try {
      final suppliers = await repo.getSuppliers(searchQuery: search);
      if (mounted) setState(() => _suppliers = suppliers);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load suppliers: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    _loadSuppliers(search: _searchController.text);
  }

  Future<void> _showAddSupplierDialog() async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Supplier'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name *'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              final repo = context.read<SalesRepository>();
              final supplier = Supplier(
                name: nameController.text.trim(),
                address: addressController.text.trim(),
                phone: phoneController.text.trim(),
                email: emailController.text.trim(),
                createdAt: DateTime.now(),
              );
              await repo.saveSupplier(supplier);
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      _loadSuppliers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddSupplierDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search suppliers',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => _applyFilters(),
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_suppliers.isEmpty) {
                  return const Center(child: Text('No suppliers found.'));
                }
                return ListView.separated(
                  itemCount: _suppliers.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final s = _suppliers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        child: Text(s.name[0].toUpperCase()),
                      ),
                      title: Text(s.name),
                      subtitle: Text(
                        [
                          s.address,
                          s.phone,
                          s.email,
                        ].where((e) => e.isNotEmpty).join(' • '),
                      ),
                      onTap: () {
                        if (widget.isSelectionMode) {
                          Navigator.pop(context, s);
                        } else {
                          // TODO: Edit supplier
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSupplierDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
