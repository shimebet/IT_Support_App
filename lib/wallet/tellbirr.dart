import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import '../global_state.dart';
import '../constants.dart';

class TellBirrPage extends StatefulWidget {
  final String token;
  const TellBirrPage({Key? key, required this.token}) : super(key: key);

  @override
  _TellBirrPageState createState() => _TellBirrPageState();
}

class _TellBirrPageState extends State<TellBirrPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedTransferType;
  String? _selectedFromAccount;
  String? _selectedSubTransferType;
  late String username = "";
  late String accountname = "";
  late String phone = "";
  late String balance = "";
  late String accountNumber = "";
  late String currentDate = getCurrentDate();
  List<Map<String, dynamic>> _accounts = [];
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _toAccountController = TextEditingController();
  String concatenatedValue = "";

  void _concatenatePhoneNumber() {
    final phone = Provider.of<GlobalState>(context, listen: false).phone;
    setState(() {
      concatenatedValue = "Topup0$phone";
    });
  }

  @override
  void initState() {
    super.initState();
    _concatenatePhoneNumber();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAccounts();
    });
  }

  static String getCurrentDate() {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('MMMM dd, yyyy');
    return formatter.format(now);
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
            if (_accounts.isNotEmpty) {
              final account = _accounts[0];
              username = account['nickName'] ?? '';
              accountname = account['accountName'] ?? '';
              balance = account['availableBalance'] ?? 'Birr 0.00';
              accountNumber = account['accountID'] ?? '';
            }
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

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _toAccountController.dispose();
    super.dispose();
  }

  void _selectTransferType(String transferType) {
    setState(() {
      _selectedTransferType = transferType;
    });
  }

  Future<void> _performTellBirrTransfer() async {
    final globalState = Provider.of<GlobalState>(context, listen: false);
    globalState.setLoading(true);
    final url = Uri.parse(ApiConstants.performTransaction);
    final headers = _buildHeaders();

    String formatDateTime(DateTime dateTime) {
      return dateTime.toUtc().toIso8601String().split('.').first + 'Z';
    }

    final now = DateTime.now();
    final formattedNow = formatDateTime(now);

    final body = json.encode({
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
      "beneficiaryName": "911500391",
      "beneficiaryNickname": "Telebirr",
      "transactionsNotes": null,
      "transactionType": "ExternalTransfer",
      "transactionCurrency": "ETB",
      "fromAccountCurrency": "ETB",
      "toAccountCurrency": "ETB",
      "numberOfRecurrences": "",
      "uploadedattachments": "",
      "deletedDocuments": "",
      "transactionAmount": _amountController.text,
      "serviceCharge": "",
      "notes": _noteController.text,
      "debitReference": "Topup0911500391",
      "remittanceInformation": "Topup0911500391",
      "creditReference": "Topup0911500391",
      "isBillPayment": true,
      "billerName": "Telebirr"
    });
    try {
      final response = await http.post(url, headers: headers, body: body);
      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['status'] == "success") {
        globalState.setLoading(false); // Stop loading here
        // await Future.delayed(Duration(seconds: 2));
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SuccessPage(
              fromAccount: _selectedFromAccount!,
              phoneNumber: "0911500391",
              beneficiaryName: "Telebirr",
              amount: _amountController.text,
              note: _noteController.text,
              transactionDate: now,
            ),
          ),
        );
      } else {
         globalState.setLoading(false);
        String errorMessage = responseData['message'] ?? 'Unknown error';
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Transfer Failed'),
            content: Text(errorMessage),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
       globalState.setLoading(false);
      print('Error occurred: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Transfer Failed'),
          content: Text('An error occurred: $e'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _showConfirmationPage() {
    if (_formKey.currentState?.validate() ?? false) {
      final now = DateTime.now();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ConfirmationPage(
            fromAccount: _selectedFromAccount!,
            phoneNumber: "0911500391",
            beneficiaryName: "Telebirr",
            amount: _amountController.text,
            note: _noteController.text,
            transactionDate: now,
            onSubmit: _performTellBirrTransfer,
          ),
        ),
      );
    }
  }

  Widget _buildTransferForm() {
    if (_selectedTransferType == null) {
      return const SizedBox.shrink();
    }
    if (_selectedTransferType == 'Transfer To Tell Birr' &&
        _selectedSubTransferType != null) {
      if (_selectedSubTransferType == 'Transfer To Own Tell Birr') {
        return _buildOwnTellBirrTransferForm();
      }
    }
    return Container();
  }

  Widget _buildOwnTellBirrTransferForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedFromAccount,
            decoration: const InputDecoration(
              labelText: 'From Account',
              contentPadding: EdgeInsets.symmetric(
                vertical: 2.0,
              ),
            ),
            items: _accounts.map((account) {
              String accountName = account['accountName'] ?? '';
              String accountId = account['accountID'] ?? '';
              String phone = concatenatedValue ?? '';
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
                if (words.length > 3) newAccountName += '...';
                accountName = newAccountName;
              }
              String formattedAccountId = accountId.length > 7
                  ? '${accountId.substring(0, 4)}...${accountId.substring(accountId.length - 3)}'
                  : accountId;

              return DropdownMenuItem<String>(
                value: account['accountID'],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
              if (value == null) {
                return 'Please select a source account';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the amount to transfer';
              } else if (double.tryParse(value) == null ||
                  double.parse(value) <= 0) {
                return 'Amount must be greater than zero';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Reason',
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _showConfirmationPage();
              }
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                  const Color.fromARGB(255, 185, 3, 155)),
              foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
              padding: MaterialStateProperty.all<EdgeInsets>(
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              textStyle: MaterialStateProperty.all<TextStyle>(
                  const TextStyle(fontSize: 16)),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferTypeButton({
    required String transferType,
    required IconData icon,
    required String label,
  }) {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: OutlinedButton.icon(
        onPressed: () => _selectTransferType(transferType),
        icon: Container(
          padding: const EdgeInsets.all(2),
          child: Icon(icon),
        ),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          alignment: Alignment.centerLeft,
          side: const BorderSide(color: Color.fromARGB(255, 249, 249, 250)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
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
          'Transfer To Tell Birr',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.0),
        ),
        backgroundColor: const Color.fromARGB(255, 134, 23, 116),
      ),
      body: ListView(
        children: [
      
              ListTile(
                onTap: () {
                  setState(() {
                    _selectedTransferType = 'Transfer To Tell Birr';
                    _selectedSubTransferType = 'Transfer To Own Tell Birr';
                  });
                },
              ),
              if (_selectedSubTransferType == 'Transfer To Own Tell Birr')
                _buildTransferForm(), // Build the form based on selection
            ],
          ),
    );
  }
}

class ConfirmationPage extends StatelessWidget {
  final String fromAccount;
  final String phoneNumber;
  final String beneficiaryName;
  final String amount;
  final String note;
  final DateTime transactionDate;
  final VoidCallback onSubmit;

  const ConfirmationPage({
    Key? key,
    required this.fromAccount,
    required this.phoneNumber,
    required this.beneficiaryName,
    required this.amount,
    required this.note,
    required this.transactionDate,
    required this.onSubmit,
  }) : super(key: key);

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
    Key? key,
    required this.fromAccount,
    required this.phoneNumber,
    required this.beneficiaryName,
    required this.amount,
    required this.note,
    required this.transactionDate,
  }) : super(key: key);

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
            Text('Date of Tran: ${transactionDate.toString()}'),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Go back to previous page
                Navigator.of(context).pop(); // Close the success page
                Navigator.of(context).pop(); // Close the success page
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
