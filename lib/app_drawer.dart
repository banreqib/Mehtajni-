import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:first/auth.dart';
import 'package:first/homepage.dart';
import 'package:first/profileworker.dart';
import 'package:first/profilehome.dart';
import 'package:first/search.dart';
import 'package:first/workers.dart';
import 'package:first/ads.dart';
import 'package:first/available_jobs.dart';
import 'package:first/chatlist.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color.fromARGB(255, 38, 95, 134),
        child: Column(
          children: <Widget>[
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.only(top: 30, right: 16, bottom: 8),
              height: 130,
              color: const Color.fromARGB(255, 38, 95, 134),
              child: const Text(
                'القائمة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'Ruqaa',
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildDrawerButton(context, 'الصفحة الأساسية',
                        rebuildHome: true),
                    _buildDrawerButton(context, 'المحادثات',
                        navigateTo: ChatListScreen()),
                    _buildDrawerButton(context, 'خدمات الشغيلة',
                        navigateTo: Workers()),
                    _buildDrawerButton(context, 'الوظائف المتاحة',
                        navigateTo: AvailableJobs()),
                    _buildDrawerButton(context, 'البحث', navigateTo: Search()),
                    _buildDrawerButton(context, 'حسابي',
                        onTap: () => _navigateToProfile(context)),
                    _buildDrawerButton(context, 'للاعلان و التواصل',
                        navigateTo: Ads()),
                  ],
                ),
              ),
            ),
            const Divider(color: Colors.white),
            _buildDrawerButton(context, "تسجيل الخروج",
                navigateTo: const AuthScreen(), removeStack: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerButton(BuildContext context, String title,
      {Widget? navigateTo,
      bool removeStack = false,
      bool rebuildHome = false,
      VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 1),
      child: TextButton(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontFamily: 'Ruqaa'),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () {
          if (onTap != null) {
            onTap();
          } else if (rebuildHome) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else if (navigateTo != null) {
            if (removeStack) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => navigateTo),
                (route) => false,
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => navigateTo),
              );
            }
          }
        },
        child: Center(
          child: Text(title),
        ),
      ),
    );
  }

  Future<void> _navigateToProfile(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (route) => false,
      );
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        _showSnackBar(context, 'خطأ: لم يتم العثور على ملف المستخدم!');
        return;
      }

      final role = userDoc.data()?['role'];

      if (role == 'worker') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const workerProfileScreen()),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
      }
    } catch (error) {
      _showSnackBar(context, 'حدث خطأ أثناء تحميل الملف الشخصي: $error');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
