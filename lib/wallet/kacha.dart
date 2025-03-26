import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async';
import '../global_state.dart';
import '../constants.dart';

class KachaPage extends StatefulWidget {
  final String token;
  const KachaPage({super.key, required this.token});

  @override
  _KachaPageState createState() => _KachaPageState();
}

class _KachaPageState extends State<KachaPage> {
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

  String _generateRandomString(int minLength, int maxLength) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final Random rnd = Random();
    final length = minLength + rnd.nextInt(maxLength - minLength + 1);
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  Future<void> _performKachaTransaction() async {
    final url = Uri.parse(ApiConstants.performKachaTransaction);
    final headers = _buildHeaders();
    final trnumber = 'FT23TRS' + _generateRandomString(1, 9);
    final body = jsonEncode({
      "trnumber": trnumber,
      "current_serviceID": "Query",
      "current_appID": "Kacha",
      "appID": "Kacha",
      "curent_apiVersion": "1.0",
      "serviceID": "Query",
      "account": _phoneController.text,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final now = DateTime.now();
        _showConfirmationPage(responseData, now);
      } else {
        throw Exception(
            'Failed to fetch Kacha data: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error performing Kacha transaction: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error performing Kacha transaction')),
      );
    }
  }

  void _showConfirmationPage(Map<String, dynamic> kachaData, DateTime now) {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ConfirmationPage(
            fromAccount: _selectedFromAccount!,
            phoneNumber: _phoneController.text,
            amount: _amountController.text,
            note: _noteController.text,
            beneficiaryName: kachaData['NS1:QueryResponse']['name'] ?? '',
            transactionDate: now,
            onSubmit: () => _performTransaction(kachaData),
          ),
        ),
      );
    }
  }

 Future<void> _performTransaction(Map<String, dynamic> kachaData) async {
  final globalState = Provider.of<GlobalState>(context, listen: false);
  globalState.setLoading(true); // Start loading

  final url = Uri.parse(ApiConstants.performTransaction);
  final headers = _buildHeaders();
  final beneficiaryName = kachaData['NS1:QueryResponse']['name'] ?? '';
  final account = kachaData['NS1:QueryResponse']['account'] ?? '';
  final formattedBeneficiaryName = account.replaceAll('251', '');
  final now = DateTime.now();
  final formattedNow = now.toUtc().toIso8601String().split('.').first + 'Z';

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
    "beneficiaryNickname": "Kacha",
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
    "billerName": "Kacha"
  });

  try {
    final response =
        await http.post(url, headers: headers, body: body);
    final responseBody = jsonDecode(response.body);
    if (response.statusCode == 200 && responseBody['status'] == 'success') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SuccessPage(
            fromAccount: _selectedFromAccount!,
            phoneNumber: _phoneController.text,
            beneficiaryName: beneficiaryName,
            amount: _amountController.text,
            note: _noteController.text,
            transactionDate: now,
          ),
        ),
      );
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
    globalState.setLoading(false); // Stop loading
  }
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
                      RegExp(r'.{4}'), (match) => '${match.group(0)} ');
                  return DropdownMenuItem<String>(
                    value: accountId,
                    child: Text('$accountName - $formattedAccountId'),
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
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  final phone = value.trim();
                  if (!RegExp(r'^2519\d{8}$').hasMatch(phone)) {
                    return 'Phone number must start with 2519 and be 10 digits long';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter amount';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Note'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        _performKachaTransaction();
                      },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                      const Color.fromARGB(255, 185, 3, 155)),
                  foregroundColor:
                      MaterialStateProperty.all<Color>(Colors.white),
                  padding: MaterialStateProperty.all<EdgeInsets>(
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                  textStyle: MaterialStateProperty.all<TextStyle>(
                      const TextStyle(fontSize: 16)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text('Submit'),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kacha Transaction',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 26.0,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 134, 23, 116),
      ),
      body: _buildTransferForm(),
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: SizedBox(
          height: 300.0,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(1.0),
              side: BorderSide(
                color: Colors.grey.shade300,
                width: 1.0,
              ),
            ),
            elevation: 1.0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20.0),
                  Text('Transfer From: $fromAccount'),
                  Text('Phone Number: $phoneNumber'),
                  Text('Beneficiary Name: $beneficiaryName'),
                  Text('Amount: $amount'),
                  Text('Note: $note'),
                  Text('Date of Tran: ${transactionDate.toString()}'),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Go back to previous page
                        Navigator.of(context).pop(); // Close the success page
                        Navigator.of(context).pop(); 
                      },
                style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Thank You! Back To Home'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
          'Confirmation',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 26.0,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 134, 23, 116),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: SizedBox(
          height: 300.0,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(1.0),
              side: BorderSide(
                color: Colors.grey.shade300,
                width: 1.0,
              ),
            ),
            elevation: 1.0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20.0),
                  Text('From Account: $fromAccount'),
                  Text('Phone Number: $phoneNumber'),
                  Text('Beneficiary Name: $beneficiaryName'),
                  Text('Amount: $amount'),
                  Text('Note: $note'),
                  Text('Date of Tran: ${transactionDate.toString()}'),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: globalState.isLoading ? null : onSubmit,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            const Color.fromARGB(255, 199, 4, 140),
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
          ),
        ),
      ),
    );
  }
}
