import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../global_state.dart';
import '../constants.dart';

class TopUpPage extends StatefulWidget {
  final String token;
  const TopUpPage({super.key, required this.token});

  @override
  _TopUpPageState createState() => _TopUpPageState();
}

class _TopUpPageState extends State<TopUpPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final _amountController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _noteController = TextEditingController();

  String? _selectedService;
  bool _isSelfSelected = false;
  bool _isOthersSelected = false;
  Map<String, dynamic>? _selectedAccount;
  late String username = "";
  late String accountname = "";
  late String balance = "";
  late String accountNumber = "";

  List<Map<String, dynamic>> accounts = [];
  bool isLoading = true;
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

  Map<String, String> _buildHeaders() {
    return {
      'X-Kony-Authorization': ' ${widget.token}',
      'Content-Type': 'application/json',
      'X-Kony-App-Key': ApiHeaders.appKey, // Use constant from ApiHeaders
      'X-Kony-App-Secret': ApiHeaders.appSecret, // Use constant from ApiHeaders
    };
  }
  void _submitTopUp() {
        setState(() {
      _isLoading = true;
    });
    if (_formKey.currentState!.validate()) {
      if (_selectedService == 'Ethio AirTime') {
        _performTransaction();
      } else if (_selectedService == 'Safaricom') {
        _submitSafaricomTopUp();
      }
    }
    //    setState(() {
    //   _isLoading = false;
    // });
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
            accounts = accountsList;
            if (accounts.isNotEmpty) {
              final account = accounts[0];
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
        throw Exception('Failed to fetch data');
      }
    } catch (error) {
      print('Error fetching data: $error');
    }
  }

  Future<void> _performTransaction() async {
  if (_formKey.currentState!.validate()) {
    final amount = double.parse(_amountController.text);
    final note = _noteController.text;

    // Determine the final phone number based on the selected checkbox
    final phoneNumber = _isSelfSelected
        ? Provider.of<GlobalState>(context, listen: false).phone
        : _phoneNumberController.text;

    if (_selectedAccount != null) {
      final availableBalance =
          double.parse(_selectedAccount!['availableBalance']);

      if (amount > availableBalance) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Insufficient Balance'),
            content: const Text(
                'The entered amount exceeds the available balance.'),
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
        return;
      }

    final url = Uri.parse(ApiConstants.performTransaction);
      final headers = _buildHeaders();

      // Function to format date and time
      String formatDateTime(DateTime dateTime) {
        return '${dateTime.toUtc().toIso8601String().split('.').first}Z';
      }

      String phone = phoneNumber.replaceAll('+251-', '');
      final now = DateTime.now();
      final formattedNow = formatDateTime(now);

      final body = jsonEncode({
        "amount": amount.toString(),
        "transactionId": "",
        "frequencyType": "Once",
        "fromAccountNumber": _selectedAccount!['accountID'],
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
        "beneficiaryName": phone,
        "beneficiaryNickname": "Ethio Telco Prepaid",
        "transactionsNotes": "",
        "transactionType": "ExternalTransfer",
        "transactionCurrency": "ETB",
        "fromAccountCurrency": "ETB",
        "toAccountCurrency": "ETB",
        "numberOfRecurrences": "",
        "uploadedattachments": "",
        "deletedDocuments": "",
        "transactionAmount": "",
        "serviceCharge": "",
        "notes": _noteController.text,
        "debitReference": "Topup0$phone",
        "remittanceInformation": "Topup0$phone",
        "creditReference": "Topup0$phone",
        "isBillPayment": true,
        "billerName": "Ethio Telco Prepaid",
      });
      // print('Request Headers: $headers');
      // print('Request Body: $body');
      try {
        final response = await http.post(url, headers: headers, body: body);
        final responseBody = jsonDecode(response.body);    
        if (response.statusCode == 200 && responseBody['status'] == 'success') {
             await Future.delayed(const Duration(seconds: 2));
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Top-Up Successfully'),
              content: Text(
                  'Amount: $amount\nPhone Number: $phoneNumber\nNote: $note'),
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
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Top-Up Failed'),
              content: Text(
                  responseBody['message'] ?? 'Failed to make the top-up'),
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
        print('Error submitting top-up: $error');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to submit top-up request: $error'),
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
  }
}
// Safaricom
 Future<void> _submitSafaricomTopUp() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final note = _noteController.text;

      // Determine the final phone number based on the selected checkbox
      final phoneNumber = _isSelfSelected
          ? Provider.of<GlobalState>(context, listen: false).phone
          : _phoneNumberController.text;

      if (_selectedAccount != null) {
        final availableBalance =
            double.parse(_selectedAccount!['availableBalance']);

        if (amount > availableBalance) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Insufficient Balance'),
              content: const Text(
                  'The entered amount exceeds the available balance.'),
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
          return;
        }
    final url = Uri.parse(ApiConstants.performTransaction);
        final headers = _buildHeaders();
    String formatDateTime(DateTime dateTime) {
        return '${dateTime.toUtc().toIso8601String().split('.').first}Z';
      }

      String phone = phoneNumber.replaceAll('+251-', '');
      final now = DateTime.now();
      final formattedNow = formatDateTime(now);

      final body = jsonEncode({
        "amount": amount.toString(),
        "transactionId": "",
        "frequencyType": "Once",
        "fromAccountNumber": _selectedAccount!['accountID'],
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
        "beneficiaryName": phone,
        "beneficiaryNickname": "Safaricom",
        "transactionsNotes": "",
        "transactionType": "ExternalTransfer",
        "transactionCurrency": "ETB",
        "fromAccountCurrency": "ETB",
        "toAccountCurrency": "ETB",
        "numberOfRecurrences": "",
        "uploadedattachments": "",
        "deletedDocuments": "",
        "transactionAmount": "",
        "serviceCharge": "",
        "notes": _noteController.text,
        "debitReference": "Topup0$phone",
        "remittanceInformation": "Topup0$phone",
        "creditReference": "Topup0$phone",
        "isBillPayment": true,
        "billerName": "Safaricom",
      });
    try {
        final response = await http.post(url, headers: headers, body: body);
        final responseBody = jsonDecode(response.body);    
        if (response.statusCode == 200 && responseBody['status'] == 'success') {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Top-Up Successful'),
              content: Text(
                  'Amount: $amount\nPhone Number: $phoneNumber\nNote: $note'),
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
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Top-Up Failed'),
              content: Text(
                  responseBody['message'] ?? 'Failed to make the top-up'),
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
        print('Error submitting top-up: $error');
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to submit top-up request: $error'),
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
    }
  }


  String _shortenText(String text) {
    if (text.length >= 8) {
      return '${text.substring(0, 4)}****${text.substring(text.length - 4)}';
    }
    return text;
  }

  String _shortenAccountName(String text) {
    if (text.isNotEmpty) {
      return text.substring(0, 1);
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
appBar: AppBar(
  title: const Text(
    'Select AirTime Service',
    style: TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 26.0,
    ),
    textAlign: TextAlign.center,
  ),
  backgroundColor: const Color.fromARGB(255, 134, 23, 116), // Set the background color of the AppBar
  centerTitle: false, // Center the title
),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
  padding: const EdgeInsets.all(8.0),
  children: [
    Column(
      children: [
        Row(
          children: [
            Radio<String>(
              value: 'Ethio AirTime',
              groupValue: _selectedService,
              onChanged: (String? value) {
                setState(() {
                  _selectedService = value;
                  _isSelfSelected = false; // Reset the checkbox state
                  _isOthersSelected = false; // Reset the checkbox state
                });
              },
            ),
            const Text('Ethio AirTime'),
          ],
        ),
        Row(
          children: [
            Radio<String>(
              value: 'Safaricom',
              groupValue: _selectedService,
              onChanged: (String? value) {
                setState(() {
                  _selectedService = value;
                  _isSelfSelected = false; // Reset the checkbox state
                  _isOthersSelected = false; // Reset the checkbox state
                });
              },
            ),
            const Text('Safaricom'),
          ],
        ),
        if (_selectedService != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Self'),
                  value: _isSelfSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      _isSelfSelected = value!;
                      if (_isSelfSelected) {
                        _concatenatePhoneNumber(); // Fetch phone number from global state
                        _isOthersSelected = false;
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Others'),
                  value: _isOthersSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      _isOthersSelected = value!;
                      if (_isOthersSelected) {
                        _phoneNumberController.clear();
                        _isSelfSelected = false;
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            ],
          ),
        ],
        if (_selectedService != null && (_isSelfSelected || _isOthersSelected)) ...[
          DropdownButtonFormField<Map<String, dynamic>>(
            value: _selectedAccount,
            decoration: const InputDecoration(
              labelText: 'Select Account Number',
            ),
            items: accounts.map((account) {
              return DropdownMenuItem<Map<String, dynamic>>(
                value: account,
                child: Text(_shortenText(account['accountID'])),
              );
            }).toList(),
            onChanged: (Map<String, dynamic>? newValue) {
              setState(() {
                _selectedAccount = newValue;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Please select an account number';
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
                return 'Please enter an amount';
              }
              return null;
            },
          ),
          if (!_isSelfSelected)
            TextFormField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a phone number';
                }
                return null;
              },
            ),
          TextFormField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Note'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitTopUp,
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
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : const Text('Top Up'),
          ),
        ],
      ],
    ),
  ],
),

        ),
      ),
    );
  }
}
