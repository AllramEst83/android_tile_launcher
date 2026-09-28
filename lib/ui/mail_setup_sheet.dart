import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/mail_format.dart';
import 'package:android_tile_launcher/services/mail_service.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key mailEmailKey = ValueKey<String>('mail-email');
const Key mailServerKey = ValueKey<String>('mail-server');
const Key mailPasswordKey = ValueKey<String>('mail-password');
const Key mailConnectKey = ValueKey<String>('mail-connect');

/// What a tap on an unset-up mail tile opens: the address, the IMAP server
/// (guessed from the address) and an app password. CONNECT logs in to check
/// them and only then saves them, in the phone's keystore. Completes with
/// `true` once an account was saved.
Future<bool> showMailSetupSheet(
  BuildContext context, {
  required MailService mail,
}) async {
  final bool? saved = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: TileColors.canvas,
    isScrollControlled: true,
    // Laid out below the status bar, so the keyboard cannot push it under it.
    useSafeArea: true,
    builder: (BuildContext sheetContext) => Padding(
      // Keep the fields above the keyboard.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _MailSetup(mail: mail),
    ),
  );
  return saved ?? false;
}

class _MailSetup extends StatefulWidget {
  const _MailSetup({required this.mail});

  final MailService mail;

  @override
  State<_MailSetup> createState() => _MailSetupState();
}

class _MailSetupState extends State<_MailSetup> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _host = TextEditingController();
  final TextEditingController _password = TextEditingController();

  // Once the user has typed in the server field it is theirs: the guess from
  // the address stops overwriting it.
  bool _hostTouched = false;
  bool _busy = false;
  String? _problem;

  @override
  void dispose() {
    _email.dispose();
    _host.dispose();
    _password.dispose();
    super.dispose();
  }

  void _emailChanged(String value) {
    if (_hostTouched) return;
    _host.text = guessImapHost(value.trim());
  }

  bool get _complete =>
      _email.text.trim().isNotEmpty &&
      _host.text.trim().isNotEmpty &&
      _password.text.isNotEmpty;

  Future<void> _connect() async {
    if (!_complete || _busy) return;
    setState(() {
      _busy = true;
      _problem = null;
    });
    final String? problem = await widget.mail.setUp(
      email: _email.text.trim(),
      host: _host.text.trim(),
      // Spaces in an app password are only how it is shown (`abcd efgh ...`).
      password: _password.text.replaceAll(' ', ''),
    );
    if (!mounted) return;
    if (problem == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _busy = false;
      _problem = problem.toUpperCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TileMetrics.margin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                Messages.mailSetUpTitle,
                style: text.bodyMedium?.copyWith(color: TileColors.textBright),
              ),
              const SizedBox(height: 4),
              Container(height: 2, color: TileColors.bezel),
              const SizedBox(height: TileMetrics.gutter),
              Text(
                Messages.mailAppPasswordNote,
                style: text.bodySmall?.copyWith(
                  fontSize: 8,
                  color: TileColors.accent,
                ),
              ),
              const SizedBox(height: TileMetrics.margin),
              _Field(
                fieldKey: mailEmailKey,
                label: Messages.mailEmail,
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                onChanged: (String v) => setState(() => _emailChanged(v)),
              ),
              _Field(
                fieldKey: mailServerKey,
                label: Messages.mailServer,
                controller: _host,
                keyboardType: TextInputType.url,
                onChanged: (String _) => setState(() => _hostTouched = true),
              ),
              _Field(
                fieldKey: mailPasswordKey,
                label: Messages.mailPassword,
                controller: _password,
                obscure: true,
                onChanged: (String _) => setState(() {}),
              ),
              const SizedBox(height: TileMetrics.margin),
              InkWell(
                key: mailConnectKey,
                onTap: _complete && !_busy ? _connect : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _complete && !_busy
                          ? TileColors.textBright
                          : TileColors.textDim,
                      width: TileMetrics.bevel,
                    ),
                  ),
                  child: Text(
                    _busy ? Messages.mailChecking : Messages.mailConnect,
                    style: text.bodySmall?.copyWith(
                      fontSize: 10,
                      color: _complete && !_busy
                          ? TileColors.textBright
                          : TileColors.textDim,
                    ),
                  ),
                ),
              ),
              if (_problem != null) ...<Widget>[
                const SizedBox(height: TileMetrics.margin),
                Text(
                  _problem!,
                  style: text.bodySmall?.copyWith(
                    fontSize: 10,
                    color: TileColors.danger,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.obscure = false,
    this.keyboardType,
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool obscure;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: TileMetrics.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: text.bodySmall?.copyWith(
              fontSize: 8,
              color: TileColors.muted,
            ),
          ),
          TextField(
            key: fieldKey,
            controller: controller,
            onChanged: onChanged,
            obscureText: obscure,
            // Nothing typed here is a word to correct or to remember.
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: keyboardType,
            style: text.bodySmall?.copyWith(
              fontSize: 12,
              color: TileColors.textBright,
            ),
            cursorColor: TileColors.textBright,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 12),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: TileColors.bezel),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: TileColors.textBright),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
