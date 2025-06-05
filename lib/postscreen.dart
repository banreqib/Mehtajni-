import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  String? selectedType;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isLoading = false;

  void _submitPost() async {
    if (selectedType == null ||
        _titleController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة جميع الحقول')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    final userId = user!.uid;

    final postData = {
      'userId': userId,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'createdAt': Timestamp.now(),
      'type': selectedType,
      'isCompleted': false,
    };

    final collectionName = selectedType == 'job' ? 'jobs' : 'services';

    await FirebaseFirestore.instance.collection(collectionName).add(postData);

    setState(() {
      _isLoading = false;
    });

    Navigator.pushReplacementNamed(
      context,
      selectedType == 'job' ? '/jobAvailable' : '/workers',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/plain.png',
              fit: BoxFit.cover,
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme:
                  const IconThemeData(color: Color.fromARGB(255, 38, 95, 134)),
              title: const Text(
                'إنشاء منشور جديد',
                style: TextStyle(
                    color: Color.fromARGB(255, 38, 95, 134),
                    fontFamily: 'Ruqaa'),
              ),
            ),
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedType,
                          hint: const Text(
                            'اختر نوع المنشور',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Ruqaa',
                              color: Color.fromARGB(255, 38, 95, 134),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'job',
                              child: Text(
                                'طلب',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Ruqaa',
                                  color: Color.fromARGB(255, 38, 95, 134),
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'service',
                              child: Text(
                                'خدمة',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'Ruqaa',
                                  color: Color.fromARGB(255, 38, 95, 134),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedType = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText:
                                'نوع الخدمة او الطلب(دهان , مواسرجي , ...)',
                            labelStyle: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Ruqaa',
                              color: Color.fromARGB(255, 38, 95, 134),
                            ),
                          ),
                        ),
                        TextField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'وصف المنشور',
                            labelStyle: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Ruqaa',
                              color: Color.fromARGB(255, 38, 95, 134),
                            ),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _submitPost,
                          child: const Text(
                            'نشر',
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'Ruqaa',
                              color: Color.fromARGB(255, 38, 95, 134),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
