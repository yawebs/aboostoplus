import 'package:eafind/theme/app_palette.dart';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:eafind/models/property_model.dart';
import 'package:eafind/models/user_model.dart';
import 'package:eafind/providers/report_property_provider.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:eafind/widgets/shared_widgets.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../const/constant.dart';
import '../../providers/refresh_deal_provider.dart';

class SubmitReport extends StatefulWidget {
  final String report;
  final bool changeStatus;

  const SubmitReport(
      {Key? key, required this.report, required this.changeStatus})
      : super(key: key);

  @override
  State<SubmitReport> createState() => _SubmitReportState();
}

class _SubmitReportState extends State<SubmitReport> {
  bool isLoading = false;
  Future<bool> updateStatus(newStatus) async {
    bool isSuccessful = false;
    var dealId =
        Provider.of<RefreshDealProvider>(context, listen: false).getDealId();
    try {
      FormData _formData = FormData.fromMap(
          {'update_status': true, 'deal_id': dealId, 'new_status': newStatus});
      Dio _dio = Dio();

      var response =
          await _dio.post(endPoint('add-deals.php'), data: _formData);

      if (response.data['status'] == true) {
        setState(() {
          isSuccessful = true;
        });
      } else {}
    } catch (e) {
      debugPrint('Catched Erro: ${e.toString()} ');
      setState(() {
        isSuccessful = false;
      });
    }
    return isSuccessful;
  }

  sendReport(report, reporterId, propertyId, propertyOwnerId) async {
    bool shouldRunBoth = true;
    FormData _formData = FormData.fromMap({
      'send_report': true,
      'report': report,
      'reporterId': reporterId,
      'propertyOwnerId': propertyOwnerId,
      'propertyId': propertyId
    });
    Dio _dio = Dio();
    try {
      setState(() {
        isLoading = true;
      });
      if (widget.changeStatus == true) {
        bool isStatusUpdated = await updateStatus('Cancelled');
        if (isStatusUpdated != true) {
          setState(() {
            shouldRunBoth = false;
          });
        }
      }

      if (shouldRunBoth == true) {
        var response =
            await _dio.post(endPoint('send-report.php'), data: _formData);
        setState(() {
          isLoading = false;
        });
        if (response.data['status'] == true) {
          Provider.of<RefreshDealProvider>(context, listen: false)
              .changeState(true);
          successSnackBar('Report Successfully Submitted', context);
          goBack(context);
        } else {
          showErrorSnackbar(response.data['message'], context);
        }
      } else {
        setState(() {
          isLoading = false;
        });
        showErrorSnackbar(
          'Oops something went wrong, we are unable to send report and change deal status now, please try again',
          context,
        );
      }
    } catch (e) {
      debugPrint('OOp Error found:${e.toString()}');
      setState(() {
        isLoading = false;
      });
      showErrorSnackbar(
        'Oops something went wrong please check your internet connection and retry',
        context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    PropertyModel property =
        Provider.of<ReportPropertyProvider>(context, listen: false)
            .getProperty();
    String report =
        Provider.of<ReportPropertyProvider>(context, listen: false).getReport();
    UserModel? currentUser =
        Provider.of<UsermodelProvider>(context, listen: false).getUserModel();
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
      child: Container(
        height: height(context) / 1.1,
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: ListView(
            shrinkWrap: true,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                    onTap: () => goBack(context), child: Icon(Icons.cancel)),
              ),
              Center(
                child: Text(
                  'Report Details',
                  style: tHead2,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'You are currently reporting ${property.title} Posted by @${property.userName}',
                  textAlign: TextAlign.center,
                ),
              ),
              Divider(),
              Card(
                color: context.palette.paper,
                child: Container(
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Text(report),
                  ),
                ),
              ),
              h40(),
              isLoading
                  ? Center(
                      child: appLoader(35.0),
                    )
                  : appButton(
                      callback: () => sendReport(report, currentUser!.id,
                          property.id, property.ownerId),
                      label: 'Submit Report',
                      color: red,
                      textColor: white)
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeb(BuildContext context) {
    PropertyModel property =
        Provider.of<ReportPropertyProvider>(context, listen: false)
            .getProperty();
    String report =
        Provider.of<ReportPropertyProvider>(context, listen: false).getReport();
    UserModel? currentUser =
        Provider.of<UsermodelProvider>(context, listen: false).getUserModel();
    return Theme(
      data: AppTheme.theme,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Report details',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark),
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => goBack(context),
                        child: const Icon(Icons.close, color: AppColors.textGrey),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'You are currently reporting ${property.title} posted by @${property.userName}',
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(report,
                      style: const TextStyle(color: AppColors.textDark)),
                ),
                const SizedBox(height: 24),
                isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: AppColors.error))
                    : MiaButton(
                        text: 'Submit report',
                        onPressed: () => sendReport(report, currentUser!.id,
                            property.id, property.ownerId),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
