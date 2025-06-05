import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:first/profileworker.dart';
import 'package:flutter/material.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<Search> {
  TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> allUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserId = currentUser?.uid;

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'worker')
          .get();

      final users =
          snapshot.docs.where((doc) => doc.id != currentUserId).map((doc) {
        final data = doc.data();
        return {
          "name": data['username'] ?? 'اسم غير معروف',
          "price": data['hourlyRate'] ?? 'غير محدد',
          "rating": data['averageRating']?.toDouble() ?? 0.0,
          "uid": doc.id,
        };
      }).toList();

      setState(() {
        allUsers = users;
        filteredUsers = List.from(users);
      });
    } catch (e) {
      print("Error fetching users: $e");
    }
  }

  void clearSearch() {
    setState(() {
      searchController.clear();
      filteredUsers = List.from(allUsers);
    });
  }

  void filterResults(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredUsers = List.from(allUsers);
      } else {
        filteredUsers = allUsers
            .where((user) => user["name"]
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void filterByPrice() {
    setState(() {
      filteredUsers.sort((a, b) => double.parse(a["price"].toString())
          .compareTo(double.parse(b["price"].toString())));
    });
  }

  void filterByRating() {
    setState(() {
      filteredUsers.sort((a, b) => b["rating"].compareTo(a["rating"]));
    });
  }

  Widget buildFilterButton(String text, VoidCallback onPressed) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(
          color: Color.fromARGB(255, 38, 95, 134),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(
            color: Color.fromARGB(255, 38, 95, 134), fontFamily: 'Ruqaa'),
      ),
    );
  }

  void navigateToProfile(String workerUid) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => workerProfileScreen(uid: workerUid),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Color.fromARGB(255, 38, 95, 134),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/plain.png',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 110, left: 10, right: 10),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color.fromARGB(255, 38, 95, 134),
                    ),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Color.fromARGB(255, 38, 95, 134),
                            ),
                            onPressed: clearSearch,
                          )
                        : null,
                    hintText: "بحث ...",
                    hintStyle: const TextStyle(
                      fontFamily: 'Ruqaa',
                      color: Color.fromARGB(255, 38, 95, 134),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color.fromARGB(255, 38, 95, 134),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color.fromARGB(255, 38, 95, 134),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    hintTextDirection: TextDirection.ltr,
                  ),
                  textAlign: TextAlign.right,
                  onChanged: filterResults,
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildFilterButton("بحث حسب السعر", filterByPrice),
                    const SizedBox(width: 10),
                    buildFilterButton("بحث حسب التقييم", filterByRating),
                  ],
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        child: ListTile(
                          title: Text(
                            user["name"],
                            style: const TextStyle(
                              fontFamily: 'Ruqaa',
                              color: Color.fromARGB(255, 38, 95, 134),
                            ),
                          ),
                          subtitle: Text(
                            "السعر: ${user["price"]} | التقييم: ${user["rating"].toStringAsFixed(1)}",
                            style: const TextStyle(
                              fontFamily: 'Ruqaa',
                              color: Color.fromARGB(255, 38, 95, 134),
                            ),
                          ),
                          onTap: () => navigateToProfile(user["uid"]),
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
    );
  }
}
