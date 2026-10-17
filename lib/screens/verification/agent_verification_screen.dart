import 'dart:io';

import 'package:eafind/const/constant.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/services/verification_service.dart';
import 'package:eafind/theme/app_palette.dart';
import 'package:eafind/utility/states_data.dart';
import 'package:eafind/widgets/verified_badge.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Agent verification: intro -> 3-step form (business, ID, selfie) ->
// "under review" -> verified. A rejection shows the admin's reason and
// lets the agent resubmit. Backed by agent-verification.php; the badge only
// appears after an admin approves in the dashboard.
class AgentVerificationScreen extends StatefulWidget {
  const AgentVerificationScreen({Key? key}) : super(key: key);

  @override
  State<AgentVerificationScreen> createState() =>
      _AgentVerificationScreenState();
}

const _ink = Color(0xFF161616);
const _ember = Color(0xFFC45A06);
const _gold = Color(0xFFFDB813);
const _green = Color(0xFF2E9E5B);
const _red = Color(0xFFD64545);

class _AgentVerificationScreenState extends State<AgentVerificationScreen> {
  bool _loading = true;
  String? _error;
  VerificationState? _state;
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final r = await VerificationService.status();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r.ok) {
        _state = r.data;
        final me = context.read<UsermodelProvider>().getUserModel();
        if (me != null) VerifiedUsers.instance.set(me.id, r.data!.isVerified);
      } else {
        _error = r.error;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Widget body;
    if (_loading) {
      body = Center(child: CircularProgressIndicator(color: palette.accent));
    } else if (_error != null) {
      body = _ErrorView(message: _error!, onRetry: _load);
    } else if (_state!.isVerified) {
      body = _VerifiedView(submission: _state!.submission);
    } else if (_showForm) {
      body = _VerificationForm(
        onCancel: () => setState(() => _showForm = false),
        onSubmitted: (s) => setState(() {
          _showForm = false;
          _state = VerificationState(false, s);
        }),
      );
    } else if (_state!.submission?.isPending == true) {
      body = _PendingView(submission: _state!.submission!, onRefresh: _load);
    } else {
      body = _IntroView(
        rejected: _state!.submission?.isRejected == true
            ? _state!.submission
            : null,
        onStart: () => setState(() => _showForm = true),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: palette.page,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: KeyedSubtree(
            key: ValueKey('$_loading$_error$_showForm'
                '${_state?.isVerified}${_state?.submission?.status}'),
            child: body,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- shared

class _Hero extends StatelessWidget {
  final Widget child;
  final VoidCallback? onBack;
  const _Hero({Key? key, required this.child, this.onBack})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 6, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_ember, _ink, Color(0xFF26122F)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -10,
            child: Icon(Icons.verified_rounded,
                size: 190, color: Colors.white.withValues(alpha: 0.05)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                onPressed: onBack ?? () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
              child,
            ],
          ),
        ],
      ),
    );
  }
}

class _BigBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _BigBadge({Key? key, required this.icon, required this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.6, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.elasticOut,
      builder: (_, s, child) => Transform.scale(scale: s, child: child),
      child: Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.18),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 24),
          ],
        ),
        child: Icon(icon, color: color, size: 40),
      ),
    );
  }
}

Widget _heroTitle(String title, String subtitle) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                height: 1.2,
                fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(subtitle,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 14,
                height: 1.45)),
      ],
    );

Widget _primaryButton(
  BuildContext context, {
  required String label,
  required IconData icon,
  required VoidCallback? onPressed,
  bool busy = false,
}) {
  final palette = context.palette;
  return SizedBox(
    height: 54,
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: busy ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.primaryFill,
        foregroundColor: Colors.white,
        disabledBackgroundColor: palette.primaryFill.withValues(alpha: 0.45),
        disabledForegroundColor: Colors.white70,
        elevation: 0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : Icon(icon, size: 19),
      label: Text(label,
          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700)),
    ),
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  static const padding = EdgeInsets.all(16);
  const _Card({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
        boxShadow: [BoxShadow(color: palette.cardShadow, blurRadius: 18, offset: const Offset(0, 6))],
      ),
      child: child,
    );
  }
}

String _date(DateTime? d) {
  if (d == null) return '';
  const m = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${d.day} ${m[d.month - 1]} ${d.year}';
}

