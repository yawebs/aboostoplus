import 'package:eafind/theme/app_palette.dart';

import 'package:dio/dio.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/models/property_model.dart';
import 'package:eafind/providers/refresh_deal_provider.dart';
import 'package:eafind/providers/report_property_provider.dart';
import 'package:eafind/screens/reports/agent/cancellation_report.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:omni_datetime_picker/omni_datetime_picker.dart';
import 'package:provider/provider.dart';

// "Manage inspection" sheet: complete / cancel the deal, reschedule it, or
// report a problem. Open it with showModalBottomSheet(isScrollControlled:
// true, backgroundColor: Colors.transparent) - it draws its own rounded
// surface.
class ChangeStatusWidget extends StatefulWidget {
  // Null when the listing was deleted after booking.
  final PropertyModel? property;
  final dynamic dealId;
  // The deal row (inspection_date, inspection_time, customer_name, ...),
  // used for the header and reschedule. Optional for older callers.
  final Map<String, dynamic>? deal;
  const ChangeStatusWidget(
      {Key? key, required this.property, required this.dealId, this.deal})
      : super(key: key);

  @override
  State<ChangeStatusWidget> createState() => _ChangeStatusWidgetState();
}

enum _Pending { none, complete, cancel, reschedule }

class _ChangeStatusWidgetState extends State<ChangeStatusWidget> {
  static const _green = Color(0xFF2E9E5B);
  static const _red = Color(0xFFD64545);
  static const _amber = Color(0xFFE8A93B);

  DateTime? _dateTime;
  bool _isLoading = false;
  // Which action is waiting for a confirm tap.
  _Pending _pending = _Pending.none;

  void cancelReportModal() {
    showModalBottomSheet(
        context: context,
        builder: (ctx) {
          return const CancellationReport();
        });
  }

