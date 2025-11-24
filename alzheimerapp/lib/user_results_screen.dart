import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class UserResultsScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const UserResultsScreen({
    Key? key,
    required this.userId,
    required this.userName,
  }) : super(key: key);

  
  Stream<List<Map<String, dynamic>>> getUserResults() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('results')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'type': data['type'] ?? 'Bilinmiyor',
                'prediction': data['prediction'] ?? 'Bilinmiyor',
                'confidence': data['confidence']?.toStringAsFixed(2) ?? '0.00',
                'date': (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
                'imageBase64': data['imageBase64'] ?? '',
                'Cystatin_C': data['Cystatin_C'] ?? '-',
                'MMP10': data['MMP10'] ?? '-',
                'Tau': data['Tau'] ?? '-',
              };
            }).toList());
  }

  String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$userName Sonuçları'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getUserResults(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Sonuçlar yüklenirken hata oluştu.'),
            );
          }

          final results = snapshot.data ?? [];
          if (results.isEmpty) {
            return const Center(
              child: Text('Bu kullanıcı için sonuç bulunamadı.'),
            );
          }

          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              final type = result['type'] ?? 'Bilinmiyor';
              final prediction = result['prediction'];
              final confidence = result['confidence'];
              final date = formatDate(result['date']);
              final imageBase64 = result['imageBase64'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
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
                      Text(
                        "🔍 Tahmin: $prediction",
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        "✅ Güvenilirlik: $confidence%",
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        "📅 Tarih: $date",
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (type == "Sayısal") ...[
                        const Divider(),
                        Text(
                          "🧪 Cystatin_C: ${result['Cystatin_C']}",
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          "🧪 MMP10: ${result['MMP10']}",
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          "🧪 Tau: ${result['Tau']}",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                      if (type == "MR" && imageBase64.isNotEmpty) ...[
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
                                width: double.infinity,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

//Tam Ekran Görüntüleyici
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
