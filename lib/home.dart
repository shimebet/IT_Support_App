import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';
import 'footer/it_support_solution.dart';
import 'footer/issue_report_page.dart';
import 'body/exchangerate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../global_state.dart';
import 'AdminHomePage.dart';
import 'UpdateProfilePage.dart';


class HomePage extends StatefulWidget {
  final String token;
  final String username; // Add this
 final String userId;
  final String userImageUrl;
   const HomePage({
    super.key,
    required this.token,
    required this.username, 
    required this.userId,
    required this.userImageUrl,
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
  void _navigateToExchangeRatePage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => ExchangeRatePage(token: widget.token)),
    );
  }
  void _navigateToMiniAppsPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => IssueReportPage(token: widget.token)),
    );
  }

void _navigateToUpdateProfilePage(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => UpdateProfilePage(
        userId: widget.userId,
        currentUsername: widget.username,
        currentImageUrl: widget.userImageUrl,
        token: widget.token,
      ),
    ),
  );
}

    void _navigateToAdminPage(BuildContext context) {
    if (role == 'Admin') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => AdminHomePage(token: widget.token)),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Access Denied"),
          content: const Text("You are not an Admin, so you can't access this page."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
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
              leading: const Icon(Icons.admin_panel_settings, color: Color.fromARGB(255, 143, 4, 120)),
              title: const Text('Admin Dashboard'),
              onTap: () {
                Navigator.of(context).pop();
                _navigateToAdminPage(context);
              },
            ),
          ListTile(
            leading: const Icon(Icons.person, color: Color.fromARGB(255, 143, 4, 120)),
            title: const Text('Edit Profile'),
            onTap: () {
              Navigator.of(context).pop(); // Close the drawer
              _navigateToUpdateProfilePage(context);
            },
          ),


              ListTile(
                leading: const Icon(Icons.logout,
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
