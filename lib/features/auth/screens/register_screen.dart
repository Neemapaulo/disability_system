import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _termsAccepted = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      _snack('Tafadhali kubali Masharti na Vigezo.', error: true);
      return;
    }

    final error = await ref.read(authProvider.notifier).register(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          fullName: _nameCtrl.text.trim(),
          phoneNumber: _phoneCtrl.text.trim(),
          mkoa: 'Dar es Salaam',
          wilaya: 'Haijachaguliwa',
          secretQuestion: '',
          secretAnswer: '',
        );

    if (!mounted) return;

    if (error == null) {
      context.go(Routes.dashboard);
    } else {
      _snack(error, error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: AppColors.primaryRed,
                      onPressed: () => context.go(Routes.onboarding),
                    ),
                    const Text(
                      'PamojaMove',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryRed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Unda Akaunti Mpya',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Jaza taarifa zako kwa usahihi ili kuanza kuripoti.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),
                _label('Majina Kamili'),
                _field(
                  ctrl: _nameCtrl,
                  hint: 'Mwajuma Juma',
                  icon: Icons.person_outline,
                  valid: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Jaza jina lako kamili'
                      : null,
                ),
                const SizedBox(height: 16),
                _label('Namba ya Simu'),
                _field(
                  ctrl: _phoneCtrl,
                  hint: '0XXXXXXXXX',
                  icon: Icons.phone_outlined,
                  keyboard: TextInputType.phone,
                  valid: (v) {
                    if (v?.trim().isEmpty ?? true) return 'Jaza namba ya simu';
                    if ((v?.trim().length ?? 0) < 10) return 'Namba si sahihi';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _label('Barua Pepe'),
                _field(
                  ctrl: _emailCtrl,
                  hint: 'mfano@barua.com',
                  icon: Icons.email_outlined,
                  keyboard: TextInputType.emailAddress,
                  valid: (v) {
                    if (v?.trim().isEmpty ?? true) return 'Jaza barua pepe';
                    if (!v!.contains('@')) return 'Barua pepe si sahihi';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _label('Nenosiri'),
                _field(
                  ctrl: _passCtrl,
                  hint: '********',
                  icon: Icons.lock_outline,
                  obscure: _obscurePass,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                  valid: (v) {
                    if (v?.isEmpty ?? true) return 'Jaza nenosiri';
                    if ((v?.length ?? 0) < 8) {
                      return 'Nenosiri liwe na herufi 8 au zaidi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _termsAccepted,
                      onChanged: (v) =>
                          setState(() => _termsAccepted = v ?? false),
                      activeColor: AppColors.primaryRed,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                            children: [
                              TextSpan(text: 'Ninakubali '),
                              TextSpan(
                                text: 'Masharti na Vigezo',
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: ' vya matumizi ya PamojaMove.'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _submit,
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.arrow_forward, size: 18),
                    label: Text(
                      isLoading ? 'Inasajili...' : 'Sajili na Endelea',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primaryRed.withValues(alpha: 0.6),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: GestureDetector(
                    onTap: () => context.go(Routes.login),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: AppColors.textSecondary),
                        children: [
                          TextSpan(text: 'Tayari unayo akaunti? '),
                          TextSpan(
                            text: 'Ingia Hapa',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboard,
    String? Function(String?)? valid,
  }) =>
      TextFormField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboard,
        validator: valid,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textHint),
          prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
          suffixIcon: suffix,
          filled: true,
          fillColor: AppColors.bgLight,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.primaryBlue, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
        ),
      );
}
