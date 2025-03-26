import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart'; // Ensure provider is imported
import 'dart:math';
import '../global_state.dart';
import '../constants.dart';

class BillPaymentPage extends StatefulWidget {
  final String token;

  const BillPaymentPage({super.key, required this.token});

  @override
  _BillPaymentPageState createState() => _BillPaymentPageState();
}

class _BillPaymentPageState extends State<BillPaymentPage> {
  String? _selectedFromAccount;
  String? _selectedTransferType;
  List<Map<String, dynamic>> _accounts = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _billController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;
  String? _transactionId;
  double? _amount;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAccounts();
    });
  }

  Future<void> _fetchAccounts() async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.fetchAccounts),
        headers: _buildHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['Accounts'] != null && data['Accounts'].isNotEmpty) {
          final accountsList = List<Map<String, dynamic>>.from(data['Accounts']);
          setState(() {
            _accounts = accountsList;
          });
        } else {
          throw Exception('No accounts found');
        }
      } else {
        throw Exception(
            'Failed to fetch accounts: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error fetching accounts: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching accounts: $error')),
      );
    }
  }

  Map<String, String> _buildHeaders() {
    return {
      'X-Kony-Authorization': ' ${widget.token}',
      'Content-Type': 'application/json',
      'X-Kony-App-Key': ApiHeaders.appKey,
      'X-Kony-App-Secret': ApiHeaders.appSecret,
    };
  }

  Future<void> _getBillAmount() async {
    setState(() {
      _isLoading = true;
    });

    final globalState = Provider.of<GlobalState>(context, listen: false);
    globalState.setLoading(true);

    final payload = {
      "bill_id": _billController.text,
      "current_serviceID": "getCustomerBillData",
      "current_appID": "XD_BillService",
      "appID": "XD_BillService",
      "biller_id": "215521",
      "curent_apiVersion": "1.0",
      "serviceID": "getCustomerBillData"
    };

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.getBillAmount),
        headers: _buildHeaders(),
        body: jsonEncode(payload),
      );

      globalState.setLoading(false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['bill_id'] == null || data['amount'] == null) {
          _showInvalidBillIdAlert();
        } else {
          setState(() {
            _transactionId = data['bill_id'];
            _amount = double.tryParse(data['amount'].toString());
          });
          _showConfirmationPage(data);
        }
      } else {
        throw Exception(
            'Failed to fetch bill amount: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (error) {
      globalState.setLoading(false);
      print('Error fetching bill amount: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching bill amount: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showInvalidBillIdAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Invalid Bill ID'),
          content: const Text('This bill ID does not exist or is invalid.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationPage(Map<String, dynamic> billData) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConfirmationPage(
          fromAccount: _selectedFromAccount!,
          amount: _amount.toString(),
          billId: _billController.text,
          transactionId: _transactionId!,
          note: _noteController.text,
          onSubmit: () => _makePayment(billData),
        ),
      ),
    );
  }

  Future<void> _makePayment(Map<String, dynamic> billData) async {
    final globalState = Provider.of<GlobalState>(context, listen: false);
    globalState.setLoading(true);

    final payload = {
      "amount": billData['amount'].toString(),
      "fromAccountNumber": _selectedFromAccount,
      "current_serviceID": "createErcaTransactions",
      "billManifestId": billData['billManifestId'],
      "message": "WITH TAX ON PAYM",
      "transactionsNotes": "NBE Account:0100191040217 Center: AA BRANCH WEST  Period:2/2024",
      "toAccountNumber": "ERCA${billData['billManifestId']}",
      "current_appID": "ErcaTaxTransaction",
      "appID": "ErcaTaxTransaction",
      "name": "TMOR42444269ZTTHPSP",
      "documentRefNo": _billController.text,
      "curent_apiVersion": "1.0",
      "deliveryDate": DateTime.now().toIso8601String(),
      "serviceID": "createErcaTransactions"
    };

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.makePayment),
        headers: _buildHeaders(),
        body: jsonEncode(payload),
      );

      globalState.setLoading(false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _showSuccessPage();
      } else {
        throw Exception(
            'Failed to make payment: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (error) {
      globalState.setLoading(false);
      print('Error making payment: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error making payment: $error')),
      );
    }
  }

  void _showSuccessPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SuccessPage(
          fromAccount: _selectedFromAccount!,
          amount: _amount.toString(),
          transactionDate: DateTime.now(),
        ),
      ),
    );
  }

  Widget _buildTransferForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedFromAccount,
              decoration: const InputDecoration(
                labelText: 'From Account',
                contentPadding: EdgeInsets.symmetric(vertical: 2.0),
              ),
              items: _accounts.map((account) {
                String accountName = account['accountName'] ?? '';
                String accountId = account['accountID'] ?? '';
                if (accountName.length > 15) {
                  List<String> words = accountName.split(' ');
                  String newAccountName = '';
                  if (words.isNotEmpty) {
                    newAccountName +=
                        words[0].substring(0, min(3, words[0].length));
                  }
                  if (words.length > 1) {
                    newAccountName +=
                        ' ${words[1].substring(0, min(3, words[1].length))}';
                  }
                  if (words.length > 2) {
                    newAccountName +=
                        ' ${words[2].substring(0, min(3, words[2].length))}';
                  }
                  accountName = newAccountName;
                }
                String formattedAccountId = accountId.replaceAllMapped(
                    RegExp(r".{4}"), (match) => "${match.group(0)} ");
                return DropdownMenuItem<String>(
                  value: account['accountID'],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            accountName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                            ),
                          ),
                          Text(
                            '$formattedAccountId, Bal: ${account['availableBalance']} ETB',
                            style: const TextStyle(
                              color: Color.fromARGB(255, 230, 177, 3),
                              fontSize: 11.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFromAccount = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select an account';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _billController,
              decoration: const InputDecoration(
                labelText: 'Bill ID',
                contentPadding: EdgeInsets.symmetric(vertical: 2.0),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the bill ID';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note',
                contentPadding: EdgeInsets.symmetric(vertical: 2.0),
              ),
            ),
            const SizedBox(height: 24.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // ElevatedButton(
                //   onPressed: () {
                //     Navigator.pop(context);
                //   },
                //   style: ButtonStyle(
                //     backgroundColor: MaterialStateProperty.all<Color>(
                //         const Color.fromARGB(255, 185, 3, 155)),
                //     foregroundColor:
                //         MaterialStateProperty.all<Color>(Colors.white),
                //     padding: MaterialStateProperty.all<EdgeInsets>(
                //         const EdgeInsets.symmetric(
                //             horizontal: 24, vertical: 12)),
                //     textStyle: MaterialStateProperty.all<TextStyle>(
                //         const TextStyle(fontSize: 16)),
                //   ),
                //   child: const Text('Cancel'),
                // ),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            _getBillAmount();
                          }
                        },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                        const Color.fromARGB(255, 185, 3, 155)),
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.white),
                    padding: MaterialStateProperty.all<EdgeInsets>(
                        const EdgeInsets.symmetric(
                            horizontal: 100, vertical: 12)),
                    textStyle: MaterialStateProperty.all<TextStyle>(
                        const TextStyle(fontSize: 16)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Get Amount'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bill Payment',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26.0),
        ),
        backgroundColor: const Color.fromARGB(255, 134, 23, 116),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          ExpansionTile(
            title: const Text(
              'ERCA Tax Payment',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            leading: const Icon(Icons.payment),
            onExpansionChanged: (isExpanded) {
              if (isExpanded) {
                setState(() {
                  _selectedTransferType = 'ERCA Tax Payment';
                });
              }
            },
            children: _selectedTransferType == 'ERCA Tax Payment'
                ? [_buildTransferForm()]
                : [],
          ),
        ],
      ),
    );
  }
}

