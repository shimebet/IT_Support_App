import 'package:flutter/material.dart';
import 'dart:convert';
import '../constants.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class ScheduleTransferPage extends StatefulWidget {
  final String token;
  const ScheduleTransferPage({super.key, required this.token});

  @override
  _ScheduleTransferPageState createState() => _ScheduleTransferPageState();
}

class _ScheduleTransferPageState extends State<ScheduleTransferPage> {
  bool isScheduling = false;
  final _formKey = GlobalKey<FormState>();
  List<dynamic> payees = [];
  Map<String, dynamic>? user;
  String? selectedFromAccount;
  String? selectedToAccount;
  String? beneficiaryName;
  String? amount;
  String? frequencyType = 'Once';
  DateTime? scheduledDate;
  DateTime? frequencyEndDate;
  bool isLoading = false;
  String? errorMessage;
  late String username = "";
  late String accountname = "";
  late String balance = "";
  late String accountNumber = "";
  late String currentDate = getCurrentDate();
  List<Map<String, dynamic>> _accounts = [];
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  TextEditingController scheduledDateController = TextEditingController();
  TextEditingController frequencyEndDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAccounts();
    _fetchData();
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
      "X-Kony-ReportingParams": '{"os":"98.0.4758.109}'
    };
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final payeesResponse = await http.get(
        Uri.parse(
            'https://infinityuat.cbe.com.et/services/data/v1/PayeeObjects/operations/Recipients/getIntraBankPayees'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      final userResponse = await http.get(
        Uri.parse(
            'https://infinityuat.cbe.com.et/services/data/v1/RBObjects/objects/User'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (payeesResponse.statusCode == 200 && userResponse.statusCode == 200) {
        setState(() {
          payees = jsonDecode(payeesResponse.body)['ExternalAccounts'];
          user = jsonDecode(userResponse.body)['records'][0];
        });
      } else {
        setState(() {
          errorMessage = 'Failed to fetch data. Please try again later.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'An error occurred. Please check your connection.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showTopSnackBar(
      BuildContext context, String message, Color backgroundColor) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).viewInsets.top +
            50, // Adjust the top position
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 8,
                ),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
      Navigator.of(context)
          .pop(); // Navigate back after the snackbar disappears
    });
  }

  Future<void> _scheduleTransfer() async {
    final headers = _buildHeaders();
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      Map<String, String?> transferData = {
        "amount": _amountController.text,
        "transactionAmount": _amountController.text,
        "frequencyEndDate": DateFormat('yyyy-MM-dd').format(frequencyEndDate!),
        "frequencyType": frequencyType!,
        "fromAccountNumber": selectedFromAccount!,
        "isScheduled": "1",
        "scheduledDate": DateFormat('yyyy-MM-dd').format(scheduledDate!),
        "toAccountNumber": selectedToAccount!,
        "transactionsNotes": _noteController.text,
        "transactionType": "ExternalTransfer",
        "transactionCurrency": "ETB",
        "fromAccountCurrency": "ETB",
        "toAccountCurrency": "ETB",
        "numberOfRecurrences": null,
        "ExternalAccountNumber": selectedToAccount!,
        "bankName": "Commercial Bank of Ethiopia"
      };

      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      try {
        final response = await http.post(
          Uri.parse(
              'https://infinityuat.cbe.com.et/services/data/v1/TransactionObjects/operations/Transaction/IntraBankAccFundTransfer'),
          headers: headers,
          body: jsonEncode(transferData),
        );
        if (response.statusCode == 200) {
          showTopSnackBar(
              context, 'Transfer scheduled successfully!', Colors.green);
        } else {
          showTopSnackBar(
              context,
              'Failed to schedule transfer. Please try again later.',
              Colors.red);
        }
      } catch (e) {
        showTopSnackBar(context,
            'An error occurred. Please check your connection.', Colors.red);
        print('Exception: $e');
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Schedule Transfer',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26.0),
        ),
        backgroundColor: const Color.fromARGB(255, 134, 23, 116),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : user == null || payees.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<String>(
                              decoration:
                                  const InputDecoration(labelText: 'Transfer From'),
                              value: selectedFromAccount,
                              items: _accounts.map((account) {
                                String accountName = account['accountName'];
                                List<String> nameParts = accountName.split(' ');
                                String shortenedName = '';

                                // Get first three characters of the first three words
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
                            DropdownButtonFormField<String>(
                              decoration:
                                  const InputDecoration(labelText: 'Transfer To'),
                              value: selectedToAccount,
                              items: payees.map((payee) {
                                String displayText =
                                    '${payee['nickName']} ${payee['accountNumber']}';
                                return DropdownMenuItem<String>(
                                  value: payee['accountNumber'],
                                  child: Text(displayText),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedToAccount = value;
                                  beneficiaryName = payees.firstWhere((payee) =>
                                      payee['accountNumber'] ==
                                      value)['beneficiaryName'];
                                });
                              },
                              validator: (value) =>
                                  value == null ? 'Select beneficiary' : null,
                            ),
                            if (beneficiaryName != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child:
                                    Text('Beneficiary Name: $beneficiaryName'),
                              ),
                            TextFormField(
                              controller:
                                  _amountController, // Ensure the controller is linked
                              decoration: const InputDecoration(labelText: 'Amount'),
                              keyboardType: TextInputType.number,
                              validator: (value) =>
                                  value!.isEmpty ? 'Enter amount' : null,
                            ),
                            DropdownButtonFormField<String>(
                              decoration:
                                  const InputDecoration(labelText: 'Frequency'),
                              value: frequencyType,
                              items: ['Once', 'Daily', 'Weekly', 'Monthly']
                                  .map((frequency) => DropdownMenuItem<String>(
                                        value: frequency,
                                        child: Text(frequency),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  frequencyType = value;
                                });
                              },
                              validator: (value) =>
                                  value == null ? 'Select frequency' : null,
                            ),
                            if (frequencyType != 'Once')
                              Column(
                                children: [
                                  TextFormField(
                                    decoration: const InputDecoration(
                                        labelText: 'Scheduled Date'),
                                    onTap: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime(2100),
                                      );
                                      if (date != null) {
                                        setState(() {
                                          scheduledDate = date;
                                          scheduledDateController.text = date
                                                  .toLocal()
                                                  .toString()
                                                  .split(' ')[
                                              0]; // Update controller text
                                        });
                                      }
                                    },
                                    readOnly: true,
                                    validator: (value) {
                                      if (scheduledDate == null) {
                                        return 'Select a date';
                                      }
                                      if (frequencyEndDate != null &&
                                          scheduledDate!
                                              .isAfter(frequencyEndDate!)) {
                                        return 'Scheduled Date must be less than or equal to Frequency End Date';
                                      }
                                      return null;
                                    },
                                    controller: scheduledDateController,
                                  ),
                                  TextFormField(
                                    decoration: const InputDecoration(
                                        labelText: 'Frequency End Date'),
                                    onTap: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime(2100),
                                      );
                                      if (date != null) {
                                        setState(() {
                                          frequencyEndDate = date;
                                          frequencyEndDateController.text = date
                                                  .toLocal()
                                                  .toString()
                                                  .split(' ')[
                                              0]; // Update controller text
                                        });
                                      }
                                    },
                                    readOnly: true,
                                    validator: (value) {
                                      if (frequencyEndDate == null) {
                                        return 'Select a date';
                                      }
                                      if (scheduledDate != null &&
                                          frequencyEndDate!
                                              .isBefore(scheduledDate!)) {
                                        return 'Frequency End Date must be greater than or equal to Scheduled Date';
                                      }
                                      return null;
                                    },
                                    controller: frequencyEndDateController,
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16.0),
                            TextFormField(
                              decoration: const InputDecoration(
                                  labelText: 'Note',
                                  hintText: 'Optional',
                                  border: OutlineInputBorder(),
                                  isDense: true),
                              controller: _noteController,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 16.0),
                            Center(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    _formKey.currentState!.save();

                                    // Ensure that the amount is converted to an int before passing
                                    int amountValue =
                                        int.tryParse(_amountController.text) ??
                                            0;

                                    // Navigate to the confirm page
                                    Navigator.of(context)
                                        .push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ConfirmTransferPage(
                                          token: widget.token,
                                          fromAccount: selectedFromAccount!,
                                          toAccount: selectedToAccount!,
                                          beneficiaryName: beneficiaryName!,
                                          amount:
                                              amountValue, // Pass the amount as an int
                                          frequencyType: frequencyType!,
                                          scheduledDate: scheduledDate,
                                          frequencyEndDate: frequencyEndDate,
                                          note: _noteController.text,
                                          onConfirm:
                                              _scheduleTransfer, // Call the schedule transfer function
                                        ),
                                      ),
                                    )
                                        .then((_) {
                                      // Clear the form after navigating back
                                      _amountController.clear();
                                      _noteController.clear();
                                      scheduledDateController.clear();
                                      frequencyEndDateController.clear();

                                      setState(() {
                                        selectedFromAccount = null;
                                        selectedToAccount = null;
                                        beneficiaryName = null;
                                        frequencyType = 'Once';
                                        scheduledDate = null;
                                        frequencyEndDate = null;
                                      });
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 134, 23,
                                      116), // Set background color
                                  foregroundColor:
                                      Colors.white, // Set text color to white
                                ),
                                child: const Text('Continue Transfer'),
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
  final String token;
  final String fromAccount;
  final String toAccount;
  final String beneficiaryName;
  final int amount;
  final String frequencyType;
  final DateTime? scheduledDate;
  final DateTime? frequencyEndDate;
  final String note;
  final Future<void> Function() onConfirm;

  const ConfirmTransferPage({
    super.key,
    required this.token,
    required this.fromAccount,
    required this.toAccount,
    required this.beneficiaryName,
    required this.amount,
    required this.frequencyType,
    required this.scheduledDate,
    required this.frequencyEndDate,
    required this.note,
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
            if (widget.scheduledDate != null || widget.frequencyEndDate != null)
              _buildInfoCard(
                'Scheduled Date',
                widget.scheduledDate != null ? widget.scheduledDate!.toLocal().toString().split(' ')[0] : '',
                'Frequency End Date',
                widget.frequencyEndDate != null ? widget.frequencyEndDate!.toLocal().toString().split(' ')[0] : '',
                Icons.calendar_today,
              ),
            _buildInfoCard('Note', widget.note, null, null, Icons.note),
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
                            _showSnackBar(context, 'Transfer completed successfully!', Colors.green);
                            Navigator.of(context).pop();
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
              content: const Text(
                  'Are you sure you want to proceed with this transfer?'),
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
