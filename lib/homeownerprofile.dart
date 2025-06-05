import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first/profilehome.dart';

class HomeownerProfileScreen extends StatefulWidget {
  static const routeName = '/homeowner-profile';
  final bool isInitialSetup;

  const HomeownerProfileScreen({super.key, this.isInitialSetup = false});

  @override
  State<HomeownerProfileScreen> createState() => _HomeownerProfileScreenState();
}

class _HomeownerProfileScreenState extends State<HomeownerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String? _userId;
  String? _username;
  String? _email;
  String? _imageUrl;
  String? _phoneNumber;
  String? _address;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

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
        _phoneNumber = data?['phoneNumber'];
        _address = data?['address'];
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
        'phoneNumber': _phoneNumber,
        'address': _address,
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
          MaterialPageRoute(builder: (ctx) => const ProfileScreen()),
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
                  color: Colors.blue[900],
                ),
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
                backgroundColor: Colors.grey[200],
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
                prefixIcon:
                    Icon(Icons.person, color: Color.fromARGB(255, 38, 95, 134)),
              ),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'الرجاء إدخال اسم مستخدم ';
                return null;
              },
              onSaved: (value) => _username = value,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _email,
              style: const TextStyle(
                  color: Color.fromARGB(255, 38, 95, 134), fontFamily: 'Ruqaa'),
              decoration: const InputDecoration(
                labelText: 'البريد الإلكتروني',
                labelStyle: TextStyle(
                    color: Color.fromARGB(255, 38, 95, 134),
                    fontFamily: 'Ruqaa'),
                prefixIcon:
                    Icon(Icons.email, color: Color.fromARGB(255, 38, 95, 134)),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: _phoneNumber,
              style: const TextStyle(
                  color: Color.fromARGB(255, 38, 95, 134), fontFamily: 'Ruqaa'),
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف',
                labelStyle: TextStyle(
                    color: Color.fromARGB(255, 38, 95, 134),
                    fontFamily: 'Ruqaa'),
                prefixIcon:
                    Icon(Icons.phone, color: Color.fromARGB(255, 38, 95, 134)),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'الرجاء إدخال رقم الهاتف';
                if (value.length != 10) return 'يجب أن يتكون الرقم من 10 أرقام';
                return null;
              },
              onSaved: (value) => _phoneNumber = value,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _address,
              style: const TextStyle(
                  color: Color.fromARGB(255, 38, 95, 134), fontFamily: 'Ruqaa'),
              decoration: const InputDecoration(
                labelText: 'العنوان',
                labelStyle: TextStyle(
                    color: Color.fromARGB(255, 38, 95, 134),
                    fontFamily: 'Ruqaa'),
                prefixIcon: Icon(Icons.location_on,
                    color: Color.fromARGB(255, 38, 95, 134)),
                hintText: 'مثال: الرياض، حي المروج',
              ),
              maxLines: 2,
              validator: (value) => value == null || value.isEmpty
                  ? 'الرجاء إدخال العنوان'
                  : null,
              onSaved: (value) => _address = value,
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
                            fontFamily: "Ruqaa"),
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
          widget.isInitialSetup
              ? 'إكمال ملف صاحب المنزل'
              : 'الملف الشخصي لصاحب المنزل',
          style: const TextStyle(
            color: Color.fromARGB(255, 38, 95, 134),
            fontFamily: 'Ruqaa',
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: widget.isInitialSetup
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: Color.fromARGB(255, 38, 95, 134)),
                onPressed: () => Navigator.of(context).pop(),
              ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
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
        ],
      ),
    );
  }
}
