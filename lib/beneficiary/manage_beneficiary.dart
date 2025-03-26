import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import 'send_money_tobeneficiary.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';

class ManageBeneficiaryPage extends StatelessWidget {
  final String token;

  const ManageBeneficiaryPage({Key? key, required this.token}): super(key: key);

void _navigateToSendMoneyToBeneficiaryPage(BuildContext context, String accountNumber) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => SendMoneyToBeneficiaryPage(
        token: token, 
        accountNumber: accountNumber,
      ),
    ),
  );
}

  @override
 Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Manage Beneficiaries'),
      backgroundColor: const Color.fromARGB(255, 134, 23, 116),
    ),
    body: FutureBuilder<List<Beneficiary>>(
      future: fetchBeneficiaries(token),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No beneficiaries found.'));
        } else {
          return ListView(
            children: snapshot.data!.map((beneficiary) {
              return ExpansionTile(
                title: Text(beneficiary.beneficiaryName),
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start, 
                    children: [
                      _buildRow(context, '  Recipient Name:', beneficiary.beneficiaryName),
                      _buildRow(context, '  Bank Name:', beneficiary.bankName),
                      _buildRow(context, '  Account Number:', beneficiary.accountNumber),
                      _buildRow(context, '  Nick Name:', beneficiary.nickName),
                      _buildRow(context, '  Verified:', beneficiary.isVerified ? 'Yes' : 'No'),
                      _buildRow(context, '  Linked Customer:', beneficiary.noOfCustomersLinked),
                      _buildRow(context, '  Routing Number:', beneficiary.routingNumber ?? 'N/A'),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                        Row(
                          children: [
                            Icon(Icons.attach_money, color: Colors.green),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the drawer
                                _navigateToSendMoneyToBeneficiaryPage(context, beneficiary.accountNumber);
                              },
                              child: Text('Send Money', style: TextStyle(color: Colors.green)),
                            ),
                          ],
                        ),

                          Row(
                            children: [
                              Icon(Icons.edit, color: Colors.blue),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditBeneficiaryPage(
                                        token: token,
                                        beneficiary: beneficiary,
                                      ),
                                    ),
                                  );
                                },
                                child: Text('Edit', style: TextStyle(color: Colors.blue)),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              TextButton(
                                onPressed: () {
                                  _deleteBeneficiary(context, beneficiary);
                                },
                                child: Text('Delete', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            }).toList(),
          );
        }
      },
    ),
  );
}

Widget _buildRow(BuildContext context, String label, String value) {
   return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(
                fontSize: 16.0,
                color: Colors.black, // Set text color to black
              ),
          children: [
            TextSpan(
              text: label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black, // Set label color to black and bold
              ),
            ),
            TextSpan(
              text: ' $value',
              style: const TextStyle(
                color: Colors.black, // Set value color to black
              ),
            ),
          ],
        ),
      ),
    );
}

  Future<List<Beneficiary>> fetchBeneficiaries(String token) async {
    final url = Uri.parse(
        'https://infinityuat.cbe.com.et/services/data/v1/PayeeObjects/operations/Recipients/getExternalPayees');
    final response = await http.post(
      url,
      headers: {
        'X-Kony-Authorization': token,
        'Content-Type': 'application/json',
        'X-Kony-App-Key': ApiHeaders.appKey,
        'X-Kony-App-Secret': ApiHeaders.appSecret,
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['opstatus'] == 0) {
        List<dynamic> accountsJson = data['ExternalAccounts'];
        return accountsJson.map((json) => Beneficiary.fromJson(json)).toList();
      } else {
        throw Exception('Failed to fetch beneficiaries');
      }
    } else {
      throw Exception('Failed to fetch beneficiaries');
    }
  }

  Future<void> _deleteBeneficiary(
      BuildContext context, Beneficiary beneficiary) async {
    bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content:
              const Text('Are you sure you want to delete this beneficiary?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User clicked "No"
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User clicked "Yes"
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return; // If the user cancels, do nothing
    }

    final url = Uri.parse(
        'https://infinityuat.cbe.com.et/services/data/v1/PayeeObjects/operations/Recipients/deleteExternalPayee');

    final requestBody = {
      "accountNumber": beneficiary.accountNumber,
      "Id": beneficiary.id,
      "isSameBankAccount": true,
      "isInternationalAccount": false,
    };

    String statusMessage;
    Color messageColor;

    final response = await http.post(
      url,
      headers: {
        'X-Kony-Authorization': token,
        'Content-Type': 'application/json',
        'X-Kony-App-Key': ApiHeaders.appKey,
        'X-Kony-App-Secret': ApiHeaders.appSecret,
      },
      body: json.encode(requestBody),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['opstatus'] == 0) {
        statusMessage = 'Beneficiary deleted successfully!';
        messageColor = Colors.green;

        // Refresh the page after deletion
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ManageBeneficiaryPage(token: token),
          ),
        );
      } else {
        statusMessage = 'Failed to delete beneficiary';
        messageColor = Colors.red;
      }
    } else {
      statusMessage = 'Failed to delete beneficiary';
      messageColor = Colors.red;
    }

    // Use Overlay.of(context) to get the OverlayState
    final overlayState = Overlay.of(context);
    if (overlayState != null) {
      showTopSnackBar(
        overlayState,
        CustomSnackBar.success(
          // or CustomSnackBar.error, CustomSnackBar.info
          message: statusMessage,
          backgroundColor: messageColor,
        ),
      );
    }
  }
}

