import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:first/homeownerprofile.dart';
import 'package:first/postscreen.dart';
import 'app_drawer.dart';

class ProfileScreen extends StatefulWidget {
  final String? uid;
  const ProfileScreen({Key? key, this.uid}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String name;
  late String phone;
  late String email;
  late String location;
  bool _isLoading = true;
  String? imageUrl;

  Future<void> _loadUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final uidToLoad = widget.uid ?? currentUser.uid;

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uidToLoad)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        setState(() {
          name = data['username'] ?? 'غير موجود';
          phone = data['phoneNumber'] ?? 'غير موجود';
          email = data['email'] ?? 'غير موجود';
          location = data['address'] ?? 'غير موجود';
        });

        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('user_images')
              .child('$uidToLoad.jpg');

          final url = await storageRef.getDownloadURL();
          setState(() {
            imageUrl = url;
          });
        } catch (e) {
          print('No profile image found: $e');
        }
      }
    } catch (error) {
      print('Error fetching user data: $error');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
            drawer: widget.uid == null ? AppDrawer() : null,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(
                color: Color.fromARGB(255, 38, 95, 134),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: imageUrl != null
                                  ? NetworkImage(imageUrl!)
                                  : null,
                              child: imageUrl == null
                                  ? const Icon(Icons.person, size: 50)
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Ruqaa',
                                      color: Color.fromARGB(255, 38, 95, 134),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (widget.uid == null)
                                    ElevatedButton(
                                      onPressed: () async {
                                        final updated =
                                            await Navigator.push<bool>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const HomeownerProfileScreen(
                                                    isInitialSetup: false),
                                          ),
                                        );
                                        if (updated == true) {
                                          setState(() {
                                            _isLoading = true;
                                          });
                                          await _loadUserData();
                                        }
                                      },
                                      child: const Text(
                                        'تعديل',
                                        style: TextStyle(
                                          fontFamily: 'Ruqaa',
                                          color:
                                              Color.fromARGB(255, 38, 95, 134),
                                        ),
                                      ),
                                    ),
                                  if (widget.uid == null)
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const CreatePostScreen()),
                                        );
                                      },
                                      child: const Text(
                                        'كتابة منشور',
                                        style: TextStyle(
                                          fontFamily: 'Ruqaa',
                                          color:
                                              Color.fromARGB(255, 38, 95, 134),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        ListTile(
                          leading: const Icon(Icons.phone,
                              color: Color.fromARGB(255, 38, 95, 134)),
                          title: Text(
                            phone,
                            style: const TextStyle(
                                color: Color.fromARGB(255, 38, 95, 134)),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.email,
                              color: Color.fromARGB(255, 38, 95, 134)),
                          title: Text(
                            email,
                            style: const TextStyle(
                                color: Color.fromARGB(255, 38, 95, 134)),
                          ),
                        ),
                        ListTile(
                          leading: const Icon(Icons.location_on,
                              color: Color.fromARGB(255, 38, 95, 134)),
                          title: Text(
                            location,
                            style: const TextStyle(
                                color: Color.fromARGB(255, 38, 95, 134)),
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
