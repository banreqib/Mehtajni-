import 'package:first/chatscreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  _UserSearchScreenState createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late User _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser!;
  }

  Future<void> _startChat(String otherUserId, String fallbackUserName) async {
    try {
      final participants = [_currentUser.uid, otherUserId]..sort();
      final chatId = participants.join('_');

      final otherUserDoc =
          await _firestore.collection('users').doc(otherUserId).get();
      final currentUserDoc =
          await _firestore.collection('users').doc(_currentUser.uid).get();

      if (!otherUserDoc.exists || !currentUserDoc.exists) {
        throw Exception('User not found');
      }

      final currentUserName = currentUserDoc['username'] ?? 'مستخدم';
      final currentUserImage = currentUserDoc['image_url'];
      final otherUserName = otherUserDoc['username'] ?? fallbackUserName;
      final otherUserImage = otherUserDoc['image_url'];

      final chatData = {
        'id': chatId,
        'participants': participants,
        'participantNames': {
          _currentUser.uid: currentUserName,
          otherUserId: otherUserName,
        },
        'participantImages': {
          _currentUser.uid: currentUserImage,
          otherUserId: otherUserImage,
        },
        'lastMessage': 'تم بدء المحادثة',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': _currentUser.uid,
        'unreadCounts': {
          _currentUser.uid: 0,
          otherUserId: 1,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.runTransaction((transaction) async {
        final chatDoc =
            await transaction.get(_firestore.collection('chats').doc(chatId));

        if (!chatDoc.exists) {
          transaction.set(_firestore.collection('chats').doc(chatId), chatData);
        } else {
          transaction.update(_firestore.collection('chats').doc(chatId), {
            'updatedAt': FieldValue.serverTimestamp(),
            'unreadCounts.${otherUserId}': FieldValue.increment(1),
          });
        }
      });

      await _firestore.collection('users').doc(otherUserId).update({
        'lastChatUpdate': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId,
            otherUserId: otherUserId,
            otherUserName: otherUserName,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فشل بدء المحادثة: ${e.toString()}',
            style: const TextStyle(color: Color.fromARGB(255, 38, 95, 134)),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/plain.png',
            fit: BoxFit.cover,
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(
              color: Color.fromARGB(255, 38, 95, 134),
            ),
            title: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ابحث عن مستخدم...',
                hintStyle: const TextStyle(
                  fontFamily: 'Ruqaa',
                  color: Color.fromARGB(255, 38, 95, 134),
                ),
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.clear,
                    color: Color.fromARGB(255, 38, 95, 134),
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
              style: const TextStyle(
                fontFamily: 'Ruqaa',
                color: Color.fromARGB(255, 38, 95, 134),
              ),
            ),
          ),
          body: _searchQuery.isEmpty
              ? const Center(
                  child: Text(
                    'اكتب اسم المستخدم للبحث',
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Ruqaa',
                      color: Color.fromARGB(255, 38, 95, 134),
                    ),
                  ),
                )
              : StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('users')
                      .orderBy('username')
                      .startAt([_searchQuery])
                      .endAt(['$_searchQuery\uf8ff'])
                      .limit(10)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'حدث خطأ في البحث',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Ruqaa',
                            color: Color.fromARGB(255, 38, 95, 134),
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'لا توجد نتائج',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Ruqaa',
                            color: Color.fromARGB(255, 38, 95, 134),
                          ),
                        ),
                      );
                    }

                    final filteredDocs = snapshot.data!.docs.where((doc) {
                      return doc.id != _currentUser.uid;
                    }).toList();

                    if (filteredDocs.isEmpty) {
                      return const Center(
                        child: Text(
                          'لا توجد نتائج',
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: 'Ruqaa',
                            color: Color.fromARGB(255, 38, 95, 134),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final userDoc = filteredDocs[index];
                        final userData = userDoc.data() as Map<String, dynamic>;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                NetworkImage(userData['image_url'] ?? ''),
                            child: userData['image_url'] == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(
                            userData['username'] ?? 'مستخدم',
                            style: const TextStyle(
                              fontFamily: 'Ruqaa',
                              color: Color.fromARGB(255, 38, 95, 134),
                            ),
                          ),
                          subtitle: Text(
                            userData['role'] == 'worker'
                                ? 'عامل: ${userData['profession'] ?? ''}'
                                : 'صاحب منزل',
                            style: const TextStyle(
                              fontFamily: 'Ruqaa',
                              color: Color.fromARGB(255, 38, 95, 134),
                            ),
                          ),
                          onTap: () => _startChat(
                            userDoc.id,
                            userData['username'] ?? 'مستخدم',
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