class ConfirmationPage extends StatelessWidget {
  final String fromAccount;
  final String amount;
  final String billId;
  final String transactionId;
  final String note;
  final VoidCallback onSubmit;

  const ConfirmationPage({
    super.key,
    required this.fromAccount,
    required this.amount,
    required this.billId,
    required this.transactionId,
    required this.note,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final globalState = Provider.of<GlobalState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Payment'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('From Account: $fromAccount'),
            const SizedBox(height: 8.0),
            Text('Amount: $amount ETB'),
            const SizedBox(height: 8.0),
            Text('Bill ID: $billId'),
            const SizedBox(height: 8.0),
            Text('Reference ID: $transactionId'),
            const SizedBox(height: 8.0),
            Text('Note: $note'),
            const SizedBox(height: 16.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: globalState.isLoading ? null : onSubmit,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 199, 4, 140),
                  minimumSize: const Size(double.infinity, 36),
                ),
                child: globalState.isLoading
                    ? const CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text('Confirm'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SuccessPage extends StatelessWidget {
  final String fromAccount;
  final String amount;
  final DateTime transactionDate;

  const SuccessPage({
    super.key,
    required this.fromAccount,
    required this.amount,
    required this.transactionDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Success'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('From Account: $fromAccount'),
            const SizedBox(height: 8.0),
            Text('Amount: $amount ETB'),
            const SizedBox(height: 8.0),
            Text('Transaction Date: $transactionDate'),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
