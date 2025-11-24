import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class MrDiagnosisScreen extends StatefulWidget {
  const MrDiagnosisScreen({Key? key}) : super(key: key);

  @override
  _MrDiagnosisScreenState createState() => _MrDiagnosisScreenState();
}

class _MrDiagnosisScreenState extends State<MrDiagnosisScreen> {
  File? _imageFile;
  String diagnosis = "Henüz bir tahmin yapılmadı.";
  bool isLoading = false;

  final ImagePicker _picker = ImagePicker();
  final Auth auth = Auth();
  final TextEditingController _urlController = TextEditingController();

  
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        final file = File(pickedFile.path);

        final fileSize = await file.length();
        if (fileSize > 5 * 1024 * 1024) {
          setState(() {
            diagnosis = "Dosya boyutu çok büyük. Lütfen 5 MB'dan küçük bir dosya yükleyin.";
          });
          return;
        }

        setState(() {
          _imageFile = file;
          diagnosis = "Görüntü yüklendi, tahmin için gönderiliyor...";
        });

        await _uploadImage();
      }
    } catch (e) {
      setState(() {
        diagnosis = "Görüntü seçilirken hata oluştu: $e";
      });
    }
  }

  //Flask API'ye Görüntü Gönderme Fonksiyonu
  Future<void> _uploadImage() async {
    if (FirebaseAuth.instance.currentUser == null) {
      setState(() {
        diagnosis = "Lütfen giriş yapın.";
      });
      return;
    }

    if (_imageFile == null) {
      setState(() {
        diagnosis = "Lütfen bir görüntü seçin veya çekin.";
      });
      return;
    }

    setState(() {
      isLoading = true;
      diagnosis = "Görüntü işleniyor, lütfen bekleyin...";
    });

    try {
      final uri = Uri.parse('http://192.168.133.254:5000/predict_alzheimer');
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);

        setState(() {
          diagnosis =
              "Sonuç: ${data['prediction']}\nGüvenilirlik: ${data['confidence'].toStringAsFixed(2)}%";
        });

        // Resmi Base64 formatına dönüştür ve kaydet
        final base64Image = _convertImageToBase64(_imageFile!);

        await auth.saveMrPredictionResult(
          prediction: data['prediction'],
          confidence: data['confidence'],
          imageBase64: base64Image,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tahmin başarıyla tamamlandı ve Firestore’a kaydedildi!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          diagnosis = "API Hatası: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        diagnosis = "Bağlantı hatası: $e";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  //Resmi Base64 Formatına Dönüştür
  String _convertImageToBase64(File imageFile) {
    try {
      List<int> imageBytes = imageFile.readAsBytesSync();
      return base64Encode(imageBytes);
    } catch (e) {
      print(" Resim Base64 formatına dönüştürülürken hata oluştu: $e");
      return "";
    }
  }

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MRI Görüntüsü Teşhis"),
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
            colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "MR GÖRÜNTÜNÜ ÇEK/YÜKLE",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.camera_alt,
                        label: "Kamera",
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                      _buildActionButton(
                        icon: Icons.image,
                        label: "Galeri",
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildUrlInput(),
                  const SizedBox(height: 30),
                  Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.file(
                              _imageFile!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(Icons.image, size: 80, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            diagnosis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  
  Widget _buildUrlInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: "Resim URL'si",
              labelStyle: TextStyle(color: Colors.white),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              String url = _urlController.text;
              if (url.isNotEmpty) {
                await _pickImageFromUrl(url);
              } else {
                setState(() {
                  diagnosis = "Lütfen geçerli bir URL girin.";
                });
              }
            },
            child: const Text("URL'den Resim Yükle"),
          ),
        ],
      ),
    );
  }

  /// URL'den resim yükleme fonksiyonu
  Future<void> _pickImageFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final downloadedFile = await _downloadImageFromUrl(url);
        setState(() {
          diagnosis = "Resim URL'den yüklendi, tahmin için gönderiliyor...";
          _imageFile = downloadedFile;
        });
        await _uploadImage();
      } else {
        setState(() {
          diagnosis = "URL'den resim alınırken hata oluştu.";
        });
      }
    } catch (e) {
      setState(() {
        diagnosis = "Bağlantı hatası: $e";
      });
    }
  }

  // URL'den resim indirme ve dosyaya kaydetme fonksiyonu
  Future<File> _downloadImageFromUrl(String url) async {
    var response = await http.get(Uri.parse(url));
    var bytes = response.bodyBytes;
    String dir = (await getTemporaryDirectory()).path;
    File file = File('$dir/temp_image.jpg');
    await file.writeAsBytes(bytes);
    return file;
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40),
          child: CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(icon, size: 40, color: Colors.blue),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.white)),
      ],
    );
  }
}
