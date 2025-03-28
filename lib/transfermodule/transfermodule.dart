import 'package:flutter/material.dart';
import 'transfer_to_other_bank_page.dart';
import 'international_transfer_page.dart';
import 'transfer.dart';
import 'scheduletransfer.dart';
import '../beneficiary/transfer_to_beneficiary.dart';

class TransferModulePage extends StatefulWidget {
  final String token;
  const TransferModulePage({super.key, required this.token});

  @override
  _TransferModulePageState createState() => _TransferModulePageState();
}

class _TransferModulePageState extends State<TransferModulePage> {
  void _navigateToTransferPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => TransferPage(token: widget.token)),
    );
  }

  void _navigateToTransferToBeneficiaryPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => TransferToBeneficiaryPage(token: widget.token)),
    );
  }

  void _navigateToScheduleTransferPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => ScheduleTransferPage(token: widget.token)),
    );
  }

  void _navigateToTransferModulePage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => TransferModulePage(token: widget.token)),
    );
  }

  void _navigateToOtherBankTransferPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => OtherBankTransferPage(token: widget.token)),
    );
  }

  void _navigateToInternationalTransferPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => InternationalTransferPage(token: widget.token)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Issue Type',
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
            leading: const Icon(Icons.transfer_within_a_station,
                color: Color.fromARGB(255, 143, 4, 120)),
            title: const Text('Connectivity Issues'),
            onTap: () {
              Navigator.of(context).pop(); // Close the drawer
              _navigateToTransferPage(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.transfer_within_a_station,
                color: Color.fromARGB(255, 143, 4, 120)),
            title: const Text('LAN & VLAN Issues'),
            onTap: () {
              Navigator.of(context).pop(); // Close the drawer
              _navigateToTransferToBeneficiaryPage(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.transfer_within_a_station,
                color: Color.fromARGB(255, 143, 4, 120)),
            title: const Text('Firewall & Security Issues'),
            onTap: () {
              Navigator.of(context).pop(); // Close the drawer
              _navigateToScheduleTransferPage(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.transfer_within_a_station,
                color: Color.fromARGB(255, 143, 4, 120)),
            title: const Text('DNS & Routing Problems'),
            onTap: () {
              Navigator.of(context).pop(); // Close the drawer
              _navigateToOtherBankTransferPage(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.transfer_within_a_station,
                color: Color.fromARGB(255, 143, 4, 120)),
            title: const Text('User & Device Specific Issues'),
            onTap: () {
              Navigator.of(context).pop(); // Close the drawer
              _navigateToInternationalTransferPage(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.transfer_within_a_station,
                color: Color.fromARGB(255, 143, 4, 120)),
            title: const Text('Hardware & Infrastructure'),
            onTap: () {
              Navigator.of(context).pop(); // Close the drawer
              _navigateToInternationalTransferPage(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.transfer_within_a_station,
                color: Color.fromARGB(255, 143, 4, 120)),
            title: const Text('Network Performance Problems'),
            onTap: () {
              Navigator.of(context).pop(); // Close the drawer
              _navigateToInternationalTransferPage(context);
            },
          ),

        ],
      ),
    );
  }
}
