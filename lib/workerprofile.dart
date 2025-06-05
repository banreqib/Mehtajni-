import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first/profileworker.dart';

class WorkerProfileScreen extends StatefulWidget {
  static const routeName = '/worker-profile';
  final bool isInitialSetup;

  const WorkerProfileScreen({super.key, this.isInitialSetup = false});

  @override
  State<WorkerProfileScreen> createState() => _WorkerProfileScreenState();
}

class _WorkerProfileScreenState extends State<WorkerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String? _userId;
  String? _username;
  String? _email;
  String? _imageUrl;

  String? _profession;
  String? _experience;
  String? _hourlyRate;
  String? _bio;
  String? _phoneNumber;
  String? _location;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  final List<String> professions = [
    "كهربجي",
    "دهين",
    "مواسرجي",
    "بليط",
    "ميكانيكي",
    "نجار",
    "صيانة اجهزة",
    "مزارع"
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _errorMessage = 'لم يتم تسجيل الدخول');
        return;
      }

      final docSnapshot =
          await _firestore.collection('users').doc(user.uid).get();

      if (!docSnapshot.exists) {
        setState(() => _errorMessage = 'لم يتم العثور على ملف المستخدم');
        return;
      }

      final data = docSnapshot.data();
      setState(() {
        _userId = user.uid;
        _username = data?['username'] ?? '';
        _email = data?['email'] ?? '';
        _imageUrl = data?['image_url'] ?? '';
        _profession = data?['profession'];
        _experience = data?['experience'];
        _hourlyRate = data?['hourlyRate'];
        _bio = data?['bio'];
        _phoneNumber = data?['phoneNumber'];
        _location = data?['location'];
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'فشل تحميل البيانات: ${error.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      _formKey.currentState!.save();

      await _firestore.collection('users').doc(_userId).update({
        'username': _username,
        'profession': _profession,
        'experience': _experience,
        'hourlyRate': _hourlyRate,
        'bio': _bio,
        'phoneNumber': _phoneNumber,
        'location': _location,
        'updatedAt': FieldValue.serverTimestamp(),
        'profileCompleted': true,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isInitialSetup
              ? 'تم إنشاء الحساب بنجاح'
              : 'تم تحديث الملف الشخصي بنجاح'),
          duration: const Duration(seconds: 2),
        ),
      );

      if (widget.isInitialSetup) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (ctx) => const workerProfileScreen()),
          (route) => false,
        );
      } else {
        Navigator.pop(context, true);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل الحفظ: ${error.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'جاري تحميل الملف الشخصي...',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Color.fromARGB(255, 38, 95, 134), fontFamily: 'Ruqaa'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'حدث خطأ غير متوقع',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.red,
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadUserData,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (_imageUrl != null && _imageUrl!.isNotEmpty)
              CircleAvatar(
                radius: 50,
                backgroundColor: Color.fromARGB(255, 38, 95, 134),
                backgroundImage: NetworkImage(_imageUrl!),
              ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: _username,
              style: const TextStyle(color: Color.fromARGB(255, 38, 95, 134)),
              decoration: const InputDecoration(
                labelText: 'اسم المستخدم',
                labelStyle: TextStyle(
                    color: Color.fromARGB(255, 38, 95, 134),
                    fontFamily: 'Ruqaa'),
                prefixIcon: Icon(
                  Icons.person,
                  color: Color.fromARGB(255, 38, 95, 134),
                ),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'الرجاء إدخال اسم المستخدم ' : null,
              onSaved: (value) => _username = value,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _email,
              style: const TextStyle(color: Color.fromARGB(255, 38, 95, 134)),
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                labelStyle: TextStyle(
                    color: Color.fromARGB(255, 38, 95, 134),
                    fontFamily: 'Ruqaa'),
                prefixIcon: Icon(
                  Icons.email,
                  color: Color.fromARGB(255, 38, 95, 134),
                ),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _profession,
              style: const TextStyle(color: Color.fromARGB(255, 38, 95, 134)),
              decoration: const InputDecoration(
                labelText: 'المهنة',
                labelStyle: TextStyle(
                    color: Color.fromARGB(255, 38, 95, 134),
                    fontFamily: 'Ruqaa'),
                prefixIcon: Icon(
                  Icons.work,
                  color: Color.fromARGB(255, 38, 95, 134),
                ),
              ),
              items: professions.map((String profession) {
                return DropdownMenuItem<String>(
                  value: profession,
                  child: Text(profession),
                );
              }).toList(),
              onChanged: (String? value) => setState(() => _profession = value),
              validator: (value) =>
                  value == null ? 'الرجاء اختيار المهنة' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _experience,
              style: const TextStyle(color: Color.fromARGB(255, 38, 95, 134)),
              decoration: const InputDecoration(
                labelText: 'سنوات الخبرة',
                labelStyle: TextStyle(
                    color: Color.fromARGB(255, 38, 95, 134),
                    fontFamily: 'Ruqaa'),
                prefixIcon: Icon(
                  Icons.timeline,
                  color: Color.fromARGB(255, 38, 95, 134),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  value!.isEmpty ? 'الرجاء إدخال سنوات الخبرة' : null,
              onSaved: (value) => _experience = value,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _hourlyRate,
              style: const TextStyle(color: Color.fromARGB(255, 38, 95, 134)),
              decoration: const InputDecoration(
                labelText: 'سعر الساعة (دينار أردني)',
                labelStyle: TextStyle(
                    color: Color.fromARGB(255, 38, 95, 134),
                    fontFamily: 'Ruqaa'),
                prefixIcon: Icon(
                  Icons.attach_money,
                  color: Color.fromARGB(255, 38, 95, 134),
                ),
              ),
              keyboardType: TextInputType.number,
              validator: (value) =>
                  value!.isEmpty ? 'الرجاء إدخال سعر الساعة' : null,
              onSaved: (value) => _hourlyRate = value,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _phoneNumber,
              style: const TextStyle(color: Color.fromARGB(255, 38, 95, 134)),
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                labelStyle: TextStyle(
                    color: Color.fromARGB(255, 38, 95, 134),
                    fontFamily: 'Ruqaa'),
                prefixIcon: Icon(
                  Icons.phone,
                  color: Color.fromARGB(255, 38, 95, 134),
                ),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (value) {
                if (value!.isEmpty) return 'الرجاء إدخال رقم الهاتف';
                if (value.length != 10) return 'يجب أن يتكون الرقم من 10 أرقام';
                return null;
              },
              onSaved: (value) => _phoneNumber = value,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _location,
              style: const TextStyle(color: Color.fromARGB(255, 38, 95, 134)),
              decoration: const InputDecoration(
                labelText: 'الموقع',
                labelStyle: TextStyle(
                    color: Color.fromARGB(255, 38, 95, 134),
                    fontFamily: 'Ruqaa'),
                prefixIcon: Icon(
                  Icons.location_on,
                  color: Color.fromARGB(255, 38, 95, 134),
                ),
              ),
              validator: (value) =>
                  value!.isEmpty ? 'الرجاء إدخال الموقع' : null,
              onSaved: (value) => _location = value,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _bio,
              style: const TextStyle(color: Color.fromARGB(255, 38, 95, 134)),
              decoration: const InputDecoration(
                labelText: 'نبذة عنك',
                labelStyle: TextStyle(
                    color: Color.fromARGB(255, 38, 95, 134),
                    fontFamily: 'Ruqaa'),
                prefixIcon: Icon(
                  Icons.info,
                  color: Color.fromARGB(255, 38, 95, 134),
                ),
                hintText: 'اكتب نبذة قصيرة عن خبراتك ومهاراتك',
                hintStyle: TextStyle(
                  color: Color.fromARGB(255, 38, 95, 134),
                ),
              ),
              maxLines: 3,
              validator: (value) =>
                  value!.isEmpty ? 'الرجاء إدخال نبذة عنك' : null,
              onSaved: (value) => _bio = value,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _submitProfile,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Color.fromARGB(255, 38, 95, 134),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'حفظ التغييرات',
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontFamily: 'Ruqaa'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isInitialSetup ? 'إكمال ملف العامل' : 'الملف الشخصي للعامل',
          style: const TextStyle(
              color: Color.fromARGB(255, 38, 95, 134),
              fontWeight: FontWeight.bold,
              fontFamily: 'Ruqaa'),
        ),
        leading: widget.isInitialSetup
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color.fromARGB(255, 38, 95, 134),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(children: [
        Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/plain.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 100.0),
          child: _errorMessage != null
              ? _buildErrorState()
              : _isLoading
                  ? _buildLoadingState()
                  : _buildProfileForm(),
        ),
      ]),
    );
  }
}
