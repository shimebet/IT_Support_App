import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
//import 'package:file_picker/file_picker.dart';


class SendMoneyToBeneficiaryPage extends StatefulWidget {
  final String token;
  final String accountNumber;
  const SendMoneyToBeneficiaryPage({super.key, required this.token, required this.accountNumber});

  @override
  _SendMoneyToBeneficiaryPageState createState() => _SendMoneyToBeneficiaryPageState();
}

class _SendMoneyToBeneficiaryPageState extends State<SendMoneyToBeneficiaryPage> {
  String? selectedFromAccount;
  String? selectedBeneficiaryAccount;
  String? beneficiaryName;
  String amount = '';
  String note = '';
  String? currentDate;
  late TextEditingController _accountNumberController;
  List<Map<String, String>> fromAccounts = [];
  List<Map<String, String>> beneficiaries = [];
  bool _isProcessing = false; // Local loading state

@override
void initState() {
  super.initState();
  _accountNumberController = TextEditingController(text: widget.accountNumber);
  currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  fetchBeneficiaries().then((_) {
    // Call this after beneficiaries have been fetched
    if (beneficiaries.isNotEmpty) {
      selectedBeneficiaryAccount = widget.accountNumber;
      onBeneficiaryAccountSelected(widget.accountNumber); 
    }
  });
  fetchFromAccounts();
}


  @override
  void dispose() {
    _accountNumberController.dispose();
    super.dispose();
  }
  Map<String, String> _buildHeaders() {
    return {
      'X-Kony-Authorization': widget.token,
      'Content-Type': 'application/json',
      'X-Kony-App-Key': ApiHeaders.appKey,
      'X-Kony-App-Secret': ApiHeaders.appSecret,
    };
  }

  Future<void> fetchFromAccounts() async {
    final url = Uri.parse(
        'https://infinityuat.cbe.com.et/services/data/v1/RBObjects/operations/Accounts/getAccountsPostLogin');

    setState(() {
      _isProcessing = true;
    });

    try {
      final response = await http.post(url, headers: _buildHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accounts = data['Accounts'] as List<dynamic>;

        setState(() {
          fromAccounts = accounts
              .map((account) => {
                    'accountID': account['accountID'] as String,
                    'accountName': account['accountName'] as String,
                  })
              .toList();
        });
      } else {
        throw Exception('Failed to load from accounts');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load from accounts: $e')),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

 Future<void> fetchBeneficiaries() async {
  final url = Uri.parse(
      'https://infinityuat.cbe.com.et/services/data/v1/PayeeObjects/operations/Recipients/getIntraBankPayees');

  setState(() {
    _isProcessing = true;
  });

  try {
    final response = await http.post(url, headers: _buildHeaders());

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final externalAccounts = data['ExternalAccounts'] as List<dynamic>;

      setState(() {
        beneficiaries = externalAccounts
            .map((account) => {
                  'accountNumber': account['accountNumber'] as String,
                  'beneficiaryName': account['beneficiaryName'] as String,
                })
            .toList();
      });
    } else {
      throw Exception('Failed to load beneficiaries');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to load beneficiaries: $e')),
    );
  } finally {
    setState(() {
      _isProcessing = false;
    });
  }
}


void onBeneficiaryAccountSelected(String? accountNumber) {
  final beneficiary = beneficiaries.firstWhere(
    (element) => element['accountNumber'] == accountNumber,
    orElse: () => {},
  );

  if (beneficiary.isNotEmpty) {
    setState(() {
      selectedBeneficiaryAccount = accountNumber;
      beneficiaryName = beneficiary['beneficiaryName'];
    });
  } else {
    // Handle the case where the account number is not found
    setState(() {
      selectedBeneficiaryAccount = null;
      beneficiaryName = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Beneficiary not found for account: $accountNumber')),
    );
  }
}



  void onContinue() async {
    if (selectedFromAccount != null &&
        selectedBeneficiaryAccount != null &&
        beneficiaryName != null &&
        amount.isNotEmpty) {
      setState(() {
        _isProcessing = true;
      });

      final userDetails = await fetchUserDetails();

      if (userDetails != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmTransferPage(
              token: widget.token,
              fromAccount: selectedFromAccount!,
              toAccount: selectedBeneficiaryAccount!,
              beneficiaryName: beneficiaryName!,
              amount: amount,
              date: currentDate!,
              note: note,
              userDetails: userDetails,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load user details')),
        );
      }

      setState(() {
        _isProcessing = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
    }
  }

  Future<Map<String, dynamic>?> fetchUserDetails() async {
    final url = Uri.parse(
        'https://infinityuat.cbe.com.et/services/data/v1/RBObjects/objects/User');

    setState(() {
      _isProcessing = true;
    });

    try {
      final response = await http.get(url, headers: _buildHeaders());

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['records'] != null && data['records'].isNotEmpty) {
          return data['records'][0];
        } else {
          throw Exception('No user details found');
        }
      } else {
        throw Exception('Failed to load user details. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user details: $e')),
      );
      return null;
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer to Beneficiary'),
        backgroundColor: const Color.fromARGB(255, 134, 23, 116),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'From Account'),
                value: selectedFromAccount,
                onChanged: (value) {
                  setState(() {
                    selectedFromAccount = value;
                  });
                },
                items: fromAccounts.map((account) {
                  return DropdownMenuItem(
                    value: account['accountID'],
                    child: Text('Act ${account['accountID']}'),
                  );
                }).toList(),
              ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Beneficiary Account'),
              value: selectedBeneficiaryAccount, // Use the initialized value here
              onChanged: (value) {
                onBeneficiaryAccountSelected(value);
              },
              items: beneficiaries.map((beneficiary) {
                return DropdownMenuItem(
                  value: beneficiary['accountNumber'],
                  child: Text(beneficiary['accountNumber']!),
                );
              }).toList(),
            ),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Beneficiary Name'),
                readOnly: true,
                controller: TextEditingController(text: beneficiaryName),
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    amount = value;
                  });
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Note'),
                onChanged: (value) {
                  setState(() {
                    note = value;
                  });
                },
              ),
              const SizedBox(height: 20),
