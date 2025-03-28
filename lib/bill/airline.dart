import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:provider/provider.dart';
import '../global_state.dart';
import '../constants.dart';

class AirLinePage extends StatefulWidget {
  final String token;

  const AirLinePage({super.key, required this.token});

  @override
  _AirLinePageState createState() => _AirLinePageState();
}

class _AirLinePageState extends State<AirLinePage> {
  String? _selectedFromAccount;
  String? _selectedTransferType;
  List<Map<String, dynamic>> _accounts = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _billController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
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
      'X-Kony-App-Key': ApiHeaders.appKey, // Use constant from ApiHeaders
      'X-Kony-App-Secret': ApiHeaders.appSecret, // Use constant from ApiHeaders
    };
  }

  Future<void> _getAirlineBillAmount() async {
    final globalState = Provider.of<GlobalState>(context, listen: false);
    globalState.setLoading(true);

    final response = await http.post(
      Uri.parse(ApiConstants.getAirlineBillAmount),
      headers: _buildHeaders(),
      body: jsonEncode(<String, String>{
        "password": "orange123%",
        "current_serviceID": "paymentInquiryy",
        "pnr": _billController.text,
        "current_appID": "EthioAirline",
        "appID": "EthioAirline",
        "curent_apiVersion": "1.0",
        "serviceID": "paymentInquiryy",
        "username": "apicbetest"
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      double? amount = data['body'][0]['amount'] != null
          ? double.tryParse(data['body'][0]['amount'].toString())
          : null;

      setState(() {
        _transactionId = data['body'][0]['reference'].toString();
        _amount = amount;
      });

      globalState.setLoading(false);

      _showConfirmationPage();
    } else {
      globalState.setLoading(false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to get amount.'),
      ));
    }
  }

  Future<void> _performBillPayment() async {
    final globalState = Provider.of<GlobalState>(context, listen: false);
    globalState.setLoading(true);

    final url = Uri.parse(ApiConstants.performTransaction);
    final headers = _buildHeaders();

    String formatDateTime(DateTime dateTime) {
      return '${dateTime.toUtc().toIso8601String().split('.').first}Z';
    }

    final now = DateTime.now();
    final formattedNow = formatDateTime(now);

    final body = jsonEncode({
      "amount": _amount?.toString(),
      "transactionId": "",
      "frequencyType": "Once",
      "fromAccountNumber": _selectedFromAccount,
      "iban": "",
      "isScheduled": "0",
      "frequencyStartDate": formattedNow,
      "frequencyEndDate": formattedNow,
      "scheduledDate": formattedNow,
      "toAccountNumber": "1000140737686",
      "ExternalAccountNumber": "1000140737686",
      "paymentType": "",
      "paidBy": "",
      "serviceName": "BILL_PAY_CREATE",
      "beneficiaryName": "05951622[Rediet Ejigu]",
      "beneficiaryNickname": "Ethiopian Airline Ticket",
      "transactionsNotes": _noteController.text,
      "transactionType": "ExternalTransfer",
      "transactionCurrency": "ETB",
      "fromAccountCurrency": "ETB",
      "toAccountCurrency": "ETB",
      "transactionAmount": "",
      "serviceCharge": "",
      "notes": null,
      "debitReference": "123456",
      "remittanceInformation": "123456",
      "creditReference": "123456",
      "isBillPayment": true,
      "billerName": "Ethiopian Airline Ticket"
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      final responseBody = jsonDecode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        globalState.setLoading(false);
        _showSuccessPage();
      } else {
        globalState.setLoading(false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Bill Payment Failed'),
            content: Text(responseBody['message'] ?? 'Bill Payment Failed'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      }
    } catch (error) {
      globalState.setLoading(false);
      print('Error submitting Bill Payment Failed: $error');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to submit Bill Payment Failed request: $error'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }

  void _showConfirmationPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConfirmationPage(
          fromAccount: _selectedFromAccount!,
          amount: _amount.toString(),
          transactionId: _transactionId!,
          note: _noteController.text,
          onSubmit: _performBillPayment,
        ),
      ),
    );
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

  Widget _buildAirLineTransferForm() {
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
                labelText: 'PNR',
                contentPadding: EdgeInsets.symmetric(vertical: 2.0),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the PNR';
                }
                return null;
              },
            ),
            const SizedBox(height: 16.0),
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                contentPadding: EdgeInsets.symmetric(vertical: 2.0),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: context.watch<GlobalState>().isLoading
                  ? null
                  : () {
                      if (_formKey.currentState?.validate() ?? false) {
                        _getAirlineBillAmount();
                      }
                    },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color.fromARGB(255, 199, 4, 140),
                minimumSize: const Size(double.infinity, 36),
              ),
              child: context.watch<GlobalState>().isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  : const Text('Get Amount'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _billController.dispose();
    _noteController.dispose();
    super.dispose();
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
              'Ethio AirLine',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            leading: const Icon(Icons.air),
            onExpansionChanged: (isExpanded) {
              if (isExpanded) {
                setState(() {
                  _selectedTransferType = 'EthioAirline';
                });
              }
            },
            children: _selectedTransferType == 'EthioAirline'
                ? [_buildAirLineTransferForm()]
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
  final String transactionId;
  final String note;
  final VoidCallback onSubmit;

  const ConfirmationPage({
    super.key,
    required this.fromAccount,
    required this.amount,
    required this.transactionId,
    required this.note,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Transfer'),
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
            Text('Reference Id: $transactionId'),
            const SizedBox(height: 8.0),
            Text('Note: $note'),
            const SizedBox(height: 16.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: context.watch<GlobalState>().isLoading
                    ? null
                    : onSubmit,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 199, 4, 140),
                  minimumSize: const Size(double.infinity, 36),
                ),
                child: context.watch<GlobalState>().isLoading
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
        title: const Text('Success'),
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
