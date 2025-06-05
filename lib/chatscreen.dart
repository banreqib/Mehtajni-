import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'profilehome.dart';
import 'profileworker.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    Key? key,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _messageController = TextEditingController();
  late User _currentUser;
  String _currentUserName = 'أنا';
  String? _otherUserImage;
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  Map<String, String> userIdToName = {};
  Map<String, String?> userIdToImage = {};

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser!;
    _loadUserData();
    _loadOtherUserData();
    _markMessagesAsRead();
    _updateUserPresence();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final sortedIds = [_currentUser.uid, widget.otherUserId]..sort();
    final generatedChatId = sortedIds.join('_');

    if (widget.chatId != generatedChatId) {
      debugPrint('chatId mismatch, using generatedChatId instead.');
    }

    final chatDoc =
        await _firestore.collection('chats').doc(generatedChatId).get();

    if (!chatDoc.exists) {
      await _firestore.collection('chats').doc(generatedChatId).set({
        'participants': sortedIds,
        'participantNames': {
          _currentUser.uid: _currentUser.displayName ?? 'مستخدم',
          widget.otherUserId: widget.otherUserName,
        },
        'lastMessage': '',
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCounts': {
          _currentUser.uid: 0,
          widget.otherUserId: 0,
        },
      });
    }

    setState(() {});

    _loadUserData();
    _loadOtherUserData();
    _markMessagesAsRead();
    _updateUserPresence();
  }

  void _updateUserPresence() async {
    await _firestore.collection('users').doc(_currentUser.uid).update({
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _loadUserData() async {
    final userDoc =
        await _firestore.collection('users').doc(_currentUser.uid).get();
    if (mounted && userDoc.exists) {
      final data = userDoc.data()!;
      setState(() {
        _currentUserName =
            data['username'] ?? _currentUser.displayName ?? 'مستخدم';
        userIdToName[_currentUser.uid] = _currentUserName;
        userIdToImage[_currentUser.uid] = data['image_url'];
      });
    }
  }

  Future<void> _loadOtherUserData() async {
    final otherUserDoc =
        await _firestore.collection('users').doc(widget.otherUserId).get();
    if (mounted && otherUserDoc.exists) {
      final data = otherUserDoc.data()!;
      setState(() {
        _otherUserImage = data['image_url'];
        userIdToName[widget.otherUserId] = data['username'] ?? 'مستخدم';
        userIdToImage[widget.otherUserId] = data['image_url'];
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final unreadMessages = await _firestore
          .collection('messages')
          .where('chatId', isEqualTo: widget.chatId)
          .where('receiverId', isEqualTo: _currentUser.uid)
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadMessages.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (var doc in unreadMessages.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();

        await _firestore.collection('chats').doc(widget.chatId).update({
          'unreadCounts.${_currentUser.uid}': 0,
        });
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_isSending || _messageController.text.trim().isEmpty) return;

    setState(() => _isSending = true);
    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      final messageData = {
        'chatId': widget.chatId,
        'senderId': _currentUser.uid,
        'receiverId': widget.otherUserId,
        'senderName': userIdToName[_currentUser.uid] ?? _currentUserName,
        'text': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'text',
      };

      await _firestore.collection('messages').add(messageData);

      await _firestore.collection('chats').doc(widget.chatId).update({
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSenderId': _currentUser.uid,
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCounts.${widget.otherUserId}': FieldValue.increment(1),
      });

      await _firestore.collection('users').doc(widget.otherUserId).update({
        'lastMessageUpdate': FieldValue.serverTimestamp(),
        'lastMessageChatId': widget.chatId,
      });
    } catch (e) {
      debugPrint('Message send error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إرسال الرسالة: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Widget _buildMessageBubble(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isMe = data['senderId'] == _currentUser.uid;
    final name =
        userIdToName[data['senderId']] ?? data['senderName'] ?? 'مستخدم';
    final image = userIdToImage[data['senderId']];
    final time = (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

    return GestureDetector(
      onLongPress: null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Ruqaa',
                    color: Color.fromARGB(255, 38, 95, 134),
                  ),
                ),
              ),
            Row(
              mainAxisAlignment:
                  isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (!isMe)
                  CircleAvatar(
                    backgroundImage: image != null ? NetworkImage(image) : null,
                    radius: 15,
                    child: image == null ? const Icon(Icons.person) : null,
                  ),
                if (!isMe) const SizedBox(width: 5),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color.fromARGB(255, 38, 95, 134)
                          : Colors.grey[300],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft:
                            isMe ? const Radius.circular(20) : Radius.zero,
                        bottomRight:
                            isMe ? Radius.zero : const Radius.circular(20),
                      ),
                    ),
                    child: Text(
                      data['text'] ?? '',
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black,
                        fontFamily: 'Ruqaa',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                DateFormat('hh:mm a').format(time),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToOtherUserProfile() async {
    try {
      final userDoc =
          await _firestore.collection('users').doc(widget.otherUserId).get();

      if (!userDoc.exists) return;

      final data = userDoc.data()!;
      final role = data['role'] ?? '';

      if (role == 'homeowner') {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileScreen(uid: widget.otherUserId),
          ),
        );
      } else if (role == 'worker') {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => workerProfileScreen(uid: widget.otherUserId),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('نوع المستخدم غير معروف')),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to user profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('خطأ في تحميل بيانات المستخدم: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesStream = _firestore
        .collection('messages')
        .where('chatId', isEqualTo: widget.chatId)
        .orderBy('timestamp', descending: true)
        .snapshots(includeMetadataChanges: true);

    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 38, 95, 134)),
        backgroundColor: Colors.white,
        elevation: 1,
        title: GestureDetector(
          onTap: _navigateToOtherUserProfile,
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: _otherUserImage != null
                    ? NetworkImage(_otherUserImage!)
                    : null,
                child:
                    _otherUserImage == null ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 10),
              Text(
                widget.otherUserName,
                style: const TextStyle(
                  fontFamily: 'Ruqaa',
                  color: Color.fromARGB(255, 38, 95, 134),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'حدث خطأ في تحميل الرسائل',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Ruqaa',
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'ابدأ المحادثة مع ${widget.otherUserName}',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Ruqaa',
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    return _buildMessageBubble(doc);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالة...',
                      hintStyle: const TextStyle(fontFamily: 'Ruqaa'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    style: const TextStyle(fontFamily: 'Ruqaa'),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: _isSending
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.send,
                          color: Color.fromARGB(255, 38, 95, 134),
                        ),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
