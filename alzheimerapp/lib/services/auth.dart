import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Auth {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _firebaseAuth.currentUser;
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  ///  **Kullanıcı Oluşturma (Kayıt)**
  Future<void> createUser({
    required String email,
    required String password,
    required String name,
    required int age,
    required String gender,
    String role = 'user',
  }) async {
    try {
      UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'name': name,
          'email': email,
          'age': age,
          'gender': gender,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        });
        print("✅ Kullanıcı başarıyla oluşturuldu.");
      }
    } catch (e) {
      print("❌ Error creating user: $e");
      throw Exception("❌ Kullanıcı oluşturulurken hata oluştu: $e");
    }
  }

  ///  MR Sonuçlarını Kaydet
  Future<void> saveMrPredictionResult({
    required String prediction,
    required double confidence,
    String? imageBase64,
  }) async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) {
        throw Exception("❌ Kullanıcı oturum açmamış.");
      }

      final resultData = {
        'type': "MR",
        'prediction': prediction,
        'confidence': confidence,
        'imageBase64': imageBase64 ?? '',
        'date': Timestamp.now(),
        'userId': uid,
        'userName': currentUser?.displayName ?? 'Bilinmeyen Kullanıcı',
      };

      // Kullanıcının hesabına sonucu kaydet
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('results')
          .add(resultData);

      // Doktorların hesabına sonucu kaydet
      final doctorRef = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();

      for (var doctor in doctorRef.docs) {
        await _firestore
            .collection('users')
            .doc(doctor.id)
            .collection('results')
            .add(resultData);
      }

      print("✅ MR tahmini başarıyla kaydedildi ve doktor hesabına eklendi.");
    } catch (e) {
      print("❌ MR sonucu kaydedilirken hata oluştu: $e");
      throw Exception("❌ MR sonucu kaydedilirken hata oluştu: $e");
    }
  }

  ///  Sayısal Sonuçları Kaydet
  Future<void> saveNumericalPredictionResult({
    required String prediction,
    required double confidence,
    required double cystatinC,
    required double mmp10,
    required double tau,
  }) async {
    try {
      final uid = currentUser?.uid;
      if (uid == null) {
        throw Exception("❌ Kullanıcı oturum açmamış.");
      }

      final resultData = {
        'type': "Sayısal",
        'prediction': prediction,
        'confidence': confidence,
        'Cystatin_C': cystatinC,
        'MMP10': mmp10,
        'Tau': tau,
        'date': Timestamp.now(),
        'userId': uid,
        'userName': currentUser?.displayName ?? 'Bilinmeyen Kullanıcı',
      };

      // Kullanıcının hesabına sonucu kaydet
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('results')
          .add(resultData);

      // Doktorların hesabına sonucu kaydet
      final doctorRef = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get();

      for (var doctor in doctorRef.docs) {
        await _firestore
            .collection('users')
            .doc(doctor.id)
            .collection('results')
            .add(resultData);
      }

      print("✅ Sayısal tahmin başarıyla kaydedildi ve doktor hesabına eklendi.");
    } catch (e) {
      print("❌ Sayısal sonuç kaydedilirken hata oluştu: $e");
      throw Exception("❌ Sayısal sonuç kaydedilirken hata oluştu: $e");
    }
  }

  ///  Kullanıcı Çıkış Yapma
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      print("✅ Kullanıcı başarıyla çıkış yaptı.");
    } catch (e) {
      print("❌ Çıkış yapılırken hata oluştu: $e");
      throw Exception("❌ Çıkış yapılırken hata oluştu: $e");
    }
  }
}
