import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'results_screen.dart';
import 'personal_info_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? userName = "";
  String? userEmail = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  /// Kullanıcı Bilgilerini Firestore'dan Al
  Future<void> _getUserInfo() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          userName = doc['name'] as String? ?? "Bilinmiyor";
          userEmail = doc['email'] as String? ?? "Bilinmiyor";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        userName = "Hata oluştu";
        userEmail = "Hata oluştu";
        isLoading = false;
      });
    }
  }

  // Oturumdan Çıkış Yap
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
        backgroundColor: const Color(0xFF1976D2),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  _buildProfileHeader(),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.count(
                      padding: const EdgeInsets.all(16),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildSquareButton(
                          label: "KİŞİSEL BİLGİLER",
                          icon: Icons.info_outline,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const PersonalInfoScreen()),
                            );
                          },
                        ),
                        _buildSquareButton(
                          label: "SONUÇLARIM",
                          icon: Icons.analytics,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const ResultsScreen()),
                            );
                          },
                        ),
                        _buildSquareButton(
                          label: "PROFİLİ DÜZENLE",
                          icon: Icons.edit,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const EditProfileScreen()),
                            );
                          },
                        ),
                        _buildSquareButton(
                          label: "ÇIKIŞ YAP",
                          icon: Icons.logout,
                          onTap: _signOut,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Profil Üst Bilgisi
  Widget _buildProfileHeader() {
    return Column(
      children: [
        const CircleAvatar(
          radius: 60,
          backgroundColor: Colors.white,
          child: Icon(
            Icons.person,
            size: 70,
            color: Color(0xFF1976D2),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          userName ?? "Bilinmiyor",
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          userEmail ?? "Bilinmiyor",
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  /// Kare Buton
  Widget _buildSquareButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: const Color(0xFF1976D2)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1976D2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
