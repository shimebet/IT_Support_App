import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ExchangeRatePage extends StatefulWidget {
  const ExchangeRatePage({super.key, required this.token});
  final String token; // Not needed for this API but kept for consistency

  @override
  _ExchangeRatePageState createState() => _ExchangeRatePageState();
}

class _ExchangeRatePageState extends State<ExchangeRatePage> {
  final formKey = GlobalKey<FormState>();
  String? selectedCurrency;
  double? rate;
  List<String> currencies = [];
  Map<String, double> conversionRates = {};
  bool loading = true;
  bool showTable = false;

  @override
  void initState() {
    super.initState();
    fetchExchangeRates();
  }

  Future<void> fetchExchangeRates() async {
    setState(() {
      loading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://v6.exchangerate-api.com/v6/c2f76c38dc9ac10fb7a48d9d/latest/USD'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final rawRates = Map<String, dynamic>.from(data['conversion_rates']);
        final rates = rawRates.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );

        setState(() {
          conversionRates = rates;
          currencies = rates.keys.toList();
          loading = false;
        });
      } else {
        throw Exception('Failed to load exchange rates');
      }
    } catch (e) {
      print('Error fetching rates: $e');
      setState(() {
        loading = false;
      });
    }
  }

  void onCurrencySelected(String? value) {
    setState(() {
      selectedCurrency = value;
      rate = conversionRates[value];
    });
  }

  void onViewPressed() {
    setState(() {
      showTable = !showTable;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('MM/dd/yyyy').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Exchange Rate',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 26.0,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 134, 23, 116),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: formKey,
                child: ListView(
                  children: [
                    Center(
                      child: Text(
                        'Date: $formattedDate',
                        style: const TextStyle(
                          color: Color.fromARGB(255, 151, 2, 126),
                          fontWeight: FontWeight.bold,
                          fontSize: 24.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Currency (vs USD)',
                        border: OutlineInputBorder(),
                      ),
                      items: currencies.map((currency) {
                        return DropdownMenuItem(
                          value: currency,
                          child: Text(currency),
                        );
                      }).toList(),
                      onChanged: onCurrencySelected,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a currency';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Exchange Rate (1 USD = ?)',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      controller: TextEditingController(
                        text: rate?.toStringAsFixed(4) ?? '',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          onViewPressed();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color.fromARGB(255, 170, 5, 134),
                      ),
                      child: Text(showTable ? 'Hide Table' : 'View All'),
                    ),
                    const SizedBox(height: 16),
                    showTable
                        ? SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Currency')),
                                DataColumn(label: Text('Rate (1 USD = ?)')),
                              ],
                              rows: conversionRates.entries.map((entry) {
                                return DataRow(cells: [
                                  DataCell(Text(entry.key)),
                                  DataCell(Text(entry.value.toStringAsFixed(4))),
                                ]);
                              }).toList(),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ],
                ),
              ),
            ),
    );
  }
}
