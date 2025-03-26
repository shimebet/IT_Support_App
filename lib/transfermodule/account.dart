import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../constants.dart';
import 'package:provider/provider.dart';
import '../global_state.dart'; // Assuming you have this provider set up

class AccountDisputePage extends StatefulWidget {
  final String token;
  const AccountDisputePage({super.key, required this.token});

  @override
  _AccountDisputePageState createState() => _AccountDisputePageState();
}

class _AccountDisputePageState extends State<AccountDisputePage> {
  List<dynamic> transactions = [];
  List<dynamic> accounts = [];
  bool isLoading = true;
  bool _isAccountLoading = false;
  String selectedFilter = 'All';
  String? selectedAccount;
  String username = '';
  String accountname = '';
  String balance = 'Birr 0.00';
  String accountNumber = '';
  bool isAccountNumberVisible = false;
  bool isBalanceVisible = false;
  late String currentDate = getCurrentDate();

  @override
  void initState() {
    super.initState();
    _fetchAccounts().then((_) {
      fetchRecentTransactions();
    });
  }

  String selectedLanguage = 'English';
  Map<String, Map<String, String>> languageData = {
    'English': {
      'welcomeText': 'WELCOME BACK!',
      'balanceText': 'Balance',
      'accountText': 'Account',
      'dateText': 'Date',
      'logoutText': 'Logout',
      'transferText': 'Transfer',
      'billPaymentText': 'Bill Payment',
      'topupText': 'Top Up',
      'governmentserviceText': 'Govnt Service',
      'helpText': 'Help',
      'eventText': 'Event',
      'settingsText': 'Settings',
      'loginWithPinText': 'Login with PIN',
      'loginWithBiometricText': 'Login with Biometric',
    },
    'Oromo': {
      'welcomeText': 'An Haa, Dhuffu!',
      'balanceText': 'Baankii',
      'accountText': 'Herrega',
      'dateText': 'Guyyaa',
      'logoutText': 'Ba\'a',
      'transferText': 'Hiraa',
      'billPaymentText': 'Gatii Kaffaltii',
      'topupText': 'Madaa',
      'governmentserviceText': 'Govnt Service',
      'helpText': 'Help',
      'eventText': 'Event',
    },
    'Amharic': {
      'welcomeText': 'ሰላም፣ እንዴት እንለምናለን!',
      'balanceText': 'ቀሪ ሂሳብ',
      'accountText': 'መለያ',
      'dateText': 'ቀን',
      'logoutText': 'ውጣ',
      'transferText': 'ማስተላለፍ',
      'billPaymentText': 'ክፍያ መጠን',
      'topupText': 'ማስተከል',
      'governmentserviceText': 'Govnt Service',
      'helpText': 'Help',
      'eventText': 'Event',
    },
  };

  String getCurrentDate() {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('MMMM dd, yyyy');
    final String formatted = formatter.format(now);
    return formatted;
  }

  String _maskAccountNumber(String value) {
    // Handle both account number and balance masking
    if (value.length <= 5) {
      return value; // Do not mask if the value is too short
    }
    int len = value.length;
    return value.substring(0, len ~/ 2 - 2) +
        '*' * 5 +
        value.substring(len ~/ 2 + 3);
  }

  String _maskTotalBalance(double balance) {
    String balanceStr = balance.toStringAsFixed(2);
    return _maskAccountNumber(balanceStr);
  }

  void _toggleVisibility() {
    setState(() {
      isAccountNumberVisible = !isAccountNumberVisible;
      isBalanceVisible = !isBalanceVisible;
    });
  }

  String _truncateAccountName(String accountName) {
    return accountName
        .split(' ')
        .map((word) => word.length > 5 ? word.substring(0, 3) : word)
        .join(' ');
  }

