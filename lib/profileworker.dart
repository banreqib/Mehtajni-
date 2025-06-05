import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:first/workerprofile.dart';
import 'package:first/postscreen.dart';
import 'app_drawer.dart';

class workerProfileScreen extends StatefulWidget {
  final String? uid;

  const workerProfileScreen({Key? key, this.uid}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<workerProfileScreen> {
  late String name;
  late String phone;
  late String email;
  late String location;
  late String proffession;
  late String experience;
  late String hourlyrate;
  late String bio;

  bool _isLoading = true;
  String? imageUrl;
  List<Map<String, dynamic>> completedJobs = [];
  double? averageRating;
  bool isCurrentUser = false;

  Future<void> _loadUserData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final targetUid = widget.uid ?? currentUser.uid;
    isCurrentUser = (targetUid == currentUser.uid);

    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUid)
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data()!;
        setState(() {
          name = data['username'] ?? 'غير موجود';
          phone = data['phoneNumber'] ?? 'غير موجود';
          email = data['email'] ?? 'غير موجود';
          location = data['location'] ?? 'غير موجود';
          proffession = data['profession'] ?? 'غير موجود';
          experience = data['experience'] ?? 'غير موجود';
          hourlyrate = data['hourlyRate'] ?? 'غير موجود';
          bio = data['bio'] ?? 'غير موجود';
          _isLoading = false;
        });

        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('user_images')
              .child('$targetUid.jpg');

          final url = await storageRef.getDownloadURL();
          setState(() {
            imageUrl = url;
          });
        } catch (_) {}

        final completedJobsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUid)
            .collection('completedJobs')
            .get();

        final List<Map<String, dynamic>> jobs = [];

        for (var doc in completedJobsSnapshot.docs) {
          final data = doc.data();
          final jobId = data['jobId'];
          final rating = (data['rating'] ?? 0).toDouble();
          final review = data['review'] ?? '';

          try {
            final jobSnapshot = await FirebaseFirestore.instance
                .collection('jobs')
                .doc(jobId)
                .get();

            if (jobSnapshot.exists) {
              final jobData = jobSnapshot.data()!;
              final title = jobData['title'] ?? 'عنوان غير معروف';
              final description = jobData['description'] ?? 'لا يوجد وصف';

              jobs.add({
                'title': title,
                'description': description,
                'rating': rating,
                'review': review,
              });
            }
          } catch (_) {}
        }

        double total = 0;
        int count = 0;
        for (var job in jobs) {
          if (job['rating'] != null && job['rating'] > 0) {
            total += job['rating'];
            count++;
          }
        }

        setState(() {
          completedJobs = jobs;
          averageRating = count > 0 ? total / count : null;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching user data: $error');
    }
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
            drawer: AppDrawer(),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(
                color: Color.fromARGB(255, 38, 95, 134),
              ),
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 70,
                                backgroundColor:
                                    Color.fromARGB(255, 38, 95, 134),
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
                                          fontFamily: 'Ruqaa',
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Color.fromARGB(255, 38, 95, 134)),
                                    ),
                                    if (averageRating != null)
                                      Text(
                                        '${averageRating!.toStringAsFixed(1)} / 5',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Ruqaa',
                                          color:
                                              Color.fromARGB(255, 38, 95, 134),
                                        ),
                                      ),
                                    const SizedBox(height: 8),
                                    if (isCurrentUser) ...[
                                      ElevatedButton(
                                        onPressed: () async {
                                          final updated =
                                              await Navigator.push<bool>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const WorkerProfileScreen(
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
                                              color: Color.fromARGB(
                                                  255, 38, 95, 134),
                                              fontFamily: 'Ruqaa'),
                                        ),
                                      ),
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
                                              color: Color.fromARGB(
                                                  255, 38, 95, 134),
                                              fontFamily: 'Ruqaa'),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          ListTile(
                            leading: const Icon(
                              Icons.phone,
                              color: Color.fromARGB(255, 38, 95, 134),
                            ),
                            title: Text(
                              phone,
                              style: TextStyle(
                                fontFamily: 'Ruqaa',
                                color: Color.fromARGB(255, 38, 95, 134),
                              ),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.email,
                              color: Color.fromARGB(255, 38, 95, 134),
                            ),
                            title: Text(
                              email,
                              style: TextStyle(
                                  color: Color.fromARGB(255, 38, 95, 134),
                                  fontFamily: 'Ruqaa'),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.location_on,
                              color: Color.fromARGB(255, 38, 95, 134),
                            ),
                            title: Text(
                              location,
                              style: TextStyle(
                                  color: Color.fromARGB(255, 38, 95, 134),
                                  fontFamily: 'Ruqaa'),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.work,
                              color: Color.fromARGB(255, 38, 95, 134),
                            ),
                            title: Text(
                              'نوع العمل: $proffession',
                              style: TextStyle(
                                  color: Color.fromARGB(255, 38, 95, 134),
                                  fontFamily: 'Ruqaa'),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.access_time,
                              color: Color.fromARGB(255, 38, 95, 134),
                            ),
                            title: Text(
                              'الخبرة: $experience',
                              style: TextStyle(
                                  color: Color.fromARGB(255, 38, 95, 134),
                                  fontFamily: 'Ruqaa'),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.monetization_on,
                              color: Color.fromARGB(255, 38, 95, 134),
                            ),
                            title: Text(
                              'السعر: $hourlyrate',
                              style: TextStyle(
                                  color: Color.fromARGB(255, 38, 95, 134),
                                  fontFamily: 'Ruqaa'),
                            ),
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.info,
                              color: Color.fromARGB(255, 38, 95, 134),
                            ),
                            title: Text(
                              'النبذة: $bio',
                              style: TextStyle(
                                  color: Color.fromARGB(255, 38, 95, 134),
                                  fontFamily: 'Ruqaa'),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'الطلبات المنجزة',
                            style: TextStyle(
                                color: Color.fromARGB(255, 38, 95, 134),
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Ruqaa'),
                          ),
                          const SizedBox(height: 12),
                          completedJobs.isEmpty
                              ? const Center(
                                  child: Text(
                                  'لا توجد طلبات منجزة',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 38, 95, 134),
                                      fontFamily: 'Ruqaa'),
                                ))
                              : SizedBox(
                                  height: 180,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: completedJobs.length,
                                    itemBuilder: (context, index) {
                                      final job = completedJobs[index];
                                      return Container(
                                        width: 260,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                        child: Card(
                                          elevation: 5,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  job['title'],
                                                  style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color.fromARGB(
                                                          255, 38, 95, 134)),
                                                ),
                                                const SizedBox(height: 8),
                                                Expanded(
                                                  child: Text(
                                                    job['description'],
                                                    maxLines: 3,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        color: Color.fromARGB(
                                                            255, 38, 95, 134),
                                                        fontSize: 14),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'التقييم: ${job['rating']}',
                                                  style: const TextStyle(
                                                    color: Color.fromARGB(
                                                        255, 38, 95, 134),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                if (job['review'] != null &&
                                                    job['review']
                                                        .toString()
                                                        .isNotEmpty)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            top: 4.0),
                                                    child: Text(
                                                      'المراجعة: ${job['review']}',
                                                      style: const TextStyle(
                                                        fontStyle:
                                                            FontStyle.italic,
                                                        fontSize: 13,
                                                        color: Color.fromARGB(
                                                            255, 38, 95, 134),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
