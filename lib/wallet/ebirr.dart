import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import '../global_state.dart';
import '../constants.dart';

class EbirrPage extends StatefulWidget {
  final String token;
  const EbirrPage({super.key, required this.token});

  @override
  _EbirrPageState createState() => _EbirrPageState();
}

class _EbirrPageState extends State<EbirrPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String? _selectedFromAccount;
  List<Map<String, dynamic>> _accounts = [];
  bool _isLoading = false;

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
          final accountsList =
              List<Map<String, dynamic>>.from(data['Accounts']);
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

  Future<void> _performEbirrTransaction() async {
    final url = Uri.parse(ApiConstants.performEbirrTransaction);
    final headers = _buildHeaders();

    final body = jsonEncode({
      "instId": "231438",
      "current_serviceID": "a2aEnquiry",
      "current_appID": "TransfertoEbirr",
      "appID": "TransfertoEbirr",
      "curent_apiVersion": "1.0",
      "accountNumber": _phoneController.text,
      "serviceID": "a2aEnquiry",
      "DateTime": DateTime.now().toIso8601String(),
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final now = DateTime.now();
        _showConfirmationPage(responseData, now);
      } else {
        throw Exception(
            'Failed to fetch Ebirr data: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error performing Ebirr transaction: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error performing Ebirr transaction')),
      );
    }
  }

  void _showConfirmationPage(Map<String, dynamic> ebirrData, DateTime now) {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ConfirmationPage(
            fromAccount: _selectedFromAccount!,
            phoneNumber: _phoneController.text,
            amount: _amountController.text,
            note: _noteController.text,
            beneficiaryName: ebirrData['reply']['beneficiaryName'] ?? '',
            transactionDate: now,
            onSubmit: () => _performTransaction(ebirrData),
          ),
        ),
      );
    }
  }

  Future<void> _performTransaction(Map<String, dynamic> ebirrData) async {
    final globalState = Provider.of<GlobalState>(context, listen: false);
    globalState.setLoading(true);

    final url = Uri.parse(ApiConstants.performTransaction);
    final headers = _buildHeaders();
    final beneficiaryName = ebirrData['reply']['beneficiaryName'] ?? '';
    final account = _phoneController.text;
    final formattedBeneficiaryName = account.replaceAll('251', '');
    final now = DateTime.now();
    final formattedNow = '${now.toUtc().toIso8601String().split('.').first}Z';

    final body = jsonEncode({
      "amount": _amountController.text,
      "transactionId": "",
      "frequencyType": "Once",
      "fromAccountNumber": _selectedFromAccount,
      "iban": "",
      "isScheduled": "0",
      "frequencyStartDate": formattedNow,
      "frequencyEndDate": formattedNow,
      "scheduledDate": formattedNow,
      "toAccountNumber": "1000171307205",
      "ExternalAccountNumber": "1000171307205",
      "paymentType": "",
      "paidBy": "",
      "serviceName": "BILL_PAY_CREATE",
      "beneficiaryName": formattedBeneficiaryName,
      "beneficiaryNickname": "EBirr",
      "transactionsNotes": null,
      "transactionType": "ExternalTransfer",
      "transactionCurrency": "ETB",
      "fromAccountCurrency": "ETB",
      "toAccountCurrency": "ETB",
      "numberOfRecurrences": "",
      "uploadedattachments": "",
      "deletedDocuments": "",
      "transactionAmount": _amountController.text,
      "serviceCharge": "0.0",
      "debitReference": "Topup0$formattedBeneficiaryName",
      "remittanceInformation": "Topup0$formattedBeneficiaryName",
      "creditReference": "Topup0$formattedBeneficiaryName",
      "isBillPayment": true,
      "billerName": "EBirr"
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      final responseBody = jsonDecode(response.body);
      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        _showSuccessPage(beneficiaryName, now);
      } else {
        throw Exception(
            'Failed to perform transaction: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error performing transaction: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error performing transaction')),
      );
    } finally {
      globalState.setLoading(false);
    }
  }

  void _showSuccessPage(String beneficiaryName, DateTime transactionDate) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SuccessPage(
          fromAccount: _selectedFromAccount!,
          phoneNumber: _phoneController.text,
          beneficiaryName: beneficiaryName,
          amount: _amountController.text,
          note: _noteController.text,
          transactionDate: transactionDate,
        ),
      ),
    );
  }

  Widget _buildTransferForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
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
                          words.sublist(0, min(2, words.length)).join(' ');
                      if (words.length > 2) {
                        newAccountName += '...';
                      }
                    }
                    accountName = newAccountName;
                  }

                  return DropdownMenuItem<String>(
                    value: account['accountID'],
                    child: Text('$accountName ($accountId)'),
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
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  contentPadding: EdgeInsets.symmetric(vertical: 2.0),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  contentPadding: EdgeInsets.symmetric(vertical: 2.0),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
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
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _isLoading = true;
                        });
                        _performEbirrTransaction();
                      },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all<Color>(
                  const Color.fromARGB(255, 185, 3, 155)),
              foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
              padding: WidgetStateProperty.all<EdgeInsets>(
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              textStyle: WidgetStateProperty.all<TextStyle>(
                  const TextStyle(fontSize: 16)),
            ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final globalState = Provider.of<GlobalState>(context);
    return Scaffold(
  

            appBar: AppBar(
        title: const Text(
          'E-Birr',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 26.0,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 134, 23, 116),
      ),
      body: globalState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildTransferForm(),
    );
  }
}

class ConfirmationPage extends StatelessWidget {
  final String fromAccount;
  final String phoneNumber;
  final String amount;
  final String note;
  final String beneficiaryName;
  final DateTime transactionDate;
  final VoidCallback onSubmit;

  const ConfirmationPage({
    super.key,
    required this.fromAccount,
    required this.phoneNumber,
    required this.amount,
    required this.note,
    required this.beneficiaryName,
    required this.transactionDate,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final globalState = Provider.of<GlobalState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Confirm Transfer',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 26.0,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 134, 23, 116),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('From Account: $fromAccount'),
            const SizedBox(height: 8.0),
            Text('Phone Number: $phoneNumber'),
            const SizedBox(height: 8.0),
            Text('Beneficiary Name: $beneficiaryName'),
            const SizedBox(height: 8.0),
            Text('Amount: $amount'),
            const SizedBox(height: 8.0),
            Text('Note: $note'),
            const SizedBox(height: 8.0),
            Text('Date of Tran: ${transactionDate.toString()}'),
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
  final String phoneNumber;
  final String beneficiaryName;
  final String amount;
  final String note;
  final DateTime transactionDate;

  const SuccessPage({
    super.key,
    required this.fromAccount,
    required this.phoneNumber,
    required this.beneficiaryName,
    required this.amount,
    required this.note,
    required this.transactionDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transfer Successful',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 26.0,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 134, 23, 116),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('From Account: $fromAccount'),
            const SizedBox(height: 8.0),
            Text('Phone Number: $phoneNumber'),
            const SizedBox(height: 8.0),
            Text('Beneficiary Name: $beneficiaryName'),
            const SizedBox(height: 8.0),
            Text('Amount: $amount'),
            const SizedBox(height: 8.0),
            Text('Note: $note'),
            const SizedBox(height: 8.0),
            Text('Date of Transaction: ${transactionDate.toString()}'),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Go back to previous page
                Navigator.of(context).pop(); // Close the success page
                // Navigator.of(context).pop();
              },
             style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Thank You! Back To Home'),
            ),
          ],
        ),
      ),
    );
  }
}
