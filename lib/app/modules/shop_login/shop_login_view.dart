import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_retail/app/routes/app_pages.dart';
import './shop_login_controller.dart';

class ShopLoginView extends GetView<ShopLoginController> {
  const ShopLoginView({super.key});

  MaterialColor _getColorForRole(String role) {
    if (role == 'Merchant') {
      return Colors.blue;
    }
    return Colors.orange;
  }

  IconData _getIconForRole(String role) {
    if (role == 'Merchant') {
      return Icons.business_center_rounded;
    }
    return Icons.badge_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final color = _getColorForRole(controller.selectedRole.value);

      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.shade50, Colors.white],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: controller.formKey,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 450.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Back button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: () =>
                                  Get.offAllNamed(Routes.CUSTOMER_INTRO),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Icon
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color, color.shade700],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              _getIconForRole(controller.selectedRole.value),
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Title
                          Text(
                            'Shop Login',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: color.shade900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter your credentials to continue',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 50),

                          // Form Card
                          Container(
                            padding: const EdgeInsets.all(28.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Role Selector
                                DropdownButtonFormField<String>(
                                  initialValue: controller.selectedRole.value,
                                  decoration: InputDecoration(
                                    labelText: 'Login as',
                                    hintText: 'Select your role',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: color,
                                        width: 2,
                                      ),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.person_outline,
                                      color: color,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  items: ['Merchant', 'Staff']
                                      .map(
                                        (role) => DropdownMenuItem(
                                          value: role,
                                          child: Text(role),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      controller.selectedRole.value = value;
                                    }
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Shop ID Field
                                TextFormField(
                                  controller: controller.shopIdController,
                                  decoration: InputDecoration(
                                    labelText: 'Shop ID',
                                    hintText: 'Enter your shop ID',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: color,
                                        width: 2,
                                      ),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.store_outlined,
                                      color: color,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  validator: (value) => value!.isEmpty
                                      ? 'Please enter Shop ID'
                                      : null,
                                ),
                                const SizedBox(height: 20),

                                // Email Field
                                TextFormField(
                                  controller: controller.emailController,
                                  decoration: InputDecoration(
                                    labelText: 'Email',
                                    hintText: 'Enter your email',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: color,
                                        width: 2,
                                      ),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.email_outlined,
                                      color: color,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!GetUtils.isEmail(value)) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // Password Field
                                TextFormField(
                                  controller: controller.passwordController,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: 'Enter your password',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: color,
                                        width: 2,
                                      ),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: color,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                  obscureText: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 32),

                                // Login Button
                                Obx(
                                  () => ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: color,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 3,
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: controller.isLoading.value
                                        ? null
                                        : controller.login,
                                    child: controller.isLoading.value
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3.0,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Text('Login'),
                                              SizedBox(width: 8),
                                              Icon(
                                                Icons.arrow_forward,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

