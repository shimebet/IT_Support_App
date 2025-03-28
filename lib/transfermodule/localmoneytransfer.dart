import 'package:flutter/material.dart';
import 'dart:convert';
import '../constants.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
//import 'package:file_picker/file_picker.dart';


class LocalMoneyTransferPage extends StatefulWidget {
  final String token;

  const LocalMoneyTransferPage({super.key, required this.token});

  @override
  _LocalMoneyTransferPageState createState() => _LocalMoneyTransferPageState();
}

class _LocalMoneyTransferPageState extends State<LocalMoneyTransferPage> {
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _accounts = [];
  String? selectedFromAccount;
  String? amount;
  String? question = 'What is your mother\'s name?';
  String? answer;
  String? charges = 'DEBIT PLUS CHARGES';
  String? mobileNumber;
  String? nickName;
  String? email;
  bool isLoading = false;
  String? errorMessage;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _nickNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
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
          setState(() {
            _accounts = List<Map<String, dynamic>>.from(data['Accounts']);
          });
        } else {
          throw Exception('No accounts found');
        }
      } else {
        throw Exception('Failed to fetch accounts');
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Error fetching accounts: $error';
      });
    }
  }

  Map<String, String> _buildHeaders() {
    return {
      'X-Kony-Authorization': widget.token,
      'Content-Type': 'application/json',
      'X-Kony-App-Key': ApiHeaders.appKey,
      'X-Kony-App-Secret': ApiHeaders.appSecret,
    };
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
                // Header with bank logo
                Center(
                  child: Image.asset(
                    'assets/images/cbe1.png', // Correct path to the image
                    height: 100.0, // Adjust the height as needed
                  ),
                ),
                const SizedBox(height: 10.0),
                const Text(
                  'Transaction Detail',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                  ),
                ),
                const SizedBox(height: 10.0),
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

                          overlayEntry?.remove(); // Remove overlay
                          //Navigator.of(context).pop(); // Navigate back to transfer page
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
                          
                          overlayEntry?.remove(); // Remove overlay
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
                        overlayEntry?.remove(); // Remove overlay
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
 Future<void> _performLocalMoneyTransfer() async {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save();

    // Prepare the transfer data
    final transferData = {
      "debitAmount": _amountController.text,
      "debitAccount": selectedFromAccount!,
      "question": _questionController.text,
      "answer": _answerController.text,
      "charges": charges!,
      "mobileNumber": _mobileNumberController.text,
      "transactionCurrency": "ETB",
      "nickName": _nickNameController.text,
      "email": _emailController.text.isNotEmpty ? _emailController.text : "",
    };

    // Log request details
    // print('Request Headers: ${_buildHeaders()}');
    // print('Request Payload: ${jsonEncode(transferData)}');

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse('https://infinityuat.cbe.com.et/services/data/v1/RBObjects/operations/LMTS/createLMTSTransfer'),
        headers: _buildHeaders(),
        body: jsonEncode(transferData),
      );

      // Log response details
      // print('Response Status: ${response.statusCode}');
      // print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Extracting data from response
        String message = responseData['LMTS']?[0]['message'] ?? 'Transaction Successful';
        String referenceId = responseData['LMTS']?[0]['lmtsId'] ?? '';
        String fromAccountNumber = responseData['LMTS']?[0]['debitAccount'] ?? '';
        String toAccountNumber = _mobileNumberController.text; // Assuming this is the 'To Account'
        int amount = int.tryParse(responseData['LMTS']?[0]['transactionAmount'] ?? '0') ?? 0;
        String processingDate = responseData['LMTS']?[0]['processingDate'] ?? '';

        // Creating content for the custom snackbar
        Widget content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reference ID: $message'),
            Text('Reference ID: $referenceId'),
            Text('From Account: $fromAccountNumber'),
            Text('To Account: $toAccountNumber'),
            Text('Amount: $amount ETB'),
            Text('Processing Date: $processingDate'),
          ],
        );

        // Show custom snackbar
        showCustomSnackBar(context, content);

        // Pop the current page to go back
        Future.delayed(const Duration(seconds: 2), () {
           Navigator.of(context).pop();
        });
      } else {
        throw Exception('Failed to create transfer');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transfer Failed: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}




  Future<void> _showConfirmPage(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ConfirmTransferPage(
            token: widget.token,
            fromAccount: selectedFromAccount!,
            toAccount: _mobileNumberController.text,
            beneficiaryName: _nickNameController.text,
            amount: int.tryParse(_amountController.text) ?? 0,
            question: _questionController.text,
            answer: _answerController.text,
            charges: charges!,
            email: _emailController.text,
            onConfirm: _performLocalMoneyTransfer,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _questionController.dispose();
    _answerController.dispose();
    _mobileNumberController.dispose();
    _nickNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Money Transfer'),
        backgroundColor: const Color.fromARGB(255, 134, 23, 116),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Transfer From'),
                          value: selectedFromAccount,
                          items: _accounts.map((account) {
                            String accountName = account['accountName'];
                            List<String> nameParts = accountName.split(' ');
                            String shortenedName = '';

                            if (nameParts.isNotEmpty) {
                              shortenedName += nameParts[0].length > 3
                                  ? nameParts[0].substring(0, 3)
                                  : nameParts[0];
                            }
                            if (nameParts.length >= 2) {
                              shortenedName += ' ${nameParts[1].length > 3
                                      ? nameParts[1].substring(0, 3)
                                      : nameParts[1]}';
                            }
                            if (nameParts.length >= 3) {
                              shortenedName += ' ${nameParts[2].length > 3
                                      ? nameParts[2].substring(0, 3)
                                      : nameParts[2]}';
                            }

                            String displayText =
                                '$shortenedName ${account['accountID']} Birr';

                            return DropdownMenuItem<String>(
                              value: account['accountID'],
                              child: Text(displayText),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedFromAccount = value;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Select account' : null,
                        ),
                        TextFormField(
                          controller: _nickNameController,
                          decoration: const InputDecoration(labelText: 'Beneficiary Name'),
                          validator: (value) => value!.isEmpty ? 'Enter beneficiary name' : null,
                        ),
                        TextFormField(
                          controller: _mobileNumberController,
                          decoration: const InputDecoration(labelText: 'Mobile Number'),
                          keyboardType: TextInputType.phone,
                          validator: _validateMobileNumber,
                        ),
                        TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(labelText: 'Amount'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final amount = double.tryParse(value ?? '');
                            if (amount == null || amount <= 0) {
                              return 'Enter a valid amount';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _questionController,
                          decoration: const InputDecoration(labelText: 'Security Question'),
                          validator: (value) => value!.isEmpty ? 'Enter Question' : null,
                        ),
                        TextFormField(
                          controller: _answerController,
                          decoration: const InputDecoration(labelText: 'Answer to Security Question'),
                          validator: (value) => value!.isEmpty ? 'Enter answer' : null,
                        ),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email (optional)'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16.0),
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              _showConfirmPage(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 134, 23, 116),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Continue to Confirm'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

String? _validateMobileNumber(String? value) {
  final phoneRegExp = RegExp(r'^\+251[0-9]{9}$'); // Adjusted regex for +251 followed by 9 digits
  if (value == null || value.isEmpty) {
    return 'Enter mobile number';
  } else if (!phoneRegExp.hasMatch(value)) {
    return 'Enter a valid mobile number (+251nnnnnnnnn)';
  }
  return null;
}
}

class ConfirmTransferPage extends StatefulWidget {
  final String token;
  final String fromAccount;
  final String toAccount;
  final String beneficiaryName;
  final int amount;
  final String question;
  final String answer;
  final String charges;
  final String email;
  final Future<void> Function() onConfirm;

  const ConfirmTransferPage({
    super.key,
    required this.token,
    required this.fromAccount,
    required this.toAccount,
    required this.beneficiaryName,
    required this.amount,
    required this.question,
    required this.answer,
    required this.charges,
    required this.email,
    required this.onConfirm,
  });

  @override
  _ConfirmTransferPageState createState() => _ConfirmTransferPageState();
}

class _ConfirmTransferPageState extends State<ConfirmTransferPage> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Transfer'),
        backgroundColor: const Color.fromARGB(255, 134, 23, 116),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoCard('From Account', widget.fromAccount, null, null, Icons.account_balance),
              _buildInfoCard('To Account', widget.toAccount, null, null, Icons.account_balance),
              _buildInfoCard('Beneficiary Name', widget.beneficiaryName, null, null, Icons.person),
              _buildInfoCard('Amount', '${widget.amount} ETB', null, null, Icons.money),
              _buildInfoCard('Security Question', widget.question, null, null, Icons.lock),
              _buildInfoCard('Answer', widget.answer, null, null, Icons.lock_open),
              _buildInfoCard('Charges', widget.charges, null, null, Icons.money),
              if (widget.email.isNotEmpty) 
                _buildInfoCard('Email', widget.email, null, null, Icons.email),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final confirm = await _showConfirmationDialog(context);
                          if (confirm) {
                            setState(() {
                              isLoading = true;
                            });
                            try {
                              await widget.onConfirm();
                              // _showSnackBar(context, 'Transfer completed successfully!', Colors.green);
                              // Navigator.of(context).pop();
                            } catch (error) {
                              _showSnackBar(context, 'Transfer failed. Please try again.', Colors.red);
                            } finally {
                              setState(() {
                                isLoading = false;
                              });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 134, 23, 116),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Confirm Transfer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label1, String value1, String? label2, String? value2, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[600]),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label1: $value1',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (label2 != null && value2 != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  '$label2: $value2',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirm Transfer'),
              content: const Text('Are you sure you want to proceed with this transfer?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
