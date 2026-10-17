import 'dart:ui';

import 'package:eafind/const/constant.dart';
import 'package:eafind/providers/report_property_provider.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CancellationReport extends StatefulWidget {
  const CancellationReport({Key? key}) : super(key: key);

  @override
  State<CancellationReport> createState() => _CancellationReportState();
}

class _CancellationReportState extends State<CancellationReport> {
  List<String> reportOptions = [
    'The Client requested for cancellation',
    'The Client is no longer interested',
    'The Property is no longer available',
    'The client is not responding',
    'Others'
  ];

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
      child: Container(
        height: height(context) / 1.1,
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: ListView(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                    onTap: () => goBack(context), child: Icon(Icons.cancel)),
              ),
              Center(
                child: Text(
                  'Cancelling Deal',
                  style: tHead2,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Please choose the right option that best describes the current situation',
                  textAlign: TextAlign.center,
                ),
              ),
              Divider(),
              ListView.builder(
                  shrinkWrap: true,
                  primary: false,
                  itemCount: reportOptions.length,
                  itemBuilder: (ctx, index) {
                    String label = reportOptions[index];
                    return reportWidget(label);
                  })
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeb(BuildContext context) {
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
                      'Cancelling deal',
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
                const Text(
                  'Please choose the option that best describes the current situation',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                for (final label in reportOptions) _webReportTile(label),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _webReportTile(String label) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Provider.of<ReportPropertyProvider>(context, listen: false)
              .setReport(label);
          goBack(context);
          showSubmitReportModal(label, context, true);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Icon(Icons.report_outlined, size: 18, color: AppColors.textGrey),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: const TextStyle(color: AppColors.textDark)),
              ),
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: AppColors.textGrey),
            ],
          ),
        ),
      ),
    );
  }

  Widget reportWidget(label) {
    return Column(
      children: [
        reportDevider(),
        GestureDetector(
          onTap: () {
            Provider.of<ReportPropertyProvider>(context, listen: false)
                .setReport(label);
            goBack(context);
            showSubmitReportModal(label, context, true);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.report,
                      size: 17,
                      color: grey,
                    ),
                    w5(),
                    Container(
                      width: width(context) / 1.3,
                      child: Text(label),
                    ),
                  ],
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 17,
                  color: grey,
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
