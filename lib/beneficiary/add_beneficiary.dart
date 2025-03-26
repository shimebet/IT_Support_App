import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../constants.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';

class AddRecipientPage extends StatefulWidget {
  final String token;

  const AddRecipientPage({Key? key, required this.token}) : super(key: key);

  @override
  _AddRecipientPageState createState() => _AddRecipientPageState();
}

class _AddRecipientPageState extends State<AddRecipientPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
        title: const Text('Add Recipient'),
        backgroundColor: const Color.fromARGB(255, 134, 23, 116),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_rounded),
            title: const Text('CBE Account'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddCBEBeneficiaryPage(token: widget.token),
                ),
              );
            },
          ),
          ListTile(
             leading: const Icon(Icons.receipt_sharp),
            title: const Text('Other Bank'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddOtherBankBeneficiaryPage(token: widget.token),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}



class AddCBEBeneficiaryPage extends StatelessWidget {
  final String token;
  const AddCBEBeneficiaryPage({Key? key, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
      title: const Text('Add CBE Beneficiary'),
      backgroundColor: const Color.fromARGB(255, 134, 23, 116),
    ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: CBEBeneficiaryForm(token: token),
      ),
    );
  }
}

class CBEBeneficiaryForm extends StatefulWidget {
  final String token;

  const CBEBeneficiaryForm({Key? key, required this.token}) : super(key: key);

  @override
  _CBEBeneficiaryFormState createState() => _CBEBeneficiaryFormState();
}

class _CBEBeneficiaryFormState extends State<CBEBeneficiaryForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _beneficiaryNameController = TextEditingController();
  String? accountNumber;
  String? beneficiaryName;
  late String nickName;
  String? cif;
  bool isLoading = false;
    bool _isLoading = false;

  Future<void> fetchCIF() async {
    final url = Uri.parse('https://infinityuat.cbe.com.et/services/data/v1/RBObjects/objects/User');
    final response = await http.get(url, headers: _buildHeaders());

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      cif =
          "[{\"contractId\":\"${data['records'][0]['CoreCustomers'][0]['contractId']}\",\"coreCustomerId\":\"${data['records'][0]['CoreCustomers'][0]['coreCustomerID']}\"}]";
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch CIF value')),
      );
    }
  }

  Future<void> fetchAccountDetails() async {
    accountNumber = _accountNumberController.text;

    if (accountNumber == null || accountNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter account number')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(
        'https://infinityuat.cbe.com.et/services/data/v1/RBObjects/operations/Transactions/getValidAccountId');
        
    final response = await http.post(
      url,
      headers: _buildHeaders(),
      body: json.encode({
        "accountID": accountNumber,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['opstatus'] == 0) {
        setState(() {
          beneficiaryName = data['Details'][0]['customerName'];
          _beneficiaryNameController.text = beneficiaryName!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch account details')),
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch account details')),
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

void _submitForm() async {
  if (_formKey.currentState!.validate()) {
    _formKey.currentState!.save();

    setState(() {
      isLoading = true; // Start loading
    });

    try {
      await fetchCIF(); // Fetch CIF
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmPage(
            accountNumber: accountNumber!,
            beneficiaryName: beneficiaryName!,
            nickName: nickName,
            cif: cif!, // Assuming CIF is required
            token: widget.token,
          ),
        ),
      );
    } finally {
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _accountNumberController,
            decoration: const InputDecoration(labelText: 'Account Number'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter account number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
        Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Expanded(
      child: TextFormField(
        readOnly: true,
        controller: _beneficiaryNameController,
        decoration: const InputDecoration(labelText: 'Beneficiary Name'),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please fetch beneficiary name';
          }
          return null;
        },
      ),
    ),
    ElevatedButton(
      onPressed: _isLoading ? null : fetchAccountDetails,
      child: _isLoading
          ? const CircularProgressIndicator()
          : const Text('Fetch Name'),
    ),
  ],
),
          const SizedBox(height: 16),

          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Nickname'),
            onSaved: (value) {
              nickName = value!;
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter nickname';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
Center(
  child: isLoading
      ? CircularProgressIndicator()
      : ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 115, 3, 150), // Button background color
            foregroundColor: Colors.white, // Button text color
          ),
          onPressed: _submitForm, // Callback function for the button press
          child: const Text('Continue'),
        ),
)


        ],
      ),
    );
  }
}

class AddOtherBankBeneficiaryPage extends StatelessWidget {
  final String token;

  const AddOtherBankBeneficiaryPage({Key? key, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Other Bank Beneficiary')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: OtherBankBeneficiaryForm(token: token),
      ),
    );
  }
}

class OtherBankBeneficiaryForm extends StatefulWidget {
  final String token;

  const OtherBankBeneficiaryForm({Key? key, required this.token}) : super(key: key);

  @override
  _OtherBankBeneficiaryFormState createState() => _OtherBankBeneficiaryFormState();
}

