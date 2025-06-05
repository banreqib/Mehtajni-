import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_drawer.dart';

class AvailableJobs extends StatelessWidget {
  const AvailableJobs({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      endDrawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 38, 95, 134)),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu,
                  size: 30, color: Color.fromARGB(255, 38, 95, 134)),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/plain.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned.fill(
            top: kToolbarHeight + 20,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('jobs')
                  .where('isCompleted', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text(
                    'لا توجد طلبات حالياً',
                    style: TextStyle(
                      color: Color.fromARGB(255, 38, 95, 134),
                    ),
                  ));
                }

                final jobs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: jobs.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'جميع الطلبات',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 38, 95, 134),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final job = jobs[index - 1].data() as Map<String, dynamic>;
                    final userId = job['userId'];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userId)
                          .get(),
                      builder: (context, userSnapshot) {
                        final userData =
                            userSnapshot.data?.data() as Map<String, dynamic>?;

                        final userName = userData?['username'] ?? 'غير معروف';
                        final userPhone =
                            userData?['phoneNumber'] ?? 'غير متوفر';

                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 5,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(
                              job['title'] ?? 'عنوان غير معروف',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 38, 95, 134),
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(job['description'] ?? 'لا يوجد وصف',
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 38, 95, 134),
                                    )),
                                const SizedBox(height: 8),
                                Text('الاسم: $userName',
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 38, 95, 134),
                                    )),
                                Text('رقم الهاتف: $userPhone',
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 38, 95, 134),
                                    )),
                              ],
                            ),
                            trailing:
                                userId == FirebaseAuth.instance.currentUser!.uid
                                    ? ElevatedButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => CompleteJobDialog(
                                                jobId: jobs[index - 1].id),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                        ),
                                        child: const Text('إنهاء العمل'),
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.chat),
                                        onPressed: () {
                                          Navigator.pushNamed(
                                            context,
                                            '/chat',
                                            arguments: {
                                              'receiverId': userId,
                                              'receiverName': userName,
                                            },
                                          );
                                        },
                                      ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CompleteJobDialog extends StatefulWidget {
  final String jobId;

  const CompleteJobDialog({super.key, required this.jobId});

  @override
  State<CompleteJobDialog> createState() => _CompleteJobDialogState();
}

class _CompleteJobDialogState extends State<CompleteJobDialog> {
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 3;
  String? _selectedUsername;
  List<String> _workerUsernames = [];
  bool _isLoadingWorkers = true;

  @override
  void initState() {
    super.initState();
    _fetchWorkers();
  }

  Future<void> _fetchWorkers() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'worker')
          .get();

      final usernames = snapshot.docs
          .where((doc) => doc.id != currentUserId)
          .map((doc) => doc.data()['username']?.toString())
          .where((username) => username != null)
          .cast<String>()
          .toList();

      setState(() {
        _workerUsernames = usernames;
        _isLoadingWorkers = false;
      });
    } catch (e) {
      print('Error fetching workers: $e');
      setState(() => _isLoadingWorkers = false);
    }
  }

  Future<void> _submitCompletion() async {
    final username = _selectedUsername;
    final review = _reviewController.text.trim();

    if (username == null || review.isEmpty || _rating < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة جميع الحقول')),
      );
      return;
    }

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم العثور على المستخدم')),
        );
        return;
      }

      final workerDoc = query.docs.first;
      final workerId = workerDoc.id;

      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(widget.jobId)
          .update({
        'isCompleted': true,
        'workerId': workerId,
        'rating': _rating,
        'review': review,
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(workerId)
          .collection('completedJobs')
          .doc(widget.jobId)
          .set({
        'jobId': widget.jobId,
        'timestamp': Timestamp.now(),
        'rating': _rating,
        'review': review,
      });

      final workerRef =
          FirebaseFirestore.instance.collection('users').doc(workerId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(workerRef);
        final data = snapshot.data()!;
        final totalRatings = (data['totalRatings'] ?? 0) + 1;
        final currentAvg = (data['averageRating'] ?? 0.0) * (totalRatings - 1);
        final newAvg = (currentAvg + _rating) / totalRatings;

        transaction.update(workerRef, {
          'totalRatings': totalRatings,
          'averageRating': newAvg,
        });
      });

      Navigator.of(context).pop();
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إنهاء العمل'),
      content: _isLoadingWorkers
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedUsername,
                    hint: const Text('اختر اسم العامل'),
                    items: _workerUsernames.map((username) {
                      return DropdownMenuItem(
                        value: username,
                        child: Text(username),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUsername = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Text('التقييم: ${_rating.toInt()}'),
                  Slider(
                    value: _rating,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _rating.toInt().toString(),
                    onChanged: (value) {
                      setState(() => _rating = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _reviewController,
                    decoration:
                        const InputDecoration(labelText: 'اكتب مراجعة قصيرة'),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          child: const Text('إلغاء'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: const Text('تم'),
          onPressed: _submitCompletion,
        ),
      ],
    );
  }
}
