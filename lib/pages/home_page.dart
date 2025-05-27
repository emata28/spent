import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

final supabase = Supabase.instance.client;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _supabaseService = SupabaseService();
  final _formKey = GlobalKey<FormState>();

  // Controllers for expense form
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  int? _selectedCurrencyId;
  List<int> _selectedCategoryIds = [];

  // Controllers for category form
  final _categoryNameController = TextEditingController();

  // Controllers for currency form
  final _currencyCodeController = TextEditingController();
  final _currencyNameController = TextEditingController();
  final _currencySymbolController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _categoryNameController.dispose();
    _currencyCodeController.dispose();
    _currencyNameController.dispose();
    _currencySymbolController.dispose();
    super.dispose();
  }

  Future<void> _addExpense() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCurrencyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a currency')),
      );
      return;
    }

    try {
      // First insert the expense
      final expense = await _supabaseService.insertData('expenses', {
        'amount': double.parse(_amountController.text),
        'description': _descriptionController.text,
        'date': _selectedDate.toIso8601String(),
        'currency_id': _selectedCurrencyId,
        'user_id': _supabaseService.currentUser?.id,
      });

      // Then add category associations
      for (final categoryId in _selectedCategoryIds) {
        await _supabaseService.insertData('expense_categories', {
          'expense_id': expense['id'],
          'category_id': categoryId,
          'user_id': _supabaseService.currentUser?.id,
        });
      }

      _amountController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedDate = DateTime.now();
        _selectedCurrencyId = null;
        _selectedCategoryIds = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding expense: $e')),
      );
    }
  }

  Future<void> _addCategory() async {
    if (_categoryNameController.text.isEmpty) return;

    try {
      await _supabaseService.insertData('categories', {
        'name': _categoryNameController.text,
      });

      _categoryNameController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding category: $e')),
      );
    }
  }

  Future<void> _addCurrency() async {
    if (_currencyCodeController.text.isEmpty ||
        _currencyNameController.text.isEmpty ||
        _currencySymbolController.text.isEmpty) return;

    try {
      await _supabaseService.insertData('currencies', {
        'code': _currencyCodeController.text.toUpperCase(),
        'name': _currencyNameController.text,
        'symbol': _currencySymbolController.text,
      });

      _currencyCodeController.clear();
      _currencyNameController.clear();
      _currencySymbolController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Currency added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding currency: $e')),
      );
    }
  }

  Future<void> _editExpense(Map<String, dynamic> expense) async {
    final amountController =
        TextEditingController(text: expense['amount'].toString());
    final descriptionController =
        TextEditingController(text: expense['description']);
    DateTime selectedDate = DateTime.parse(expense['date']);
    int? selectedCurrencyId = expense['currency_id'];
    List<int> selectedCategoryIds = [];

    // Get current categories for this expense
    final categories = await _supabaseService
        .getData('expense_categories')
        .then((ec) => ec.where((e) => e['expense_id'] == expense['id']));
    selectedCategoryIds =
        categories.map((c) => c['category_id'] as int).toList();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Expense'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date'),
                subtitle: Text(selectedDate.toString().split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    selectedDate = date;
                  }
                },
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _supabaseService.getData('currencies'),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  return DropdownButtonFormField<int>(
                    value: selectedCurrencyId,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(),
                    ),
                    items: snapshot.data!.map((currency) {
                      return DropdownMenuItem<int>(
                        value: currency['id'] as int,
                        child:
                            Text('${currency['code']} - ${currency['name']}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      selectedCurrencyId = value;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _supabaseService.getData('categories'),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Categories'),
                      Wrap(
                        spacing: 8.0,
                        children: snapshot.data!.map((category) {
                          final isSelected =
                              selectedCategoryIds.contains(category['id']);
                          return FilterChip(
                            label: Text(category['name']),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                selectedCategoryIds.add(category['id'] as int);
                              } else {
                                selectedCategoryIds.remove(category['id']);
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Update expense
                await _supabaseService.updateData(
                  'expenses',
                  expense['id'].toString(),
                  {
                    'amount': double.parse(amountController.text),
                    'description': descriptionController.text,
                    'date': selectedDate.toIso8601String(),
                    'currency_id': selectedCurrencyId,
                  },
                );

                // Delete existing category associations
                final existingCategories = await _supabaseService
                    .getData('expense_categories')
                    .then((ec) =>
                        ec.where((e) => e['expense_id'] == expense['id']));
                for (final category in existingCategories) {
                  await _supabaseService.deleteData(
                    'expense_categories',
                    category['id'].toString(),
                  );
                }

                // Add new category associations
                for (final categoryId in selectedCategoryIds) {
                  await _supabaseService.insertData('expense_categories', {
                    'expense_id': expense['id'],
                    'category_id': categoryId,
                    'user_id': _supabaseService.currentUser?.id,
                  });
                }

                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Expense updated successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating expense: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editCategory(Map<String, dynamic> category) async {
    final controller = TextEditingController(text: category['name']);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _supabaseService.updateData(
                  'categories',
                  category['id'].toString(),
                  {'name': controller.text},
                );
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Category updated successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating category: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _editCurrency(Map<String, dynamic> currency) async {
    final codeController = TextEditingController(text: currency['code']);
    final nameController = TextEditingController(text: currency['name']);
    final symbolController = TextEditingController(text: currency['symbol']);

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Currency'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Currency Code (e.g., USD)',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Currency Name (e.g., US Dollar)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: symbolController,
                decoration: const InputDecoration(
                  labelText: 'Currency Symbol (e.g., \$)',
                  border: OutlineInputBorder(),
                ),
                maxLength: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _supabaseService.updateData(
                  'currencies',
                  currency['id'].toString(),
                  {
                    'code': codeController.text.toUpperCase(),
                    'name': nameController.text,
                    'symbol': symbolController.text,
                  },
                );
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Currency updated successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating currency: $e')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spent'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Categories'),
            Tab(text: 'Currencies'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Expenses Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        title: const Text('Date'),
                        subtitle: Text(_selectedDate.toString().split(' ')[0]),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              _selectedDate = date;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _supabaseService.getData('currencies'),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }
                          return DropdownButtonFormField<int>(
                            value: _selectedCurrencyId,
                            decoration: const InputDecoration(
                              labelText: 'Currency',
                              border: OutlineInputBorder(),
                            ),
                            items: snapshot.data!.map((currency) {
                              return DropdownMenuItem<int>(
                                value: currency['id'] as int,
                                child: Text(
                                    '${currency['code']} - ${currency['name']}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCurrencyId = value;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: _supabaseService.getData('categories'),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Categories'),
                              Wrap(
                                spacing: 8.0,
                                children: snapshot.data!.map((category) {
                                  final isSelected = _selectedCategoryIds
                                      .contains(category['id']);
                                  return FilterChip(
                                    label: Text(category['name']),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          _selectedCategoryIds
                                              .add(category['id'] as int);
                                        } else {
                                          _selectedCategoryIds
                                              .remove(category['id']);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _addExpense,
                        child: const Text('Add Expense'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Recent Expenses',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _supabaseService.getData('expenses'),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final expense = snapshot.data![index];
                        return FutureBuilder<Map<String, dynamic>>(
                          future: _supabaseService
                              .getData('currencies')
                              .then((currencies) => currencies.firstWhere(
                                    (c) => c['id'] == expense['currency_id'],
                                  )),
                          builder: (context, currencySnapshot) {
                            if (!currencySnapshot.hasData) {
                              return const ListTile(
                                title: Text('Loading...'),
                              );
                            }
                            final currency = currencySnapshot.data!;
                            return ListTile(
                              title: Text(expense['description']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${expense['amount']} ${currency['symbol']} - ${expense['date'].toString().split('T')[0]}',
                                  ),
                                  FutureBuilder<List<String>>(
                                    future: _supabaseService
                                        .getData('expense_categories')
                                        .then((ec) => ec
                                            .where((e) =>
                                                e['expense_id'] ==
                                                expense['id'])
                                            .toList())
                                        .then((ec) async {
                                      final categories = await _supabaseService
                                          .getData('categories');
                                      return ec.map((e) {
                                        final category = categories.firstWhere(
                                          (c) => c['id'] == e['category_id'],
                                          orElse: () => {'name': 'Unknown'},
                                        );
                                        return category['name'] as String;
                                      }).toList();
                                    }),
                                    builder: (context, snapshot) {
                                      if (!snapshot.hasData) {
                                        return const SizedBox.shrink();
                                      }
                                      return Wrap(
                                        spacing: 4.0,
                                        children:
                                            snapshot.data!.map((categoryName) {
                                          return Chip(
                                            label: Text(
                                              categoryName,
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                            padding: EdgeInsets.zero,
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          );
                                        }).toList(),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      _editExpense(expense);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () async {
                                      try {
                                        // First delete expense_categories entries
                                        final categories =
                                            await _supabaseService
                                                .getData('expense_categories')
                                                .then((ec) => ec.where((e) =>
                                                    e['expense_id'] ==
                                                    expense['id']));
                                        for (final category in categories) {
                                          await _supabaseService.deleteData(
                                            'expense_categories',
                                            category['id'].toString(),
                                          );
                                        }
                                        // Then delete the expense
                                        await _supabaseService.deleteData(
                                          'expenses',
                                          expense['id'].toString(),
                                        );
                                        setState(() {});
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Error deleting expense: $e')),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // Categories Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _categoryNameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addCategory,
                  child: const Text('Add Category'),
                ),
                const SizedBox(height: 24),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _supabaseService.getData('categories'),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final category = snapshot.data![index];
                        return ListTile(
                          title: Text(category['name']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editCategory(category),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  try {
                                    await _supabaseService.deleteData(
                                      'categories',
                                      category['id'].toString(),
                                    );
                                    setState(() {});
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Error deleting category: $e')),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // Currencies Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _currencyCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Currency Code (e.g., USD)',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _currencyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Currency Name (e.g., US Dollar)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _currencySymbolController,
                  decoration: const InputDecoration(
                    labelText: 'Currency Symbol (e.g., \$)',
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 5,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _addCurrency,
                  child: const Text('Add Currency'),
                ),
                const SizedBox(height: 24),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _supabaseService.getData('currencies'),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final currency = snapshot.data![index];
                        return ListTile(
                          title:
                              Text('${currency['code']} - ${currency['name']}'),
                          subtitle: Text(currency['symbol']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editCurrency(currency),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  try {
                                    await _supabaseService.deleteData(
                                      'currencies',
                                      currency['id'].toString(),
                                    );
                                    setState(() {});
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Error deleting currency: $e')),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
