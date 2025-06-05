import 'package:firebase_storage/firebase_storage.dart';
import 'package:first/homepage.dart';
import 'package:first/homeownerprofile.dart';
import 'package:first/workerprofile.dart';
import 'package:first/admin.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:first/user_image_picker.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  var _isLogin = true;
  var _enteredEmail = '';
  var _enteredPassword = '';
  File? _selectedImage;
  var _enteredUserName = '';
  String? _userRole;
  var _isAuthenticating = false;

  final List<String> _roles = ['homeowner', 'worker'];

  Future<void> _submit() async {
    final isValid = _form.currentState!.validate();
    if (!isValid) return;

    if (!_isLogin && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(' اختر صورة')),
      );
      return;
    }

    if (!_isLogin && _userRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(' اختر نوع الحساب')),
      );
      return;
    }

    _form.currentState!.save();

    try {
      setState(() => _isAuthenticating = true);

      UserCredential userCredentials;

      final isAdminAccount =
          _enteredEmail == 'admin@gmail.com' && _enteredPassword == 'admin123';

      if (_isLogin && isAdminAccount) {
        userCredentials = await _firebase.signInWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );

        final adminDoc = await FirebaseFirestore.instance
            .collection('admins')
            .where('email', isEqualTo: _enteredEmail)
            .get();

        if (adminDoc.docs.isEmpty) {
          await FirebaseFirestore.instance.collection('admins').add({
            'adminid': userCredentials.user!.uid,
            'email': _enteredEmail,
            'password': _enteredPassword,
            'createdAt': Timestamp.now(),
          });
        }

        Future.microtask(() {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (ctx) => const AdminPage()),
            );
          }
        });
        return;
      }

      if (_isLogin) {
        userCredentials = await _firebase.signInWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );
      } else {
        userCredentials = await _firebase.createUserWithEmailAndPassword(
          email: _enteredEmail,
          password: _enteredPassword,
        );

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('user_images')
            .child('${userCredentials.user!.uid}.jpg');

        await storageRef.putFile(_selectedImage!);
        final imageUrl = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set({
          'username': _enteredUserName,
          'email': _enteredEmail,
          'image_url': imageUrl,
          'role': _userRole,
          'createdAt': Timestamp.now(),
        });

        if (_userRole == 'worker') {
          Future.microtask(() {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (ctx) =>
                        WorkerProfileScreen(isInitialSetup: true)),
              );
            }
          });
        } else {
          Future.microtask(() {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                    builder: (ctx) =>
                        HomeownerProfileScreen(isInitialSetup: true)),
              );
            }
          });
        }
        return;
      }

      Future.microtask(() {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (ctx) => const HomeScreen()),
            (route) => false,
          );
        }
      });
    } on FirebaseAuthException catch (error) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'ما زبط تفوت عحسابك')),
      );
    } finally {
      if (mounted) {
        setState(() => _isAuthenticating = false);
      }
    }
  }

  void _showPasswordResetDialog(BuildContext context) {
    final _resetEmailController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(' كلمة السر الجديدة'),
        content: TextField(
          controller: _resetEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: ' اكتب ايميلك',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('الغاء '),
          ),
          ElevatedButton(
            onPressed: () async {
              final email = _resetEmailController.text.trim();
              if (email.isNotEmpty && email.contains('@')) {
                try {
                  await FirebaseAuth.instance
                      .sendPasswordResetEmail(email: email);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('بعتناه عالايميل')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text(' ما زبط نبعت عالايميل  ')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(' اكتب ايميل زابط')),
                );
              }
            },
            child: const Text('ابعت'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Color.fromARGB(255, 38, 95, 134),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              _isLogin
                  ? 'assets/images/background2.png'
                  : 'assets/images/plain.png',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: _isLogin ? 1 : 110),
            if (_isLogin) SizedBox(height: 190),
            if (_isLogin)
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  style: TextStyle(
                    fontFamily: 'Ruqaa',
                    color: Color.fromARGB(255, 38, 95, 134),
                  ),
                  children: [
                    TextSpan(
                      text: ' مرحبا فيك في محتاجني؟',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 7),
            SingleChildScrollView(
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(20),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Form(
                      key: _form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!_isLogin)
                            UserImagePicker(
                              onPickedImage: (pickedImage) {
                                _selectedImage = pickedImage;
                              },
                            ),
                          TextFormField(
                            decoration: const InputDecoration(
                              hintText: '  اكتب ايميلك',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 14),
                            validator: (value) {
                              if (value == null ||
                                  value.trim().isEmpty ||
                                  !value.contains('@')) {
                                return 'اكتب ايميلك صح    ';
                              }
                              return null;
                            },
                            onSaved: (value) => _enteredEmail = value!,
                          ),
                          TextFormField(
                            decoration: const InputDecoration(
                              hintText: 'اكتب كلمة السر',
                            ),
                            obscureText: true,
                            style: const TextStyle(fontSize: 14),
                            validator: (value) {
                              if (value == null || value.trim().length < 6) {
                                return 'كلمة السر لازم اطول من 6 خانات';
                              }
                              return null;
                            },
                            onSaved: (value) => _enteredPassword = value!,
                            textAlign: TextAlign.right,
                          ),
                          if (_isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  _showPasswordResetDialog(context);
                                },
                                child: const Text(
                                  'مش متذكر كلمة السر؟',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 38, 95, 134),
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          if (!_isLogin)
                            DropdownButton<String>(
                              value: _userRole,
                              hint: const Text('اختر نوع الحساب'),
                              onChanged: (newValue) {
                                setState(() {
                                  _userRole = newValue;
                                });
                              },
                              items: _roles
                                  .map<DropdownMenuItem<String>>((String role) {
                                return DropdownMenuItem<String>(
                                  value: role,
                                  child: Text(role == 'homeowner'
                                      ? 'صاحب منزل'
                                      : 'عامل'),
                                );
                              }).toList(),
                            ),
                          if (_isAuthenticating)
                            const CircularProgressIndicator(),
                          if (!_isAuthenticating)
                            TextButton(
                              onPressed: _submit,
                              child: Text(
                                _isLogin ? 'الدخول' : 'تسجيل',
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 38, 95, 134),
                                ),
                              ),
                            ),
                          if (!_isAuthenticating)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                  _userRole = null;
                                });
                              },
                              child: Text(
                                _isLogin ? ' حساب جديد' : 'عندي حساب',
                                style: const TextStyle(
                                  color: Color.fromARGB(255, 38, 95, 134),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
