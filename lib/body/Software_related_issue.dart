import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SoftwareRelatedIssuePage extends StatefulWidget {
  final String token;

  const SoftwareRelatedIssuePage({super.key, required this.token});

  @override
  State<SoftwareRelatedIssuePage> createState() => _SoftwareRelatedIssuePageState();
}

class _SoftwareRelatedIssuePageState extends State<SoftwareRelatedIssuePage> {
  List<Map<String, dynamic>> _filteredIssues = [];
  bool _isLoading = true;

  final List<String> _softwareKeywords = [
    'zoom',
    'westernunion',
    'western',
    'union',
    'java',
    'boleatlantic',
    'bole',
    'atlantic',
    'moneygram',
    'swift',
    'finacle',
    'temenos',
    'corebanking',
    'microsoft',
    'excel',
    'word',
    'outlook',
    'windows',
    'antivirus',
    'update',
    'installation',
    'softwareissue',
  ];

  @override
  void initState() {
    super.initState();
    _fetchFilteredIssues();
  }

  bool _titleContainsSoftwareKeyword(String title) {
    final lowerTitleNoSpaces = title.toLowerCase().replaceAll(' ', '');
    return _softwareKeywords.any((keyword) => lowerTitleNoSpaces.contains(keyword));
  }

  Future<void> _fetchFilteredIssues() async {
    final url = Uri.parse('https://node-api-g7fs.onrender.com/api/support');
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> issues = jsonDecode(response.body);

        final List<Map<String, dynamic>> softwareIssues = issues
            .where((issue) {
              final title = issue['issueTitle']?.toString() ?? '';
              return _titleContainsSoftwareKeyword(title);
            })
            .cast<Map<String, dynamic>>()
            .toList();

        setState(() {
          _filteredIssues = softwareIssues;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load issues');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch issues')),
      );
    }
  }

  Widget _buildIssueCard(Map<String, dynamic> issue) {
    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              issue['issueTitle'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text("Description: ${issue['issueDescription'] ?? ''}"),
            const SizedBox(height: 8),
            if ((issue['issueSolution'] ?? '').isNotEmpty)
              Text("Solution: ${issue['issueSolution']}"),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Software Related Issues'),
        backgroundColor: Colors.indigo,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredIssues.isEmpty
              ? const Center(child: Text('No software-related issues found.'))
              : ListView.builder(
                  itemCount: _filteredIssues.length,
                  itemBuilder: (context, index) {
                    return _buildIssueCard(_filteredIssues[index]);
                  },
                ),
    );
  }
}
