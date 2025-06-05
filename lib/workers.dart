import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_drawer.dart';

class Workers extends StatelessWidget {
  const Workers({super.key});

  Future<Map<String, dynamic>> getUserInfo(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.exists ? userDoc.data()! : {};
  }

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
              stream:
                  FirebaseFirestore.instance.collection('services').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final services = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: services.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'جميع الخدمات',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 38, 95, 134),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final service = services[index - 1];
                    final userId = service['userId'];

                    return FutureBuilder<Map<String, dynamic>>(
                      future: getUserInfo(userId),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) return const SizedBox();

                        final user = userSnapshot.data!;
                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 5,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(service['title'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 38, 95, 134),
                                )),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(service['description'],
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 38, 95, 134),
                                    )),
                                const SizedBox(height: 8),
                                Text(
                                    'الاسم: ${user['username'] ?? 'غير معروف'}',
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 38, 95, 134),
                                    )),
                                Text(
                                    'رقم الهاتف: ${user['phoneNumber'] ?? 'غير متوفر'}',
                                    style: const TextStyle(
                                      color: Color.fromARGB(255, 38, 95, 134),
                                    )),
                              ],
                            ),
                            trailing: IconButton(
                                icon: const Icon(Icons.chat),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/chat',
                                    arguments: {
                                      'receiverId': userId,
                                      'receiverName':
                                          user['username'] ?? 'مستخدم',
                                    },
                                  );
                                }),
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
