import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminHomePage extends StatefulWidget {
  final String token;

  const AdminHomePage({Key? key, required this.token}) : super(key: key);

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  List<dynamic> users = [];
  List<dynamic> issues = [];
  List<dynamic> filteredUsers = [];
  List<dynamic> filteredIssues = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    setState(() => isLoading = true);
    try {
      final userRes = await http.get(
        Uri.parse('https://node-api-g7fs.onrender.com/api/users'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      final issueRes = await http.get(
        Uri.parse('https://node-api-g7fs.onrender.com/api/support'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );

      if (userRes.statusCode == 200 && issueRes.statusCode == 200) {
        final decodedUserData = json.decode(userRes.body);
        final decodedIssueData = json.decode(issueRes.body);

        setState(() {
          users = decodedUserData is List ? decodedUserData : decodedUserData['users'] ?? [];
          issues = decodedIssueData is List ? decodedIssueData : decodedIssueData['issues'] ?? [];
          filteredUsers = users;
          filteredIssues = issues;
        });
      } else {
        throw Exception("Failed to load data: users(${userRes.statusCode}), issues(${issueRes.statusCode})");
      }
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void filterUsers(String query) {
    setState(() {
      filteredUsers = users.where((user) {
        final firstName = user['firstName']?.toLowerCase() ?? '';
        final username = user['username']?.toLowerCase() ?? '';
        return firstName.contains(query.toLowerCase()) || username.contains(query.toLowerCase());
      }).toList();
    });
  }

  void filterIssues(String query) {
    setState(() {
      filteredIssues = issues.where((issue) {
        final title = issue['issueTitle']?.toLowerCase() ?? '';
        final desc = issue['issueDescription']?.toLowerCase() ?? '';
        return title.contains(query.toLowerCase()) || desc.contains(query.toLowerCase());
      }).toList();
    });
  }

  String shorten(String text, [int maxLen = 10]) {
    if (text.isEmpty) return '';
    return text.length <= maxLen ? text : '${text.substring(0, maxLen)}...';
  }

  void showEditUserDialog(Map user) {
    final firstNameCtrl = TextEditingController(text: user['firstName']);
    final lastNameCtrl = TextEditingController(text: user['lastName']);
    final emailCtrl = TextEditingController(text: user['email']);
    final roleCtrl = TextEditingController(text: user['role']);
    final branchCtrl = TextEditingController(text: user['branchName']);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Edit User"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: firstNameCtrl, decoration: const InputDecoration(labelText: "First Name")),
              TextField(controller: lastNameCtrl, decoration: const InputDecoration(labelText: "Last Name")),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: "Email")),
              DropdownButtonFormField<String>(
                value: roleCtrl.text,
                onChanged: (value) => setState(() => roleCtrl.text = value ?? ''),
                items: ['Admin', 'IT_Team', 'Branch_Manager', 'Branch_Staff']
                    .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                    .toList(),
                decoration: const InputDecoration(labelText: "Role"),
              ),
              TextField(controller: branchCtrl, decoration: const InputDecoration(labelText: "Branch Name")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              showLoadingDialog("Updating user...");
              final res = await http.put(
                Uri.parse('https://node-api-g7fs.onrender.com/api/users/${user['_id']}'),
                headers: {
                  'Authorization': 'Bearer ${widget.token}',
                  'Content-Type': 'application/json',
                },
                body: json.encode({
                  'firstName': firstNameCtrl.text,
                  'lastName': lastNameCtrl.text,
                  'email': emailCtrl.text,
                  'role': roleCtrl.text,
                  'branchName': branchCtrl.text,
                }),
              );
              Navigator.pop(context);
              Navigator.pop(context);
              if (res.statusCode == 200) {
                fetchAllData();
                showSuccessDialog("User updated successfully.");
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void showEditIssueDialog(Map issue) {
    final titleCtrl = TextEditingController(text: issue['issueTitle']);
    final descCtrl = TextEditingController(text: issue['issueDescription']);
    final solutionCtrl = TextEditingController(text: issue['issueSolution']);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Edit Issue"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Title")),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: "Description")),
            TextField(controller: solutionCtrl, decoration: const InputDecoration(labelText: "Solution")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              showLoadingDialog("Updating issue...");
              final res = await http.put(
                Uri.parse('https://node-api-g7fs.onrender.com/api/support/${issue['_id']}'),
                headers: {
                  'Authorization': 'Bearer ${widget.token}',
                  'Content-Type': 'application/json',
                },
                body: json.encode({
                  'issueTitle': titleCtrl.text,
                  'issueDescription': descCtrl.text,
                  'issueSolution': solutionCtrl.text,
                }),
              );
              Navigator.pop(context);
              Navigator.pop(context);
              if (res.statusCode == 200) {
                fetchAllData();
                showSuccessDialog("Issue updated successfully.");
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void showUnmaskedDetailDialog(Map issue) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(issue['issueTitle'] ?? 'No Title'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("📄 Description:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(issue['issueDescription'] ?? 'No description.'),
              const SizedBox(height: 12),
              const Text("✅ Solution:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(issue['issueSolution'] ?? 'No solution yet.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void confirmDelete(String id, bool isUser) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: Text("Are you sure you want to delete this ${isUser ? "user" : "issue report"}?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("No")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              showLoadingDialog("Deleting...");
              final res = await http.delete(
                Uri.parse('https://node-api-g7fs.onrender.com/api/${isUser ? "users" : "support"}/$id'),
                headers: {'Authorization': 'Bearer ${widget.token}'},
              );
              Navigator.pop(context);
              if (res.statusCode == 200) {
                fetchAllData();
                showSuccessDialog("${isUser ? "User" : "Issue"} deleted successfully.");
              }
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }

  void showLoadingDialog(String message) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Success"),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("👥 Users", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(labelText: "Search by first name or username"),
                    onChanged: filterUsers,
                  ),
                  const SizedBox(height: 10),
                  ...filteredUsers.map((user) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text("${user['firstName']} ${user['lastName']}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Username: ${user['username']}"),
                            Text("Email: ${user['email']}"),
                            Text("Role: ${user['role']}"),
                            Text("Branch: ${user['branchName']}"),
                          ],
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.green),
                              onPressed: () => showEditUserDialog(user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => confirmDelete(user['_id'], true),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),
                  const Divider(thickness: 2),
                  const SizedBox(height: 10),
                  const Text("📝 Issue Reports", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(labelText: "Search by title or description"),
                    onChanged: filterIssues,
                  ),
                  const SizedBox(height: 10),
                  ...filteredIssues.map((issue) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text(issue['issueTitle'] ?? 'No Title'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Description: ${shorten(issue['issueDescription'] ?? '')}"),
                            Text("Solution: ${shorten(issue['issueSolution'] ?? '')}"),
                          ],
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility, color: Colors.blue),
                              onPressed: () => showUnmaskedDetailDialog(issue),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.green),
                              onPressed: () => showEditIssueDialog(issue),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => confirmDelete(issue['_id'], false),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