  Future<void> _fetchAccounts() async {
    final globalState = Provider.of<GlobalState>(context, listen: false);
    globalState.setLoading(true);
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.fetchAccounts),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['Accounts'] != null && data['Accounts'].isNotEmpty) {
          final accountsList =
              List<Map<String, dynamic>>.from(data['Accounts']);
          setState(() {
            accounts = accountsList;
            if (accounts.isNotEmpty) {
              selectedAccount = accounts[0]['accountID'];
              username = accounts[0]['nickName'] ?? '';
              accountname = accounts[0]['accountName'] ?? '';
              balance = accounts[0]['availableBalance'] ?? 'Birr 0.00';
              accountNumber = accounts[0]['accountID'] ?? '';
            }
            _isAccountLoading = false;
          });
        } else {
          throw Exception('No accounts found');
        }
      } else {
        throw Exception('Failed to fetch data');
      }
    } catch (error) {
      print('Error fetching accounts: $error');
    } finally {
      globalState.setLoading(false);
    }
  }

  Future<void> fetchRecentTransactions() async {
    if (selectedAccount == null) return;

    setState(() {
      _isAccountLoading = true;
    });

    final url = Uri.parse(ApiConstants.fetchRecentTransactions);
    final headers = _buildHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['Transactions'] != null) {
        setState(() {
          transactions = responseData['Transactions'];
          isLoading = false;
        });
      } else {
        setState(() {
          transactions = [];
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }

    setState(() {
      _isAccountLoading = false;
    });
  }

  Map<String, String> _buildHeaders() {
    return {
      'X-Kony-Authorization': '${widget.token}',
      'Content-Type': 'application/json',
      'X-Kony-App-Key': ApiHeaders.appKey,
      'X-Kony-App-Secret': ApiHeaders.appSecret,
    };
  }

  List<dynamic> getFilteredTransactions(String accountNumber) {
    List<dynamic> filteredByAccount = transactions.where((transaction) {
      return transaction['fromAccountNumber'] == accountNumber ||
          transaction['toAccountNumber'] == accountNumber;
    }).toList();

    if (selectedFilter == 'All') {
      return filteredByAccount;
    } else {
      return filteredByAccount.where((transaction) {
        return transaction['statusDescription']?.toString() == selectedFilter;
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final globalState = Provider.of<GlobalState>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Account Transaction Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
          textAlign: TextAlign.start,
        ),
        backgroundColor: const Color.fromARGB(255, 134, 23, 116),
        centerTitle: false,
      ),
      body: Column(
        children: [
          globalState.isLoading
              ? Center(child: CircularProgressIndicator())
              : Container(
                  padding: const EdgeInsets.only(right: 12.0, left: 6.0),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Circular shape
                    ),
                    child: Container(
                      height: 250, // Adjust height as needed
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(12), // Circular shape
                        image: const DecorationImage(
                          image: AssetImage('assets/images/cbe7.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(26.0), // General padding
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${languageData[selectedLanguage]!['welcomeText']} $username', // Display welcome message
                              style: TextStyle(
                                fontSize:
                                    12, // Adjusted font size for better readability
                                color: Colors.orangeAccent.shade200,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: CarouselSlider(
                                options: CarouselOptions(
                                  height: 200.0,
                                  enlargeCenterPage: true,
                                  autoPlay: true,
                                  aspectRatio: 4.0,
                                  autoPlayCurve: Curves.fastOutSlowIn,
                                  enableInfiniteScroll: true,
                                  autoPlayAnimationDuration:
                                      const Duration(milliseconds: 1000),
                                  viewportFraction: 0.9,
                                ),
                                items: accounts.map((account) {
                                  final String accountName =
                                      account['accountName'] ?? '';
                                  final String truncatedAccountName =
                                      _truncateAccountName(accountName);
                                  final String accountNumber =
                                      account['accountID'] ?? '';
                                  final String balance =
                                      account['availableBalance'] ?? '0.00';

                                  // Calculate the total balance
                                  double totalBalance =
                                      accounts.fold(0.0, (sum, account) {
                                    return sum +
                                        double.parse(
                                            account['availableBalance'] ??
                                                '0.00');
                                  });

                                  return Builder(
                                    builder: (BuildContext context) {
                                      return Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 0.0),
                                        decoration: const BoxDecoration(
                                          color: Colors.transparent,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  '$truncatedAccountName:',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    isAccountNumberVisible
                                                        ? Icons.visibility_off
                                                        : Icons.visibility,
                                                    color: Colors.white,
                                                  ),
                                                  onPressed: _toggleVisibility,
                                                ),
                                              ],
                                            ),
                                            Text(
                                              'Account: ${isAccountNumberVisible ? accountNumber : _maskAccountNumber(accountNumber)}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 15),
                                            Text(
                                              'Balance: ${isBalanceVisible ? balance : '****'} Birr',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 15),
                                            Row(
                                              children: [
                                                Text(
                                                  '${languageData[selectedLanguage]!['dateText']} :',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  currentDate,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            // Display Total Asset with mask
                                            const SizedBox(height: 15),
                                            Text(
                                              'Total Asset: ${isAccountNumberVisible ? totalBalance.toStringAsFixed(2) : _maskTotalBalance(totalBalance)} Birr',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
            child: DropdownButtonFormField<String>(
              value: selectedFilter,
              onChanged: (newValue) {
                setState(() {
                  selectedFilter = newValue!;
                  fetchRecentTransactions();
                });
              },
              items: <String>[
                'All',
                'Completed',
                'Pending',
                'Failed',
                'Scheduled'
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0), // Adjust padding if needed
                labelText: 'Filter Transactions By Status',
                labelStyle: TextStyle(
                  color: Color.fromARGB(
                      255, 211, 10, 201), // Change this to your desired color
                  fontSize: 20.0, // Change this to your desired font size
                  fontWeight: FontWeight
                      .bold, // Change this to your desired font weight
                ),
                border: InputBorder.none, // Removes the border
                alignLabelWithHint: true, // Align label with hint text
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: accounts.map((account) {
                final accountId = account['accountID'];
                final accountName = account['accountName'] ?? 'Unknown';

                return ExpansionTile(
                  title: Text(accountName),
                  initiallyExpanded: accountId == selectedAccount,
                  onExpansionChanged: (isExpanded) {
                    setState(() {
                      if (isExpanded) {
                        selectedAccount = accountId;
                        isLoading = true; // Set loading to true when expanding
                        fetchRecentTransactions().then((_) {
                          setState(() {
                            isLoading =
                                false; // Set loading to false when data is fetched
                          });
                        }).catchError((error) {
                          setState(() {
                            isLoading =
                                false; // Set loading to false if there is an error
                          });
                          // Handle error (e.g., show an error message)
                        });
                      } else if (selectedAccount == accountId) {
                        selectedAccount = null;
                        transactions = [];
                      }
                    });
                  },
                  children: [
                    if (selectedAccount == accountId) ...[
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : getFilteredTransactions(accountId).isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('No transactions found.'),
                                )
                              : Column(
                                  children: getFilteredTransactions(accountId)
                                      .map((transaction) {
                                    final fromAccountName =
                                        transaction['fromAccountName'] ?? 'N/A';
                                    final words = fromAccountName.split(' ');
                                    final displayName = words.length >= 3
                                        ? '${words[0]} ${words[1]} ${words[2]}'
                                        : fromAccountName;

                                    return Card(
                                      child: ListTile(
                                        title: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 0.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    displayName,
                                                    style: const TextStyle(
                                                        fontSize: 12),
                                                  ),
                                                  Text(
                                                    'Birr ${transaction['amount']?.toString() ?? 'N/A'}',
                                                    style: const TextStyle(
                                                        fontSize: 14),
                                                  ),
                                                  Row(
                                                    children: [
                                                      Text(
                                                        transaction['statusDescription']
                                                                ?.toString() ??
                                                            'N/A',
                                                        style: const TextStyle(
                                                            fontSize: 14),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Icon(
                                                        transaction['currentStatus'] ==
                                                                'ACSC'
                                                            ? Icons.check_circle
                                                            : Icons.cancel,
                                                        color: transaction[
                                                                    'currentStatus'] ==
                                                                'ACSC'
                                                            ? Colors.green
                                                            : Colors.red,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Transaction Number: ${transaction['transactionId'] ?? 'N/A'}',
                                              style: const TextStyle(
                                                  fontSize: 14.0),
                                            ),
                                            Text(
                                              'Transaction Type: ${transaction['transactionType'] ?? 'N/A'}',
                                              style: const TextStyle(
                                                  fontSize: 14.0),
                                            ),
                                            Text(
                                              'From Account Number: ${transaction['fromAccountNumber'] ?? 'N/A'}',
                                              style: const TextStyle(
                                                  fontSize: 14.0),
                                            ),
                                            Text(
                                              'From Account Name: ${transaction['fromAccountName'] ?? 'N/A'}',
                                              style: const TextStyle(
                                                  fontSize: 14.0),
                                            ),
                                            Text(
                                              'To Account Number: ${transaction['toAccountNumber'] ?? 'N/A'}',
                                              style: const TextStyle(
                                                  fontSize: 14.0),
                                            ),
                                            Text(
                                              'To Account Name: ${transaction['toAccountName'] ?? 'N/A'}',
                                              style: const TextStyle(
                                                  fontSize: 14.0),
                                            ),
                                            Text(
                                              'Frequency: ${transaction['frequencyType'] ?? 'N/A'}',
                                              style: const TextStyle(
                                                  fontSize: 14.0),
                                            ),
                                            Text(
                                              'Date: ${transaction['scheduledDate'] ?? 'N/A'}',
                                              style: const TextStyle(
                                                  fontSize: 14.0),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                    ],
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
