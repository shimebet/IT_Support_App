import 'package:flutter/material.dart';
import 'airline.dart';
import 'billpayment.dart';
import 'topup.dart';

class BillPaymentModulePage extends StatefulWidget {
  final String token;

  const BillPaymentModulePage({super.key, required this.token});

  @override
  _BillPaymentModulePageState createState() => _BillPaymentModulePageState();
}

class _BillPaymentModulePageState extends State<BillPaymentModulePage> {

  void _navigateToBillPaymentPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => BillPaymentPage(token: widget.token)),
    );
  }
  void _navigateToTopUpPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => TopUpPage(token: widget.token)),
    );
  }
  void _navigateToAirLinePage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => AirLinePage(token: widget.token)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Bill Payment Type',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 26.0,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 134, 23, 116),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.payment,
                color: Color.fromARGB(255, 143, 4, 120)),
            title: const Text('CBE Bill Payment'),
            onTap: () {
              Navigator.of(context).pop(); // Close the drawer
              _navigateToBillPaymentPage(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment,
                color: Color.fromARGB(255, 143, 4, 120)),
            title: const Text('AirLine'),
            onTap: () {
              Navigator.of(context).pop(); // Close the drawer
              _navigateToAirLinePage(context);
            },
          ),
            ListTile(
            leading: const Icon(Icons.payment,
                color: Color.fromARGB(255, 143, 4, 120)),
            title: const Text('TopUp'),
            onTap: () {
              Navigator.of(context).pop(); // Close the drawer
              _navigateToTopUpPage(context);
            },
          ),
        ],
      ),
    );
  }
}
