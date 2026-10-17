import 'package:eafind/theme/app_palette.dart';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eafind/models/user_model.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/screens/agents/bank_list.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../const/constant.dart';

class BankDetails extends StatefulWidget {
  const BankDetails({Key? key}) : super(key: key);

  @override
  State<BankDetails> createState() => _BankDetailsState();
}

class _BankDetailsState extends State<BankDetails> {
  String selectedBank = 'Bank Name';
  var _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? bankName, accountName, accountNumber;
  List<String> banks = ['First Bank', 'Access Bank', 'FCMB', 'Ecobank', 'GTB'];
  UserModel? onlineUser;
  getUser() {
    setState(() {
      onlineUser =
          Provider.of<UsermodelProvider>(context, listen: false).getUserModel();
    });
  }

  submitForm() async {
    UserModel? _userModel =
        Provider.of<UsermodelProvider>(context, listen: false).getUserModel();
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _formKey.currentState!.save();
      });

      FormData formData = FormData.fromMap({
        'add-bank': true,
        'bankName': bankName,
        'accountName': accountName,
        'ownerId': _userModel!.id,
        'accountNumber': accountNumber.toString()
      });
      Dio _dio = Dio();
      try {
        var response =
            await _dio.post(endPoint('add-bank.php'), data: formData);
        if (response.data['status'] == true) {
          setState(() {
            _isLoading = false;
          });
          goTo(
              context,
              BankList(
                user: _userModel,
              ),
              false);
        } else {
          setState(() {
            _isLoading = false;
          });
          showErrorSnackbar(response.data['message'], context);
        }
      } on DioException catch (e) {
        debugPrint("Dio Exeception: ${e.error.toString()}");
        setState(() {
          _isLoading = false;
        });
        showErrorSnackbar(
            'Server Error: We are unable to process your request now, please try again leta',
            context);
      } on SocketException catch (e) {
        debugPrint("Dio Exeception: ${e.toString()}");
        setState(() {
          _isLoading = false;
        });
        showErrorSnackbar(
            'Network Error: Please Check your internet connection and try again',
            context);
      } catch (e) {
        debugPrint("oops something went wrong: ${e.toString()}");
        setState(() {
          _isLoading = false;
        });
        showErrorSnackbar(
            'Network Error: Please Check your internet connection and try again',
            context);
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUser();
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    return Theme(
      data: AppTheme.of(context),
      child: Scaffold(
        backgroundColor: context.palette.surface,
        appBar: AppBar(
          title: const Text('Bank Details'),
          leading: GestureDetector(
            onTap: () => goBack(context),
            child: const Icon(
              Icons.arrow_back_ios,
              size: 18,
            ),
          ),
          actions: [
            GestureDetector(
              onTap: () => goTo(
                  context,
                  BankList(
                    user: onlineUser!,
                  ),
                  false),
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Icon(
                  Icons.book_outlined,
                  size: 20,
                ),
              ),
            )
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.palette.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add the bank account you want payouts sent to.',
                    style: TextStyle(fontSize: 13, color: context.palette.textGrey),
                  ),
                  const SizedBox(height: 20),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value:
                              selectedBank == 'Bank Name' ? null : selectedBank,
                          decoration:
                              const InputDecoration(labelText: 'Bank name'),
                          hint: const Text('Choose bank'),
                          items: banks
                              .map((b) => DropdownMenuItem(
                                  value: b, child: Text(b)))
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              selectedBank = value;
                              bankName = value;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Please select a bank' : null,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Account name',
                          hint: 'Enter account name',
                          icon: Icons.person_outline,
                          validator: (value) => value!.isEmpty
                              ? 'Account name is required'
                              : null,
                          onSaved: (v) => accountName = v,
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Account number',
                          hint: 'Enter account number',
                          icon: Icons.numbers,
                          keyboardType: TextInputType.number,
                          validator: (value) => value!.isEmpty
                              ? 'Account number is required'
                              : null,
                          onSaved: (v) => accountNumber = v,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  MiaButton(
                    text: 'Add bank',
                    isEnabled: !_isLoading,
                    onPressed: submitForm,
                    prefix: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWeb(BuildContext context) {
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => goBack(context),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.arrow_back_ios_new,
                                    size: 16, color: AppColors.primary),
                                const SizedBox(width: 6),
                                Text('Back',
                                    style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                        const Text(
                          'Bank details',
                          style: TextStyle(
                            fontFamily: 'Fraunces',
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () =>
                                goTo(context, BankList(user: onlineUser!), false),
                            child: Icon(Icons.book_outlined,
                                color: AppColors.textDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Account',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark)),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: selectedBank == 'Bank Name'
                                  ? null
                                  : selectedBank,
                              decoration:
                                  const InputDecoration(labelText: 'Bank name'),
                              hint: const Text('Choose bank'),
                              items: banks
                                  .map((b) =>
                                      DropdownMenuItem(value: b, child: Text(b)))
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() {
                                  selectedBank = value;
                                  bankName = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Account name',
                              hint: 'Enter account name',
                              validator: (value) => value!.isEmpty
                                  ? 'Account name is required'
                                  : null,
                              onSaved: (v) => accountName = v,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Account number',
                              hint: 'Enter account number',
                              keyboardType: TextInputType.number,
                              validator: (value) => value!.isEmpty
                                  ? 'Account number is required'
                                  : null,
                              onSaved: (v) => accountNumber = v,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    MiaButton(
                      text: 'Add bank',
                      isEnabled: !_isLoading,
                      onPressed: submitForm,
                      prefix: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : null,
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

}
