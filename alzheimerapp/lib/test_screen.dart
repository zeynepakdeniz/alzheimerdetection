import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth.dart'; 
import 'dart:convert';

class TestScreen extends StatefulWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  
  TextEditingController cystatinController = TextEditingController();
  TextEditingController mmp10Controller = TextEditingController();
  TextEditingController tauController = TextEditingController();

  String diagnosis = ''; 
  String probability = '';
  bool isLoading = false; 

  // Flask API URL
  final String apiUrl = 'http://192.168.133.254:5000/predict_ensemble';
  final Auth auth = Auth(); // Firestore servisi

  
  Future<void> diagnoseAlzheimer() async {
    if (FirebaseAuth.instance.currentUser == null) {
      setState(() {
        diagnosis = "Lütfen giriş yapın.";
      });
      return;
    }

    setState(() {
      isLoading = true;
      diagnosis = '';
      probability = '';
    });

    try {
      
      final double? cystatinC = double.tryParse(cystatinController.text);
      final double? mmp10 = double.tryParse(mmp10Controller.text);
      final double? tau = double.tryParse(tauController.text);

      if (cystatinC == null || mmp10 == null || tau == null) {
        setState(() {
          diagnosis = 'Lütfen geçerli sayısal değerler girin.';
        });
        return;
      }

      // API'ye POST isteği gönderitoruz
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'Cystatin_C': cystatinC,
          'MMP10': mmp10,
          'tau': tau,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Yüzdelik güvenilirlik hesaplama
        final probabilityValue = (data['probability'][0][1] * 100).toStringAsFixed(2);

        setState(() {
          // Sonucu güncellemee
          diagnosis = data['prediction'] == 1
              ? 'Alzheimer hastalığı riski var'
              : 'Alzheimer hastalığı riski yok';
          probability = 'Güvenilirlik: $probabilityValue%';
        });

        //  Firestore'a sonucu ve kullanıcı girişlerini kaydet
        await auth.saveNumericalPredictionResult(
          prediction: data['prediction'].toString(),
          confidence: data['probability'][0][1] * 100,
          cystatinC: cystatinC,
          mmp10: mmp10,
          tau: tau,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tahmin başarıyla tamamlandı ve Firestore’a kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          diagnosis = 'API Hatası: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        diagnosis = 'Bağlantı hatası: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Ekranı'),
        backgroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Test Değerlerini Girin',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: cystatinController,
                label: 'Cystatin C',
                icon: Icons.science,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: mmp10Controller,
                label: 'MMP10',
                icon: Icons.science_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: tauController,
                label: 'Tau',
                icon: Icons.science_sharp,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: isLoading ? null : diagnoseAlzheimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'Sonuç Al',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 30),
              if (diagnosis.isNotEmpty)
                Column(
                  children: [
                    Text(
                      diagnosis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      probability,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
