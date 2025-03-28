import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:math';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
//import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../global_state.dart';
import '../constants.dart';

class TransferPage extends StatefulWidget {
  final String token;
  const TransferPage({super.key, required this.token});

  @override
  _TransferPageState createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  String? _selectedTransferType;
  String? _selectedFromAccount;
  String? _selectedToAccount;
  String? _selectedOwnAccountTransferType;
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String concatenatedValue = "";
// Method to get the amount as a double, supporting both integer and decimal values
double? getAmount() {
  if (_amountController.text.isNotEmpty) {
    return double.tryParse(_amountController.text);
  }
  return null;
}
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
          final accountsList = List<Map<String, dynamic>>.from(data['Accounts']);
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

  Future<void> _checkAccountValidity(String toAccountNumber) async {
    final url = Uri.parse(ApiConstants.checkAccountValidity);
    final headers = _buildHeaders();

    final body = jsonEncode({
      'accountID': toAccountNumber,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      await Future.delayed(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['Details'] != null && responseData['Details'].isNotEmpty) {
          final displayName = responseData['Details'][0]['displayName'];

          if (displayName != null) {
            await _navigateToConfirmationPage(toAccountNumber, displayName);
          } else {
            throw Exception('Account is not valid or displayName is missing');
          }
        } else {
          throw Exception('No details found in the response');
        }
      } else {
        throw Exception(
            'Failed to check account validity: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error checking account validity: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid transfer account')),
      );
    }
  }

  Future<void> _checkownAccountValidity(String toAccountNumber) async {
    final url = Uri.parse(ApiConstants.checkAccountValidity);
    final headers = _buildHeaders();

    final body = jsonEncode({
      'accountID': toAccountNumber,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['Details'] != null && responseData['Details'].isNotEmpty) {
          final displayName = responseData['Details'][0]['displayName'];

          if (displayName != null) {
            await _navigateToOwnConfirmationPage(toAccountNumber, displayName);
          } else {
            throw Exception('Account is not valid or displayName is missing');
          }
        } else {
          throw Exception('No details found in the response');
        }
      } else {
        throw Exception(
            'Failed to check account validity: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error checking account validity: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid transfer account')),
      );
    }
  }

Future<void> _navigateToConfirmationPage(
    String toAccountNumber, String displayName) async {
  final transferAmount = double.tryParse(_amountController.text) ?? 0.0; // Keep as double
  final reason = _noteController.text;
  final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => ConfirmationPage(
        fromAccount: accountNumber,
        toAccountName: displayName,
        toAccountNumber: toAccountNumber,
        amount: transferAmount.toStringAsFixed(2), // Convert to string with two decimal places
        reason: reason,
        currentDate: currentDate,
        onConfirm: () async {
          await _makeTransfer(toAccountNumber, transferAmount.toStringAsFixed(2), reason); // Use formatted string
        },
      ),
    ),
  );
}

Future<void> _navigateToOwnConfirmationPage(
    String toAccountNumber, String displayName) async {
  final transferAmount = double.tryParse(_amountController.text) ?? 0.0; // Keep as double
  final reason = _noteController.text;
  final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => ConfirmationPage(
        fromAccount: accountNumber,
        toAccountName: displayName,
        toAccountNumber: toAccountNumber,
        amount: transferAmount.toStringAsFixed(2), // Convert to string with two decimal places
        reason: reason,
        currentDate: currentDate,
        onConfirm: () async {
          await _makeownTransfer(toAccountNumber, transferAmount.toStringAsFixed(2), reason); // Use formatted string
        },
      ),
    ),
  );
}



