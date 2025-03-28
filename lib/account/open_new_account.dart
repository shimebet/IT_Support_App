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
  String? _selectedRole = 'Admin'; // or null if you want it unselected initially
  final TextEditingController roleController = TextEditingController(text: 'Admin');
  final TextEditingController branchNameController = TextEditingController();
  final TextEditingController branchGradeController = TextEditingController();
  final TextEditingController branchIdController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
// STATE VARIABLES
File? _image;
File? _nationalIdImage;
String? _base64Image;
bool _profileImageUploaded = false;
bool _nationalIdImageUploaded = false;
  final ImagePicker _picker = ImagePicker();

Widget _buildDropdownField({
  required String labelText,
  required List<String> items,
  required String? value,
  required ValueChanged<String?> onChanged,
  required bool isRequired,
  FormFieldValidator<String>? validator,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: labelText,
            style: const TextStyle(fontSize: 14, color: Colors.black),
            children: isRequired
                ? [
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red),
                    ),
                  ]
                : [],
          ),
        ),
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
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
    ),
  );
}


Future<void> _pickImage({required bool isNationalId}) async {
  if (isNationalId && _nationalIdImageUploaded) {
    setState(() {
      _nationalIdImage = null;
      _nationalIdImageUploaded = false;
    });
    return;
  }

  if (!isNationalId && _profileImageUploaded) {
    setState(() {
      _image = null;
      _base64Image = null;
      _profileImageUploaded = false;
    });
    return;
  }

  final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
  if (pickedFile != null) {
    final compressedBytes = await FlutterImageCompress.compressWithFile(
      pickedFile.path,
      quality: 40,
    );

    if (compressedBytes != null) {
      setState(() {
        if (isNationalId) {
          _nationalIdImage = File(pickedFile.path);
          _nationalIdImageUploaded = true;
        } else {
          _image = File(pickedFile.path);
          _base64Image = 'data:image/jpeg;base64,${base64Encode(compressedBytes)}';
          _profileImageUploaded = true;
        }
      });
    }
  }
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
          Text('Registering...'),
        ],
      ),
    ),
  );
}

Future<void> _submitRegistration() async {
  showLoadingDialog();

  final uri = Uri.parse('https://node-api-g7fs.onrender.com/api/users/register');

  final Map<String, dynamic> body = {
    "firstName": firstNameController.text.trim(),
    "lastName": lastNameController.text.trim(),
    "username": usernameController.text.trim(),
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

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);

      Navigator.pop(context); // ✅ close loading

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Success'),
          content: Text('Registered successfully! Welcome ${data['firstName']}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // close dialog
                Navigator.of(context).pushReplacementNamed('/');
              },
              child: const Text('Go to Home'),
            ),
          ],
        ),
      );
    } else {
      final error = jsonDecode(response.body);
      Navigator.pop(context); // ✅ close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed: ${error['message']}')),
      );
    }
  } catch (e) {
    Navigator.pop(context); // ✅ close loading on exception
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('An error occurred. Please try again later.')),
    );
    print('Error: $e');
  }
}

Widget _buildTextField({
  required TextEditingController controller,
  required String hintText,
  required String labelText,
  bool isRequired = false,
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
        label: RichText(
          text: TextSpan(
            text: labelText,
            style: const TextStyle(fontSize: 14, color: Colors.black),
            children: isRequired
                ? [
                    const TextSpan(
                      text: ' *',
                      style: TextStyle(color: Colors.red),
                    ),
                  ]
                : [],
          ),
        ),
        hintStyle: const TextStyle(fontSize: 14),
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
  bool showRemove = false,
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
        const SizedBox(height: 6),
        if (imageFile != null)
          TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.delete),
            label: const Text('Remove Image'),
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
                    isRequired: true,
                    validator: (value) => value!.isEmpty ? 'Enter first name' : null,
                  ),
                  _buildTextField(
                    controller: lastNameController,
                    hintText: 'Enter Last Name',
                    labelText: 'Last Name',
                    isRequired: true,
                    validator: (value) => value!.isEmpty ? 'Enter last name' : null,
                  ),
                  _buildTextField(
                    controller: usernameController,
                    hintText: 'Enter Username',
                    labelText: 'Username',
                    isRequired: true,
                    validator: (value) => value!.isEmpty ? 'Enter username' : null,
                  ),
                  _buildTextField(
                    controller: emailController,
                    hintText: 'Enter Email',
                    labelText: 'Email',
                    isRequired: true,
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
                    controller: addressController,
                    hintText: 'Enter Address',
                    labelText: 'Address',
                    isRequired: true,
                    validator: (value) => value!.isEmpty ? 'Enter address' : null,
                  ),
                  _buildDropdownField(
                    labelText: 'Role',
                    items: ['Admin', 'Support Team'],
                    value: _selectedRole,
                    isRequired: true,
                    validator: (value) => value == null || value.isEmpty ? 'Select role' : null,
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value;
                        roleController.text = value ?? '';
                      });
                    },
                  ),
                    _buildTextField(
                      controller: branchNameController,
                      hintText: 'Enter Branch Name',
                      labelText: 'Branch Name',
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
                      isRequired: true, // 
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
                      isRequired: true, // 
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
                              ElevatedButton.icon(
                                onPressed: () => _pickImage(isNationalId: false),
                                icon: Icon(_profileImageUploaded ? Icons.delete : Icons.image),
                                label: Text(_profileImageUploaded ? 'Remove Profile' : 'Upload Profile'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState?.validate() ?? false) {
                                    _submitRegistration();
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
