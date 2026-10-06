import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../core/validators.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import 'auth_screens.dart';
import 'facilities_screen.dart' show SectionHeaderInline;
import 'search_screen.dart';

const _defaultCategories = ['Diskusi Umum', 'Kelas Tari', 'Karawitan', 'Topeng', 'Acara & Booking'];

Future<List<String>> _loadCategories() async {
  try {
    final res = await api.get('/forum/categories');
    final list = res['categories'];
    if (list is List && list.isNotEmpty) return list.map((e) => e.toString()).toList();
  } on ApiException {
    // pakai daftar bawaan
  }
  return _defaultCategories;
}

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  String _category = '';
  late Future<List<ThreadSummary>> _future = _load();
  late final Future<List<String>> _categories = _loadCategories();

  Future<List<ThreadSummary>> _load() async {
    final q = <String, String>{if (_category.isNotEmpty) 'category': _category};
    return mapList((await api.get('/forum', query: q))['threads'], ThreadSummary.fromJson);
  }

  void _refresh() => setState(() => _future = _load());

  Future<void> _newThread() async {
    // Lapisan 3: autentikasi sebelum membuat diskusi
    if (!await ensureLogin(context)) return;
    if (!mounted) return;
    final created = await showNewThreadSheet(context);
    if (created == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Forum Diskusi',
      actions: [searchAction(context)],
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.wood800,
        foregroundColor: AppColors.cream100,
        onPressed: _newThread,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Diskusi baru'),
      ),
      body: Column(children: [
        FutureBuilder<List<String>>(
          future: _categories,
          builder: (context, snap) {
            final cats = snap.data ?? const <String>[];
            return SizedBox(
              height: 54,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  for (final c in ['', ...cats])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c.isEmpty ? 'Semua' : c),
                        selected: _category == c,
                        selectedColor: AppColors.gold300,
                        onSelected: (_) {
                          _category = c;
                          _refresh();
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        Expanded(
          child: FutureBuilder<List<ThreadSummary>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator(color: AppColors.gold400));
              }
              if (snap.hasError) return ErrorView(message: snap.error.toString(), onRetry: _refresh);
              final items = snap.data ?? [];
              if (items.isEmpty) return const EmptyState('Belum ada diskusi. Mulai yang pertama!', icon: Icons.forum_outlined);
              return RefreshIndicator(
                onRefresh: () async => _refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final t = items[i];
                    return AppCard(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ThreadScreen(id: t.id))).then((_) => _refresh()),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        TagChip(t.category),
                        const SizedBox(height: 8),
                        Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                        const SizedBox(height: 6),
                        Row(children: [
                          Expanded(child: Text('${t.userName} · ${formatDate(t.date)}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5))),
                          const Icon(Icons.chat_bubble_outline_rounded, size: 15, color: AppColors.inkSoft),
                          const SizedBox(width: 4),
                          Text('${t.replyCount}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
                        ]),
                      ]),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

/// Bottom sheet "Mulai Diskusi Baru" (sesuai desain Figma).
/// Muncul di atas halaman forum, bar navigasi bawah tetap terlihat.
Future<bool?> showNewThreadSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const NewThreadSheet(),
  );
}

class NewThreadSheet extends StatefulWidget {
  const NewThreadSheet({super.key});

  @override
  State<NewThreadSheet> createState() => _NewThreadSheetState();
}

class _NewThreadSheetState extends State<NewThreadSheet> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _content = TextEditingController();
  String _category = _defaultCategories.first;
  bool _busy = false;
  late final Future<List<String>> _categories = _loadCategories();

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Lapisan 1: validasi UI
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      // Lapisan 2: server memvalidasi ulang; Lapisan 3/4: server membaca identitas dari token
      await api.post('/forum', body: {
        'title': Validators.clean(_title.text),
        'content': Validators.clean(_content.text),
        'category': _category,
      });
      if (!mounted) return;
      showSnack(context, 'Diskusi dibuat!');
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _dec(String hint) {
    OutlineInputBorder border(Color c, [double w = 1.5]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.inkSoft),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(AppColors.wood800),
      enabledBorder: border(AppColors.wood800),
      focusedBorder: border(AppColors.gold400, 2),
      errorBorder: border(AppColors.danger),
      focusedErrorBorder: border(AppColors.danger, 2),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 16, color: AppColors.wood900)),
      );

  @override
  Widget build(BuildContext context) {
    // Sheet naik mengikuti keyboard.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFDFAE8),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: AppColors.wood800),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
          child: Form(
            key: _form,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mulai Diskusi Baru', style: headingStyle(size: 28, color: AppColors.wood800)),
                const SizedBox(height: 18),
                _label('Kategori'),
                FutureBuilder<List<String>>(
                  future: _categories,
                  builder: (context, snap) {
                    final cats = snap.data ?? _defaultCategories;
                    if (!cats.contains(_category)) _category = cats.first;
                    return DropdownButtonFormField<String>(
                      value: _category,
                      isExpanded: true,
                      decoration: _dec(''),
                      borderRadius: BorderRadius.circular(16),
                      dropdownColor: Colors.white,
                      items: [for (final c in cats) DropdownMenuItem(value: c, child: Text(c))],
                      onChanged: (v) => setState(() => _category = v ?? _category),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _label('Judul'),
                TextFormField(
                  controller: _title,
                  inputFormatters: InputFormats.maxLen(120),
                  decoration: _dec('Judul diskusi'),
                  validator: Validators.text('Judul', min: 5, max: 120),
                ),
                const SizedBox(height: 14),
                _label('Pertanyaan'),
                TextFormField(
                  controller: _content,
                  minLines: 4,
                  maxLines: 6,
                  inputFormatters: InputFormats.maxLen(2000),
                  decoration: _dec('Tulis pertanyaan Anda di sini...'),
                  validator: Validators.text('Pertanyaan', min: 10, max: 2000),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFFDFAE8),
                        side: const BorderSide(color: AppColors.wood800, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Batal', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _busy ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(_busy ? 'Mengirim...' : 'Kirim', style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ThreadScreen extends StatefulWidget {
  final String id;
  const ThreadScreen({super.key, required this.id});

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  final _form = GlobalKey<FormState>();
  final _reply = TextEditingController();
  late Future<ForumThread> _future = _load();
  bool _busy = false;

  Future<ForumThread> _load() async =>
      ForumThread.fromJson((await api.get('/forum/${Uri.encodeComponent(widget.id)}'))['thread'] as Map<String, dynamic>);

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    if (!await ensureLogin(context)) return;
    setState(() => _busy = true);
    try {
      await api.post('/forum/${Uri.encodeComponent(widget.id)}/replies', body: {'content': Validators.clean(_reply.text)});
      if (!mounted) return;
      _reply.clear();
      FocusScope.of(context).unfocus();
      setState(() => _future = _load());
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Diskusi',
      body: FutureBuilder<ForumThread>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: AppColors.gold400));
          }
          if (snap.hasError) return ErrorView(message: snap.error.toString(), onRetry: () => setState(() => _future = _load()));
          final t = snap.data!;
          return ListView(padding: const EdgeInsets.all(16), children: [
            Align(alignment: Alignment.centerLeft, child: TagChip(t.category)),
            const SizedBox(height: 8),
            Text(t.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.wood900)),
            const SizedBox(height: 4),
            Text('${t.userName} · ${formatDate(t.date)}', style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5)),
            const SizedBox(height: 12),
            Text(t.content, style: const TextStyle(height: 1.5)),
            SectionHeaderInline('Balasan (${t.replies.length})'),
            if (t.replies.isEmpty) const EmptyState('Belum ada balasan.', icon: Icons.chat_bubble_outline_rounded),
            for (final r in t.replies)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  color: AppColors.cream200,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(r.userName, style: const TextStyle(fontWeight: FontWeight.w700))),
                      Text(formatDate(r.date), style: const TextStyle(color: AppColors.inkSoft, fontSize: 12)),
                    ]),
                    const SizedBox(height: 4),
                    Text(r.content),
                  ]),
                ),
              ),
            const SizedBox(height: 8),
            AppCard(
              child: Form(
                key: _form,
                child: Column(children: [
                  TextFormField(
                    controller: _reply,
                    maxLines: 3,
                    inputFormatters: InputFormats.maxLen(1000),
                    decoration: inputDec('Tulis balasan'),
                    validator: Validators.text('Balasan', min: 2, max: 1000),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(onPressed: _busy ? null : _send, child: Text(_busy ? 'Mengirim...' : 'Kirim balasan')),
                  ),
                ]),
              ),
            ),
          ]);
        },
      ),
    );
  }
}