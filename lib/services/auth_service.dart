import 'dart:io'; // نحتاجها للتعامل مع الملفات (الصور)
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // مكتبة التخزين للصور

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage =
      FirebaseStorage.instance; // تعريف الـ Storage

  // مراقبة حالة المستخدم
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // المستخدم الحالي
  User? get currentUser => _auth.currentUser;

  // ─── التحقق من قوة كلمة المرور (Regex) ───────────────────────
  bool isStrongPassword(String password) {
    // يجب أن تحتوي على: 8 أحرف على الأقل، حرف كبير، حرف صغير، رقم، ورمز خاص
    final regex = RegExp(
      r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$',
    );
    return regex.hasMatch(password);
  }

  // ─── تسجيل الدخول (معدلة لفحص الصلاحية Role) ─────────────────
  Future<UserCredential?> signIn({
    required String email,
    required String password,
    required String expectedRole, // <--- استلام نوع الحساب المتوقع من الشاشة
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    // 1. تفعيل شرط التحقق من الإيميل ومنع الدخول بدونه
    if (!credential.user!.emailVerified) {
      await _auth.signOut(); // تسجيل خروج فوري
      throw FirebaseAuthException(
        code: 'email-not-verified',
      ); // إرسال الخطأ للشاشة
    }

    // 2. جلب بيانات المستخدم من Firestore لفحص الـ Role
    DocumentSnapshot userDoc = await _firestore
        .collection('users')
        .doc(credential.user!.uid)
        .get();

    if (userDoc.exists) {
      String actualRole = userDoc.get('role') ?? '';

      // 3. مقارنة الـ Role الفعلي بالـ Role المتوقع من الشاشة
      if (actualRole != expectedRole) {
        await _auth.signOut(); // تسجيل خروج فوري
        throw FirebaseAuthException(code: 'wrong-role'); // رمي خطأ الصلاحية
      }
    } else {
      // في حال الحساب موجود بالـ Auth ومش موجود بالـ Firestore
      await _auth.signOut();
      throw FirebaseAuthException(code: 'user-not-found');
    }

    return credential;
  }

  // ─── دالة رفع الصور إلى Firebase Storage ────────────────────
  Future<String> uploadImage(
    File imageFile,
    String folderName,
    String userId,
  ) async {
    // إنشاء مسار للصورة: folderName/userId_timestamp.jpg
    String fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference ref = _storage.ref().child(folderName).child(fileName);

    // رفع الملف
    UploadTask uploadTask = ref.putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask;

    // إرجاع رابط الصورة (URL) بعد رفعها
    return await snapshot.ref.getDownloadURL();
  }

  // ─── إنشاء حساب جديد (للعميل العادي مع صورة شخصية) ───────────
  Future<UserCredential?> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    File? profileImage, // استقبال الصورة الشخصية للعميل (اختيارية)
  }) async {
    // 1. فحص قوة كلمة المرور قبل إرسالها للفايربيس
    if (!isStrongPassword(password)) {
      throw FirebaseAuthException(code: 'weak-password-regex');
    }

    // 2. إنشاء الحساب في Firebase Auth
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    try {
      // 3. إرسال إيميل التفعيل للمستخدم
      await credential.user!.sendEmailVerification();

      String uid = credential.user!.uid;
      String profileImageUrl = '';

      // 4. إذا العميل رفع صورة، بنرفعها على الـ Storage ونأخذ الرابط
      if (profileImage != null) {
        profileImageUrl = await uploadImage(
          profileImage,
          'customer_profiles',
          uid,
        );
      }

      // 5. حفظ البيانات في Firestore مع رابط الصورة الشخصية
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': role,
        'profileImageUrl': profileImageUrl,
        'preferredLang': 'ar',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      await credential.user?.delete();
      rethrow;
    }

    return credential;
  }

  // ─── استعادة كلمة المرور (إرسال إيميل إعادة التعيين) ───────────────
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ─── إنشاء حساب جديد (لصاحب الورشة مع إثباتات) ───────────────
  Future<UserCredential?> registerWorkshop({
    required String name,
    required String email,
    required String password,
    required String phone,
    required File licenseImage, // صورة رخصة المهن
    required File shopImage, // صورة واجهة المحل
  }) async {
    if (!isStrongPassword(password)) {
      throw FirebaseAuthException(code: 'weak-password-regex');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password.trim(),
    );

    try {
      // إرسال إيميل التفعيل
      await credential.user!.sendEmailVerification();

      String uid = credential.user!.uid;

      // رفع الصور للـ Storage واستلام الروابط
      String licenseUrl = await uploadImage(
        licenseImage,
        'workshop_licenses',
        uid,
      );
      String shopImageUrl = await uploadImage(
        shopImage,
        'workshop_images',
        uid,
      );

      // حفظ بيانات الورشة في Firestore مع الروابط وحالة "قيد المراجعة"
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': 'workshop',
        'status': 'pending', // <--- أهم نقطة: الحساب مش مفعل فوراً
        'licenseImageUrl': licenseUrl,
        'shopImageUrl': shopImageUrl,
        'preferredLang': 'ar',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // في حال فشل رفع الصور أو قاعدة البيانات، نحذف الحساب
      await credential.user?.delete();
      rethrow;
    }

    return credential;
  }

  // ─── تسجيل الخروج ───────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─── جلب بيانات المستخدم ─────────────────────────────────────
  Future<DocumentSnapshot> getUserData(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
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
        return 'كلمة السر ضعيفة جداً من قبل النظام';
      case 'weak-password-regex':
        return 'يجب أن تحتوي كلمة السر على 8 أحرف، حرف كبير، رقم، ورمز خاص (!@#\$)';
      case 'email-not-verified':
        return 'يرجى تأكيد بريدك الإلكتروني أولاً لتتمكن من الدخول';
      case 'wrong-role': // <--- الخطأ الجديد لمنع التداخل
        return 'هذا الحساب غير مصرح له بالدخول من هنا، يرجى استخدام شاشة الدخول الصحيحة';
      case 'invalid-email':
        return 'صيغة الإيميل غلط';
      case 'network-request-failed':
        return 'تحقق من الاتصال بالإنترنت';
      default:
        return 'صار خطأ، حاول مرة ثانية';
    }
  }
}
