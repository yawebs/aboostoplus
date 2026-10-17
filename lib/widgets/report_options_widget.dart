import 'package:eafind/theme/app_palette.dart';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:eafind/models/property_model.dart';
import 'package:eafind/models/user_model.dart';
import 'package:eafind/providers/refresh_deal_provider.dart';
import 'package:eafind/providers/report_property_provider.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../const/constant.dart';
import 'report_modal.dart';

class ReportOptionsSheet extends StatefulWidget {
  final PropertyModel property;
  const ReportOptionsSheet({Key? key, required this.property})
      : super(key: key);

  @override
  State<ReportOptionsSheet> createState() => _ReportOptionsSheetState();
}

class _ReportOptionsSheetState extends State<ReportOptionsSheet> {
  bool _isLoading = false;
  deleteProperty() async {
    setState(() {
      _isLoading = true;
    });
    FormData _formData = FormData.fromMap({
      'delete_item': true,
      'property_id': widget.property.id,
      'owner_id': widget.property.ownerId
    });
    try {
      Dio _dio = Dio();
      var response =
          await _dio.post(endPoint('delete-property.php'), data: _formData);
      if (response.data['status'] == true) {
        Provider.of<RefreshDealProvider>(context, listen: false)
            .shouldRefreshProperty(true);
        setState(() {
          _isLoading = false;
        });
        goBack(context);
        successSnackBar('property successfully deleted', context);
      } else {
        setState(() {
          _isLoading = false;
        });
        goBack(context);
        showErrorSnackbar(
            'unable to remove item, please try again  leta', context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Oops not working ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    UserModel? onlineUser =
        Provider.of<UsermodelProvider>(context, listen: false).getUserModel();
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        height: height(context) / 2,
        decoration: BoxDecoration(
          color: ReportColors.paper,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(15),
            topRight: Radius.circular(15),
          ),
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            GestureDetector(
              onTap: () => goBack(context),
              child: Align(
                alignment: Alignment.topRight,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.cancel,
                    size: 25,
                  ),
                ),
              ),
            ),
            h10(),
            Center(
              child: Container(
                width: 40,
                height: 3,
                color: grey.withOpacity(.5),
              ),
            ),
            const SizedBox(height: 20),
            onlineUser!.id == widget.property.ownerId
                ? ownerOptions(context)
                : usersOptions(onlineUser.id),
            h10(),
          ],
        ),
      ),
    );
  }

  usersOptions(userId) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 2.0,
        color: ReportColors.paper,
        child: Container(
          width: width(context) / 1.2,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.save,
                    color: context.palette.ink,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Save House',
                            style: AppTextStyles.serif(size: 16)),
                        Text(
                          'Save this house for future reference',
                          style: AppTextStyles.mono(color: grey, size: 12),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            h10(),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.hide_source,
                    color: context.palette.ink,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hide House',
                          style: AppTextStyles.serif(size: 16),
                        ),
                        Text(
                          'Stop seeing houses from this agent',
                          style: AppTextStyles.mono(color: grey, size: 12),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            GestureDetector(
              onTap: () => showUserReportModal(context,
                  target: ReportTarget(
                    type: ReportTargetType.property,
                    name: widget.property.title,
                    id: widget.property.id.toString(),
                    subtitle: widget.property.description,
                  ),
                  userId: userId),
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.report,
                      color: context.palette.ink,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Report House',
                            style: AppTextStyles.serif(size: 16),
                          ),
                          Text(
                            'Tell us whats wrong about this house',
                            style: AppTextStyles.mono(color: grey, size: 12),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )
          ]),
        ),
      ),
    );
  }

  ownerOptions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        child: Container(
          width: width(context) / 1.2,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_note,
                    color: context.palette.ink,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Property',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: context.palette.ink,
                          ),
                        ),
                        Text(
                          'Save this house for future reference',
                          style: TextStyle(
                            color: grey,
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            h10(),
            GestureDetector(
              onTap: () => deleteProperty(),
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.hide_source,
                      color: context.palette.ink,
                    ),
                    _isLoading
                        ? appLoader(35.0)
                        : Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delete Property',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: context.palette.ink,
                                  ),
                                ),
                                Container(
                                  width: width(context) / 1.3,
                                  child: Text(
                                    'Deleting this property would completely remove it from our Database',
                                    style: TextStyle(
                                      color: grey,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          )
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Provider.of<ReportPropertyProvider>(context, listen: false)
                    .setProperty(widget.property);
                showCustomerReportModal(context);
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.report,
                      color: context.palette.ink,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Report House',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: context.palette.ink,
                            ),
                          ),
                          Text(
                            'Tell us whats wrong about this house',
                            style: TextStyle(
                              color: grey,
                            ),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            )
          ]),
        ),
      ),
    );
  }
}
