import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
// import 'transfermodule/transfer.dart';
// import 'bill/topup.dart';
// import 'bill/billpayment.dart';
// import 'bill/airline.dart';
// import 'body/govermment.dart';
import 'footer/it_support_solution.dart';
import 'footer/issue_report_page.dart';
// import 'body/help.dart';
// import 'body/support.dart';
import 'body/exchangerate.dart';
import 'auth/biometric_auth.dart';
import 'auth/login.dart';
// import 'body/event.dart';
// import 'beneficiary/add_beneficiary.dart';
// import 'beneficiary/manage_beneficiary.dart';
// import 'beneficiary/transfer_to_beneficiary.dart';
// import 'beneficiary/send_money_tobeneficiary.dart';
// import 'transfermodule/transfermodule.dart';
// import 'wallet/wallettransfermodule.dart';
// import 'wallet/kacha.dart';
// import 'wallet/ebirr.dart';
// import 'wallet/cbebirr.dart';
// import 'wallet/tellbirr.dart';
// import 'transfermodule/transfer_to_other_bank_page.dart';
// import 'transfermodule/international_transfer_page.dart';
// import 'transfermodule/localmoneytransfer.dart';
// import 'bill/billpaymentmodule.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../global_state.dart';
// import '../constants.dart';
// import 'transfermodule/account.dart';
// import 'transfermodule/scheduletransfer.dart';

class HomePage extends StatefulWidget {
  final String token;
  final String username; // Add this

   const HomePage({
    super.key,
    required this.token,
    required this.username, // Add this
  });

  @override
  _HomePageState createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  late String username = "";
  late String accountname = "";
  late String email = "";
  late String role = "";
  late String branchAddress = "";
  late String branchGrade = "";
  late String branchId = "";
  late String currentDate = getCurrentDate();
  List<Map<String, dynamic>> accounts = [];
  bool isAccountNumberVisible = false;
  bool isBalanceVisible = false;
  bool _isLoading = false;

  String selectedLanguage = 'English';
 Map<String, Map<String, String>> languageData = {
  'English': {
    'welcomeText': 'WELCOME BACK! TO CBE',
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
    'governmentserviceText': 'Tajaajila Mootummaa',
    'helpText': 'Gargaarsa',
    'eventText': 'Taateewwan',
    'settingsText': 'Sajoo',
    'loginWithPinText': 'Pin fayyadami',
    'loginWithBiometricText': 'Biometric fayyadami',
  },
  'Amharic': {
    'welcomeText': 'ሰላም፣ እንኳን በደህና መጡ!',
    'balanceText': 'ቀሪ ሂሳብ',
    'accountText': 'ሒሳብ',
    'dateText': 'ቀን',
    'logoutText': 'ውጣ',
    'transferText': 'ማስተላለፍ',
    'billPaymentText': 'ክፍያ መጠን',
    'topupText': 'ማስተከል',
    'governmentserviceText': 'የመንግስት አገልግሎት',
    'helpText': 'እርዳታ',
    'eventText': 'ክስተቶች',
    'settingsText': 'ቅንብሮች',
    'loginWithPinText': 'ፒን ያስገቡ',
    'loginWithBiometricText': 'በባዮሜትሪክ ይግቡ',
  },
};


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserData();
    });
  }

  String getCurrentDate() {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('MMMM dd, yyyy');
    final String formatted = formatter.format(now);
    return formatted;
  }

  // String _maskAccountNumber(String accountNumber) {
  //   if (accountNumber.length <= 5) {
  //     return accountNumber; // Do not mask if the account number is too short
  //   }
  //   int len = accountNumber.length;
  //   return accountNumber.substring(0, len ~/ 2 - 2) +
  //       '*' * 5 +
  //       accountNumber.substring(len ~/ 2 + 3);
  // }

  // void _toggleVisibility() {
  //   setState(() {
  //     isAccountNumberVisible = !isAccountNumberVisible;
  //     isBalanceVisible = !isBalanceVisible;
  //   });
  // }

  // String _truncateAccountName(String accountName) {
  //   return accountName
  //       .split(' ')
  //       .map((word) => word.length > 5 ? word.substring(0, 3) : word)
  //       .join(' ');
  // }

 Future<void> _fetchUserData() async {
  final globalState = Provider.of<GlobalState>(context, listen: false);
  globalState.setLoading(true);

  try {
    final response = await http.get(
      Uri.parse('https://node-api-g7fs.onrender.com/api/users/me'),
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        username = data['userName'] ?? '';
        accountname = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}';
        role = data['role'] ?? '';
        branchAddress = data['branchAddress'] ?? '';
        branchGrade = data['branchGrade'] ?? '';
      });
    } else {
      throw Exception('Failed to fetch user data');
    }
  } catch (error) {
    print('Error fetching user data: $error');
  } finally {
    globalState.setLoading(false);
  }
}



  void _logout(BuildContext context) {
    Navigator.of(context).pushReplacementNamed('/');
  }

  Future<void> _refreshPage() async {
    setState(() {
      _isLoading = true;
    });
    await _fetchUserData(); // Await the fetch data method
    setState(() {
      _isLoading = false;
    });
  }