  Future<void> _post(Map<String, dynamic> fields, String successMessage) async {
    setState(() => _isLoading = true);
    try {
      final response = await Dio()
          .post(endPoint('add-deals.php'), data: FormData.fromMap(fields));
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (response.data is Map && response.data['status'] == true) {
        Provider.of<RefreshDealProvider>(context, listen: false)
            .changeState(true);
        goBack(context);
        successSnackBar(successMessage, context);
      } else {
        final message = response.data is Map
            ? (response.data['message'] ?? 'Something went wrong').toString()
            : 'Something went wrong';
        goBack(context);
        showErrorSnackbar(message, context);
      }
    } catch (e) {
      debugPrint('Deal update failed: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      showErrorSnackbar('Network error, please try again', context);
    }
  }

  void updateStatus(String newStatus) => _post({
        'update_status': true,
        'deal_id': widget.dealId,
        'new_status': newStatus,
      }, 'Inspection marked as $newStatus');

  void _saveReschedule() {
    final when = _dateTime;
    if (when == null) return;
    _post({
      'reschedule_deal': true,
      'deal_id': widget.dealId,
      // Same formats the booking screen stores.
      'inspection_date': DateFormat.yMEd().format(when),
      'inspection_time': DateFormat('hh:mm a').format(when),
    }, 'Inspection rescheduled');
  }

  // Previously the sheet closed itself *before* opening the picker, so the
  // picked date was dropped and never saved. Now the picker opens on top and
  // the new time is confirmed in the sheet.
  Future<void> pickDate() async {
    final now = DateTime.now();
    final DateTime? dateTime = await showOmniDateTimePicker(
      context: context,
      initialDate: _currentWhen != null && _currentWhen!.isAfter(now)
          ? _currentWhen!
          : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      is24HourMode: false,
      isShowSeconds: false,
      minutesInterval: 5,
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      constraints: const BoxConstraints(maxWidth: 350, maxHeight: 650),
      theme: ThemeData.dark(),
      transitionDuration: const Duration(milliseconds: 200),
      barrierDismissible: true,
    );
    if (!mounted || dateTime == null) return;
    setState(() {
      _dateTime = dateTime;
      _pending = _Pending.reschedule;
    });
  }

  DateTime? get _currentWhen {
    final deal = widget.deal;
    if (deal == null) return null;
    try {
      final day = DateFormat.yMEd().parse(deal['inspection_date'].toString());
      final time =
          DateFormat('hh:mm a').parse(deal['inspection_time'].toString());
      return DateTime(day.year, day.month, day.day, time.hour, time.minute);
    } catch (_) {
      return null;
    }
  }

  String _format(DateTime d) =>
      '${DateFormat('EEE, MMM d').format(d)} · ${DateFormat('h:mm a').format(d)}';

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.inkMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _header(palette),
              const SizedBox(height: 20),
              _sectionLabel(palette, 'UPDATE STATUS'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _statusTile(
                      palette,
                      color: _green,
                      icon: Icons.task_alt_rounded,
                      title: 'Completed',
                      subtitle: 'Inspection took place',
                      selected: _pending == _Pending.complete,
                      onTap: _isLoading
                          ? null
                          : () => setState(() => _pending =
                              _pending == _Pending.complete
                                  ? _Pending.none
                                  : _Pending.complete),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statusTile(
                      palette,
                      color: _red,
                      icon: Icons.event_busy_rounded,
                      title: 'Cancel',
                      subtitle: 'Call off with a reason',
                      selected: _pending == _Pending.cancel,
                      onTap: _isLoading
                          ? null
                          : widget.property == null
                              // Listing deleted: no report form to attach
                              // it to, so just confirm and cancel.
                              ? () => setState(() => _pending =
                                  _pending == _Pending.cancel
                                      ? _Pending.none
                                      : _Pending.cancel)
                              : () {
                                  Provider.of<ReportPropertyProvider>(context,
                                          listen: false)
                                      .setProperty(widget.property!);
                                  goBack(context);
                                  cancelReportModal();
                                },
                    ),
                  ),
                ],
              ),
              _confirmBar(palette),
              const SizedBox(height: 20),
              _sectionLabel(palette, 'MORE OPTIONS'),
              const SizedBox(height: 10),
              _optionRow(
                palette,
                color: palette.accent,
                icon: Icons.edit_calendar_rounded,
                title: 'Reschedule',
                subtitle: _dateTime != null
                    ? 'New time: ${_format(_dateTime!)}'
                    : 'Pick a new date & time',
                onTap: _isLoading ? null : pickDate,
              ),
              if (widget.property != null) ...[
                const SizedBox(height: 8),
                _optionRow(
                  palette,
                  color: _amber,
                  icon: Icons.flag_rounded,
                  title: 'Report a problem',
                  subtitle: 'No-show, misconduct or anything else',
                  onTap: _isLoading
                      ? null
                      : () {
                          Provider.of<ReportPropertyProvider>(context,
                                  listen: false)
                              .setProperty(widget.property!);
                          goBack(context);
                          showCustomerReportModal(context);
                        },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(AppPalette palette) {
    final p = widget.property;
    final when = _currentWhen;
    final client = (widget.deal?['customer_name'] ?? '').toString().trim();
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 56,
            height: 56,
            child: p == null || p.images.isEmpty || p.isVideo == 1
                ? Container(
                    color: palette.tile,
                    child:
                        Icon(Icons.home_work_outlined, color: palette.inkMuted),
                  )
                : Image.network(
                    p.images[0],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: palette.tile,
                      child: Icon(Icons.home_work_outlined,
                          color: palette.inkMuted),
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manage inspection',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                [
                  p == null
                      ? (widget.deal?['property_title'] ?? 'Removed listing')
                          .toString()
                      : p.title.isNotEmpty
                          ? p.title
                          : p.category,
                  if (client.isNotEmpty) 'with $client'
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: palette.inkSoft),
              ),
              if (when != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: palette.primaryFill.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 12, color: palette.accent),
                      const SizedBox(width: 4),
                      Text(
                        _format(when),
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: palette.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          onPressed: () => goBack(context),
          icon: Icon(Icons.close_rounded, color: palette.inkSoft),
        ),
      ],
    );
  }

  Widget _sectionLabel(AppPalette palette, String text) => Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
          color: palette.inkMuted,
        ),
      );

  Widget _statusTile(
    AppPalette palette, {
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: selected ? color.withValues(alpha: 0.14) : palette.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? color : palette.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11.5, color: palette.inkMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Inline confirmation for the action picked above it, so one stray tap
  // can't close a deal.
  Widget _confirmBar(AppPalette palette) {
    final completing = _pending == _Pending.complete;
    final cancelling = _pending == _Pending.cancel;
    final rescheduling = _pending == _Pending.reschedule && _dateTime != null;
    final show = completing || cancelling || rescheduling;
    final color = completing
        ? _green
        : cancelling
            ? _red
            : palette.accent;
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: !show
          ? const SizedBox(width: double.infinity)
          : Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      completing
                          ? 'Mark this inspection as completed? This closes the deal.'
                          : cancelling
                              ? 'The listing was removed. Cancel this inspection?'
                              : 'Move the inspection to ${_format(_dateTime!)}?',
                      style: TextStyle(
                          fontSize: 13, height: 1.35, color: palette.ink),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() {
                              _pending = _Pending.none;
                              if (rescheduling) _dateTime = null;
                            }),
                    child: Text('Not now',
                        style: TextStyle(color: palette.inkSoft)),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : completing
                            ? () => updateStatus('Completed')
                            : cancelling
                                ? () => updateStatus('Cancelled')
                                : _saveReschedule,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: color.withValues(alpha: 0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(completing
                            ? 'Complete'
                            : cancelling
                                ? 'Cancel it'
                                : 'Save'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _optionRow(
    AppPalette palette, {
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: palette.ink)),
                    const SizedBox(height: 1),
                    Text(subtitle,
                        style:
                            TextStyle(fontSize: 12, color: palette.inkMuted)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: palette.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
