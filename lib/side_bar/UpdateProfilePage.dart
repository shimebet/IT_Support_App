import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class UpdateProfilePage extends StatefulWidget {
  String userId;
  String currentUsername;
  String currentImageUrl;
  String token;

  UpdateProfilePage({
    super.key,
    required this.userId,
    required this.currentUsername,
    required this.currentImageUrl,
    required this.token,
  });

  @override
  State<UpdateProfilePage> createState() => _UpdateProfilePageState();
}

class _UpdateProfilePageState extends State<UpdateProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  File? _image;
  String? _base64Image;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    usernameController.text = widget.currentUsername;
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        pickedFile.path,
        quality: 40,
      );
      if (compressedBytes != null) {
        setState(() {
          _image = File(pickedFile.path);
          _base64Image =
              'data:image/jpeg;base64,${base64Encode(compressedBytes)}';
        });
      }
    }
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final uri = Uri.parse(
      'https://node-api-g7fs.onrender.com/api/users/${widget.userId}',
    );
    final Map<String, dynamic> body = {
      if (usernameController.text.isNotEmpty)
        "username": usernameController.text.trim(),
      if (passwordController.text.isNotEmpty)
        "password": passwordController.text.trim(),
      if (_base64Image != null) "userImage": _base64Image!,
    };

    try {
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(body),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final updatedData = jsonDecode(response.body);

        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (_) => AlertDialog(
                title: const Text('Success'),
                content: const Text('Profile updated successfully!'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog

                      setState(() {
                        usernameController.text =
                            updatedData['username'] ?? usernameController.text;

                        if (updatedData['userImage'] != null) {
                          _image = null;
                          _base64Image = null;
                          if (updatedData['userImage'] != null) {
                            _image = null;
                            _base64Image = null;

                            // ✅ If the returned path is relative, prefix it with the domain
                            final imagePath = updatedData['userImage'];
                            widget.currentImageUrl =
                                imagePath.startsWith('http')
                                    ? imagePath
                                    : 'https://node-api-g7fs.onrender.com/$imagePath';
                          }
                        }
                      });
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: ${error['message']}')));
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      const Text(
                        'Profile Image',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey[200],
                          backgroundImage:
                              _image != null
                                  ? FileImage(_image!)
                                  : (widget.currentImageUrl.isNotEmpty &&
                                      (widget.currentImageUrl.startsWith(
                                            'http',
                                          ) ||
                                          widget.currentImageUrl.startsWith(
                                            'https',
                                          )))
                                  ? NetworkImage(widget.currentImageUrl)
                                  : null,
                          child:
                              (_image == null &&
                                      (widget.currentImageUrl.isEmpty ||
                                          !widget.currentImageUrl.startsWith(
                                            'http',
                                          )))
                                  ? const Icon(
                                    Icons.camera_alt,
                                    size: 30,
                                    color: Colors.grey,
                                  )
                                  : null,
                        ),
                      ),

                      const SizedBox(height: 16),
                      TextFormField(
                        controller: usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Enter username'
                                    : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'New Password',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              value.length < 6) {
                            return 'Min 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submitUpdate,
                        child: const Text('Update'),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