Center(
  child: _isProcessing
      ? const CircularProgressIndicator()
      : Container(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 115, 3, 150), 
              foregroundColor: Colors.white// Background color for the button
            ),
            onPressed: onContinue,
            child: const Text('Continue'),
          ),
        ),
)

            ],
          ),
        ),
      ),
    );
  }
}

class ConfirmTransferPage extends StatefulWidget {
  final String amount;
  final String fromAccount;
  final String toAccount;
  final String date;
  final String beneficiaryName;
  final String note;
  final String token;
  final Map<String, dynamic> userDetails;
  const ConfirmTransferPage({
    super.key,
    required this.amount,
    required this.fromAccount,
    required this.toAccount,
    required this.date,
    required this.beneficiaryName,
    required this.note,
    required this.token,
      required this.userDetails,
  });

  @override
  _ConfirmTransferPageState createState() => _ConfirmTransferPageState();
}

class _ConfirmTransferPageState extends State<ConfirmTransferPage> {
  bool _isProcessing = false;
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
                          //final filePath =
                             // '${(await FilePicker.platform.getDirectoryPath() ?? '')}/cbe-transaction-$timestamp.png';

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
 Future<void> _createOneTimeTransfer() async {
  setState(() {
    _isProcessing = true;
  });

  final url = Uri.parse(
      'https://infinityuat.cbe.com.et/services/data/v1/RBObjects/operations/Transactions/createOneTimeTransfer');
double amount = double.tryParse(widget.amount) ?? 0.0;
      int amountAsInt = amount.toInt(); // Convert double to int
  final body = {
    "amount": amountAsInt,
    "transactionId": "",
    "frequencyType": "Once",
    "fromAccountNumber": widget.fromAccount,
    "iban": "",
    "isScheduled": "0",
    "frequencyStartDate": widget.date,
    "frequencyEndDate": "",
    "scheduledDate": widget.date,
    "toAccountNumber": widget.toAccount,
    "ExternalAccountNumber": widget.toAccount,
    "paymentType": "",
    "paidBy": "",
    "serviceName": "INTRA_BANK_FUND_TRANSFER_CREATE",
    "beneficiaryName": widget.beneficiaryName,
    "beneficiaryNickname": widget.beneficiaryName,
    "transactionsNotes": widget.note,
    "transactionType": "ExternalTransfer",
    "transactionCurrency": "ETB",
    "fromAccountCurrency": "ETB",
    "toAccountCurrency": "ETB",
    "numberOfRecurrences": "",
    "uploadedattachments": "",
    "deletedDocuments": "",
    "transactionAmount": widget.amount,
    "serviceCharge": "",
    "notes": widget.note,
    "sendOnDateComponents": [],
    "customerName": "",
    "validate": false
  };

  final headers = {
    'X-Kony-Authorization': widget.token,
    'Content-Type': 'application/json',
    'X-Kony-App-Key': ApiHeaders.appKey,
    'X-Kony-App-Secret': ApiHeaders.appSecret,
  };

  try {
    final response = await http.post(url, headers: headers, body: jsonEncode(body));

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      // Extracting data from response
      String message = responseData['message'] ?? 'Transaction Successful';
      String referenceId = responseData['referenceId'] ?? '';
      String fromAccountNumber = responseData['fromAccountNumber'] ?? '';
      String toAccountNumber = responseData['toAccountNumber'] ?? '';
      int amount = responseData['amount'] ?? 0;
      String processingDate = responseData['processingDate'] ?? '';

      // Creating content for the custom snackbar
      Widget content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reference ID: $referenceId'),
          Text('From Account: $fromAccountNumber'),
          Text('To Account: $toAccountNumber'),
          Text('Amount: $amount ETB'),
          Text('Processing Date: $processingDate'),
        ],
      );

      // Show custom snackbar
      showCustomSnackBar(context, content);
       Future.delayed(const Duration(seconds: 1), () { 
          Navigator.of(context).pop();
          // Pop the current page to go back
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
      _isProcessing = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Transfer'),
        backgroundColor: const Color.fromARGB(255, 134, 23, 116),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'From Account: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  widget.fromAccount,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8), // Add space between rows
            Row(
              children: [
                const Text(
                  'To Account: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  widget.toAccount,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8), // Add space between rows
            Row(
              children: [
                const Text(
                  'Beneficiary Name: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  widget.beneficiaryName,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8), // Add space between rows
            Row(
              children: [
                const Text(
                  'Amount: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  widget.amount,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8), // Add space between rows
            Row(
              children: [
                const Text(
                  'Date: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
                ),
                Text(
                  widget.date,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8), // Add space between rows
            Row(
              children: [
                const Text(
                  'Note: ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
                ),
                Text(
                  widget.note,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 20), // Add space before the button
            Center(
              child: _isProcessing
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _createOneTimeTransfer,
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all<Color>(
                            const Color.fromARGB(255, 115, 3, 150)), 
                        foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
                        padding: WidgetStateProperty.all<EdgeInsets>(
                            const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                        textStyle: WidgetStateProperty.all<TextStyle>(
                            const TextStyle(fontSize: 16)),
                      ),
                      child: const Text('Confirm'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

