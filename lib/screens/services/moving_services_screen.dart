import 'package:cached_network_image/cached_network_image.dart';
import 'package:eafind/const/constant.dart';
import 'package:eafind/models/chat_item_ref.dart';
import 'package:eafind/models/house_type_model.dart';
import 'package:eafind/providers/usermodel_provider.dart';
import 'package:eafind/screens/authscreen/login_screen.dart';
import 'package:eafind/screens/marketplace/chat_screen.dart';
import 'package:eafind/screens/services/list_service_screen.dart';
import 'package:eafind/screens/services/my_services_screen.dart';
import 'package:eafind/services/service_providers_service.dart';
import 'package:eafind/theme/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// "Moving & home services": movers, cleaners, painters, power, plumbing,
// electrical and fumigation. Providers are marketplace listings in the
// home-service categories (see homeServiceTypes); customers request a quote,
// which opens a chat with the provider pre-filled with the job details.
class MovingServicesScreen extends StatelessWidget {
  // Optional context, e.g. the area of a home the user just secured.
  final String? movingTo;
  const MovingServicesScreen({Key? key, this.movingTo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final deep = Color.lerp(palette.primaryFill, Colors.black, 0.4)!;
    return Scaffold(
      backgroundColor: palette.page,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).padding.top + 8, 20, 26),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [palette.primaryFill, deep],
                ),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    onPressed: () => goBack(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Moving soon?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Find movers, cleaners and handymen for your new home, '
                    'and get quotes in the app.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // How it works
                  Row(
                    children: const [
                      _Step(n: 1, text: 'Pick a\nservice'),
                      _StepLine(),
                      _Step(n: 2, text: 'Request a\nquote'),
                      _StepLine(),
                      _Step(n: 3, text: 'Chat &\nagree price'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final type = homeServiceTypes[i];
                  final info = homeServiceInfo[type]!;
                  return _CategoryTile(
                    type: type,
                    info: info,
                    onTap: () => goTo(
                      context,
                      ServiceProvidersScreen(category: type, movingTo: movingTo),
                      false,
                    ),
                  );
                },
                childCount: homeServiceTypes.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  16, 8, 16, 24 + MediaQuery.of(context).padding.bottom),
              child: const _ProviderCta(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final int n;
  final String text;
  const _Step({required this.n, required this.text});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color(0xFFF5C76A),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text('$n',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: Color(0xFF3F224F))),
            ),
          ),
          const SizedBox(height: 6),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11.5,
                  height: 1.25,
                  color: Colors.white.withValues(alpha: 0.85))),
        ],
      );
}

class _StepLine extends StatelessWidget {
  const _StepLine();
  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          height: 2,
          margin: const EdgeInsets.only(bottom: 34, left: 6, right: 6),
          color: Colors.white.withValues(alpha: 0.25),
        ),
      );
}

