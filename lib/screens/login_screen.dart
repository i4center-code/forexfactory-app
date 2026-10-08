import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/api_scope.dart';

/// Login / register form. Used inside the "حساب" tab.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _username = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    for (final c in [_email, _password, _name, _username]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final api = ApiScope.read(context);
    try {
      if (_register) {
        await api.register(
          email: _email.text,
          password: _password.text,
          name: _name.text,
          username: _username.text,
        );
      } else {
        await api.login(_email.text, _password.text);
      }
      // AccountScreen rebuilds into the profile view via ApiScope.
    } on ApiException catch (e) {
      setState(() => _error = e.displayMessage);
    } catch (_) {
      setState(() => _error = 'ارتباط برقرار نشد. دوباره تلاش کنید.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setMode(bool register) {
    if (_busy || _register == register) return;
    setState(() {
      _register = register;
      _error = null;
    });
  }

  Widget _tab(String label, bool register) {
    final p = context.pal;
    final sel = _register == register;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _setMode(register),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: sel ? p.primary : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: sel ? Colors.white : AppInk.muted)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppInk.line),
              boxShadow: [BoxShadow(color: p.primary.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [p.primary, p.secondary]),
                      ),
                      child: Image.asset('assets/branding/forex-logo.png'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('فارکس فکتوری ایران', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: p.primary)),
                  const SizedBox(height: 4),
                  Text(_register ? 'یک حساب جدید بسازید' : 'به حساب خود وارد شوید', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5, color: AppInk.muted)),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: p.tint, borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [_tab('ورود', false), _tab('ثبت‌نام', true)]),
                  ),
                  const SizedBox(height: 18),
                  if (_register) ...[
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'نام (اختیاری)', prefixIcon: Icon(Icons.badge_outlined)),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _username,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(labelText: 'نام کاربری (اختیاری)', prefixIcon: Icon(Icons.alternate_email_rounded)),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(labelText: 'ایمیل', prefixIcon: Icon(Icons.mail_outline_rounded)),
                    validator: (v) => (v == null || !v.contains('@')) ? 'ایمیل معتبر وارد کنید' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    textDirection: TextDirection.ltr,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'رمز عبور',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < (_register ? 8 : 1))
                        ? (_register ? 'حداقل ۸ کاراکتر' : 'رمز عبور را وارد کنید')
                        : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                      child: Text(_error!, style: TextStyle(fontSize: 12.5, color: Theme.of(context).colorScheme.error), textAlign: TextAlign.center),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_register ? 'ثبت‌نام' : 'ورود'),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _busy ? null : () => _setMode(!_register),
                    child: Text(_register ? 'حساب دارید؟ وارد شوید' : 'حساب ندارید؟ ثبت‌نام کنید'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
