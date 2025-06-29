import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Rx<User?> _user = Rx<User?>(null);

  User? get user => _user.value;

  bool get isAuthenticated => _user.value != null;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final RxBool isLogin = true.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _user.bindStream(_auth.authStateChanges());
  }

  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      Get.snackbar(
        'Authentication Error',
        'Failed to sign in: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<bool> createUserWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      Get.snackbar(
        'Authentication Error',
        'Failed to create account: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> handleAuth() async {
    isLoading.value = true;

    final authController = Get.find<AuthController>();

    if (isLogin.value) {
      await authController.signInWithEmailAndPassword(
        emailController.text.trim(),
        passwordController.text,
      );
    } else {
      await authController.createUserWithEmailAndPassword(
        emailController.text.trim(),
        passwordController.text,
      );
    }

    isLoading.value = false;
  }
}