class _CategoryTile extends StatelessWidget {
  final String type;
  final HomeServiceInfo info;
  final VoidCallback onTap;
  const _CategoryTile(
      {required this.type, required this.info, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: info.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(info.icon, color: info.color, size: 24),
              ),
              const Spacer(),
              Text(type,
                  style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: palette.ink)),
              const SizedBox(height: 2),
              Text(info.blurb,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: palette.inkSoft)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderCta extends StatelessWidget {
  final String? category;
  const _ProviderCta({this.category});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.primaryFill.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.handyman_rounded, color: palette.accent, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Offer one of these services?',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: palette.ink)),
                    const SizedBox(height: 2),
                    Text(
                        'List your business and get requests from people moving home.',
                        style: TextStyle(fontSize: 12, color: palette.inkSoft)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _requireLogin(context,
                      () => goTo(context, ListServiceScreen(initialCategory: category), false)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.primaryFill,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('List your service'),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => _requireLogin(
                    context, () => goTo(context, const MyServicesScreen(), false)),
                child: const Text('My services'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _requireLogin(BuildContext context, VoidCallback then) {
  if (context.read<UsermodelProvider>().getUserModel() == null) {
    showToast('Log in to continue');
    goTo(context, const LoginScreen(fromNav: false), false);
    return;
  }
  then();
}

// ── Providers in one category ─────────────────────────────────────────────
class ServiceProvidersScreen extends StatefulWidget {
  final String category;
  final String? movingTo;
  const ServiceProvidersScreen({Key? key, required this.category, this.movingTo})
      : super(key: key);

  @override
  State<ServiceProvidersScreen> createState() => _ServiceProvidersScreenState();
}

class _ServiceProvidersScreenState extends State<ServiceProvidersScreen> {
  List<ServiceProvider>? _providers;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = await ServiceProvidersService.byCategory(widget.category);
    if (!mounted) return;
    setState(() {
      _providers = r.data ?? [];
      _error = r.error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final info = homeServiceInfo[widget.category];
    final providers = _providers;
    return Scaffold(
      backgroundColor: palette.page,
      appBar: AppBar(
        backgroundColor: palette.page,
        elevation: 0,
        iconTheme: IconThemeData(color: palette.ink),
        title: Text(widget.category,
            style: TextStyle(color: palette.ink, fontWeight: FontWeight.w700)),
      ),
      body: providers == null
          ? Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2.4, color: palette.accent))
          : RefreshIndicator(
              color: palette.accent,
              onRefresh: _load,
              child: providers.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(28, 70, 28, 0),
                      children: [
                        Icon(info?.icon ?? Icons.handyman_rounded,
                            size: 56, color: palette.inkMuted),
                        const SizedBox(height: 14),
                        Text(
                            _error ??
                                'No ${widget.category.toLowerCase()} providers yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: palette.ink)),
                        const SizedBox(height: 6),
                        Text(
                            'New providers are joining. Know a good one? Ask them to list on Aboostoplus.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: palette.inkSoft)),
                        const SizedBox(height: 18),
                        _ProviderCta(category: widget.category),
                      ],
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(16, 8, 16,
                          24 + MediaQuery.of(context).padding.bottom),
                      itemCount: providers.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => i == providers.length
                          ? _ProviderCta(category: widget.category)
                          : _ProviderCard(
                              provider: providers[i],
                              movingTo: widget.movingTo,
                            ),
                    ),
            ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final ServiceProvider provider;
  final String? movingTo;
  const _ProviderCard({required this.provider, this.movingTo});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final p = provider;
    final info = homeServiceInfo[p.category];
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Work photos strip
          if (p.images.isNotEmpty)
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                itemCount: p.images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: p.images.length == 1
                        ? MediaQuery.of(context).size.width - 72
                        : 200,
                    child: CachedNetworkImage(
                      imageUrl: p.images[i],
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: palette.tile),
                      errorWidget: (_, __, ___) => Container(color: palette.tile),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(p.businessName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              color: palette.ink)),
                    ),
                    if (p.startingPrice != null && p.startingPrice! > 0)
                      Text(
                        'From ₦${NumberFormat('#,##0').format(p.startingPrice)}',
                        style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: palette.accent),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 13, color: palette.inkMuted),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text('${p.areas} · ${p.state}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 12, color: palette.inkSoft)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(p.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13, height: 1.4, color: palette.inkSoft)),
                if (p.ownerName.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: palette.tile,
                        backgroundImage: p.ownerImage.isNotEmpty
                            ? NetworkImage(p.ownerImage)
                            : null,
                      ),
                      const SizedBox(width: 6),
                      Text('Listed by ${p.ownerName}',
                          style:
                              TextStyle(fontSize: 11.5, color: palette.inkMuted)),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => launchUrl(Uri.parse('tel:${p.phone}')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.ink,
                          side: BorderSide(color: palette.border),
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(Icons.call_rounded,
                            size: 18, color: info?.color ?? palette.accent),
                        label: const Text('Call'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => showQuoteRequestSheet(context, p,
                            movingTo: movingTo),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: palette.primaryFill,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.request_quote_rounded, size: 18),
                        label: const Text('Request a quote',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quote request ─────────────────────────────────────────────────────────
Future<void> showQuoteRequestSheet(
  BuildContext context,
  ServiceProvider provider, {
  String? movingTo,
}) async {
  final me = context.read<UsermodelProvider>().getUserModel();
  if (me == null) {
    showToast('Log in to request a quote');
    goTo(context, const LoginScreen(fromNav: false), false);
    return;
  }
  if (me.id == provider.ownerId) {
    showToast('This is your own service');
    return;
  }
  final message = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuoteForm(category: provider.category, movingTo: movingTo),
  );
  if (message == null || !context.mounted) return;
  goTo(
    context,
    ChatScreen(
      currentUserId: me.id,
      receiverId: provider.ownerId,
      senderName: me.firstName,
      senderImage: me.profileImage,
      // Pins the service in the chat for both sides.
      item: ChatItemRef(
        type: 'service',
        id: provider.id.toString(),
        title: provider.businessName,
        image: provider.images.isNotEmpty ? provider.images.first : '',
        amount: provider.startingPrice ?? 0,
      ),
      initialMessage: message,
    ),
    false,
  );
}


class _QuoteForm extends StatefulWidget {
  final String category;
  final String? movingTo;
  const _QuoteForm({required this.category, this.movingTo});

  @override
  State<_QuoteForm> createState() => _QuoteFormState();
}

class _QuoteFormState extends State<_QuoteForm> {
  final _from = TextEditingController();
  late final _to = TextEditingController(text: widget.movingTo ?? '');
  final _notes = TextEditingController();
  DateTime? _date;
  String _size = '1–2 bedroom';

  bool get _isMoving => widget.category == 'Moving & Haulage';

  static const _sizes = ['Room / self-con', '1–2 bedroom', '3+ bedroom', 'Office'];

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (d != null) setState(() => _date = d);
  }

  String? _validate() {
    if (_isMoving && _from.text.trim().isEmpty) return 'Where are you moving from?';
    if (_to.text.trim().isEmpty) {
      return _isMoving ? 'Where are you moving to?' : 'Where is the job?';
    }
    if (_date == null) return 'Pick a date';
    return null;
  }

  void _submit() {
    final error = _validate();
    if (error != null) {
      showToast(error);
      return;
    }
    final date = DateFormat('EEE, d MMM yyyy').format(_date!);
    final notes = _notes.text.trim();
    final lines = <String>[
      'Hi, I found you on Aboostoplus and would like a quote for '
          '${widget.category.toLowerCase()}.',
      if (_isMoving) '• From: ${_from.text.trim()}',
      _isMoving ? '• To: ${_to.text.trim()}' : '• Location: ${_to.text.trim()}',
      '• Date: $date',
      '• Size: $_size',
      if (notes.isNotEmpty) '• Details: $notes',
      'What would it cost?',
    ];
    Navigator.pop(context, lines.join('\n'));
  }

  InputDecoration _decoration(AppPalette palette, String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: palette.card,
        isDense: true,
        prefixIcon: Icon(icon, size: 19, color: palette.accent),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.accent, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final info = homeServiceInfo[widget.category];
    return Container(
      decoration: BoxDecoration(
        color: palette.paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(info?.icon ?? Icons.handyman_rounded,
                      color: info?.color ?? palette.accent),
                  const SizedBox(width: 10),
                  Text('Request a quote',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: palette.ink)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Your details go to the provider in a chat, where you can agree a price.',
                style: TextStyle(fontSize: 12.5, color: palette.inkSoft),
              ),
              const SizedBox(height: 16),
              if (_isMoving) ...[
                TextField(
                  controller: _from,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration(palette, 'Moving from (area)',
                      Icons.trip_origin_rounded),
                ),
                const SizedBox(height: 10),
              ],
              TextField(
                controller: _to,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration(
                    palette,
                    _isMoving ? 'Moving to (area)' : 'Job location (area)',
                    Icons.location_on_rounded),
              ),
              const SizedBox(height: 10),
              Material(
                color: palette.card,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: palette.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event_rounded,
                            size: 19, color: palette.accent),
                        const SizedBox(width: 12),
                        Text(
                          _date == null
                              ? 'Pick a date'
                              : DateFormat('EEEE, d MMM yyyy').format(_date!),
                          style: TextStyle(
                              color: _date == null
                                  ? palette.inkMuted
                                  : palette.ink),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Home size',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: palette.ink)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in _sizes)
                    ChoiceChip(
                      label: Text(s),
                      selected: _size == s,
                      onSelected: (_) => setState(() => _size = s),
                      selectedColor: palette.primaryFill,
                      labelStyle: TextStyle(
                        color: _size == s ? Colors.white : palette.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _notes,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration(palette, 'Anything else? (optional)',
                    Icons.notes_rounded),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.primaryFill,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                  label: const Text('Continue to chat',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
