import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:first/auth.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _ownerController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (ctx) => const AuthScreen()),
      (route) => false,
    );
  }

  Future<void> _submitAd() async {
    if (!_formKey.currentState!.validate() ||
        _startDate == null ||
        _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('املأ كل المعلومات واختر التواريخ')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('ads').add({
      'text': _textController.text.trim(),
      'owner': _ownerController.text.trim(),
      'startdate': Timestamp.fromDate(_startDate!),
      'enddate': Timestamp.fromDate(_endDate!),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم حفظ الإعلان')),
    );

    _textController.clear();
    _ownerController.clear();
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  Future<void> _pickDate(bool isStart) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (selectedDate != null) {
      setState(() {
        if (isStart) {
          _startDate = selectedDate;
        } else {
          _endDate = selectedDate;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/plain.png'),
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 80, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'صفحة الأدمن',
                  style: TextStyle(
                    color: Color.fromARGB(255, 38, 95, 134),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Card(
                    color: Colors.white.withOpacity(0.9),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'نص الإعلان',
                            style: TextStyle(
                              color: Color.fromARGB(255, 38, 95, 134),
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          TextFormField(
                            controller: _textController,
                            textDirection: TextDirection.rtl,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'اكتب نص الإعلان';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'صاحب الإعلان',
                            style: TextStyle(
                              color: Color.fromARGB(255, 38, 95, 134),
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                          TextFormField(
                            controller: _ownerController,
                            textDirection: TextDirection.rtl,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'اكتب اسم الشركة أو الشخص';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          const Center(
                            child: Text(
                              'التواريخ',
                              style: TextStyle(
                                color: Color.fromARGB(255, 38, 95, 134),
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _pickDate(false),
                                  child: Text(
                                    _endDate == null
                                        ? 'اختر النهاية'
                                        : 'نهاية: ${_endDate!.toLocal().toString().split(' ')[0]}',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _pickDate(true),
                                  child: Text(
                                    _startDate == null
                                        ? 'اختر البداية'
                                        : 'بداية: ${_startDate!.toLocal().toString().split(' ')[0]}',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: ElevatedButton(
                              onPressed: _submitAd,
                              child: const Text('إضافة الإعلان'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () => _logout(context),
                    child: const Text('تسجيل الخروج'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
