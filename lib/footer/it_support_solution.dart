import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';

class SupportIssuesPage extends StatefulWidget {
  final String token;
  final String username;

  const SupportIssuesPage({
    super.key,
    required this.token,
    required this.username,
  });

  @override
  _SupportIssuesPageState createState() => _SupportIssuesPageState();
}

class _SupportIssuesPageState extends State<SupportIssuesPage> {
  List<dynamic> issues = [];
  bool isLoading = true;
  String selectedFilter = 'All';

  final List<String> issueCategories = [
    'All',
    'Computer Issues',
    'Printer Issues',
    'Software Issues',
    'Network Issues',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    fetchSupportIssues();
  }

  Map<String, String> _buildHeaders() {
    return {
      'Authorization': 'Bearer ${widget.token}',
      'Content-Type': 'application/json',
    };
  }
void showLoadingDialog() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Please wait...'),
        ],
      ),
    ),
  );
}

  Future<void> fetchSupportIssues() async {
    final url = Uri.parse('https://node-api-g7fs.onrender.com/api/support');
    final headers = _buildHeaders();

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        setState(() {
          issues = responseData;
          isLoading = false;
        });
      } else {
        print('Failed to load issues: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error fetching issues: $e');
      setState(() => isLoading = false);
    }
  }

 Future<void> deleteIssue(String issueId) async {
  showLoadingDialog(); // 👈 show spinner

  final url = Uri.parse('https://node-api-g7fs.onrender.com/api/support/$issueId');
  final response = await http.delete(url, headers: _buildHeaders());

  Navigator.pop(context); // 👈 close loading spinner

  if (response.statusCode == 200) {
    fetchSupportIssues();

    // ✅ Success dialog
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Deleted'),
        content: const Text('Issue deleted successfully!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to delete: ${response.statusCode}')),
    );
  }
}



  void showUpdateDialog(Map<String, dynamic> issue) {
  final titleController = TextEditingController(text: issue['issueTitle']);
  final descController = TextEditingController(text: issue['issueDescription']);
  final solutionController = TextEditingController(text: issue['issueSolution']);
  final issueId = issue['_id'];

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Update Issue'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
            TextField(controller: solutionController, decoration: const InputDecoration(labelText: 'Solution')),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
         onPressed: () async {
  showLoadingDialog(); // 👈 show spinner

  final url = Uri.parse('https://node-api-g7fs.onrender.com/api/support/$issueId');
  final updatedData = {
    'issueTitle': titleController.text,
    'issueDescription': descController.text,
    'issueSolution': solutionController.text,
  };

  final response = await http.put(
    url,
    headers: _buildHeaders(),
    body: jsonEncode(updatedData),
  );

  Navigator.pop(context); // 👈 close loading dialog

  if (response.statusCode == 200) {
    Navigator.pop(context); // close update form
    fetchSupportIssues();

    // ✅ Success dialog
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Issue updated successfully!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to update: ${response.statusCode}')),
    );
  }
},

          child: const Text('Update'),
        ),
      ],
    ),
  );
}


  List<dynamic> getFilteredIssues() {
    if (selectedFilter == 'All') return issues;

    return issues.where((issue) {
      final title = issue['issueTitle']?.toString().toLowerCase().trim();
      final filter = selectedFilter.toLowerCase().trim();
      return title == filter;
    }).toList();
  }

  Widget _buildImageFromBase64(String base64String) {
    try {
      Uint8List imageBytes = base64Decode(base64String);
      return Image.memory(
        imageBytes,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    } catch (e) {
      return const Column(
        children: [
          Icon(Icons.broken_image, size: 40),
          Text('Invalid image format'),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredIssues = getFilteredIssues();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Support Issues Page',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 26.0,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 134, 23, 116),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: selectedFilter,
              onChanged: (newValue) {
                setState(() {
                  selectedFilter = newValue!;
                });
              },
              items: issueCategories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              decoration: const InputDecoration(
                labelText: 'Filter by Issue Title',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredIssues.isEmpty
                    ? const Center(child: Text('No support issues found.'))
                    : ListView.builder(
                        itemCount: filteredIssues.length,
                        itemBuilder: (context, index) {
                          final issue = filteredIssues[index];
                          final fullName = '${issue['firstName']} ${issue['lastName']}';
                          final imageData = issue['issueImage'];

                          final issueCreatorUsername = (issue['user']?['username'] ?? '').toString().trim().toLowerCase();
                          final currentUser = widget.username.trim().toLowerCase();
                          final isOwner = issueCreatorUsername == currentUser;
                          // Debug print
                          // print('Logged-in username: $currentUser');
                          // print('Issue creator username: $issueCreator');

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ExpansionTile(
                              title: Text(
                                issue['issueTitle'] ?? 'No Title',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('Reported by: $fullName'),
                              children: [
                                if (imageData != null && imageData.toString().trim().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Attached Image:',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 8),
                                        _buildImageFromBase64(imageData),
                                      ],
                                    ),
                                  ),
                                ListTile(
                                  title: Text('Description:\n${issue['issueDescription'] ?? 'N/A'}'),
                                ),
                                ListTile(
                                  title: Text('Solution:\n${issue['issueSolution'] ?? 'N/A'}'),
                                ),
                                ListTile(
                                  title: Text('Reported At: ${issue['createdAt'] ?? 'N/A'}'),
                                ),
                                if (isOwner)
                                  OverflowBar(
                                    alignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () => showUpdateDialog(issue),
                                        child: const Text('Edit'),
                                      ),
                                      TextButton(
                                        onPressed: () => deleteIssue(issue['_id']),
                                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