// Toggle account number visibility
//   void _toggleAccountNumberVisibility() {
//     setState(() {
//       isAccountNumberVisible = !isAccountNumberVisible;
//     });
//   }

//   void _navigateToTransferPage(BuildContext context) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//           builder: (context) => TransferPage(token: widget.token)),
//     );
//   }
//     void _navigateToScheduleTransferPage(BuildContext context) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//           builder: (context) => ScheduleTransferPage(token: widget.token)),
//     );
//   }
//       void _navigateToLocalMoneyTransferPage(BuildContext context) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//           builder: (context) => LocalMoneyTransferPage(token: widget.token)),
//     );
//   }
//     void _navigateToTransferModulePage(BuildContext context) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//           builder: (context) => TransferModulePage(token: widget.token)),
//     );
//   }
//       void _navigateToWalletTransferPage(BuildContext context) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//           builder: (context) => WalletTransferPage(token: widget.token)),
//     );
//   }
//      void _navigateToBillPaymentModulePage(BuildContext context) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//           builder: (context) => BillPaymentModulePage(token: widget.token)),
//     );
//   }
//   void _navigateToOtherBankTransferPage(BuildContext context) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//           builder: (context) => OtherBankTransferPage(token: widget.token)),
//     );
//   }
//  void _navigateToInternationalTransferPage(BuildContext context) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//           builder: (context) => InternationalTransferPage(token: widget.token)),
//     );
//   }

//   void _navigateToBillPaymentPage(BuildContext context) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//           builder: (context) => BillPaymentPage(token: widget.token)),
//     );
//   }
//   void _navigateToAddRecipientPage(BuildContext context) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//           builder: (context) => AddRecipientPage(token: widget.token)),
//     );
//   }
//   void _navigateToManageBeneficiaryPage(BuildContext context) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//           builder: (context) => ManageBeneficiaryPage(token: widget.token)),
//     );
//   }
//     void _navigateToTransferToBeneficiaryPage(BuildContext context) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//           builder: (context) => TransferToBeneficiaryPage(token: widget.token)),
//     );
//   }
// void _navigateToSendMoneyToBeneficiaryPage(BuildContext context, String accountNumber) {
//   Navigator.of(context).push(
//     MaterialPageRoute(
//       builder: (context) => SendMoneyToBeneficiaryPage(
//         token: widget.token, 
//         accountNumber: accountNumber,
//       ),
//     ),
//   );
// }
//   void _navigateToAirLinePage(BuildContext context) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//           builder: (context) => AirLinePage(token: widget.token)),
//     );
//   }

//   void _navigateToTopUpPage(BuildContext context) {
//     Navigator.of(context).push(
//       MaterialPageRoute(builder: (context) => TopUpPage(token: widget.token)),
//     );
//   }

