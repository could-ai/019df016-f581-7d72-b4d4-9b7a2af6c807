import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const PricingApp());
}

class PricingApp extends StatelessWidget {
  const PricingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saudi Pricing App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006C35), // Saudi Green
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const PricingScreen(),
      },
    );
  }
}

class PricingItem {
  String name;
  String unit;
  double quantity;
  double supplyPrice;
  double applyPrice;

  PricingItem({
    this.name = '',
    this.unit = 'm2',
    this.quantity = 1.0,
    this.supplyPrice = 0.0,
    this.applyPrice = 0.0,
  });

  double get total => quantity * (supplyPrice + applyPrice);
}

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  final List<PricingItem> _items = [
    PricingItem(name: 'Gypsum Board', unit: 'm2', quantity: 100, supplyPrice: 15, applyPrice: 20),
    PricingItem(name: 'Ceramic Tiles', unit: 'm2', quantity: 50, supplyPrice: 35, applyPrice: 25),
  ];

  double get grandTotal => _items.fold(0, (sum, item) => sum + item.total);

  void _addNewRow() {
    setState(() {
      _items.add(PricingItem());
    });
  }

  void _removeRow(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _exportToCsv() async {
    List<List<dynamic>> rows = [];
    
    // Headers
    rows.add([
      "Item Description", 
      "Unit", 
      "Qty", 
      "Supply Price (SAR)", 
      "Apply Price (SAR)", 
      "Total Price (SAR)"
    ]);

    // Data
    for (var item in _items) {
      rows.add([
        item.name,
        item.unit,
        item.quantity,
        item.supplyPrice,
        item.applyPrice,
        item.total,
      ]);
    }

    // Grand Total
    rows.add(["", "", "", "", "Grand Total", grandTotal]);

    String csv = const ListToCsvConverter().convert(rows);

    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/pricing_sheet.csv';
      final file = File(path);
      await file.writeAsString(csv);

      await Share.shareXFiles(
        [XFile(path)],
        text: 'Saudi Supply & Apply Pricing Sheet',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting file: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we're on a wide screen
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supply & Apply Estimator (KSA)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export to Excel (CSV)',
            onPressed: _exportToCsv,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isWide 
                ? _buildDesktopTable() 
                : _buildMobileList(),
          ),
          _buildSummaryBar(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewRow,
        tooltip: 'Add Item',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.builder(
      itemCount: _items.length,
      padding: const EdgeInsets.only(bottom: 80),
      itemBuilder: (context, index) {
        final item = _items[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: item.name,
                        decoration: const InputDecoration(
                          labelText: 'Item Description',
                          isDense: true,
                        ),
                        onChanged: (val) => item.name = val,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _removeRow(index),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        initialValue: item.unit,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          isDense: true,
                        ),
                        onChanged: (val) => item.unit = val,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        initialValue: item.quantity.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Qty',
                          isDense: true,
                        ),
                        onChanged: (val) {
                          setState(() {
                            item.quantity = double.tryParse(val) ?? 0.0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        initialValue: item.supplyPrice.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Supply (SAR)',
                          isDense: true,
                        ),
                        onChanged: (val) {
                          setState(() {
                            item.supplyPrice = double.tryParse(val) ?? 0.0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        initialValue: item.applyPrice.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Apply (SAR)',
                          isDense: true,
                        ),
                        onChanged: (val) {
                          setState(() {
                            item.applyPrice = double.tryParse(val) ?? 0.0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Row Total: ${item.total.toStringAsFixed(2)} SAR',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Item Description')),
              DataColumn(label: Text('Unit')),
              DataColumn(label: Text('Qty'), numeric: true),
              DataColumn(label: Text('Supply (SAR)'), numeric: true),
              DataColumn(label: Text('Apply (SAR)'), numeric: true),
              DataColumn(label: Text('Total (SAR)'), numeric: true),
              DataColumn(label: Text('')),
            ],
            rows: _items.asMap().entries.map((entry) {
              int index = entry.key;
              PricingItem item = entry.value;
              return DataRow(
                cells: [
                  DataCell(
                    SizedBox(
                      width: 200,
                      child: TextFormField(
                        initialValue: item.name,
                        decoration: const InputDecoration(border: InputBorder.none),
                        onChanged: (val) => item.name = val,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 60,
                      child: TextFormField(
                        initialValue: item.unit,
                        decoration: const InputDecoration(border: InputBorder.none),
                        onChanged: (val) => item.unit = val,
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue: item.quantity.toString(),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(border: InputBorder.none),
                        onChanged: (val) {
                          setState(() {
                            item.quantity = double.tryParse(val) ?? 0.0;
                          });
                        },
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue: item.supplyPrice.toString(),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(border: InputBorder.none),
                        onChanged: (val) {
                          setState(() {
                            item.supplyPrice = double.tryParse(val) ?? 0.0;
                          });
                        },
                      ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue: item.applyPrice.toString(),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(border: InputBorder.none),
                        onChanged: (val) {
                          setState(() {
                            item.applyPrice = double.tryParse(val) ?? 0.0;
                          });
                        },
                      ),
                    ),
                  ),
                  DataCell(Text(item.total.toStringAsFixed(2))),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _removeRow(index),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Grand Total',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            '${grandTotal.toStringAsFixed(2)} SAR',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