void showCustomSnackBar(BuildContext context, Widget content) {
  final overlay = Overlay.of(context);
  OverlayEntry? overlayEntry; // Declare overlayEntry as nullable
  final GlobalKey repaintBoundaryKey = GlobalKey(); // Key for RepaintBoundary

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 20.0,
      left: 10.0,
      right: 10.0,
      child: Material(
        color: Colors.transparent,
        child: RepaintBoundary(
          key: repaintBoundaryKey,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6, // Specify the width as 60% of the screen width
            height: MediaQuery.of(context).size.height * 0.6,
            padding: const EdgeInsets.all(45.0),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255), // Background color of the message
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10.0,
                  spreadRadius: 2.0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with green background
                // Bank logo
                Center(
                  child: Image.asset(
                    'assets/images/cbe1.png', // Correct path to the image
                    height: 100.0, // Adjust the height as needed
                  ),
                ),
                const SizedBox(height: 10.0),
                const Expanded(
                  child: Text(
                    'Transaction Detail',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 20.0,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: DefaultTextStyle(
                        style: const TextStyle(
                          color: Colors.black,
                        ),
                        child: content,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Footer with icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.download, color: Colors.black),
                      onPressed: () async {
                        try {
                          RenderRepaintBoundary boundary = repaintBoundaryKey
                              .currentContext!
                              .findRenderObject() as RenderRepaintBoundary;
                          ui.Image image = await boundary.toImage();
                          ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                          Uint8List pngBytes = byteData!.buffer.asUint8List();

                          final timestamp = DateTime.now()
                              .toIso8601String()
                              .replaceAll(RegExp('[^0-9]'), '');
                          // final filePath =
                          //     '${(await FilePicker.platform.getDirectoryPath() ?? '')}/cbe-transaction-$timestamp.png';

                          // final file = File(filePath);

                          // await file.writeAsBytes(pngBytes);

                          // ScaffoldMessenger.of(context).showSnackBar(
                          //   SnackBar(
                          //     content: Text('Message saved to $filePath'),
                          //   ),
                          // );

                          Navigator.of(context).pop(); // Navigate back to transfer page
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to save message: $e'),
                            ),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.black),
                      onPressed: () async {
                        try {
                          RenderRepaintBoundary boundary = repaintBoundaryKey
                              .currentContext!
                              .findRenderObject() as RenderRepaintBoundary;
                          ui.Image image = await boundary.toImage();
                          ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
                          Uint8List pngBytes = byteData!.buffer.asUint8List();

                          final tempDir = await Directory.systemTemp.createTemp();
                          final filePath = '${tempDir.path}/cbe-transaction.png';
                          final file = File(filePath);

                          await file.writeAsBytes(pngBytes);

                          await Share.shareFiles([filePath], text: 'Here is the transaction detail.');
                          Navigator.of(context).pop(); // Navigate back to transfer page
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to share message: $e'),
                            ),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: () {
                        overlayEntry?.remove();
                        Navigator.of(context).pop(); // Navigate back to transfer page
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  // Auto-close after 10 seconds and navigate back to transfer page
  Future.delayed(const Duration(seconds: 10), () {
    if (overlayEntry?.mounted == true) {
      overlayEntry?.remove();
      Navigator.of(context).pop();
    }
  });
}




  Future<void> _makeTransfer(
      String toAccountNumber, String transferAmount, String reason) async {
    if (_formKey.currentState!.validate()) {
      final url = Uri.parse(ApiConstants.performTransaction);
      final headers = _buildHeaders();
      double amount = double.tryParse(_amountController.text) ?? 0.0;
      int amountAsInt = amount.toInt(); // Convert double to int

      final body = jsonEncode({
        'amount': amountAsInt,
        'transactionId': '',
        'frequencyType': 'Once',
        'fromAccountNumber': _selectedFromAccount,
        'iban': '',
        'isScheduled': '0',
        'frequencyStartDate': DateTime.now().toIso8601String(),
        'frequencyEndDate': '',
        'scheduledDate': DateTime.now().toIso8601String(),
        'toAccountNumber': _toAccountController.text,
        'ExternalAccountNumber': _toAccountController.text,
        'paymentType': '',
        'paidBy': '',
        'serviceName': 'INTRA_BANK_FUND_TRANSFER_CREATE',
        'beneficiaryName': 'BENEFICIARY_NAME',
        'beneficiaryNickname': 'BENEFICIARY_NICKNAME',
        'transactionsNotes': _noteController.text,
        'transactionType': 'ExternalTransfer',
        'transactionCurrency': 'ETB',
        'fromAccountCurrency': 'ETB',
        'toAccountCurrency': 'ETB',
        'numberOfRecurrences': '',
        'uploadedattachments': '',
        'deletedDocuments': '',
        'transactionAmount': _amountController.text,
        'serviceCharge': '',
        'notes': _noteController.text,
        'sendOnDateComponents': [],
        'customerName': 'CUSTOMER_NAME',
        'validate': false,
      });

      try {
        final response = await http.post(url, headers: headers, body: body);

       if (response.statusCode == 200) {
  final responseBody = json.decode(response.body);
  if ((responseBody['referenceId'] != null && responseBody['status'] == "Sent") ||
      responseBody['status'] == "success") {
    
    String message = responseBody['message'] ?? 'Transfer successful';
    String referenceId = responseBody['referenceId'] ?? '';
    String fromAccountNumber = responseBody['fromAccountNumber'] ?? '';
    String toAccountNumber = responseBody['toAccountNumber'] ?? '';

    // Convert amount to double
    double amount = double.tryParse(responseBody['amount'].toString()) ?? 0.0;
    
    String processingDate = responseBody['processingDate'] ?? '';

showCustomSnackBar(
  context,
  Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Colors.black, // Default text color
            fontSize: 14.0, // Default text size
          ),
          children: [
            const TextSpan(text: 'Message: '),
            TextSpan(
              text: message,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: '\n\nReference ID: '),
            TextSpan(
              text: referenceId,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: '\n\nFrom Account: '),
            TextSpan(
              text: fromAccountNumber,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: '\n\nTo Account: '),
            TextSpan(
              text: toAccountNumber,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: '\n\nAmount: '),
            TextSpan(
              text: '${amount.toStringAsFixed(2)} ETB',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: '\n\nProcessing Date: '),
            TextSpan(
              text: processingDate,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ],
  ),
);

    Navigator.pop(context);
  } else {
    throw Exception(
      'Failed to make transfer: ${responseBody['dbpErrMsg'] ?? 'Unknown error'}',
    );
  }
}else {
          throw Exception('Failed to make transfer: ${response.reasonPhrase}');
        }
      } catch (error) {
        print('Error making transfer: $error');
        showCustomSnackBar(
          context,
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Transaction Failed',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              Text('Transfer failed: $error'),
            ],
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _makeownTransfer(
      String toAccountNumber, String transferAmount, String reason) async {
    if (_formKey.currentState!.validate()) {
      final url = Uri.parse(ApiConstants.performTransaction);
      final headers = _buildHeaders();
     double amount = double.tryParse(_amountController.text) ?? 0.0;
     int amountAsInt = amount.toInt(); // Convert double to int

      final body = jsonEncode({
        'amount': amountAsInt,
        'transactionId': '',
        'frequencyType': 'Once',
        'fromAccountNumber': _selectedFromAccount,
        'iban': '',
        'isScheduled': '0',
        'frequencyStartDate': DateTime.now().toIso8601String(),
        'frequencyEndDate': '',
        'scheduledDate': DateTime.now().toIso8601String(),
        'toAccountNumber': _selectedToAccount,
        'ExternalAccountNumber': _toAccountController.text,
        'paymentType': '',
        'paidBy': '',
        'serviceName': 'INTRA_BANK_FUND_TRANSFER_CREATE',
        'beneficiaryName': 'BENEFICIARY_NAME',
        'beneficiaryNickname': 'BENEFICIARY_NICKNAME',
        'transactionsNotes': _noteController.text,
        'transactionType': 'ExternalTransfer',
        'transactionCurrency': 'ETB',
        'fromAccountCurrency': 'ETB',
        'toAccountCurrency': 'ETB',
        'numberOfRecurrences': '',
        'uploadedattachments': '',
        'deletedDocuments': '',
        'transactionAmount': _amountController.text,
        'serviceCharge': '',
        'notes': _noteController.text,
        'sendOnDateComponents': [],
        'customerName': 'CUSTOMER_NAME',
        'validate': false,
      });
      try {
        final response = await http.post(url, headers: headers, body: body);

        if (response.statusCode == 200) {
          final responseBody = json.decode(response.body);
          if ((responseBody['referenceId'] != null &&
                  responseBody['status'] == "Sent") ||
              responseBody['status'] == "success") {
            String message = responseBody['message'] ?? 'Transfer successful';
            String referenceId = responseBody['referenceId'] ?? '';
            String fromAccountNumber = responseBody['fromAccountNumber'] ?? '';
            String toAccountNumber = responseBody['toAccountNumber'] ?? '';
             // Convert amount to double
            double amount = double.tryParse(responseBody['amount'].toString()) ?? 0.0;
            String processingDate = responseBody['processingDate'] ?? '';

showCustomSnackBar(
  context,
  Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Colors.black, // Default text color
            fontSize: 14.0, // Default text size
          ),
          children: [
            const TextSpan(text: 'Message: '),
            TextSpan(
              text: message,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: '\n\nReference ID: '),
            TextSpan(
              text: referenceId,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: '\n\nFrom Account: '),
            TextSpan(
              text: fromAccountNumber,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: '\n\nTo Account: '),
            TextSpan(
              text: toAccountNumber,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: '\n\nAmount: '),
            TextSpan(
              text: '${amount.toStringAsFixed(2)} ETB',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const TextSpan(text: '\n\nProcessing Date: '),
            TextSpan(
              text: processingDate,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    ],
  ),
);

            Navigator.pop(context);
          } else {
            throw Exception(
                'Failed to make transfer: ${responseBody['dbpErrMsg'] ?? 'Unknown error'}');
          }
        } else {
          throw Exception('Failed to make transfer: ${response.reasonPhrase}');
        }
      } catch (error) {
        print('Error making transfer: $error');
        showCustomSnackBar(
          context,
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Transaction Failed',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 4),
              Text('Transfer failed: $error'),
            ],
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Map<String, String> _buildHeaders() {
    return {
      'Authorization': 'Bearer ${widget.token}',
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

  Widget _buildTransferForm() {
    if (_selectedTransferType == null) {
      return const SizedBox.shrink();
    }

    if (_selectedTransferType == 'Transfer To CBE Account') {
      return _buildCBEAccountTransferForm();
    } else if (_selectedTransferType == 'Transfer To Own Account') {
      return _buildOwnAccountTransferForm();
    }
    return Container();
  }

  Widget _buildCBEAccountTransferForm() {
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
                          '$formattedAccountId,  Bal: ${account['availableBalance']} ETB',
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
            controller: _toAccountController,
            decoration: const InputDecoration(
              labelText: 'Transfer to Account',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the account to transfer to';
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
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the amount to transfer';
    }

    // Try parsing the value as a double
    double? amount = double.tryParse(value);
    if (amount == null) {
      print("Parsing failed: $value"); // Debug print
      return 'Please enter a valid number';
    }

    if (amount <= 0) {
      return 'Amount must be greater than zero';
    }

    return null; // Return null if the input is valid
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
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  _isLoading = true;
                });

                await _checkAccountValidity(_toAccountController.text);

                setState(() {
                  _isLoading = false;
                });

                // Use getAmount() to get the parsed amount as a double
                double? amount = getAmount();
                if (amount != null) {
                  // Perform the transfer using the amount
                }
              }
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
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnAccountTransferForm() {
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
                _selectedToAccount = null;
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
          DropdownButtonFormField<String>(
            value: _selectedToAccount,
            decoration: const InputDecoration(
              labelText: 'Transfer to Account',
              contentPadding: EdgeInsets.symmetric(
                vertical: 2.0,
              ),
            ),
            items: _accounts
                .where(
                    (account) => account['accountID'] != _selectedFromAccount)
                .map((account) {
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
                _selectedToAccount = value;
              });
            },
            validator: (value) {
              if (value == null) {
                return 'Please select a destination account';
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
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter the amount to transfer';
    }

    // Try parsing the value as a double
    double? amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Please enter a valid amount';
    }
    
    return null; // Return null if the input is valid
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
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                setState(() {
                  _isLoading = true;
                });
                await _checkownAccountValidity(_selectedToAccount!);
                setState(() {
                  _isLoading = false;
                });
              }
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
                ? const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                : const Text('Continue'),
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
          'Issue Detail',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26.0),
        ),
        backgroundColor: const Color.fromARGB(
            255, 134, 23, 116),
      ),
//       body: ListView(
//   padding: const EdgeInsets.all(8.0),
//   children: [
//     Column(
//       children: [
//         ExpansionTile(
//           title: const Text('Other CBE Account'),
//           leading: const Icon(Icons.transfer_within_a_station),
//           onExpansionChanged: (isExpanded) {
//             setState(() {
//               if (isExpanded) {
//                 _selectedTransferType = 'Transfer To CBE Account';
//               } else {
//                 _selectedTransferType = null; // Clear when collapsed
//               }
//             });
//           },
//           children: _selectedTransferType == 'Transfer To CBE Account'
//               ? [_buildTransferForm()]
//               : [],
//         ),
//         ExpansionTile(
//           title: const Text('Own Account'),
//           leading: const Icon(Icons.transfer_within_a_station),
//           onExpansionChanged: (isExpanded) {
//             setState(() {
//               if (isExpanded) {
//                 _selectedTransferType = 'Transfer To Own Account';
//               } else {
//                 _selectedTransferType = null; // Clear when collapsed
//               }
//             });
//           },
//           children: _selectedTransferType == 'Transfer To Own Account'
//               ? [_buildTransferForm()]
//               : [],
//         ),
//       ],
//     ),
//   ],
// ),

    );
  }
}


class ConfirmationPage extends StatelessWidget {
  final String fromAccount;
  final String toAccountName;
  final String toAccountNumber;
  final String amount; // Expecting double
  final String reason;
  final String currentDate;
  final Future<void> Function() onConfirm;

  const ConfirmationPage({
    super.key,
    required this.fromAccount,
    required this.toAccountName,
    required this.toAccountNumber,
    required this.amount,
    required this.reason,
    required this.currentDate,
    required this.onConfirm,
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 60.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0),
            side: const BorderSide(
              color: Color.fromARGB(255, 248, 247, 247),
              width: 1.0,
            ),
          ),
          color: const Color.fromARGB(255, 206, 238, 177), // Corrected backgroundColor placement
          elevation: 1.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text('Debit Acc: '),
                    Expanded(
                      child: Text(
                        fromAccount,
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('Credit Acc Name: '),
                    Expanded(
                      child: Text(
                        toAccountName,
                        textAlign: TextAlign.start,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('Credit Acc Num: '),
                    Expanded(
                      child: Text(
                        toAccountNumber,
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('Amount: '),
                    Expanded(
                      child: Text(
                        '$amount ETB', // amount is double
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('Reason: '),
                    Expanded(
                      child: Text(
                        reason,
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text('Date: '),
                    Expanded(
                      child: Text(
                        currentDate,
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (globalState.isLoading)
                  const CircularProgressIndicator(),
                if (!globalState.isLoading)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: globalState.isLoading
                            ? null
                            : () async {
                                globalState.setLoading(true);

                                try {
                                  await onConfirm();
                                } finally {
                                  globalState.setLoading(false);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:
                              const Color.fromARGB(255, 161, 1, 182), // Text color for the button
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: globalState.isLoading
                            ? const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              )
                            : const Text('Confirm'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

