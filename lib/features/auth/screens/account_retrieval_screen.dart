import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class AccountRetrievalScreen extends ConsumerStatefulWidget {
  const AccountRetrievalScreen({super.key});

  @override
  ConsumerState<AccountRetrievalScreen> createState() => _AccountRetrievalScreenState();
}

class _AccountRetrievalScreenState extends ConsumerState<AccountRetrievalScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _answerCtrl = TextEditingController();
  
  bool _isLoading = false;
  String? _result;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final authSvc = ref.read(authServiceProvider);
    final msg = await authSvc.retrieveAccount(
      fullName:     _nameCtrl.text.trim(),
      phoneNumber:  _phoneCtrl.text.trim(),
      secretAnswer: _answerCtrl.text.trim(),
    );

    setState(() {
      _isLoading = false;
      _result    = msg;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      appBar: AppBar(
        title: const Text('Rejesha Akaunti', 
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sahau Taarifa?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Jaza taarifa zako hapa chini ili kupata barua pepe ya akaunti yako.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),

              _label('Majina Kamili'),
              _field(ctrl: _nameCtrl, hint: 'Mwajuma Juma', icon: Icons.person_outline),
              const SizedBox(height: 20),

              _label('Namba ya Simu'),
              _field(ctrl: _phoneCtrl, hint: '0XXXXXXXXX', icon: Icons.phone_outlined, keyboard: TextInputType.phone),
              const SizedBox(height: 20),

              _label('Jibu la Swali la Siri'),
              _field(ctrl: _answerCtrl, hint: 'Jibu lako...', icon: Icons.help_outline),
              const SizedBox(height: 32),

              if (_result != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _result!.contains('Tayari') 
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _result!.contains('Tayari') 
                          ? AppColors.success 
                          : AppColors.error
                    ),
                  ),
                  child: Text(
                    _result!,
                    style: TextStyle(
                      color: _result!.contains('Tayari') 
                          ? AppColors.success 
                          : AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Kagua Taarifa', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
  );

  Widget _field({required TextEditingController ctrl, required String hint, required IconData icon, TextInputType? keyboard}) =>
      TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        validator: (v) => (v?.isEmpty ?? true) ? 'Jaza uwanja huu' : null,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          filled: true,
          fillColor: AppColors.bgLight,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}
