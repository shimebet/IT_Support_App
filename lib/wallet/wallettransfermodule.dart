import 'package:flutter/material.dart';
import 'cbebirr.dart';
import 'ebirr.dart';
import 'tellbirr.dart';
import 'kacha.dart';

class WalletTransferPage extends StatefulWidget {
  final String token;

  const WalletTransferPage({super.key, required this.token});

  @override
  _WalletTransferPageState createState() => _WalletTransferPageState();
}

class _WalletTransferPageState extends State<WalletTransferPage> {
 void _navigateToKachaPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => KachaPage(token: widget.token)),
    );
  }

  void _navigateToCbeBirPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => CbeBirPage(token: widget.token)),
    );
  }

  void _navigateToEbirrPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => EbirrPage(token: widget.token)),
    );
  }

  void _navigateToTellBirrPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => TellBirrPage(token: widget.token)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Wallet Transfer Type',
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
            leading: const Icon(Icons.send,
                color: Color.fromARGB(255, 143, 4, 120)),
            title: const Text('Transfer To Kach'),
            onTap: () {
              Navigator.of(context).pop(); // Close the drawer
              _navigateToKachaPage(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment,
                color: Color.fromARGB(255, 143, 4, 120)),
            title: const Text('Transfer To CBE Birr'),
            onTap: () {
              Navigator.of(context).pop(); // Close the drawer
              _navigateToCbeBirPage(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.money_off_outlined,
                color: Color.fromARGB(255, 143, 4, 120)),
            title: const Text('Transfer To E_Birr'),
            onTap: () {
              Navigator.of(context).pop(); // Close the drawer
              _navigateToEbirrPage(context);
            },
          ),
                ListTile(
            leading: const Icon(Icons.phone_android_outlined,
                color: Color.fromARGB(255, 143, 4, 120)),
            title: const Text('Transfer To TellBirr'),
            onTap: () {
              Navigator.of(context).pop(); // Close the drawer
              _navigateToTellBirrPage(context);
            },
          ),
        ],
      ),
    );
  }
}
