// report_modal.dart
//
// A "case file" style report flow for flagging an agent or property
// listing, built as a draggable bottom sheet.
//
// Dependencies (pubspec.yaml):
//   google_fonts: ^6.2.1
//   http: ^1.2.0
//
// Requires report_service.dart in the same project.
//
// Usage:
//   showReportModal(
//     context,
//     target: ReportTarget(
//       type: ReportTargetType.property,
//       id: property.id.toString(),   // houses.id, or agent's uniqueId
//       name: '3-Bed Duplex, Old GRA Layout',
//       subtitle: 'Listed by Adaeze Okonkwo · Port Harcourt',
//     ),
//     userId: currentUser.uniqueId,
//     onSubmitted: () => setState(() => feedItems.remove(property)),
//   );

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/report_services.dart';

// ---------------------------------------------------------------
// Design tokens — case-file palette
// ---------------------------------------------------------------
class ReportColors {
  static const ink = Color(0xFF16221E);
  static const paper = Color(0xFFFBFAF7);
  static const paperDim = Color(0xFFF3F1EA);
  static const line = Color(0xFFE4E1D6);
  static const flag = Color(0xFFC1451F);
  static const flagDim = Color(0xFFFBEAE3);
  static const evergreen = Color(0xFF1D3A32);
  static const sub = Color(0xFF6B6A60);
  static const disabled = Color(0xFFE9DCD4);
}

enum ReportTargetType { agent, property }

class ReportTarget {
  final ReportTargetType type;
  final String id; // houses.id (as string) for property, or uniqueId for agent
  final String name;
  final String subtitle;
  final String? imageUrl;

  const ReportTarget({
    required this.type,
    required this.id,
    required this.name,
    required this.subtitle,
    this.imageUrl,
  });
}

class ReportReason {
  final String id;
  final String label;
  final String hint;
  final IconData icon;
  const ReportReason(this.id, this.label, this.hint, this.icon);
}

const List<ReportReason> kReportReasons = [
  ReportReason('misleading', 'Misleading listing',
      "Photos, price, or details don't match reality", Icons.home_outlined),
  ReportReason('fake', 'Fake or duplicate',
      "Listing looks copied, staged, or doesn't exist", Icons.copy_outlined),
  ReportReason(
      'agent',
      'Agent behavior',
      'Harassment, pressure tactics, unprofessional conduct',
      Icons.person_outline),
  ReportReason(
      'scam',
      'Scam or payment risk',
      'Asked to pay outside the platform, upfront fees',
      Icons.attach_money_outlined),
  ReportReason(
      'content',
      'Inappropriate content',
      'Offensive, explicit, or unrelated material',
      Icons.report_gmailerrorred_outlined),
  ReportReason('other', 'Something else', "Doesn't fit the categories above",
      Icons.block_outlined),
];

/// Entry point — call this to open the report flow as a bottom sheet.
Future<void> showUserReportModal(
  BuildContext context, {
  required ReportTarget target,
  required String userId, // the current user's uniqueId
  VoidCallback? onSubmitted, // e.g. remove this item from your feed list
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: ReportColors.ink.withOpacity(0.55),
    builder: (ctx) => ReportModalSheet(
      target: target,
      userId: userId,
      onSubmitted: onSubmitted,
    ),
  );
}

class ReportModalSheet extends StatefulWidget {
  final ReportTarget target;
  final String userId;
  final VoidCallback? onSubmitted;

  const ReportModalSheet({
    Key? key,
    required this.target,
    required this.userId,
    this.onSubmitted,
  }) : super(key: key);

  @override
  State<ReportModalSheet> createState() => _ReportModalSheetState();
}

