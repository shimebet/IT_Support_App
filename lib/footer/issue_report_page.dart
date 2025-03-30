import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class IssueReportPage extends StatefulWidget {
  final String token;

  const IssueReportPage({super.key, required this.token});

  @override
  _IssueReportPageState createState() => _IssueReportPageState();
}
 bool _txtFileUploaded = false;
bool _imageUploaded = false;

class _IssueReportPageState extends State<IssueReportPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _issueDescriptionController = TextEditingController();
  final TextEditingController _issueSolutionController = TextEditingController();

  String _selectedIssueTitle = 'Computer Issues';
  File? _selectedImage;
  String? _base64Image;

  final List<String> _issueCategories = [
    'Computer Issues',
    'Printer Issues',
    'Software Issues',
    'Network Issues',
    'Other',
  ];

  final ImagePicker _picker = ImagePicker();

  Map<String, String> _buildHeaders() {
    return {
      'Authorization': 'Bearer ${widget.token}',
      'Content-Type': 'application/json',
    };
  }

Future<void> _pickImage() async {
  if (_imageUploaded) {
    setState(() {
      _selectedImage = null;
      _base64Image = null;
      _imageUploaded = false;
    });
    return;
  }

  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
  if (image != null) {
    final compressedBytes = await FlutterImageCompress.compressWithFile(
      image.path,
      quality: 40,
    );

    if (compressedBytes != null) {
      setState(() {
        _selectedImage = File(image.path);
        _base64Image = base64Encode(compressedBytes);
        _imageUploaded = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image compression failed.')),
      );
    }
  }
}


Future<void> _pickTxtFile() async {
  if (_txtFileUploaded) {
    setState(() {
      _txtFileUploaded = false;
      _issueSolutionController.clear();
    });
    return;
  }

  const typeGroup = XTypeGroup(label: 'Text Files', extensions: ['txt']);
  final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

  if (file != null) {
    final content = await file.readAsString();
    setState(() {
      _issueSolutionController.text = content;
      _txtFileUploaded = true;
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No file selected.')),
    );
  }
}


  Future<void> _showConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Submission'),
        content: const Text('Are you sure you want to submit this issue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _submitIssue();
    }
  }

  Future<void> _showSuccessDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Issue submitted successfully.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    Navigator.of(context).pop(); // Back to home
  }

  Future<void> _submitIssue() async {
    final url = Uri.parse('https://node-api-g7fs.onrender.com/api/support');
    final headers = _buildHeaders();

    final body = jsonEncode({
      "firstName": _firstNameController.text.trim(),
      "lastName": _lastNameController.text.trim(),
      "issueTitle": _selectedIssueTitle,
      "issueDescription": _issueDescriptionController.text.trim(),
      "issueSolution": _issueSolutionController.text.trim(),
      "issueImage": _base64Image ?? "",
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        _formKey.currentState?.reset();
        setState(() {
          _selectedImage = null;
          _base64Image = null;
        });
        await _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error submitting issue.')),
      );
    }
  }

  void _onSubmitPressed() {
    if (_formKey.currentState!.validate()) {
      _showConfirmationDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Issue'),
        backgroundColor: const Color.fromARGB(255, 134, 23, 116),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) => value!.isEmpty ? 'Enter first name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) => value!.isEmpty ? 'Enter last name' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedIssueTitle,
                decoration: const InputDecoration(labelText: 'Issue Title'),
                items: _issueCategories
                    .map((issue) => DropdownMenuItem(value: issue, child: Text(issue)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedIssueTitle = value!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _issueDescriptionController,
                decoration: const InputDecoration(labelText: 'Issue Description'),
                maxLines: 4,
                validator: (value) => value!.isEmpty ? 'Describe the issue' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _issueSolutionController,
                decoration: const InputDecoration(labelText: 'Suggested Solution'),
                maxLines: 3,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _pickTxtFile,
                  icon: Icon(_txtFileUploaded ? Icons.delete : Icons.upload_file),
                  label: Text(_txtFileUploaded ? 'Remove File' : 'Upload .txt File'),
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(_imageUploaded ? Icons.delete : Icons.image),
                    label: Text(_imageUploaded ? 'Remove Image' : 'Upload Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 134, 23, 116),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _imageUploaded ? "Image Selected" : "No image selected",
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),

              if (_selectedImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Image.file(_selectedImage!, height: 150),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _onSubmitPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 134, 23, 116),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Submit Issue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
