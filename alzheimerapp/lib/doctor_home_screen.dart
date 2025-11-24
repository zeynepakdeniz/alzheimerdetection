import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'user_results_screen.dart';
import 'chatbot_screen.dart';  // ChatbotScreen'i import ettik

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({Key? key}) : super(key: key);

  @override
  _DoctorHomeScreenState createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  String searchQuery = ""; // Arama metnini tutacak değişken

  ///  **Çıkış Yap Fonksiyonu**
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      print("Çıkış yapılırken hata oluştu: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Çıkış yapılırken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  ///  **Kullanıcıları Getirme**
  Stream<List<Map<String, dynamic>>> getUsers() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'user') // Sadece kullanıcı rolleri
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'uid': doc.id,
                'name': data['name'] ?? 'Bilinmiyor',
                'email': data['email'] ?? 'Bilinmiyor',
              };
            }).toList());
  }

  ///  **Kullanıcı Sonuçlarını Göster**
  void navigateToUserResults(String userId, String userName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserResultsScreen(userId: userId, userName: userName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Doktor Paneli'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: signOut,
              tooltip: 'Çıkış Yap',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Kullanıcı ara...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value.toLowerCase(); // Arama metnini güncelle
                  });
                },
              ),
            ),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              // Chatbot'a gitmek için buton ekledik
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatbotScreen()),  // Chatbot ekranına yönlendiriyoruz
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Chatbot ile Konuş',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(  // Kullanıcılar listesi
                  stream: getUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.white));
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          "Kullanıcılar yüklenirken hata oluştu.",
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final users = snapshot.data ?? [];
                    if (users.isEmpty) {
                      return const Center(
                        child: Text(
                          "Hiç kullanıcı bulunamadı.",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      );
                    }

                    // Arama metnine göre kullanıcıları filtrele
                    final filteredUsers = users.where((user) {
                      final name = user['name'].toString().toLowerCase();
                      return name.contains(searchQuery);
                    }).toList();

                    if (filteredUsers.isEmpty) {
                      return const Center(
                        child: Text(
                          "Eşleşen kullanıcı bulunamadı.",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredUsers.length,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(
                              user['name'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(user['email']),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () => navigateToUserResults(user['uid'], user['name']),
                          ),
                        );
                      },
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