class EditBeneficiaryPage extends StatefulWidget {
  final String token;
  final Beneficiary beneficiary;

  const EditBeneficiaryPage(
      {Key? key, required this.token, required this.beneficiary})
      : super(key: key);

  @override
  _EditBeneficiaryPageState createState() => _EditBeneficiaryPageState();
}

class _EditBeneficiaryPageState extends State<EditBeneficiaryPage> {
  final _formKey = GlobalKey<FormState>();
  String cif = ""; // Initialize with an empty string
  final TextEditingController _nickNameController = TextEditingController();
  bool _isLoading = false; // For loading indicator

  @override
  void initState() {
    super.initState();
    _nickNameController.text = widget.beneficiary.nickName;
    fetchCIF(); // Fetch CIF on initialization
  }

  Future<void> fetchCIF() async {
    final url = Uri.parse(
        'https://infinityuat.cbe.com.et/services/data/v1/RBObjects/objects/User');
    final response = await http.get(url, headers: _buildHeaders());

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        cif =
            "[{\"contractId\":\"${data['records'][0]['CoreCustomers'][0]['contractId']}\",\"coreCustomerId\":\"${data['records'][0]['CoreCustomers'][0]['coreCustomerID']}\"}]";
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch CIF value')),
      );
    }
  }

  Future<void> _editBeneficiary(BuildContext context) async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    final url = Uri.parse(
        'https://infinityuat.cbe.com.et/services/data/v1/PayeeObjects/operations/Recipients/editExternalPayee');

    String statusMessage;
    Color messageColor;

    try {
      final requestBody = {
        "accountNumber": widget.beneficiary.accountNumber,
        "accountType": "",
        "bankName": widget.beneficiary.bankName,
        "beneficiaryName": widget.beneficiary.beneficiaryName,
        "cif": cif, // Make sure this is the correct format
        "displayName": "",
        "isBusinessPayee": "",
        "isInternationalAccount": "false",
        "isSameBankAccount": "true",
        "nickName": _nickNameController.text,
        "oldName": "",
        "payeeId": widget.beneficiary.id,
        "routingNumber": widget.beneficiary.routingNumber ?? "N/A",
        "swiftCode": "N/A",
      };

      final headers = _buildHeaders();

      final response = await http.put(
        url,
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['Id'] != null) {
          statusMessage =
              'Beneficiary updated successfully! ID: ${responseData['Id']}';
          messageColor = Colors.green;

          // Refresh the ManageBeneficiaryPage after updating
          Navigator.pop(context); // Pop EditBeneficiaryPage
          Navigator.pop(context); // Pop ManageBeneficiaryPage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ManageBeneficiaryPage(token: widget.token),
            ),
          );
        } else {
          statusMessage = 'Failed to update beneficiary';
          messageColor = Colors.red;
        }
      } else {
        statusMessage = 'Failed to update beneficiary';
        messageColor = Colors.red;

        final responseData = json.decode(response.body);
        print('Detailed Error: ${responseData['dbpErrMsg']}');
      }
    } catch (e) {
      statusMessage = 'Error: ${e.toString()}';
      messageColor = Colors.red;
    }

    setState(() {
      _isLoading = false; // Hide loading indicator
    });

    // Use Overlay.of(context) to get the OverlayState
    final overlayState = Overlay.of(context);
    if (overlayState != null) {
      showTopSnackBar(
        overlayState,
        CustomSnackBar.success(
          // or CustomSnackBar.error, CustomSnackBar.info
          message: statusMessage,
          backgroundColor: messageColor,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Beneficiary'),
        backgroundColor: const Color.fromARGB(255, 134, 23, 116),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRow(context, 'Recipient Name:',
                    widget.beneficiary.beneficiaryName),
                _buildRow(context, 'Bank Name:', widget.beneficiary.bankName),
                _buildRow(context, 'Account Number:',
                    widget.beneficiary.accountNumber),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: _nickNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nick Name',
                      border:
                          OutlineInputBorder(), // Add this line to give a specific border
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color:
                                Colors.blue), // Set border color when focused
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color:
                                Colors.grey), // Set border color when enabled
                      ),
                      labelStyle: TextStyle(
                          color: Colors.black), // Label color to black
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a nickname';
                      }
                      return null;
                    },
                    style: const TextStyle(
                        color: Colors.black), // Text color to black
                  ),
                ),
                _buildRow(context, 'Verified:',
                    widget.beneficiary.isVerified ? 'Yes' : 'No'),
                _buildRow(context, 'Linked Customer:',
                    widget.beneficiary.noOfCustomersLinked),
                _buildRow(context, 'Routing Number:',
                    widget.beneficiary.routingNumber ?? 'N/A'),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null // Disable button while loading
                        : () {
                            if (_formKey.currentState!.validate()) {
                              _editBeneficiary(context);
                            }
                          },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                          const Color.fromARGB(255, 185, 3, 155)),
                      foregroundColor:
                          MaterialStateProperty.all<Color>(Colors.white),
                      padding: MaterialStateProperty.all<EdgeInsets>(
                          const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12)),
                      textStyle: MaterialStateProperty.all<TextStyle>(
                          const TextStyle(fontSize: 16)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color.fromARGB(255, 255, 255, 255)),
                          )
                        : const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(
                fontSize: 12.0,
                color: Colors.black, // Set text color to black
                decoration:
                    TextDecoration.none, // Ensure no underline is applied
              ),
          children: [
            TextSpan(
              text: label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black, // Set label color to black and bold
                decoration:
                    TextDecoration.none, // Ensure no underline is applied
              ),
            ),
            TextSpan(
              text: ' $value',
              style: const TextStyle(
                color: Colors.black, // Set value color to black
                decoration:
                    TextDecoration.none, // Ensure no underline is applied
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Beneficiary {
  final String accountNumber;
  final String bankName;
  final String beneficiaryName;
  final String createdOn;
  final bool isInternationalAccount;
  final bool isSameBankAccount;
  final bool isVerified;
  final String nickName;
  final String cif;
  final String id;
  final String noOfCustomersLinked;
  final String? routingNumber;

  Beneficiary({
    required this.accountNumber,
    required this.bankName,
    required this.beneficiaryName,
    required this.createdOn,
    required this.isInternationalAccount,
    required this.isSameBankAccount,
    required this.isVerified,
    required this.nickName,
    required this.cif,
    required this.id,
    required this.noOfCustomersLinked,
    this.routingNumber,
  });

  factory Beneficiary.fromJson(Map<String, dynamic> json) {
    return Beneficiary(
      accountNumber: json['accountNumber'],
      bankName: json['bankName'],
      beneficiaryName: json['beneficiaryName'],
      createdOn: json['createdOn'],
      isInternationalAccount: json['isInternationalAccount'] == 'false',
      isSameBankAccount: json['isSameBankAccount'] == 'true',
      isVerified: json['isVerified'] == 'true',
      nickName: json['nickName'],
      cif: json['cif'],
      id: json['Id'],
      noOfCustomersLinked: json['noOfCustomersLinked'],
      routingNumber: json['routingNumber'],
    );
  }
}