class _OtherBankBeneficiaryFormState extends State<OtherBankBeneficiaryForm> {
  final _formKey = GlobalKey<FormState>();
  late String accountNumber;
  late String beneficiaryName;
  late String nickName;

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmPage(
            accountNumber: accountNumber,
            beneficiaryName: beneficiaryName,
            nickName: nickName,
            cif: '', // Other bank does not require CIF, pass empty string
            token: widget.token,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: 'Account Number'),
            onSaved: (value) {
              accountNumber = value!;
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter account number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Beneficiary Name'),
            onSaved: (value) {
              beneficiaryName = value!;
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter beneficiary name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Nickname'),
            onSaved: (value) {
              nickName = value!;
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter nickname';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _submitForm,
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

class ConfirmPage extends StatelessWidget {
  final String accountNumber;
  final String beneficiaryName;
  final String nickName;
  final String cif;
  final String token;

  final ValueNotifier<bool> isModifyLoading = ValueNotifier(false);
  final ValueNotifier<bool> isSubmitLoading = ValueNotifier(false);

  ConfirmPage({
    Key? key,
    required this.accountNumber,
    required this.beneficiaryName,
    required this.nickName,
    required this.cif,
    required this.token,
  }) : super(key: key);

  Map<String, String> _buildHeaders() {
    return {
      'X-Kony-Authorization': token,
      'Content-Type': 'application/json',
      'X-Kony-App-Key': ApiHeaders.appKey,
      'X-Kony-App-Secret': ApiHeaders.appSecret,
    };
  }

  Future<void> _submitBeneficiary(BuildContext context) async {
  isSubmitLoading.value = true;
  final url = Uri.parse(
      'https://infinityuat.cbe.com.et/services/data/v1/PayeeObjects/operations/Recipients/createExternalPayee');

  String statusMessage;
  Color messageColor;

  try {
    final response = await http.post(
      url,
      headers: _buildHeaders(),
      body: json.encode({
        "routingNumber": "",
        "swiftCode": "",
        "bankName": "CBE",
        "accountType": "",
        "accountNumber": accountNumber,
        "beneficiaryName": beneficiaryName,
        "nickName": nickName,
        "isBusinessPayee": "0",
        "displayName": "OTHER_INTERNAL_MEMBER",
        "isSameBankAccount": "true",
        "isInternationalAccount": "false",
        "isVerified": "true",
        "cif": cif,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      if (responseData['Id'] != null) {
        statusMessage = 'Beneficiary added successfully! ID: ${responseData['Id']}';
        messageColor = Colors.green;
      } else if (responseData['dbpErrCode'] == '12062') {
        // Handle the specific error where the payee is already associated with the CIF
        statusMessage = 'Failed to add beneficiary: ${responseData['dbpErrMsg']}';
        messageColor = Colors.red;
      } else {
        statusMessage = 'Failed to add beneficiary: ${responseData['dbpErrMsg']}';
        messageColor = Colors.red;
      }
    } else {
      statusMessage = 'Failed to add beneficiary';
      messageColor = Colors.red;
    }
  } catch (e) {
    statusMessage = 'Error: ${e.toString()}';
    messageColor = Colors.red;
  } finally {
    isSubmitLoading.value = false;
  }

  // Show the status message in a dialog
  final overlayState = Overlay.of(context);
  if (overlayState != null) {
    showTopSnackBar(
      overlayState,
      CustomSnackBar.success(
        message: statusMessage,
        backgroundColor: messageColor,
      ),
    );
  }

  if (messageColor == Colors.green) {
    Navigator.of(context).pop();
    Navigator.of(context).pop();
     Navigator.of(context).pop();
  } else {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.of(context).pop();
       Navigator.of(context).pop();
        Navigator.of(context).pop();
    });
  }
}



@override
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Confirm Details'),
      backgroundColor: const Color.fromARGB(255, 134, 23, 116),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity, // Set width to full width of the parent
            height: 250, // Specify the height of the card
            child: Card(
              elevation: 1,
              margin: const EdgeInsets.all(8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Confirm to Add Beneficiary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 115, 3, 150),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Account Number:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4), // Add spacing between the label and the value
                        Text(accountNumber),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Beneficiary Name:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                             fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4), // Add spacing between the label and the value
                        Text(beneficiaryName),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Nickname:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4), // Add spacing between the label and the value
                        Text(nickName),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: isModifyLoading,
                builder: (context, loading, child) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 115, 3, 150),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: loading
                        ? null
                        : () {
                            isModifyLoading.value = true;
                            Navigator.pop(context);
                            isModifyLoading.value = false;
                          },
                    child: loading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          )
                        : const Text('Modify'),
                  );
                },
              ),
              const SizedBox(width: 16),
              ValueListenableBuilder<bool>(
                valueListenable: isSubmitLoading,
                builder: (context, loading, child) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 115, 3, 150),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: loading
                        ? null
                        : () => _submitBeneficiary(context),
                    child: loading
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          )
                        : const Text('Submit'),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
}