//   void _navigateToGovernmentServicePage(BuildContext context) {
//     Navigator.of(context).push(
//       MaterialPageRoute(builder: (context) => const GovernmentServicePage()),
//     );
//   }

//   void _navigateToHelpPage(BuildContext context) {
//     Navigator.of(context).push(
//       MaterialPageRoute(builder: (context) => const HelpPage()),
//     );
//   }

//   void _navigateToEventPage(BuildContext context) {
//     Navigator.of(context).push(
//       MaterialPageRoute(builder: (context) => const EventPage()),
//     );
//   }



 void _navigateToRecentTransactionsPage(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => SupportIssuesPage(
        token: widget.token,
        username: widget.username, // <-- Pass the username here
      ),
    ),
  );
}


  // void _navigateToAccountDisputePage(BuildContext context) {
  //   Navigator.of(context).push(
  //     MaterialPageRoute(
  //         builder: (context) => AccountDisputePage(token: widget.token)),
  //   );
  // }

  void _navigateToExchangeRatePage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => ExchangeRatePage(token: widget.token)),
    );
  }

  // void _navigateToKachaPage(BuildContext context) {
  //   Navigator.of(context).push(
  //     MaterialPageRoute(builder: (context) => KachaPage(token: widget.token)),
  //   );
  // }

  // void _navigateToCbeBirPage(BuildContext context) {
  //   Navigator.of(context).push(
  //     MaterialPageRoute(builder: (context) => CbeBirPage(token: widget.token)),
  //   );
  // }

  // void _navigateToEbirrPage(BuildContext context) {
  //   Navigator.of(context).push(
  //     MaterialPageRoute(builder: (context) => EbirrPage(token: widget.token)),
  //   );
  // }

  // void _navigateToTellBirrPage(BuildContext context) {
  //   Navigator.of(context).push(
  //     MaterialPageRoute(
  //         builder: (context) => TellBirrPage(token: widget.token)),
  //   );
  // }

  // void _navigateToSupportPage(BuildContext context) {
  //   Navigator.of(context).push(
  //     MaterialPageRoute(builder: (context) => SupportPage(token: widget.token)),
  //   );
  // }

  void _navigateToMiniAppsPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => IssueReportPage(token: widget.token)),
    );
  }

  void _navigateToLoginWithPinPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  void _navigateToLoginWithBiometricPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const BiometricAuthPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final globalState = Provider.of<GlobalState>(context);
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/cbe6.png', // Replace with your image asset path
          height: 80,
          width: 200,
        ), // Display image
        actions: [
          DropdownButton<String>(
            value: selectedLanguage,
            onChanged: (String? newValue) {
              setState(() {
                selectedLanguage = newValue!;
              });
            },
            underline: const SizedBox(),
            items:
                languageData.keys.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0.0),
                  child: Text(value),
                ),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await _refreshPage(); // Call _refreshPage and await its completion
            },
          ),
        ],
      ),
      drawer: SizedBox(
        width: 250, // Adjust width as needed
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                height: 150, // Adjust height as needed for DrawerHeader
                child: DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 151, 16, 129),
                  ),
                  padding: EdgeInsets.zero,
                  child: Container(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 250,
                      height: 100,
                      child: Image.asset(
                        'assets/images/cbe6.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.account_balance_outlined,
                  color: Color.fromARGB(255, 143, 4, 120),
                ),
                title: const Text('Home'),
                onTap: () {
                  Navigator.of(context).pop(); // Close the drawer
                },
              ),
              ExpansionTile(
                leading: const Icon(
                  Icons.payment,
                  color: Color.fromARGB(255, 143, 4, 120),
                ),
                title: const Text('Network'), // Name the dropdown as 'MyBill'
                trailing: const Icon(
                  Icons.arrow_drop_down,
                  color: Color.fromARGB(255, 143, 4, 120),
                ),
                onExpansionChanged: (bool expanded) {
                  if (expanded) {

                  }
                },
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.transfer_within_a_station,
                        color: Color.fromARGB(255, 143, 4, 120)),
                    title: const Text('Connectivity Issues'),
                    onTap: () {
                      // Navigator.of(context).pop(); // Close the drawer
                      // _navigateToTransferPage(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.transfer_within_a_station,
                        color: Color.fromARGB(255, 143, 4, 120)),
                    title: const Text('LAN & VLAN Issues'),
                    onTap: () {
                      // Navigator.of(context).pop(); // Close the drawer
                      // _navigateToTransferToBeneficiaryPage(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.transfer_within_a_station,
                        color: Color.fromARGB(255, 143, 4, 120)),
                    title: const Text('Firewall & Security Issues'),
                    onTap: () {
                      // Navigator.of(context).pop(); // Close the drawer
                      // _navigateToScheduleTransferPage(context);
                    },
                  ),
                 ListTile(
                    leading: const Icon(Icons.transfer_within_a_station,
                        color: Color.fromARGB(255, 143, 4, 120)),
                    title: const Text('DNS & Routing Problems'),
                    onTap: () {
                      // Navigator.of(context).pop(); // Close the drawer
                      // _navigateToLocalMoneyTransferPage(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.transfer_within_a_station,
                        color: Color.fromARGB(255, 143, 4, 120)),
                    title: const Text('User & Device Specific Issues'),
                    onTap: () {
                      // Navigator.of(context).pop(); // Close the drawer
                      // _navigateToOtherBankTransferPage(context);
                    },
                  ),
                ListTile(
                    leading: const Icon(Icons.transfer_within_a_station,
                        color: Color.fromARGB(255, 143, 4, 120)),
                    title: const Text('Hardware & Infrastructure'),
                    onTap: () {
                      // Navigator.of(context).pop(); // Close the drawer
                      // _navigateToInternationalTransferPage(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.local_activity_outlined,
                        color: Color.fromARGB(255, 143, 4, 120)),
                    title: const Text('Network Performance Problems'),
                    onTap: () {
                      // Navigator.of(context).pop(); // Close the drawer
                      // _navigateToRecentTransactionsPage(context);
                    },
                  ),
                ],
              ),

               ExpansionTile(
                leading: const Icon(
                  Icons.payment,
                  color: Color.fromARGB(255, 143, 4, 120),
                ),
                title: const Text('Computer'), // Name the dropdown as 'MyBill'
                trailing: const Icon(
                  Icons.arrow_drop_down,
                  color: Color.fromARGB(255, 143, 4, 120),
                ),
                onExpansionChanged: (bool expanded) {
                  if (expanded) {
                  }
                },
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.transfer_within_a_station,
                        color: Color.fromARGB(255, 143, 4, 120)),
                    title: const Text('Computer & Peripheral Hardware'),
                    onTap: () {
                      // Navigator.of(context).pop(); // Close the drawer
                      // _navigateToAddRecipientPage(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.transfer_within_a_station,
                        color: Color.fromARGB(255, 143, 4, 120)),
                    title: const Text('User Login & Access'),
                    onTap: () {
                      // Navigator.of(context).pop(); // Close the drawer
                      // _navigateToManageBeneficiaryPage(context);
                    },
                  ),

                    ListTile(
                    leading: const Icon(Icons.transfer_within_a_station,
                        color: Color.fromARGB(255, 143, 4, 120)),
                    title: const Text('Operating System & Applications'),
                    onTap: () {
                      // Navigator.of(context).pop(); // Close the drawer
                      // _navigateToManageBeneficiaryPage(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.transfer_within_a_station,
                        color: Color.fromARGB(255, 143, 4, 120)),
                    title: const Text('Display & Drivers'),
                    onTap: () {
                      // Navigator.of(context).pop(); // Close the drawer
                      // _navigateToManageBeneficiaryPage(context);
                    },
                  ),

                ],
              ),

              ExpansionTile(
                leading: const Icon(
                  Icons.payment,
                  color: Color.fromARGB(255, 143, 4, 120),
                ),
                title: const Text('Software'), // Name the dropdown as 'MyBill'
                trailing: const Icon(
                  Icons.arrow_drop_down,
                  color: Color.fromARGB(255, 143, 4, 120),
                ),
                onExpansionChanged: (bool expanded) {
                  if (expanded) {
                  }
                },
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.payment,
                        color: Color.fromARGB(255, 143, 4, 120)),
                   title: const Text('Software Install & Licensing'),
                    onTap: () {
                      // Navigator.of(context).pop(); // Close the drawer
                      // _navigateToBillPaymentPage(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.payment,
                        color: Color.fromARGB(255, 143, 4, 120)),
                    title: const Text('Peripheral Software Issues'),
                    onTap: () {
                      // Navigator.of(context).pop(); // Close the drawer
                      // _navigateToTopUpPage(context);
                    },
                  ),    
                  // ListTile(
                  //   leading: const Icon(Icons.payment,
                  //       color: Color.fromARGB(255, 143, 4, 120)),
                  //   title: Text('AirLine'),
                  //   onTap: () {
                  //     Navigator.of(context).pop(); // Close the drawer
                  //     _navigateToAirLinePage(context);
                  //   },
                  // ),       
                ],
              ),
              ExpansionTile(
                leading: const Icon(
                  Icons.payment,
                  color: Color.fromARGB(255, 143, 4, 120),
                ),
                title: const Text('ATM'), // Name the dropdown as 'MyBill'
                trailing: const Icon(
                  Icons.arrow_drop_down,
                  color: Color.fromARGB(255, 143, 4, 120),
                ),
                onExpansionChanged: (bool expanded) {
                  if (expanded) {
// Handle any actions when the tile is expanded, if needed
                  }
                },
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.transfer_within_a_station,
                        color: Color.fromARGB(255, 143, 4,
                            120)), // Optional: use a different icon if you prefer
                    title: const Text('Display & Input Devices'),
                    onTap: () {
                      // Navigator.of(context).pop(); // Close the drawer
                      // _navigateToKachaPage(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.transfer_within_a_station,
                        color: Color.fromARGB(255, 143, 4,
                            120)), // Optional: use a different icon if you prefer
                    title: const Text('Cash Dispensing & Handling'),
                    onTap: () {
                      // Navigator.of(context).pop(); // Close the drawer
                      // _navigateToEbirrPage(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.transfer_within_a_station,
                        color: Color.fromARGB(255, 143, 4,
                            120)), // Optional: use a different icon if you prefer
                    title: const Text('System & Application'),
                    onTap: () {
                      // Navigator.of(context).pop(); // Close the drawer
                      // _navigateToCbeBirPage(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.transfer_within_a_station,
                        color: Color.fromARGB(255, 143, 4,
                            120)), // Optional: use a different icon if you prefer
                    title: const Text('Security & Network'),
                    onTap: () {
                      // Navigator.of(context).pop(); // Close the drawer
                      // _navigateToTellBirrPage(context);
                    },
                  ),
                ListTile(
                    leading: const Icon(Icons.transfer_within_a_station,
                        color: Color.fromARGB(255, 143, 4,
                            120)), // Optional: use a different icon if you prefer
                    title: const Text('Transaction & Service Errors'),
                    onTap: () {
                      // Navigator.of(context).pop(); // Close the drawer
                      // _navigateToTellBirrPage(context);
                    },
                  ),

                ],
              ),
              ListTile(
                leading: const Icon(Icons.currency_exchange,
                    color: Color.fromARGB(255, 143, 4, 120)),
                title: const Text('Printer'),
                onTap: () {
                  // Navigator.of(context).pop(); // Close the drawer
                  // _navigateToExchangeRatePage(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.payment,
                    color: Color.fromARGB(255, 143, 4, 120)),
                title: const Text('Access'),
                onTap: () {
                  // Navigator.of(context).pop(); // Close the drawer
                  // _navigateToSupportPage(context);
                },
              ),
              ExpansionTile(
                leading: const Icon(
                  Icons.settings,
                  color: Color.fromARGB(255, 143, 4, 120),
                ),
                title: Text(languageData[selectedLanguage]!['settingsText']!),
                trailing: const Icon(
                  Icons.arrow_drop_down,
                  color: Color.fromARGB(255, 143, 4, 120),
                ),
                onExpansionChanged: (bool expanded) {
                  if (expanded) {
// Handle any actions when the tile is expanded, if needed
                  }
                },
                children: <Widget>[
                  ListTile(
                    title: Text(
                        languageData[selectedLanguage]!['loginWithPinText']!),
                    onTap: () {
                      Navigator.of(context).pop(); // Close the drawer
                      _navigateToLoginWithPinPage(context);
                    },
                  ),
                  ListTile(
                    title: Text(languageData[selectedLanguage]![
                        'loginWithBiometricText']!),
                    onTap: () {
                      Navigator.of(context).pop(); // Close the drawer
                      _navigateToLoginWithBiometricPage(context);
                    },
                  ),
                ],
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app,
                    color: Color.fromARGB(255, 143, 4, 120)),
                title: Text(languageData[selectedLanguage]!['logoutText']!),
                onTap: () {
                  Navigator.of(context).pop(); // Close the drawer
                  _logout(context);
                },
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.only(right: 12.0, left: 6.0),
              child: globalState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Card(
  elevation: 3,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Container(
    height: 180,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(15),
      image: const DecorationImage(
        image: AssetImage('assets/images/card5.jpg'),
        fit: BoxFit.cover,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(26.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Text

        Text(
          '${languageData[selectedLanguage]!['welcomeText']} ',
          style: const TextStyle(
            fontSize: 18,
            color: Color.from(alpha: 0.992, red: 0.988, green: 0.086, blue: 0.988),
            fontWeight: FontWeight.bold,
          ),
        ),

          //Full Name
          Text(
            'Name: $accountname',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Role
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Role: $role',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            
            ],
          ),
          Text(
            'Address: $branchAddress',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Date
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${languageData[selectedLanguage]!['dateText']} : ',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                currentDate,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
),

            ),
            const Spacer(),
            Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    // WiFi or Network
    Column(
      children: [
        Container(
          padding: const EdgeInsets.all(0.0),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color.fromRGBO(86, 5, 236, 1),
              width: 2,
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.wifi,
                size: 30, color: Color.fromRGBO(5, 28, 238, 0.973)),
            onPressed: () {
              // _navigateToTransferModulePage(context);
            },
          ),
        ),
        const Text('Network'),
      ],
    ),

    // Computer
    Column(
      children: [
        Container(
          padding: const EdgeInsets.all(0.0),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color.fromRGBO(66, 4, 238, 1),
              width: 2,
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.computer,
                size: 30, color: Color.fromRGBO(40, 3, 247, 0.993)),
            onPressed: () {
              // _navigateToBillPaymentModulePage(context);
            },
          ),
        ),
        const Text('Computer'),
      ],
    ),

    // ATM
    Column(
      children: [
        Container(
          padding: const EdgeInsets.all(0.0),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color.fromRGBO(56, 4, 245, 1),
              width: 2,
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.atm,
                size: 30, color: Color.fromRGBO(66, 3, 240, 0.952)),
            onPressed: () {
              // _navigateToTopUpPage(context);
            },
          ),
        ),
        const Text('ATM'),
      ],
    ),
  ],
),

  const Spacer(),
  Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    // Printer
    Column(
      children: [
        Container(
          padding: const EdgeInsets.all(0.0),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color.fromRGBO(27, 3, 243, 1),
              width: 2,
            ),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.print,
              size: 30,
              color: Color.fromRGBO(27, 2, 247, 0.986),
            ),
            onPressed: () {
              // _navigateToHelpPage(context);
            },
          ),
        ),
        const Text('Printer'),
      ],
    ),

  Column(
  children: [
    Container(
      padding: const EdgeInsets.all(0.0),
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromRGBO(20, 3, 253, 1), // Better color format
          width: 2,
        ),
      ),
      child: IconButton(
        icon: const Icon(
          Icons.settings, // Changed icon to software-related
          size: 30,
          color: Color.fromRGBO(26, 1, 250, 1),
        ),
        onPressed: () {
          // _navigateToWalletTransferPage(context);
        },
      ),
    ),
    const Text('Software'),
  ],
),


    // Access
    Column(
      children: [
        Container(
          padding: const EdgeInsets.all(0.0),
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color.fromRGBO(26, 1, 250, 1),
              width: 2,
            ),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.lock_open,
              size: 30,
              color: Color.fromRGBO(26, 1, 250, 1),
            ),
            onPressed: () {
              // _navigateToGovernmentServicePage(context);
            },
          ),
        ),
        const Text('Access'),
      ],
    ),
  ],
),

            const Spacer(),
            CarouselSlider(
              options: CarouselOptions(
                height: 170.0,
                autoPlay: true,
                enlargeCenterPage: true,
                aspectRatio: 2.0,
                autoPlayCurve: Curves.fastOutSlowIn,
                enableInfiniteScroll: true,
                autoPlayAnimationDuration: const Duration(milliseconds: 1600),
                viewportFraction: 1.1,
              ),
              items: [
              'assets/images/network.jpg',
              'assets/images/printer.jpg',
              'assets/images/software.jpg',
              'assets/images/hardware.jpg',
              'assets/images/western.jpg',
              'assets/images/moneygram.jpg',
              'assets/images/hardware1.jpg',
              'assets/images/software1.jpg',
              'assets/images/network1.jpg',
              ].map((i) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: double.infinity,
                      height: 150,
                      margin: const EdgeInsets.symmetric(horizontal: 0.0),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 190, 9, 166),
                        border: Border.all(
                          color: const Color.fromARGB(255, 223, 226, 228),
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(i, fit: BoxFit.cover),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            Container(
              height: 50.0, // Adjust this value as needed to reduce the height
              color: const Color.fromARGB(255, 151, 16, 129),
              padding: const EdgeInsets.symmetric(vertical: 0.0),
              margin: EdgeInsets.zero, // Remove any margin
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.home,
                              size: 20,
                              color: Color.fromARGB(255, 255, 254, 254),
                            ), // Reduced size
                            tooltip: 'Home',
                            onPressed: () {
                              _refreshPage();
                            },
                          ),
                          const Positioned(
                            bottom:
                                4, // Adjust this value to position the text as needed
                            child: Text(
                              'Home',
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white), // Reduced font size
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.payment,
                              size: 20,
                              color: Color.fromARGB(255, 255, 254, 254),
                            ), // Reduced size
                            tooltip: 'Exchange',
                            onPressed: () {
                              _navigateToExchangeRatePage(context);
                            },
                          ),
                          const Positioned(
                            bottom:
                                4, // Adjust this value to position the text as needed
                            child: Text(
                              'Exchange',
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white), // Reduced font size
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.receipt,
                              size: 20,
                              color: Color.fromARGB(255, 255, 254, 254),
                            ), // Reduced size
                            tooltip: 'Issue Solution',
                            onPressed: () {
                              _navigateToRecentTransactionsPage(
                                  context); // Updated navigation
                            },
                          ),
                          const Positioned(
                            bottom:
                                4, // Adjust this value to position the text as needed
                            child: Text(
                              'Solution',
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white), // Reduced font size
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.event,
                              size: 20,
                              color: Color.fromARGB(255, 255, 254, 254),
                            ), // Reduced size
                            tooltip: 'Issue',
                            onPressed: () {
                              _navigateToMiniAppsPage(
                                  context); // Updated navigation
                            },
                          ),
                          const Positioned(
                            bottom:
                                4, // Adjust this value to position the text as needed
                            child: Text(
                              'Report Issue',
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white), // Reduced font size
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
