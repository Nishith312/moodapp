import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mood_demo/controller/auth_controller.dart';

class LoginScreen extends StatelessWidget {
  final controller = Get.find<AuthController>();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mood Tracker')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mood, size: 80, color: Colors.blue),
            SizedBox(height: 32),
            TextField(
              controller: controller.emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: controller.passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Obx(
                () => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.handleAuth,
                  child: controller.isLoading.value
                      ? CircularProgressIndicator()
                      : Obx(() => Text(controller.isLogin.value ? 'Login' : 'Sign Up')),
                ),
              ),
            ),
            Obx(
              () => TextButton(
                onPressed: () => controller.isLogin.value = !controller.isLogin.value,
                child: Text(
                  controller.isLogin.value
                      ? 'Don\'t have an account? Sign up'
                      : 'Already have an account? Login',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
