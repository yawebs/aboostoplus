import 'package:eafind/theme/app_palette.dart';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/models/property_model.dart';
import 'package:eafind/screens/inspection_booking_screen.dart';
import 'package:eafind/theme/app_theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutterwave_standard_smart/models/responses/charge_response.dart';

import 'package:intl/intl.dart';

import '../models/user_model.dart';
import '../services/db_services.dart';
import '../services/payment.dart';

class Paymentsheet extends StatefulWidget {
  final PropertyModel property;
  final UserModel userCustomer;
  const Paymentsheet(
      {Key? key, required this.property, required this.userCustomer})
      : super(key: key);

  @override
  State<Paymentsheet> createState() => _PaymentsheetState();
}

class _PaymentsheetState extends State<Paymentsheet> {
  int amount = 0;
  bool isLoading = false;
  bool paymentTapped = false;
  UserModel? propertyOwner;
  int agentFee = 0;
  int leadFee = 0;
  int platformFee = 0;
  bool isFree = true;

  static const _successGreen = Color(0xFF2E9E5B);

  getPropertyOwner() async {
    debugPrint("Getting property owner ${widget.property.propertyOwner}");
    setState(() {
      propertyOwner =
          UserModel.fromDoc2(json.decode(widget.property.propertyOwner));
    });
    try {
      // var serviceChargeData =
      //     await DbServices.getCharges(widget.property.ownerId);

      // setState(() {
      //   propertyOwner = widget.property.propertyOwner;
      //   platformFee = serviceChargeData['platform_fee'];
      //   leadFee = serviceChargeData['leads-fee'];
      //   agentFee = serviceChargeData['agent_inspection_fee'];
      //   amount = platformFee + agentFee;
      //   isLoading = false;
      // });
    } catch (e) {
      debugPrint('Something went wron trying to fecth property owner');
    }
  }

  addPaymentHistory(paymentRef) async {
    try {
      setState(() {
        isLoading = true;
      });
      FormData formData = FormData.fromMap(
        {
          'agentId': widget.property.ownerId,
          'amount': amount,
          'customerId': widget.userCustomer.id,
          'payment_ref': paymentRef,
          'payment_details': 1
        },
      );
      var response =
          await Dio().post(endPoint('new-payment.php'), data: formData);
      setState(() {
        isLoading = false;
      });
      return response;
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint(e.toString());
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getPropertyOwner();
  }

  Future<void> _processPayment(BuildContext context) async {
    if (paymentTapped == false) {
      // check if the user has this amount in his wallet;
      setState(() {
        paymentTapped = true;
      });
      if (isFree) {
        await goTo(
          context,
          InspectionBookingScreen(
            property: widget.property,
            amount: amount,
            userCustomer: widget.userCustomer,
            transactionRef: 'free',
          ),
          false,
        );
        // Back from the booking screen: re-enable the button, otherwise
        // a second tap just says "Already Processing".
        if (mounted) setState(() => paymentTapped = false);
        return;
      }
      ChargeResponse response = await Payment().payWithFlutterwave(
        context,
        amount.toDouble(),
        '',
        widget.userCustomer.email,
      );
      debugPrint('Response is $response');

      if (response.status == 'successful' && response.success == true) {
        await addPaymentHistory(response.txRef);

        if (propertyOwner != null) {
          if (propertyOwner!.leadId.toString().isNotEmpty) {
            await DbServices.updateBalance(
              propertyOwner!.id,
              leadFee,
            );
          }
        }
        goTo(
          context,
          InspectionBookingScreen(
            property: widget.property,
            amount: amount,
            userCustomer: widget.userCustomer,
            transactionRef: response.txRef,
          ),
          false,
        );
      } else {
        setState(() {
          isLoading = false;
          paymentTapped = false;
        });
        goBack(context);
        showToast('Ooops something went wrong, try again');
      }
    } else {
      showToast('Already Processing');
    }
  }

  bool get _isFreeBooking => isFree || amount <= 0;

  String _naira(num value) => '₦${NumberFormat('#,##0').format(value)}';

  String get _agentName {
    final owner = propertyOwner;
    if (owner != null && owner.firstName.trim().isNotEmpty) {
      return '${owner.firstName} ${owner.lastName}'.trim();
    }
    return widget.property.userName;
  }

  String get _ownerRole => widget.property.userType.toLowerCase();

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWeb(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    return SafeArea(
      top: false,
      child: isLoading
          ? SizedBox(
              height: 260,
              child: Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: context.palette.accent),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: _content(context, showHandle: true),
            ),
    );
  }

