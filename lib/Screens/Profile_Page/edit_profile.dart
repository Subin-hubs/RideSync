import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  final String currentName;
  const EditProfilePage({super.key, required this.currentName});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _nameCtrl = TextEditingController();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _isDark = false;
  bool _savingName = false;
  bool _savingPass = false;
  bool _hideCurrentPass = true;
  bool _hideNewPass = true;
  bool _hideConfirmPass = true;

  Color get _bg => _isDark ? const Color(0xFF0D0D12) : const Color(0xFFF4F6FB);
  Color get _surface => _isDark ? const Color(0xFF16161F) : Colors.white;
  Color get _border => _isDark ? const Color(0xFF252535) : const Color(0xFFEAECF0);
  Color get _primary => _isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1D23);
  Color get _secondary => _isDark ? const Color(0xFF7A7A90) : const Color(0xFF94A3B8);
  Color get _accent => _isDark ? const Color(0xFFCBFF3F) : const Color(0xFF6C63FF);
  Color get _inputFill => _isDark ? const Color(0xFF1C1C26) : const Color(0xFFF8F8FC);

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.currentName;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return _snack('Name cannot be empty', isError: true);
    if (name == widget.currentName) return _snack('No changes made');

    setState(() => _savingName = true);
    try {
      final uid = _auth.currentUser!.uid;
      await _firestore.collection('users').doc(uid).update({'Full_Name': name});
      if (mounted) {
        _snack('Name updated successfully');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context, true); // ✅ triggers refresh
      }
    } catch (e) {
      _snack('Failed to update name', isError: true);
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<void> _savePassword() async {
    final current = _currentPassCtrl.text.trim();
    final newPass = _newPassCtrl.text.trim();
    final confirm = _confirmPassCtrl.text.trim();

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      return _snack('Please fill all password fields', isError: true);
    }
    if (newPass.length < 6) {
      return _snack('Password must be at least 6 characters', isError: true);
    }
    if (newPass != confirm) {
      return _snack('Passwords do not match', isError: true);
    }

    setState(() => _savingPass = true);
    try {
      final user = _auth.currentUser!;
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: current,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPass);
      if (mounted) {
        _currentPassCtrl.clear();
        _newPassCtrl.clear();
        _confirmPassCtrl.clear();
        _snack('Password updated successfully');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context, true); // ✅ triggers refresh
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _snack('Current password is incorrect', isError: true);
      } else {
        _snack('Failed to update password', isError: true);
      }
    } finally {
      if (mounted) setState(() => _savingPass = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor:
      isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      color: _bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: _surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded,
                color: _primary, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Edit Profile',
            style: TextStyle(
              color: _primary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(height: 1, color: _border),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // ── Change Name Section ──
              _sectionLabel('DISPLAY NAME'),
              const SizedBox(height: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                  boxShadow: _isDark
                      ? []
                      : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _inputField(
                      controller: _nameCtrl,
                      label: 'Full Name',
                      icon: Icons.person_outline_rounded,
                      hint: 'Enter your full name',
                    ),
                    const SizedBox(height: 16),
                    _primaryButton(
                      label: 'Save Name',
                      loading: _savingName,
                      onTap: _saveName,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Change Password Section ──
              _sectionLabel('CHANGE PASSWORD'),
              const SizedBox(height: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _border),
                  boxShadow: _isDark
                      ? []
                      : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _inputField(
                      controller: _currentPassCtrl,
                      label: 'Current Password',
                      icon: Icons.lock_outline_rounded,
                      hint: 'Enter your current password',
                      obscure: _hideCurrentPass,
                      toggleObscure: () => setState(
                              () => _hideCurrentPass = !_hideCurrentPass),
                    ),
                    const SizedBox(height: 14),
                    _inputField(
                      controller: _newPassCtrl,
                      label: 'New Password',
                      icon: Icons.lock_reset_rounded,
                      hint: 'At least 6 characters',
                      obscure: _hideNewPass,
                      toggleObscure: () =>
                          setState(() => _hideNewPass = !_hideNewPass),
                    ),
                    const SizedBox(height: 14),
                    _inputField(
                      controller: _confirmPassCtrl,
                      label: 'Confirm New Password',
                      icon: Icons.check_circle_outline_rounded,
                      hint: 'Repeat your new password',
                      obscure: _hideConfirmPass,
                      toggleObscure: () => setState(
                              () => _hideConfirmPass = !_hideConfirmPass),
                    ),
                    const SizedBox(height: 16),
                    _primaryButton(
                      label: 'Update Password',
                      loading: _savingPass,
                      onTap: _savePassword,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          color: _secondary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool obscure = false,
    VoidCallback? toggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _secondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          decoration: BoxDecoration(
            color: _inputFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: TextStyle(color: _primary, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: _secondary.withOpacity(0.6), fontSize: 14),
              prefixIcon: Icon(icon, color: _accent, size: 18),
              suffixIcon: toggleObscure != null
                  ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: _secondary,
                  size: 18,
                ),
                onPressed: toggleObscure,
              )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _primaryButton({
    required String label,
    required bool loading,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isDark
                ? [const Color(0xFFCBFF3F), const Color(0xFFAAE030)]
                : [const Color(0xFF6C63FF), const Color(0xFF9B8FFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: loading
              ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _isDark ? const Color(0xFF0D0D12) : Colors.white,
            ),
          )
              : Text(
            label,
            style: TextStyle(
              color: _isDark ? const Color(0xFF0D0D12) : Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}