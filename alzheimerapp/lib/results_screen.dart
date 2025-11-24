import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

//TamEkran Görüntüleyici
class FullScreenImage extends StatelessWidget {
  final String imageBase64;

  const FullScreenImage({Key? key, required this.imageBase64}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.memory(
            base64Decode(imageBase64),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({Key? key}) : super(key: key);

  @override
  _ResultsScreenState createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<List<Map<String, dynamic>>> getResults(String type) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('results')
        .where('type', isEqualTo: type)
        .orderBy('date', descending: true)
        .snapshots()
        .handleError((error) {
      print("Firestore bağlantı hatası: $error");
    }).map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'type': data['type'] ?? 'Bilinmiyor',
          'prediction': data['prediction']?.toString() ?? 'Bilinmiyor',
          'confidence': data['confidence']?.toStringAsFixed(2) ?? '0.00',
          'imageBase64': data['imageBase64'],
          'Cystatin_C': data['Cystatin_C'],
          'MMP10': data['MMP10'],
          'Tau': data['Tau'],
          'date': (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
    });
  }

  String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Sonuçlarım",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1976D2),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Sayısal Sonuçlar'),
            Tab(icon: Icon(Icons.medical_services), text: 'MR Sonuçları'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildResultsList(type: "Sayısal"),
          _buildResultsList(type: "MR"),
        ],
      ),
    );
  }

  Widget _buildResultsList({required String type}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getResults(type),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Veri yüklenirken hata oluştu. Lütfen tekrar deneyin.",
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Henüz bir sonuç yok.",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            );
          }

          final results = snapshot.data!;
          return ListView.builder(
            itemCount: results.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemBuilder: (context, index) {
              final result = results[index];
              final prediction = result['prediction'] ?? "Bilinmiyor";
              final confidence = result['confidence'] ?? "0.00";
              final date = result['date'] as DateTime;
              final imageBase64 = result['imageBase64'];

              return _buildResultCard(
                type: type,
                prediction: prediction,
                confidence: confidence,
                date: formatDate(date),
                imageBase64: imageBase64,
                additionalData: {
                  'Cystatin_C': result['Cystatin_C'],
                  'MMP10': result['MMP10'],
                  'Tau': result['Tau'],
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildResultCard({
    required String type,
    required String prediction,
    required String confidence,
    required String date,
    String? imageBase64,
    Map<String, dynamic>? additionalData,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Icon(
                    type == "MR" ? Icons.medical_services : Icons.analytics,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    type == "MR" ? "🧠 MR Tahmini" : "📊 Sayısal Tahmin",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            Text("🔍 Tahmin: $prediction"),
            Text("✅ Güvenilirlik: $confidence%"),
            Text("📅 Tarih: $date"),
            if (type == "Sayısal") ...[
              const Divider(),
              Text("🧪 Cystatin_C: ${additionalData?['Cystatin_C']}"),
              Text("🧪 MMP10: ${additionalData?['MMP10']}"),
              Text("🧪 Tau: ${additionalData?['Tau']}"),
            ],
            if (type == "MR" && imageBase64 != null && imageBase64.isNotEmpty) ...[
              const Divider(),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImage(imageBase64: imageBase64),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.memory(
                      base64Decode(imageBase64),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