// ---------------------------------------------------------------- intro

class _IntroView extends StatelessWidget {
  final VerificationSubmission? rejected;
  final VoidCallback onStart;
  const _IntroView({Key? key, this.rejected, required this.onStart})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bottom = MediaQuery.of(context).padding.bottom;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _Hero(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const _BigBadge(
                        icon: Icons.verified_rounded, color: _gold),
                    const SizedBox(height: 18),
                    _heroTitle(
                      'Become a verified agent',
                      'Renters trust agents with the blue tick. Verify your '
                          'identity once and the badge shows on your profile, '
                          'listings and chats.',
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                child: Column(
                  children: [
                    if (rejected != null) ...[
                      _RejectedBanner(submission: rejected!),
                      const SizedBox(height: 16),
                    ],
                    _Card(
                      child: Column(
                        children: const [
                          _Benefit(
                            icon: Icons.trending_up_rounded,
                            color: _green,
                            title: 'More enquiries',
                            text:
                                'House hunters filter for and contact verified agents first.',
                          ),
                          _Benefit(
                            icon: Icons.shield_rounded,
                            color: Color(0xFF3A86E0),
                            title: 'Stand out from scammers',
                            text:
                                'The badge proves a real, ID-checked person is behind your listings.',
                          ),
                          _Benefit(
                            icon: Icons.workspace_premium_rounded,
                            color: Color(0xFFF7821B),
                            title: 'Free, takes 3 minutes',
                            text:
                                'Reviewed by the Aboostoplus team, usually within 24-48 hours.',
                            last: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Have these ready',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: palette.ink)),
                          const SizedBox(height: 12),
                          _need(palette, Icons.badge_rounded,
                              'A valid government ID (NIN, driver\'s licence, passport or voter\'s card)'),
                          _need(palette, Icons.store_rounded,
                              'Your office or business address'),
                          _need(palette, Icons.face_retouching_natural_rounded,
                              'Good light for a quick selfie'),
                          _need(palette, Icons.receipt_long_rounded,
                              'CAC number if you are registered (optional)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(Icons.lock_rounded,
                            size: 15, color: palette.inkMuted),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Your documents are stored privately and only seen by the Aboostoplus review team. They are never shown on your profile.',
                            style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: palette.inkMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(18, 8, 18, 14 + bottom),
          child: _primaryButton(
            context,
            label: rejected != null ? 'Fix & resubmit' : 'Start verification',
            icon: Icons.arrow_forward_rounded,
            onPressed: onStart,
          ),
        ),
      ],
    );
  }

  Widget _need(AppPalette palette, IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: palette.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13.5, height: 1.35, color: palette.inkSoft)),
            ),
          ],
        ),
      );
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String text;
  final bool last;
  const _Benefit({
    Key? key,
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
    this.last = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: palette.ink)),
                const SizedBox(height: 2),
                Text(text,
                    style: TextStyle(
                        fontSize: 12.5, height: 1.4, color: palette.inkMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RejectedBanner extends StatelessWidget {
  final VerificationSubmission submission;
  const _RejectedBanner({Key? key, required this.submission}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _red.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: _red, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your last request was not approved',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: palette.ink)),
                const SizedBox(height: 4),
                Text(
                    submission.rejectionReason.isNotEmpty
                        ? submission.rejectionReason
                        : 'Please check your details and photos, then try again.',
                    style: TextStyle(
                        fontSize: 13, height: 1.4, color: palette.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- pending

class _PendingView extends StatelessWidget {
  final VerificationSubmission submission;
  final Future<void> Function() onRefresh;
  const _PendingView(
      {Key? key, required this.submission, required this.onRefresh})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final id = idTypeFor(submission.idType);
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: palette.accent,
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _Hero(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const _BigBadge(
                    icon: Icons.hourglass_top_rounded, color: _gold),
                const SizedBox(height: 18),
                _heroTitle(
                  'We\'re reviewing your details',
                  'Thanks! Our team is checking your ID. You\'ll get a '
                      'notification as soon as you\'re verified.',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
            child: Column(
              children: [
                _Card(
                  child: Column(
                    children: [
                      _TimelineStep(
                        title: 'Submitted',
                        subtitle: _date(submission.createdAt),
                        state: _StepState.done,
                      ),
                      const _TimelineStep(
                        title: 'Under review',
                        subtitle: 'Usually within 24-48 hours',
                        state: _StepState.current,
                      ),
                      const _TimelineStep(
                        title: 'Verified badge goes live',
                        subtitle: 'On your profile, listings and chats',
                        state: _StepState.upcoming,
                        last: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('What you sent',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: palette.ink)),
                      const SizedBox(height: 12),
                      _fact(palette, 'Legal name', submission.legalName),
                      if (submission.businessName.isNotEmpty)
                        _fact(palette, 'Business', submission.businessName),
                      _fact(palette, 'ID', '${id?.label ?? submission.idType}'
                          ' ending ${submission.idNumberHint}'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text('Pull down to check for updates',
                    style: TextStyle(fontSize: 12, color: palette.inkMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fact(AppPalette palette, String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 92,
              child: Text(k,
                  style: TextStyle(fontSize: 13, color: palette.inkMuted)),
            ),
            Expanded(
              child: Text(v,
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: palette.ink)),
            ),
          ],
        ),
      );
}

enum _StepState { done, current, upcoming }

class _TimelineStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final _StepState state;
  final bool last;
  const _TimelineStep({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.state,
    this.last = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = state == _StepState.done
        ? _green
        : state == _StepState.current
            ? const Color(0xFFF7821B)
            : palette.border;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state == _StepState.upcoming
                      ? Colors.transparent
                      : color.withValues(alpha: 0.15),
                  border: Border.all(color: color, width: 2),
                ),
                child: state == _StepState.done
                    ? const Icon(Icons.check_rounded, size: 15, color: _green)
                    : state == _StepState.current
                        ? Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle),
                            ),
                          )
                        : null,
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: state == _StepState.done
                        ? _green.withValues(alpha: 0.5)
                        : palette.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 18, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: state == _StepState.upcoming
                              ? palette.inkMuted
                              : palette.ink)),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style:
                            TextStyle(fontSize: 12.5, color: palette.inkMuted)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- verified

class _VerifiedView extends StatelessWidget {
  final VerificationSubmission? submission;
  const _VerifiedView({Key? key, this.submission}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final me = context.read<UsermodelProvider>().getUserModel();
    final name = me == null ? '' : '${me.firstName} ${me.lastName}'.trim();
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _Hero(
          child: Column(
            children: [
              const SizedBox(height: 4),
              const _BigBadge(
                  icon: Icons.verified_rounded, color: VerifiedBadge.blue),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(name.isEmpty ? 'You' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.verified_rounded,
                      color: VerifiedBadge.blue, size: 24),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Verified agent'
                '${submission?.reviewedAt != null ? ' since ${_date(submission!.reviewedAt)}' : ''}',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
          child: _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your badge is live on',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: palette.ink)),
                const SizedBox(height: 14),
                const _Benefit(
                  icon: Icons.person_rounded,
                  color: Color(0xFF3A86E0),
                  title: 'Your profile',
                  text: 'Visitors see you are an ID-checked agent.',
                ),
                const _Benefit(
                  icon: Icons.home_work_rounded,
                  color: _green,
                  title: 'Every listing',
                  text: 'Next to your name on each property you post.',
                ),
                const _Benefit(
                  icon: Icons.chat_bubble_rounded,
                  color: Color(0xFFF7821B),
                  title: 'Chats',
                  text: 'House hunters see the tick when they message you.',
                  last: true,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Keep your listings honest - the badge can be removed if reports '
            'about your account are upheld.',
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 12, height: 1.4, color: palette.inkMuted),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- error

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({Key? key, required this.message, required this.onRetry})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      children: [
        const _Hero(child: SizedBox(height: 4)),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_rounded,
                      size: 46, color: palette.inkMuted),
                  const SizedBox(height: 12),
                  Text(message,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: palette.inkSoft)),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- form

class _VerificationForm extends StatefulWidget {
  final VoidCallback onCancel;
  final ValueChanged<VerificationSubmission> onSubmitted;
  const _VerificationForm(
      {Key? key, required this.onCancel, required this.onSubmitted})
      : super(key: key);

  @override
  State<_VerificationForm> createState() => _VerificationFormState();
}

class _VerificationFormState extends State<_VerificationForm> {
  static const _steps = ['Business', 'ID document', 'Selfie'];
  int _step = 0;
  bool _submitting = false;

  final _detailsKey = GlobalKey<FormState>();
  final _idKey = GlobalKey<FormState>();
  late final TextEditingController _legal;
  final _business = TextEditingController();
  final _address = TextEditingController();
  final _cac = TextEditingController();
  final _idNumber = TextEditingController();
  String? _state;
  IdType _idType = idTypes.first;
  XFile? _front;
  XFile? _back;
  XFile? _selfie;
  bool _consent = false;

  @override
  void initState() {
    super.initState();
    final me = context.read<UsermodelProvider>().getUserModel();
    _legal = TextEditingController(
        text: me == null ? '' : '${me.firstName} ${me.lastName}'.trim());
    final st = me?.state ?? '';
    _state = allStatesAndCities.any((s) => s.state == st) ? st : null;
    if ((me?.address ?? '').isNotEmpty) _address.text = me!.address;
  }

  @override
  void dispose() {
    for (final c in [_legal, _business, _address, _cac, _idNumber]) {
      c.dispose();
    }
    super.dispose();
  }

  void _back_() {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      widget.onCancel();
    } else {
      setState(() => _step--);
    }
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      if (!_detailsKey.currentState!.validate()) return;
      if (_state == null) {
        showToast('Choose your state');
        return;
      }
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (!_idKey.currentState!.validate()) return;
      if (_front == null) {
        showToast('Add a photo of the front of your ID');
        return;
      }
      setState(() => _step = 2);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    if (_selfie == null) {
      showToast('Take a selfie to finish');
      return;
    }
    if (!_consent) {
      showToast('Please confirm the declaration');
      return;
    }
    setState(() => _submitting = true);
    final r = await VerificationService.submit(
      legalName: _legal.text.trim(),
      businessName: _business.text.trim(),
      officeAddress: _address.text.trim(),
      state: _state!,
      cacNumber: _cac.text.trim(),
      idType: _idType.key,
      idNumber: _idNumber.text.replaceAll(' ', '').toUpperCase(),
      idFront: _front!,
      idBack: _idType.hasBack ? _back : null,
      selfie: _selfie!,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (r.ok) {
      successSnackBar('Submitted! We\'ll notify you once you\'re verified.',
          context);
      widget.onSubmitted(r.data!);
    } else {
      showErrorSnackbar(r.error!, context);
    }
  }

  Future<XFile?> _pick({required bool selfie}) async {
    ImageSource? source = ImageSource.camera;
    if (!selfie && !kIsWeb) {
      source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _SourceSheet(),
      );
      if (source == null) return null;
    }
    if (kIsWeb) source = ImageSource.gallery;
    try {
      return await ImagePicker().pickImage(
        source: source,
        preferredCameraDevice: selfie ? CameraDevice.front : CameraDevice.rear,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
    } catch (e) {
      showToast('Could not open the camera. Check app permissions.');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bottom = MediaQuery.of(context).padding.bottom;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back_();
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            _Hero(
              onBack: _back_,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STEP ${_step + 1} OF 3',
                      style: const TextStyle(
                          color: _gold,
                          fontSize: 11.5,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    const [
                      'Your business',
                      'Government ID',
                      'Take a selfie',
                    ][_step],
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  _progress(),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween(
                            begin: const Offset(0.06, 0), end: Offset.zero)
                        .animate(a),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: [_detailsStep, _idStep, _selfieStep][_step](palette),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(18, 10, 18, 12 + bottom),
              decoration: BoxDecoration(
                color: palette.page,
                border: Border(top: BorderSide(color: palette.border)),
              ),
              child: _primaryButton(
                context,
                label: _step < 2
                    ? 'Continue'
                    : _submitting
                        ? 'Submitting…'
                        : 'Submit for review',
                icon: _step < 2
                    ? Icons.arrow_forward_rounded
                    : Icons.verified_rounded,
                busy: _submitting,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progress() {
    return Row(
      children: [
        for (var i = 0; i < _steps.length; i++) ...[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 5,
                  decoration: BoxDecoration(
                    color: i <= _step
                        ? _gold
                        : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(_steps[i],
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: i <= _step
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5))),
              ],
            ),
          ),
          if (i < _steps.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  // Step 1
  Widget _detailsStep(AppPalette palette) {
    return Form(
      key: _detailsKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          _field(palette,
              controller: _legal,
              label: 'Full legal name',
              hint: 'Exactly as it appears on your ID',
              icon: Icons.person_rounded,
              caps: TextCapitalization.words,
              validator: (v) => (v ?? '').trim().length < 4
                  ? 'Enter your full name as on your ID'
                  : null),
          const SizedBox(height: 14),
          _field(palette,
              controller: _business,
              label: 'Business / agency name (optional)',
              icon: Icons.storefront_rounded,
              caps: TextCapitalization.words),
          const SizedBox(height: 14),
          _field(palette,
              controller: _address,
              label: 'Office address',
              hint: 'Street, area and city',
              icon: Icons.location_on_rounded,
              maxLines: 2,
              caps: TextCapitalization.words,
              validator: (v) => (v ?? '').trim().length < 8
                  ? 'Enter your office or business address'
                  : null),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _state,
            isExpanded: true,
            dropdownColor: palette.paper,
            style: TextStyle(color: palette.ink, fontSize: 15),
            decoration: _decoration(palette, 'State', Icons.map_rounded),
            items: [
              for (final s in allStatesAndCities)
                DropdownMenuItem(value: s.state, child: Text(s.state)),
            ],
            onChanged: (v) => setState(() => _state = v),
          ),
          const SizedBox(height: 14),
          _field(palette,
              controller: _cac,
              label: 'CAC number (optional)',
              hint: 'e.g. RC1234567 or BN1234567',
              icon: Icons.receipt_long_rounded,
              caps: TextCapitalization.characters,
              validator: (v) {
                final t = (v ?? '').replaceAll(' ', '').toUpperCase();
                if (t.isEmpty) return null;
                return RegExp(r'^(RC|BN|IT)?[0-9]{4,10}$').hasMatch(t)
                    ? null
                    : 'Enter a valid CAC number';
              }),
          const SizedBox(height: 10),
          _tip(palette, Icons.info_outline_rounded,
              'Registered businesses can add their CAC number so the review team can confirm it.'),
        ],
      ),
    );
  }

  // Step 2
  Widget _idStep(AppPalette palette) {
    return Form(
      key: _idKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
        children: [
          _label(palette, 'ID TYPE'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in idTypes)
                GestureDetector(
                  onTap: () => setState(() {
                    _idType = t;
                    if (!t.hasBack) _back = null;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 9),
                    decoration: BoxDecoration(
                      color: _idType == t ? palette.primaryFill : palette.card,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: _idType == t
                              ? palette.primaryFill
                              : palette.border),
                    ),
                    child: Text(t.label,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color:
                                _idType == t ? Colors.white : palette.ink)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          _field(palette,
              controller: _idNumber,
              label: '${_idType.label} number',
              hint: _idType.hint,
              icon: Icons.pin_rounded,
              caps: TextCapitalization.characters,
              keyboard: _idType.key == 'nin'
                  ? TextInputType.number
                  : TextInputType.text,
              validator: (v) {
                final t = (v ?? '').replaceAll(' ', '').toUpperCase();
                return _idType.pattern.hasMatch(t)
                    ? null
                    : 'Enter a valid ${_idType.label} number';
              }),
          const SizedBox(height: 20),
          _label(palette, 'PHOTOS OF YOUR ID'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DocSlot(
                  label: 'Front',
                  icon: Icons.credit_card_rounded,
                  file: _front,
                  onTap: () async {
                    final f = await _pick(selfie: false);
                    if (f != null) setState(() => _front = f);
                  },
                ),
              ),
              if (_idType.hasBack) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _DocSlot(
                    label: 'Back (optional)',
                    icon: Icons.flip_rounded,
                    file: _back,
                    onTap: () async {
                      final f = await _pick(selfie: false);
                      if (f != null) setState(() => _back = f);
                    },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _tip(palette, Icons.wb_sunny_rounded,
              'Lay the ID flat in good light. All four corners visible, no glare, and every detail readable.'),
        ],
      ),
    );
  }

  // Step 3
  Widget _selfieStep(AppPalette palette) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
      children: [
        Center(
          child: GestureDetector(
            onTap: () async {
              final f = await _pick(selfie: true);
              if (f != null) setState(() => _selfie = f);
            },
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: palette.card,
                    border: Border.all(
                        color: _selfie != null ? _green : palette.accent,
                        width: 3),
                    boxShadow: [BoxShadow(color: palette.cardShadow, blurRadius: 18, offset: const Offset(0, 6))],
                  ),
                  child: ClipOval(
                    child: _selfie != null
                        ? _preview(_selfie!)
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.face_retouching_natural_rounded,
                                  size: 60, color: palette.accent),
                              const SizedBox(height: 6),
                              Text('Tap to take selfie',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: palette.accent)),
                            ],
                          ),
                  ),
                ),
                if (_selfie != null)
                  Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: palette.primaryFill,
                      shape: BoxShape.circle,
                      border: Border.all(color: palette.page, width: 3),
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        size: 18, color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        _Card(
          child: Column(
            children: [
              _check(palette, 'Face the camera, eyes open, no sunglasses or cap'),
              _check(palette, 'Bright, even light - no strong shadows'),
              _check(palette, 'Just you in the photo, and it should match your ID',
                  last: true),
            ],
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _consent = !_consent),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  height: 24,
                  child: Checkbox(
                    value: _consent,
                    activeColor: palette.primaryFill,
                    onChanged: (v) => setState(() => _consent = v ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'I confirm these documents are mine and genuine. I agree '
                    'that Aboostoplus may review them to verify my identity.',
                    style: TextStyle(
                        fontSize: 12.5, height: 1.4, color: palette.inkSoft),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _check(AppPalette palette, String text, {bool last = false}) =>
      Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_rounded, size: 18, color: _green),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13.5, height: 1.35, color: palette.inkSoft)),
            ),
          ],
        ),
      );

  Widget _tip(AppPalette palette, IconData icon, String text) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: palette.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: palette.accent),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 12.5, height: 1.4, color: palette.inkSoft)),
            ),
          ],
        ),
      );

  Widget _label(AppPalette palette, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
        child: Text(text,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                color: palette.inkMuted)),
      );

  InputDecoration _decoration(AppPalette palette, String label, IconData icon,
          {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: palette.card,
        alignLabelWithHint: true,
        prefixIcon: Icon(icon, size: 19, color: palette.accent),
        labelStyle: TextStyle(color: palette.inkSoft),
        hintStyle: TextStyle(color: palette.inkMuted, fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _red, width: 1.5),
        ),
      );

  Widget _field(
    AppPalette palette, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboard,
    TextCapitalization caps = TextCapitalization.none,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        keyboardType: keyboard,
        textCapitalization: caps,
        maxLines: maxLines,
        validator: validator,
        style: TextStyle(color: palette.ink, fontSize: 15),
        decoration: _decoration(palette, label, icon, hint: hint),
      );
}

Widget _preview(XFile f) => kIsWeb
    ? Image.network(f.path, fit: BoxFit.cover)
    : Image.file(File(f.path), fit: BoxFit.cover);

class _DocSlot extends StatelessWidget {
  final String label;
  final IconData icon;
  final XFile? file;
  final VoidCallback onTap;
  const _DocSlot({
    Key? key,
    required this.label,
    required this.icon,
    required this.file,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: 1.58, // ID-card shape
            child: Container(
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: file != null
                      ? _green
                      : palette.accent.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14.5),
                child: file != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          _preview(file!),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                  color: _green, shape: BoxShape.circle),
                              child: const Icon(Icons.check_rounded,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: palette.accent, size: 28),
                          const SizedBox(height: 4),
                          Text('Add photo',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: palette.accent)),
                        ],
                      ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(file != null ? '$label · tap to retake' : label,
              style: TextStyle(fontSize: 12, color: palette.inkMuted)),
        ),
      ],
    );
  }
}

class _SourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Widget option(IconData icon, String text, ImageSource s) => ListTile(
          leading: Icon(icon, color: palette.accent),
          title: Text(text,
              style:
                  TextStyle(color: palette.ink, fontWeight: FontWeight.w600)),
          onTap: () => Navigator.pop(context, s),
        );
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: palette.paper,
        borderRadius: BorderRadius.circular(22),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            option(Icons.photo_camera_rounded, 'Take a photo',
                ImageSource.camera),
            option(Icons.photo_library_rounded, 'Choose from gallery',
                ImageSource.gallery),
          ],
        ),
      ),
    );
  }
}