class _ReportModalSheetState extends State<ReportModalSheet> {
  int step = 1; // 1 reason, 2 details, 3 done
  String? reasonId;
  final TextEditingController detailsCtrl = TextEditingController();
  final List<String> attachedFiles = [];
  String? caseId;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    detailsCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    detailsCtrl.dispose();
    super.dispose();
  }

  ReportReason? get selectedReason =>
      kReportReasons.where((r) => r.id == reasonId).firstOrNull;

  bool get canContinue =>
      step == 1 ? reasonId != null : detailsCtrl.text.trim().length >= 10;

  void _mockAttach() {
    // Swap this for `file_picker` in a real app.
    if (attachedFiles.length >= 3) return;
    setState(
        () => attachedFiles.add('evidence_${attachedFiles.length + 1}.jpg'));
  }

  Future<void> _goNext() async {
    if (step == 1 && reasonId != null) {
      setState(() => step = 2);
      return;
    }

    if (step == 2 && canContinue) {
      FocusScope.of(context).unfocus();
      setState(() => isSubmitting = true);

      final service = ReportService();
      final result = await service.submitReport(
        userId: widget.userId,
        targetType: widget.target.type.name, // 'property' | 'agent'
        targetId: widget.target.id,
        reasonId: reasonId!,
        details: detailsCtrl.text.trim(),
        // evidenceUrls: attachedFiles, // wire up once files are actually uploaded
      );

      if (!mounted) return;
      setState(() => isSubmitting = false);

      if (result.success) {
        setState(() {
          caseId = result.caseRef;
          step = 3;
        });
        widget.onSubmitted?.call();
      } else {
        debugPrint(result.message ?? 'Could not submit report');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Could not submit report')),
        );
      }
    }
  }

  void _goBack() => setState(() => step = 1);

  @override
  Widget build(BuildContext context) {
    final serif = GoogleFonts.fraunces(
        fontWeight: FontWeight.w600, color: ReportColors.ink, fontSize: 22);
    final mono = GoogleFonts.ibmPlexMono(
        fontWeight: FontWeight.w500, color: ReportColors.ink, fontSize: 15);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: ReportColors.paper,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: ReportColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    _buildHeader(),
                    if (step != 3) ...[
                      const SizedBox(height: 12),
                      Text('Report this ${widget.target.type.name}',
                          style: serif),
                      const SizedBox(height: 14),
                      _buildTargetCard(),
                      const SizedBox(height: 18),
                      _buildProgress(),
                      const SizedBox(height: 18),
                    ],
                    if (step == 1) _buildReasonList(),
                    if (step == 2) _buildDetailsStep(),
                    if (step == 3) _buildConfirmation(serif, mono),
                  ],
                ),
              ),
              if (step != 3) _buildFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.flag_outlined, size: 16, color: ReportColors.flag),
        const SizedBox(width: 6),
        Text('TRUST & SAFETY REPORT',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: ReportColors.sub,
            )),
        const Spacer(),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, size: 20, color: ReportColors.sub),
          splashRadius: 20,
        ),
      ],
    );
  }

  Widget _buildTargetCard() {
    final t = widget.target;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ReportColors.paperDim,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ReportColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFDEDACB),
              borderRadius: BorderRadius.circular(10),
              image: t.imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(t.imageUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: t.imageUrl == null
                ? Icon(
                    t.type == ReportTargetType.agent
                        ? Icons.person_outline
                        : Icons.home_outlined,
                    color: ReportColors.evergreen,
                    size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: ReportColors.ink)),
                Text(t.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: ReportColors.sub)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress() {
    return Row(
      children: [1, 2].map((s) {
        final active = step >= s;
        return Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(right: s == 1 ? 8 : 0),
            decoration: BoxDecoration(
              color: active ? ReportColors.flag : ReportColors.line,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReasonList() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Choose the option that best describes the issue.',
              style:
                  GoogleFonts.inter(fontSize: 12.5, color: ReportColors.sub)),
        ),
        const SizedBox(height: 12),
        ...List.generate(kReportReasons.length, (i) {
          final r = kReportReasons[i];
          final active = reasonId == r.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => reasonId = r.id);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: active ? ReportColors.flagDim : ReportColors.paper,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: active ? ReportColors.flag : ReportColors.line),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color:
                            active ? ReportColors.flag : ReportColors.paperDim,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color:
                                active ? ReportColors.flag : ReportColors.line),
                      ),
                      child: Text(
                        (i + 1).toString().padLeft(2, '0'),
                        style: GoogleFonts.ibmPlexMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: active ? ReportColors.paper : ReportColors.sub,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(r.icon,
                                  size: 14,
                                  color: active
                                      ? ReportColors.flag
                                      : ReportColors.evergreen),
                              const SizedBox(width: 6),
                              Text(r.label,
                                  style: GoogleFonts.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: ReportColors.ink)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(r.hint,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: ReportColors.sub,
                                  height: 1.3)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: ReportColors.flagDim,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(selectedReason?.label ?? '',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: ReportColors.flag)),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _goBack,
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              icon: const Icon(Icons.chevron_left,
                  size: 15, color: ReportColors.evergreen),
              label: Text('change',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: ReportColors.evergreen)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Tell us what happened',
            style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: ReportColors.ink)),
        const SizedBox(height: 6),
        TextField(
          controller: detailsCtrl,
          maxLines: 5,
          maxLength: 600,
          style: GoogleFonts.inter(fontSize: 13.5, color: ReportColors.ink),
          decoration: InputDecoration(
            counterText: '',
            hintText:
                'Include specific details — dates, messages, or anything that will help our review team understand the issue.',
            hintStyle:
                GoogleFonts.inter(fontSize: 12.5, color: ReportColors.sub),
            filled: true,
            fillColor: ReportColors.paper,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ReportColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: ReportColors.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: ReportColors.evergreen, width: 1.5),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Minimum 10 characters',
                  style:
                      GoogleFonts.inter(fontSize: 11, color: ReportColors.sub)),
              Text('${detailsCtrl.text.trim().length}/600',
                  style:
                      GoogleFonts.inter(fontSize: 11, color: ReportColors.sub)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: ReportColors.ink),
            children: [
              const TextSpan(text: 'Attach evidence '),
              TextSpan(
                text: '(optional)',
                style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: ReportColors.sub),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...attachedFiles.map((f) => Container(
                  padding: const EdgeInsets.only(
                      left: 10, right: 6, top: 6, bottom: 6),
                  decoration: BoxDecoration(
                    color: ReportColors.paperDim,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: ReportColors.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.attach_file,
                          size: 13, color: ReportColors.sub),
                      const SizedBox(width: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 110),
                        child: Text(f,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: ReportColors.ink)),
                      ),
                      InkWell(
                        onTap: () => setState(() => attachedFiles.remove(f)),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.close,
                              size: 13, color: ReportColors.sub),
                        ),
                      ),
                    ],
                  ),
                )),
            if (attachedFiles.length < 3)
              InkWell(
                onTap: _mockAttach,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: ReportColors.line, style: BorderStyle.solid),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined,
                          size: 14, color: ReportColors.evergreen),
                      const SizedBox(width: 6),
                      Text('Add file',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: ReportColors.evergreen)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmation(TextStyle serif, TextStyle mono) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: ReportColors.evergreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.verified_user_outlined,
              color: ReportColors.paper, size: 28),
        ),
        const SizedBox(height: 16),
        Text('Report received', style: serif),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Our trust & safety team will review this within 24–48 hours. We'll email you if we need more information.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 13, color: ReportColors.sub, height: 1.5),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: ReportColors.paperDim,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ReportColors.line),
          ),
          child: Column(
            children: [
              Text('CASE REFERENCE',
                  style: GoogleFonts.inter(
                      fontSize: 10.5,
                      letterSpacing: 1.1,
                      color: ReportColors.sub)),
              Text(caseId ?? '—', style: mono),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: ReportColors.evergreen,
              foregroundColor: ReportColors.paper,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text('Done',
                style: GoogleFonts.inter(
                    fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: ReportColors.line)),
      ),
      child: Row(
        children: [
          if (step == 2)
            OutlinedButton.icon(
              onPressed: _goBack,
              style: OutlinedButton.styleFrom(
                foregroundColor: ReportColors.ink,
                side: const BorderSide(color: ReportColors.line),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.chevron_left, size: 16),
              label: Text('Back', style: GoogleFonts.inter(fontSize: 13)),
            )
          else
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: ReportColors.sub),
              child: Text('Cancel', style: GoogleFonts.inter(fontSize: 13)),
            ),
          const Spacer(),
          ElevatedButton(
            onPressed: (canContinue && !isSubmitting) ? _goNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: ReportColors.flag,
              disabledBackgroundColor: ReportColors.disabled,
              foregroundColor: ReportColors.paper,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ReportColors.paper,
                    ),
                  )
                : Text(step == 1 ? 'Continue' : 'Submit report',
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

// ---------------------------------------------------------------
// Demo usage
// ---------------------------------------------------------------
class ReportDemoPage extends StatelessWidget {
  const ReportDemoPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const target = ReportTarget(
      type: ReportTargetType.property,
      id: '482', // houses.id, as a string
      name: '3-Bed Duplex, Old GRA Layout',
      subtitle: 'Listed by Adaeze Okonkwo · Port Harcourt',
    );

    return Scaffold(
      backgroundColor: ReportColors.paperDim,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: ReportColors.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ReportColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFDEDACB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.home_outlined,
                    color: ReportColors.evergreen),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(target.name,
                        style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    Text(target.subtitle,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: ReportColors.sub)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => showUserReportModal(
                  context,
                  target: target,
                  userId:
                      'CURRENT_USER_UNIQUE_ID', // e.g. from your session/local storage
                  onSubmitted: () {
                    // e.g. setState(() => feedItems.removeWhere((p) => p.id == target.id));
                  },
                ),
                icon: const Icon(Icons.flag_outlined, color: ReportColors.flag),
                style: IconButton.styleFrom(
                    backgroundColor: ReportColors.flagDim,
                    shape: const CircleBorder()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