  Widget _buildWeb(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.palette.paper,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppShadows.card,
          ),
          child: isLoading
              ? SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(
                        color: context.palette.accent),
                  ),
                )
              : _content(context, showHandle: false),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, {required bool showHandle}) {
    final palette = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHandle) ...[
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
        ],
        _header(palette),
        const SizedBox(height: 18),
        _propertySummary(palette),
        const SizedBox(height: 12),
        _feeBreakdown(palette),
        const SizedBox(height: 12),
        _notice(palette),
        const SizedBox(height: 18),
        _payButton(palette),
        if (!_isFreeBooking) ...[
          const SizedBox(height: 10),
          _securedBy(palette),
        ],
      ],
    );
  }

  Widget _header(AppPalette palette) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: palette.primaryFill.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.event_available_rounded,
              color: palette.accent, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Book an inspection',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: palette.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _agentName.trim().isEmpty
                    ? 'Schedule a visit with the $_ownerRole'
                    : 'With $_agentName · ${widget.property.userType}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: palette.inkSoft),
              ),
            ],
          ),
        ),
        InkWell(
          customBorder: const CircleBorder(),
          onTap: () => goBack(context),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: palette.card,
              shape: BoxShape.circle,
              border: Border.all(color: palette.border),
            ),
            child: Icon(Icons.close_rounded, size: 18, color: palette.ink),
          ),
        ),
      ],
    );
  }

  Widget _imageFallback(AppPalette palette) => Container(
        color: palette.tile,
        child: Icon(Icons.home_work_outlined, color: palette.inkMuted),
      );

  Widget _propertySummary(AppPalette palette) {
    final p = widget.property;
    final location = [p.community, p.city]
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .join(', ');
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 60,
              height: 60,
              child: p.images.isEmpty || p.isVideo == 1
                  ? _imageFallback(palette)
                  : Image.network(
                      p.images[0],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imageFallback(palette),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title.isNotEmpty ? p.title : p.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: palette.ink,
                  ),
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 13, color: palette.inkMuted),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 12, color: palette.inkSoft),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${_naira(num.tryParse(p.amount.toString()) ?? 0)}${p.priceSuffix}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: palette.accent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _feeRow(AppPalette palette, String label, int value, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 14, color: palette.ink)),
                Text(hint,
                    style: TextStyle(fontSize: 11.5, color: palette.inkMuted)),
              ],
            ),
          ),
          Text(
            value <= 0 ? 'Free' : _naira(value),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: value <= 0 ? _successGreen : palette.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _feeBreakdown(AppPalette palette) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PAYMENT SUMMARY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: palette.inkMuted,
            ),
          ),
          const SizedBox(height: 4),
          _feeRow(palette, 'Inspection fee', agentFee,
              'Paid to the $_ownerRole'),
          _feeRow(palette, 'Platform fee', platformFee, 'Booking & support'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _DashedDivider(color: palette.border),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total due',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: palette.ink,
                  ),
                ),
              ),
              Text(
                _naira(_isFreeBooking ? 0 : amount),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: palette.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _notice(AppPalette palette) {
    final free = _isFreeBooking;
    final color = free ? _successGreen : palette.accent;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            free ? Icons.celebration_rounded : Icons.info_outline_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              free
                  ? 'Inspections are free right now, so no payment is needed. '
                      'Just pick a date that works for you.'
                  : 'This fee secures your inspection with the $_ownerRole. '
                      'You will choose a date right after payment.',
              style:
                  TextStyle(fontSize: 12.5, height: 1.4, color: palette.ink),
            ),
          ),
        ],
      ),
    );
  }

  Widget _payButton(AppPalette palette) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: paymentTapped ? null : () => _processPayment(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: palette.primaryFill,
          disabledBackgroundColor: palette.primaryFill.withValues(alpha: 0.6),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: paymentTapped
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isFreeBooking
                        ? Icons.calendar_month_rounded
                        : Icons.lock_rounded,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isFreeBooking
                        ? 'Continue to booking'
                        : 'Pay ${_naira(amount)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _securedBy(AppPalette palette) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.verified_user_rounded, size: 14, color: palette.inkMuted),
        const SizedBox(width: 6),
        Text('Secured by',
            style: TextStyle(fontSize: 12, color: palette.inkMuted)),
        const SizedBox(width: 6),
        ClipOval(
          child: Image.asset(
            imageRounte(name: 'flutterwave.png'),
            width: 16,
            height: 16,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'Flutterwave',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: palette.inkSoft,
          ),
        ),
      ],
    );
  }
}

class _DashedDivider extends StatelessWidget {
  final Color color;
  const _DashedDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const dash = 5.0, gap = 4.0;
      final count = (constraints.maxWidth / (dash + gap)).floor();
      return Row(
        children: List.generate(
          count,
          (_) => Container(
            width: dash,
            height: 1,
            margin: const EdgeInsets.only(right: gap),
            color: color,
          ),
        ),
      );
    });
  }
}
