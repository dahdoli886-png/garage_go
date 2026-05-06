import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // مراقبة حالة المستخدم
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // المستخدم الحالي
  User? get currentUser => _auth.currentUser;

  // ─── تسجيل الدخول ───────────────────────────────────────────
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );
    return credential;
  }

  // ─── إنشاء حساب جديد ────────────────────────────────────────
  Future<UserCredential?> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    // 1. إنشاء الحساب في Firebase Auth
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    try {
      // 2. حفظ البيانات في Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': role,
        'preferredLang': 'ar',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // إذا فشل الحفظ في الداتابيز، نحذف الحساب عشان ما يصير معلق
      await credential.user?.delete();
      rethrow; // تمرير الخطأ للـ Provider عشان يظهره للمستخدم
    }

    return credential;
  }

  // ─── تسجيل الخروج ───────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─── ترجمة أكواد الخطأ ──────────────────────────────────────
  String getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'لا يوجد حساب بهاد الإيميل';
      case 'wrong-password':
        return 'كلمة السر غلط';
      case 'email-already-in-use':
        return 'الإيميل مسجّل مسبقاً';
      case 'weak-password':
        return 'كلمة السر ضعيفة، لازم تكون 6 أحرف على الأقل';
      case 'invalid-email':
        return 'صيغة الإيميل غلط';
      case 'network-request-failed':
        return 'تحقق من الاتصال بالإنترنت';
      default:
        return 'صار خطأ، حاول مرة ثانية';
    }
  }
}