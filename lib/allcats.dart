import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:first/profileworker.dart';
import 'package:flutter/material.dart';
import 'app_drawer.dart';
import 'homepage.dart';

class Allcats extends StatelessWidget {
  const Allcats({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Ruqaa'),
      home: CategoriesScreen(),
    );
  }
}

class CategoriesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> categories = [
    {
      'name': "كهربجي",
      'icon': Icons.electrical_services,
      'previousPageTitle': "كهربجي"
    },
    {'name': "دهين", 'icon': Icons.format_paint, 'previousPageTitle': "دهين"},
    {'name': "مواسرجي", 'icon': Icons.plumbing, 'previousPageTitle': "مواسرجي"},
    {'name': "نجار", 'icon': Icons.carpenter, 'previousPageTitle': "نجار"},
    {'name': "بليط", 'icon': Icons.construction, 'previousPageTitle': "بليط"},
    {
      'name': "ميكانيكي",
      'icon': Icons.car_repair,
      'previousPageTitle': "ميكانيكي"
    },
    {'name': "مزارع", 'icon': Icons.grass, 'previousPageTitle': "مزارع"},
    {
      'name': "صيانة أجهزة",
      'icon': Icons.build,
      'previousPageTitle': "صيانة أجهزة"
    },
  ];

  CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: AppDrawer(),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme:
              const IconThemeData(color: Color.fromARGB(255, 38, 95, 134)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back,
                color: Color.fromARGB(255, 38, 95, 134)),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/plain.png',
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),
                  const Text(
                    "كل الأقسام",
                    style: TextStyle(
                      fontFamily: 'Ruqaa',
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 38, 95, 134),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => JobType(
                                  previousPageTitle: categories[index]
                                      ['previousPageTitle'],
                                ),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 35,
                                backgroundColor:
                                    const Color.fromARGB(255, 38, 95, 134),
                                child: Icon(
                                  categories[index]['icon'],
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                categories[index]['name'],
                                style: const TextStyle(
                                  fontFamily: 'Ruqaa',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color.fromARGB(255, 38, 95, 134),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class JobType extends StatelessWidget {
  final String previousPageTitle;

  const JobType({super.key, required this.previousPageTitle});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            previousPageTitle,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Ruqaa',
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 38, 95, 134),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/plain.png',
                fit: BoxFit.cover,
              ),
            ),
            FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .where('profession', isEqualTo: previousPageTitle)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('حدث خطأ أثناء جلب البيانات'));
                }

                final workers = snapshot.data!.docs;

                if (workers.isEmpty) {
                  return const Center(
                      child: Text('لا يوجد عمال لهذه الفئة حالياً'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: workers.length,
                  itemBuilder: (context, index) {
                    final worker = workers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 4,
                      color: Colors.white.withOpacity(0.9),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(worker['image_url']),
                        ),
                        title: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    workerProfileScreen(uid: worker.id),
                              ),
                            );
                          },
                          child: Text(worker['username']),
                        ),
                        subtitle: Text('الخبرة: ${worker['experience']} سنوات'),
                        trailing: Text('${worker['hourlyRate']} د/س'),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
