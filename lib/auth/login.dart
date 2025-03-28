import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../home.dart';
import '../account/open_new_account.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import '../global_state.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool rememberMe = false;
  bool _isPasswordVisible = false;
  bool _isButtonActive = false;
  bool _isLoading = true;
  bool showInvalidCredentials = false;
  bool isNetworkError = false;
  bool usernameError = false;
  bool passwordError = false;

  String selectedLanguage = 'English';
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  Map<String, Map<String, String>> languageData = {
  'English': {
    'welcomeText': 'Hello, Welcome Back!',
    'usernameHint': 'UserName',
    'passwordHint': 'Password',
    'rememberMeText': 'Remember Me',
    'loginButtonText': 'Login',
    'forgetPasswordText': 'Forget Password?',
    'openNewAccountText': 'New User',
    'locateUsText': 'Locate Us',
    'enrollActivateText': 'New Event',
    'supportText': 'Support',
  },
  'Amharic': {
    'welcomeText': 'ሰላም፣ እንዳን በደለና መጣስ!',
    'usernameHint': 'የተጠቃሚ ስም',
    'passwordHint': 'የይለፍ ቃል',
    'rememberMeText': 'አስታውሰኝ',
    'loginButtonText': 'ግባ',
    'forgetPasswordText': 'የይለፍ ቃል ረሳሑን?',
    'openNewAccountText': 'አዲስ መለያ ክፍት',
    'locateUsText': 'ያግኑን',
    'enrollActivateText': 'New Event',
    'supportText': 'ድጋፍ'
  },
  'Oromic': {
    'welcomeText': 'Akkam, Baga Nagaan Dhuftan!',
    'usernameHint': 'Maqaa Ittiin Seentan',
    'passwordHint': 'Jecha Ceʼumsaa',
    'rememberMeText': 'Na Yaadadhu',
    'loginButtonText': 'Seeni',
    'forgetPasswordText': 'Jecha Ceʼumsaa Dagatte?',
    'openNewAccountText': 'Fayyadamaa Haaraa',
    'locateUsText': 'Nu Argadhu',
    'enrollActivateText': 'Waliigalte Haaraa',
    'supportText': 'Deggersa',
  },
};

  @override
  void initState() {
    super.initState();
    _loadRememberedUsername();
    _simulateLoading();
  }

  Future<void> _simulateLoading() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRememberedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('savedUsername');
    if (savedUsername != null) {
      setState(() {
        usernameController.text = savedUsername;
        rememberMe = true;
      });
    }
  }

  void _saveUsername() async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setString('savedUsername', usernameController.text);
    } else {
      await prefs.remove('savedUsername');
    }
  }

  void _checkFormValidity() {
    setState(() {
      _isButtonActive = usernameController.text.isNotEmpty &&
          passwordController.text.isNotEmpty;
    });
  }

  Future<void> login() async {
    String enteredUsername = usernameController.text.trim();
    String enteredPassword = passwordController.text.trim();

    if (enteredUsername.isEmpty || enteredPassword.isEmpty) {
      setState(() {
        usernameError = enteredUsername.isEmpty;
        passwordError = enteredPassword.isEmpty;
        showInvalidCredentials = false;
        isNetworkError = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      usernameError = false;
      passwordError = false;
      showInvalidCredentials = false;
      isNetworkError = false;
    });

    final url = Uri.parse('https://node-api-g7fs.onrender.com/api/users/login');
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode({
      'username': enteredUsername,
      'password': enteredPassword,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        final String token = responseData['token'] ?? '';
        final String email = responseData['email'] ?? '';
        final String username = responseData['username'] ?? enteredUsername;
        final String userId = responseData['_id'];

        final globalState = Provider.of<GlobalState>(context, listen: false);
        globalState.setUsername(username);
        globalState.setEmail(email);
        globalState.setUserId(userId);
        globalState.setToken(token);

        _saveUsername();

        setState(() {
          showInvalidCredentials = false;
          isNetworkError = false;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(token: token, username: username),
          ),
        );
      } else if (response.statusCode == 401) {
        setState(() {
          showInvalidCredentials = true;
          isNetworkError = false;
        });
      } else {
        setState(() {
          showInvalidCredentials = false;
          isNetworkError = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${response.statusCode}')),
        );
      }
    } catch (error) {
      setState(() {
        showInvalidCredentials = false;
        isNetworkError = true;
      });
      print('Login error: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 235, 230, 230),
      body: _isLoading
          ? Center(
              child: LoadingAnimationWidget.hexagonDots(
                color: const Color.fromARGB(255, 211, 7, 167),
                size: 100,
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(50)),
                    child: Image.asset(
                      'assets/images/cbe1.png',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        languageData[selectedLanguage]!['welcomeText']!,
                        style: const TextStyle(
                          color: Color.fromARGB(216, 95, 105, 2),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 15),
                      DropdownButton<String>(
                        value: selectedLanguage,
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedLanguage = newValue!;
                          });
                        },
                        underline: const SizedBox(),
                        items: languageData.keys
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Text(value),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (showInvalidCredentials || isNetworkError)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        isNetworkError
                            ? 'Network error. Please check your connection.'
                            : 'Invalid username or password.',
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  SizedBox(
                    width: 300,
                    child: Column(
                      children: [
                        TextField(
                          controller: usernameController,
                          onChanged: (value) {
                            setState(() {
                              usernameError = false;
                            });
                            _checkFormValidity();
                          },
                          decoration: InputDecoration(
                            hintText:
                                languageData[selectedLanguage]!['usernameHint'],
                            errorText:
                                usernameError ? 'Username is required' : null,
                            border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20)),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: passwordController,
                          onChanged: (value) {
                            setState(() {
                              passwordError = false;
                            });
                            _checkFormValidity();
                          },
                          obscureText: !_isPasswordVisible,
                          decoration: InputDecoration(
                            hintText:
                                languageData[selectedLanguage]!['passwordHint'],
                            errorText:
                                passwordError ? 'Password is required' : null,
                            border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20)),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.5),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 250,
                        child: ElevatedButton(
                          onPressed: _isButtonActive ? login : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isButtonActive
                                ? const Color.fromARGB(255, 182, 4, 143)
                                : const Color.fromARGB(255, 230, 226, 229),
                            foregroundColor: _isButtonActive
                                ? Colors.white
                                : const Color.fromARGB(255, 70, 3, 31),
                          ),
                          child: Text(
                              languageData[selectedLanguage]!['loginButtonText']!),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: rememberMe,
                        onChanged: (value) {
                          setState(() {
                            rememberMe = value!;
                          });
                        },
                        activeColor: const Color.fromARGB(31, 240, 3, 149),
                        checkColor: const Color.fromARGB(246, 65, 2, 41),
                      ),
                      Text(
                        languageData[selectedLanguage]!['rememberMeText']!,
                        style: const TextStyle(
                          color: Color.fromARGB(246, 65, 2, 41),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          print('Forget is clicked');
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color.fromARGB(246, 65, 2, 41),
                        ),
                        child: Text(languageData[selectedLanguage]!['forgetPasswordText']!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const OpenNewAccountPage()),
                          );
                        },
                        child: Text(
                          languageData[selectedLanguage]!['openNewAccountText']!,
                          style: const TextStyle(
                            color: Color.fromARGB(253, 99, 1, 61),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  CarouselSlider(
                    options: CarouselOptions(
                      height: 180.0,
                      autoPlay: true,
                      enlargeCenterPage: true,
                      aspectRatio: 2.0,
                      autoPlayCurve: Curves.fastOutSlowIn,
                      enableInfiniteScroll: true,
                      autoPlayAnimationDuration: const Duration(milliseconds: 800),
                      viewportFraction: 1.1,
                    ),
                    items: [
                      'assets/images/network.jpg',
                      'assets/images/printer.jpg',
                      'assets/images/software.jpg',
                      'assets/images/hardware.jpg',
                      'assets/images/western.jpg',
                      'assets/images/moneygram.jpg',
                      'assets/images/hardware1.jpg',
                      'assets/images/software1.jpg',
                      'assets/images/network1.jpg',
                    ].map((i) {
                      return Builder(
                        builder: (BuildContext context) {
                          return Container(
                            width: double.infinity,
                            height: 150,
                            margin: const EdgeInsets.symmetric(horizontal: 0.0),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 219, 6, 155),
                              border: Border.all(
                                color: const Color.fromARGB(255, 250, 251, 252),
                                width: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(i, fit: BoxFit.cover),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          languageData[selectedLanguage]!['locateUsText']!,
                          style: const TextStyle(
                            color: Color.fromARGB(246, 65, 2, 41),
                            fontSize: 12,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          languageData[selectedLanguage]!['enrollActivateText']!,
                          style: const TextStyle(
                            color: Color.fromARGB(246, 65, 2, 41),
                            fontSize: 12,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          languageData[selectedLanguage]!['supportText']!,
                          style: const TextStyle(
                            color: Color.fromARGB(246, 65, 2, 41),
                            fontSize: 12,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
