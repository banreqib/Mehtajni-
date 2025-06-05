import 'package:first/chatscreen.dart';
import 'package:first/user_search_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    if (_currentUser != null) {
      _updateUserLastSeen();
    }

    _firestore
        .collection('users')
        .doc(_currentUser!.uid)
        .snapshots()
        .listen((snap) {
      if (snap.data()?['lastMessageUpdate'] != null && mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _updateUserLastSeen() async {
    if (_currentUser == null) return;
    await _firestore.collection('users').doc(_currentUser!.uid).update({
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _markMessagesAsRead(String chatId) async {
    if (_currentUser == null) return;
    try {
      final unreadMessages = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: chatId)
          .where('senderId', isNotEqualTo: _currentUser!.uid)
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadMessages.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in unreadMessages.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }

      await _firestore.collection('chats').doc(chatId).update({
        'unreadCounts.${_currentUser!.uid}': 0,
      });
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Stream<QuerySnapshot> get _chatsStream {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: _currentUser!.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots(includeMetadataChanges: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/plain.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Text(
                  'المحادثات',
                  style: TextStyle(
                    fontFamily: 'Ruqaa',
                    color: Color.fromARGB(255, 38, 95, 134),
                    fontSize: 24,
                  ),
                ),
                iconTheme: const IconThemeData(
                  color: Color.fromARGB(255, 38, 95, 134),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    color: const Color.fromARGB(255, 38, 95, 134),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserSearchScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      debugPrint('Chat List Error: ${snapshot.error}');
                      return Center(
                          child: Text('حدث خطأ في تحميل المحادثات',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'Ruqaa',
                                  color: Colors.grey[600])));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                          child: Text('لا توجد محادثات',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontFamily: 'Ruqaa',
                                  color: Colors.grey[600])));
                    }

                    final chats = snapshot.data!.docs;

                    return RefreshIndicator(
                      onRefresh: () async {
                        setState(() {});
                        return Future.delayed(const Duration(seconds: 1));
                      },
                      child: ListView.builder(
                        itemCount: chats.length,
                        itemBuilder: (context, index) {
                          final chatDoc = chats[index];
                          final chatData =
                              chatDoc.data() as Map<String, dynamic>;
                          final participants =
                              List<String>.from(chatData['participants'] ?? []);

                          if (participants.length != 2 ||
                              !participants.contains(_currentUser!.uid)) {
                            return const SizedBox.shrink();
                          }

                          final otherUserId = participants.firstWhere(
                            (id) => id != _currentUser!.uid,
                            orElse: () => '',
                          );

                          if (otherUserId.isEmpty)
                            return const SizedBox.shrink();

                          final sortedParticipants = [
                            otherUserId,
                            _currentUser!.uid
                          ]..sort();
                          final correctChatId = sortedParticipants.join('_');

                          final unreadCount = (chatData['unreadCounts']
                                  ?[_currentUser!.uid] ??
                              0) as int;

                          return FutureBuilder<DocumentSnapshot>(
                            future: _firestore
                                .collection('users')
                                .doc(otherUserId)
                                .get(),
                            builder: (context, userSnapshot) {
                              String otherUserName = 'مستخدم';
                              if (userSnapshot.connectionState ==
                                      ConnectionState.done &&
                                  userSnapshot.hasData) {
                                final userData = userSnapshot.data!.data()
                                    as Map<String, dynamic>;
                                otherUserName =
                                    userData['username'] ?? 'مستخدم';
                              }

                              return Dismissible(
                                key: Key(chatDoc.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(Icons.delete,
                                      color: Colors.white),
                                ),
                                onDismissed: (direction) => _firestore
                                    .collection('chats')
                                    .doc(chatDoc.id)
                                    .delete(),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundImage: NetworkImage(
                                      chatData['participantImages']
                                              ?[otherUserId] ??
                                          '',
                                    ),
                                    child: (chatData['participantImages']
                                                ?[otherUserId] ==
                                            null)
                                        ? const Icon(Icons.person)
                                        : null,
                                  ),
                                  title: Text(
                                    otherUserName,
                                    style: const TextStyle(
                                      fontFamily: 'Ruqaa',
                                      color: Color.fromARGB(255, 38, 95, 134),
                                    ),
                                  ),
                                  subtitle: Text(
                                    chatData['lastMessage']?.toString() ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Ruqaa',
                                      color: Color.fromARGB(255, 38, 95, 134),
                                    ),
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (chatData['lastMessageTime'] != null)
                                        Text(
                                          DateFormat('hh:mm a').format(
                                              chatData['lastMessageTime']
                                                  .toDate()),
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                      if (unreadCount > 0)
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color.fromARGB(
                                                255, 38, 95, 134),
                                          ),
                                          child: Text(
                                            unreadCount.toString(),
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
                                          ),
                                        ),
                                    ],
                                  ),
                                  onTap: () async {
                                    await _markMessagesAsRead(correctChatId);

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ChatScreen(
                                          chatId: correctChatId,
                                          otherUserId: otherUserId,
                                          otherUserName: otherUserName,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
