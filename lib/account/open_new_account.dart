import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class OpenNewAccountPage extends StatefulWidget {
  const OpenNewAccountPage({super.key});

  @override
  _OpenNewAccountPageState createState() => _OpenNewAccountPageState();
}

class _OpenNewAccountPageState extends State<OpenNewAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController roleController = TextEditingController(text: 'admin');
  final TextEditingController branchNameController = TextEditingController();
  final TextEditingController branchGradeController = TextEditingController();
  final TextEditingController branchIdController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  File? _image;
  File? _nationalIdImage;
  String? _base64Image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage({required bool isNationalId}) async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final compressedBytes = await FlutterImageCompress.compressWithFile(
        pickedFile.path,
        quality: 40, // Compress to reduce size
      );

      if (compressedBytes != null) {
        setState(() {
          if (isNationalId) {
            _nationalIdImage = File(pickedFile.path);
          } else {
            _image = File(pickedFile.path);
            _base64Image = 'data:image/jpeg;base64,${base64Encode(compressedBytes)}';
          }
        });
      }
    }
  }

 Future<void> _submitRegistration() async {
  final uri = Uri.parse('https://node-api-g7fs.onrender.com/api/users/register');

  final Map<String, dynamic> body = {
    "firstName": firstNameController.text.trim(),
    "lastName": lastNameController.text.trim(),
    "userName": usernameController.text.trim(),
    "email": emailController.text.trim(),
    "password": passwordController.text.trim(),
    "role": roleController.text.trim(),
    "branchName": branchNameController.text.trim(),
    "branchAddress": addressController.text.trim(),
    "branchGrade": branchGradeController.text.trim(),
    "branchId": branchIdController.text.trim(),
    "userImage": _base64Image ?? "",
  };

  try {
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Success'),
          content: Text('Registered successfully! Welcome ${data['firstName']}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pushReplacementNamed('/'); 
              },
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    } else {
      try {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${error['message']}')),
        );
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unexpected error occurred.')),
        );
      }
    }
  } catch (e) {
    print('Registration Error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error occurred during registration')),
    );
  }
}



  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required String labelText,
    TextInputType? keyboardType,
    bool obscureText = false,
    FormFieldValidator<String>? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: validator,
        decoration: InputDecoration(
          hintText: hintText,
          labelText: labelText,
          hintStyle: const TextStyle(fontSize: 14),
          labelStyle: const TextStyle(fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.deepPurple),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection({
    required String label,
    required File? imageFile,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: imageFile == null
                  ? const Center(child: Text('Tap to upload image'))
                  : Image.file(imageFile, fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Open New Account')),
      body: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Card(
              elevation: 20,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildTextField(
                      controller: firstNameController,
                      hintText: 'Enter First Name',
                      labelText: 'First Name',
                      validator: (value) => value!.isEmpty ? 'Enter first name' : null,
                    ),
                    _buildTextField(
                      controller: lastNameController,
                      hintText: 'Enter Last Name',
                      labelText: 'Last Name',
                      validator: (value) => value!.isEmpty ? 'Enter last name' : null,
                    ),
                    _buildTextField(
                      controller: usernameController,
                      hintText: 'Enter Username',
                      labelText: 'Username',
                      validator: (value) => value!.isEmpty ? 'Enter username' : null,
                    ),
                    _buildTextField(
                      controller: emailController,
                      hintText: 'Enter Email',
                      labelText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value!.isEmpty) return 'Enter email';
                        if (!RegExp(r'^[\w-]+@([\w-]+\.)+[a-zA-Z]{2,7}$').hasMatch(value)) {
                          return 'Invalid email';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: phoneController,
                      hintText: 'Enter Phone Number',
                      labelText: 'Phone Number',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value!.isEmpty) return 'Enter phone number';
                        if (!RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(value)) {
                          return 'Invalid phone number';
                        }
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: addressController,
                      hintText: 'Enter Address',
                      labelText: 'Address',
                      validator: (value) => value!.isEmpty ? 'Enter address' : null,
                    ),
                    _buildTextField(
                      controller: roleController,
                      hintText: 'Enter Role (e.g., admin)',
                      labelText: 'Role',
                      validator: (value) => value!.isEmpty ? 'Enter role' : null,
                    ),
                    _buildTextField(
                      controller: branchNameController,
                      hintText: 'Enter Branch Name',
                      labelText: 'Branch Name',
                      validator: (value) => null,
                    ),
                    _buildTextField(
                      controller: branchGradeController,
                      hintText: 'Enter Branch Grade (e.g., A, B)',
                      labelText: 'Branch Grade',
                      validator: (value) => null,
                    ),
                    _buildTextField(
                      controller: branchIdController,
                      hintText: 'Enter Branch ID (e.g., BR001)',
                      labelText: 'Branch ID',
                      validator: (value) => null,
                    ),

                    _buildImageSection(
                      label: 'CBE ID Image',
                      imageFile: _nationalIdImage,
                      onTap: () => _pickImage(isNationalId: true),
                    ),
                    _buildTextField(
                      controller: passwordController,
                      hintText: 'Enter Password',
                      labelText: 'Password',
                      obscureText: true,
                      validator: (value) {
                        if (value!.isEmpty) return 'Enter password';
                        if (value.length < 6) return 'Min 6 characters';
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: confirmPasswordController,
                      hintText: 'Confirm Password',
                      labelText: 'Confirm Password',
                      obscureText: true,
                      validator: (value) {
                        if (value!.isEmpty) return 'Confirm password';
                        if (value != passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Column(
                        children: [
                          _image == null
                              ? GestureDetector(
                                  onTap: () => _pickImage(isNationalId: false),
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color.fromARGB(255, 78, 55, 55),
                                    ),
                                    child: Icon(Icons.add_a_photo, color: Colors.grey[700]),
                                  ),
                                )
                              : Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: FileImage(_image!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (_image == null)
                                ElevatedButton(
                                  onPressed: () => _pickImage(isNationalId: false),
                                  child: const Text('Upload Profile'),
                                ),
                              ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState?.validate() ?? false) {
                                    if (_image == null || _nationalIdImage == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please upload both profile and National ID images'),
                                        ),
                                      );
                                    } else {
                                      _submitRegistration();
                                    }
                                  }
                                },
                                child: const Text('Register'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
