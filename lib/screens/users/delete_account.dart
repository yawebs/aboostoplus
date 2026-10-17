import 'package:eafind/screens/authscreen/login_screen.dart';
import 'package:eafind/services/new_auth_service.dart';
import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../const/constant.dart';

class DeleteAccount extends StatefulWidget {
  const DeleteAccount({
    Key? key,
  }) : super(key: key);

  @override
  State<DeleteAccount> createState() => _DeleteAccountState();
}

class _DeleteAccountState extends State<DeleteAccount> {
  bool _deleting = false;

  Future<void> _delete() async {
    if (_deleting) return;
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
            'Your profile, listings, saved homes, alerts and verification documents will be permanently deleted. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Delete', style: TextStyle(color: red))),
        ],
      ),
    );
    if (sure != true || !mounted) return;

    setState(() => _deleting = true);
    final error = await NewAuthService.instance.deleteAccount();
    if (!mounted) return;
    if (error != null) {
      setState(() => _deleting = false);
      showToast(error);
      return;
    }
    showToast('Your account has been deleted');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen(fromNav: false)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => goBack(context),
          child: const Icon(Icons.arrow_back),
        ),
        title: const Text('Delete My Account'),
        centerTitle: true,
      ),
      bottomSheet: Container(
        height: 120,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            appButton(
                callback: _delete,
                label: _deleting ? 'Deleting…' : 'Delete My Account',
                color: red,
                textColor: white),
            h10(),
            appButton(
                callback: () => goBack(context),
                label: 'Cancel',
                color: context.palette.primaryFill,
                textColor: white)
          ],
        ),
      ),
      body: ListView(
        children: [
          h40(),
          Column(
            children: [
              Icon(
                Icons.delete_outline_sharp,
                color: red,
                size: 40,
              ),
              h10(),
              Text(
                'Are you sure you want to ',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: context.palette.ink, fontSize: 18),
              ),
              Text(
                'delete your accounts',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: context.palette.ink, fontSize: 18),
              ),
              Text(
                'This can not be undone',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.palette.ink.withOpacity(.5),
                    fontSize: 15),
              ),
            ],
          ),
          h20(),
          ListTile(
            leading: Container(
              padding: EdgeInsets.all(8.0),
              decoration:
                  BoxDecoration(borderRadius: appRadius(100.0), color: black),
              child: Icon(
                Icons.data_array,
                size: 15,
                color: white,
              ),
            ),
            title: Text('All data and history will no longer be accessible'),
          ),
          ListTile(
            leading: Container(
              padding: EdgeInsets.all(8.0),
              decoration:
                  BoxDecoration(borderRadius: appRadius(100.0), color: black),
              child: Icon(
                Icons.person,
                size: 15,
                color: white,
              ),
            ),
            title: Text('Your profile would be permanently removed'),
          )
        ],
      ),
    );
  }

  Widget _buildWeb(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AppCard(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.delete_outline_sharp,
                          color: AppColors.error, size: 32),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Are you sure you want to delete your account?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This can not be undone',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textGrey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _webListItem(Icons.data_array,
                        'All data and history will no longer be accessible'),
                    const SizedBox(height: 10),
                    _webListItem(
                        Icons.person, 'Your profile would be permanently removed'),
                    const SizedBox(height: 28),
                    MiaButton(
                      text: _deleting ? 'Deleting…' : 'Delete my account',
                      isEnabled: !_deleting,
                      onPressed: _delete,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => goBack(context),
                      child: const Text('Cancel',
                          style: TextStyle(color: AppColors.textGrey)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _webListItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
              color: AppColors.textDark, shape: BoxShape.circle),
          child: Icon(icon, size: 15, color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
        ),
      ],
    );
  }
}
