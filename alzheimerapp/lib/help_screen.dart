import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yardım'),
        backgroundColor: const Color(0xFF1976D2),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Yardım ve Bilgilendirme',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListView(
                    children: [
                      _buildInfoCard(
                        context,
                        title: 'Alzheimer Nedir?',
                        description: 'Alzheimer hastalığı hakkında bilgi alın.',
                        icon: Icons.info,
                        color: Colors.blueAccent,
                        onTap: () async {
                          final content = await _fetchWikipediaContent("Alzheimer_hastalığı");
                          _showScrollableDialog(context, "Alzheimer Nedir", content);
                        },
                      ),
                      _buildInfoCard(
                        context,
                        title: 'Belirtiler ve Semptomlar',
                        description: 'Alzheimer hastalığının belirtilerini öğrenin.',
                        icon: Icons.warning,
                        color: Colors.orangeAccent,
                        onTap: () async {
                          final content = await _fetchWikipediaContent("Alzheimer_hastalığı#Belirtiler");
                          _showScrollableDialog(context, "Belirtiler ve Semptomlar", content);
                        },
                      ),
                      _buildInfoCard(
                        context,
                        title: 'Neden AlzAware?',
                        description: 'AlzAware uygulaması hakkında bilgi alın.',
                        icon: Icons.lightbulb,
                        color: Colors.greenAccent,
                        onTap: () {
                          _showScrollableDialog(
                            context,
                            "Neden AlzAware?",
                            "AlzAware, Alzheimer hastalığının erken tespiti için kullanıcıların testler yapabileceği bir mobil uygulamadır. "
                            "Bu uygulama, hastalığın belirtilerine dair verileri toplar, analiz eder ve kullanıcılara kendi risk durumları "
                            "hakkında bilgi sunar. Modern ve kullanıcı dostu bir arayüze sahip olan AlzAware, "
                            "Alzheimer hakkında bilinçlendirme sağlamayı hedefler.",
                          );
                        },
                      ),
                      _buildInfoCard(
                        context,
                        title: 'Daha Fazla Bilgi',
                        description: 'Alzheimer hakkında daha fazla bilgi edinin.',
                        icon: Icons.link,
                        color: Colors.purpleAccent,
                        onTap: () async {
                          final content = await _fetchWikipediaContent("Alzheimer");
                          _showScrollableDialog(context, "Daha Fazla Bilgi", content);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  
  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(description),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ),
    );
  }

  /// **Wikipedia İçeriği Getirme**
  Future<String> _fetchWikipediaContent(String searchTerm) async {
    final url = Uri.parse(
        "https://tr.wikipedia.org/w/api.php?action=query&prop=extracts&format=json&titles=$searchTerm&exintro=1&explaintext=1");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']['pages'];
        final firstPage = pages.values.first;
        return firstPage['extract'] ?? 'Bilgi bulunamadı.';
      } else {
        return 'Bilgi alınırken bir hata oluştu.';
      }
    } catch (e) {
      return 'Bilgi alınırken bir hata oluştu.';
    }
  }

 
  void _showScrollableDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat"))],
      ),
    );
  }
}
