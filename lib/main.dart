import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first/auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:first/homepage.dart';
import 'package:first/homeownerprofile.dart';
import 'package:first/workerprofile.dart';
import 'package:first/workers.dart';
import 'package:first/available_jobs.dart';
import 'package:first/postscreen.dart';
import 'package:first/user_search_screen.dart';
import 'package:first/chatscreen.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, child) {
        return const App();
      },
    ),
  );
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 0.85),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Mehtajni',
        theme: ThemeData(
          fontFamily: 'Ruqaa',
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 38, 95, 134),
          ),
        ),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (ctx, snapshot) {
            print("Auth state changed: hasData = ${snapshot.hasData}");

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData) {
              Future.microtask(() {
                Navigator.of(ctx).pushReplacementNamed('/auth');
              });
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(snapshot.data!.uid)
                  .get(),
              builder: (ctx, userSnapshot) {
                print("User doc snapshot: hasData = ${userSnapshot.hasData}");

                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }

                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  if (userData['profileCompleted'] != true) {
                    if (userData['role'] == 'worker') {
                      return WorkerProfileScreen(isInitialSetup: true);
                    } else {
                      return HomeownerProfileScreen(isInitialSetup: true);
                    }
                  }

                  return const HomeScreen();
                }

                Future.microtask(() {
                  Navigator.of(ctx).pushReplacementNamed('/auth');
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              },
            );
          },
        ),
        routes: {
          '/worker-profile': (ctx) => const WorkerProfileScreen(),
          '/homeowner-profile': (ctx) => const HomeownerProfileScreen(),
          '/worker-home': (ctx) => const HomeScreen(),
          '/homeowner-home': (ctx) => const HomeScreen(),
          '/home': (context) => const HomeScreen(),
          '/createPost': (context) => const CreatePostScreen(),
          '/workers': (context) => const Workers(),
          '/jobAvailable': (context) => const AvailableJobs(),
          '/user-search': (context) => const UserSearchScreen(),
          '/auth': (context) => const AuthScreen(),
          '/chat': (context) {
            final args = ModalRoute.of(context)!.settings.arguments
                as Map<String, dynamic>;
            final otherUserId = args['receiverId'];
            final otherUserName = args['receiverName'];

            final currentUserId = FirebaseAuth.instance.currentUser!.uid;
            final participants = [currentUserId, otherUserId]..sort();
            final chatId = participants.join('_');

            return ChatScreen(
              chatId: chatId,
              otherUserId: otherUserId,
              otherUserName: otherUserName,
            );
          },
        },
      ),
    );
  }
}
