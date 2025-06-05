import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_drawer.dart';
import 'search.dart';
import 'allcats.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      theme: ThemeData(
        fontFamily: 'Ruqaa',
        primaryColor: const Color.fromARGB(255, 38, 95, 134),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            fontFamily: 'Ruqaa',
            color: Color.fromARGB(255, 38, 95, 134),
          ),
          bodyLarge: TextStyle(
            fontSize: 18,
            fontFamily: 'Ruqaa',
            color: Color.fromARGB(255, 38, 95, 134),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 38, 95, 134),
            padding: const EdgeInsets.symmetric(horizontal: 29, vertical: 8),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontSize: 20,
              fontFamily: 'Ruqaa',
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _hasErrorOccurred = false;

  @override
  void initState() {
    super.initState();
    _videoController =
        VideoPlayerController.asset('assets/video/finalvideo.mp4')
          ..initialize().then((_) {
            setState(() {
              _isVideoInitialized = true;
            });
            _videoController.setLooping(true);
            _videoController.play();
          }).catchError((error) {
            setState(() {
              _hasErrorOccurred = true;
            });
            print('Error loading video: $error');
          });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      endDrawer: AppDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(
            Icons.search,
            size: 30,
            color: Color.fromARGB(255, 38, 95, 134),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const Search()),
            );
          },
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(
                Icons.menu,
                size: 30,
                color: Color.fromARGB(255, 38, 95, 134),
              ),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 70),
                  Center(child: buildVideoPlayer()),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const Allcats()),
                        );
                      },
                      child: const Text(
                        'كل الأقسام',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Ruqaa',
                          color: Color.fromARGB(255, 38, 95, 134),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        buildCircularButton(
                            "كهربجي", Icons.electrical_services, "كهربجي"),
                        buildCircularButton("دهين", Icons.format_paint, "دهين"),
                        buildCircularButton(
                            "مواسرجي", Icons.plumbing, "مواسرجي"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 120,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('ads')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                              child: Text('لا توجد إعلانات حالياً'));
                        }

                        final now = DateTime.now();
                        final ads = snapshot.data!.docs.where((doc) {
                          final startDate =
                              (doc['startdate'] as Timestamp).toDate();
                          final endDate =
                              (doc['enddate'] as Timestamp).toDate();
                          return now.isAfter(startDate) &&
                              now.isBefore(endDate);
                        }).toList();

                        if (ads.isEmpty) {
                          return const Center(
                            child: Text(
                              'لا توجد إعلانات نشطة حاليا',
                              style: TextStyle(
                                color: Color.fromARGB(255, 38, 95, 134),
                              ),
                            ),
                          );
                        }

                        return PageView.builder(
                          controller: PageController(viewportFraction: 0.85),
                          itemCount: ads.length,
                          itemBuilder: (context, index) {
                            final ad = ads[index];
                            final owner = ad['owner'] ?? '';
                            final text = ad['text'] ?? '';

                            return Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 10),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.fromARGB(255, 38, 95, 134),
                                    blurRadius: 6,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Directionality(
                                textDirection: TextDirection.rtl,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      owner,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Ruqaa',
                                        color: Color.fromARGB(255, 38, 95, 134),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      text,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontFamily: 'Ruqaa',
                                        color: Color.fromARGB(255, 38, 95, 134),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildVideoPlayer() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black,
      ),
      child: _isVideoInitialized
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: VideoPlayer(_videoController),
            )
          : _hasErrorOccurred
              ? const Center(child: Text("Error loading video"))
              : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget buildCircularButton(
      String title, IconData icon, String previousPageTitle) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    JobType(previousPageTitle: previousPageTitle),
              ),
            );
          },
          child: CircleAvatar(
            radius: 35,
            backgroundColor: Color.fromARGB(255, 38, 95, 134),
            child: Icon(icon, size: 35, color: Colors.white),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'Ruqaa',
            color: Color.fromARGB(255, 38, 95, 134),
          ),
        ),
      ],
    );
  }
}
