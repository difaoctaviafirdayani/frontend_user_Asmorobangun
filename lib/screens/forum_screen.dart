import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/auth_state.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../core/validators.dart';
import '../models/models.dart';
import '../widgets/common.dart';
import 'auth_screens.dart';

const _defaultCategories = ['Diskusi Umum', 'Kelas Tari', 'Karawitan', 'Topeng', 'Acara & Booking'];

Future<List<String>> _loadCategories() async {
  try {
    final res = await api.get('/forum/categories');
    final list = res['categories'];
    if (list is List && list.isNotEmpty) return list.map((e) => e.toString()).toList();
  } on ApiException {}
  return _defaultCategories;
}

const _filterCategories = ['Diskusi Umum', 'Layanan'];

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final _search = TextEditingController();
  String _category = '';
  String _query = '';
  late Future<List<ThreadSummary>> _future = _load();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<ThreadSummary>> _load() async =>
      mapList((await api.get('/forum'))['threads'], ThreadSummary.fromJson);

  void _refresh() {
    final future = _load();
    setState(() {
      _future = future;
    });
  }

  Future<void> _newThread() async {
    if (!await ensureLogin(context)) return;
    if (!mounted) return;
    final created = await showNewThreadSheet(context);
    if (created == true) _refresh();
  }

  OutlineInputBorder _noBorder() =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none);

  Widget _searchBar() => TextField(
        controller: _search,
        onChanged: (v) => setState(() => _query = v),
        cursorColor: Colors.white,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Cari topik diskusi',
          hintStyle: const TextStyle(color: Colors.white, fontSize: 16),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                ),
          filled: true,
          fillColor: AppColors.wood700,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: _noBorder(),
          enabledBorder: _noBorder(),
          focusedBorder: _noBorder(),
        ),
      );

  Widget _filterDropdown() {
    final items = ['', ..._filterCategories];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.wood700, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _category,
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.wood700),
          style: const TextStyle(fontSize: 15, color: AppColors.wood700),
          items: [
            for (final c in items) DropdownMenuItem(value: c, child: Text(c.isEmpty ? 'Semua kategori' : c)),
          ],
          onChanged: (v) => setState(() => _category = v ?? ''),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Forum Diskusi',
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.wood700,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        onPressed: _newThread,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Diskusi Baru', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: _searchBar(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: _filterDropdown(),
        ),
        Expanded(
          child: FutureBuilder<List<ThreadSummary>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator(color: AppColors.gold400));
              }
              if (snap.hasError) return ErrorView(message: snap.error.toString(), onRetry: _refresh);
              final q = _query.trim().toLowerCase();
              final items = (snap.data ?? []).where((t) {
                final okCat = _category.isEmpty || t.category.toLowerCase() == _category.toLowerCase();
                final okQ = q.isEmpty || t.title.toLowerCase().contains(q);
                return okCat && okQ;
              }).toList();
              if (items.isEmpty) {
                return EmptyState(
                  (snap.data ?? []).isEmpty ? 'Belum ada diskusi. Mulai yang pertama!' : 'Tidak ada diskusi yang cocok.',
                  icon: Icons.forum_outlined,
                );
              }
              return RefreshIndicator(
                onRefresh: () async => _refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final t = items[i];
                    return InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ThreadScreen(id: t.id)))
                          .then((_) => _refresh()),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(2, 12, 2, 10),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.wood700, width: 1.2)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t.category.toUpperCase(),
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.wood700)),
                          const SizedBox(height: 2),
                          Text(t.title,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, height: 1.35, color: AppColors.wood700)),
                          const SizedBox(height: 2),
                          Text('${t.userName} - ${formatDateLong(t.date)} - ${t.replyCount} balasan',
                              style: const TextStyle(fontSize: 14, color: AppColors.wood700)),
                        ]),
                      ),
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
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
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

  OutlineInputBorder _border(Color c, [double w = 1.5]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c, width: w));

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.watch<AuthState>().isLoggedIn;
    return AppScaffold(
      title: 'Forum Diskusi',
      backgroundColor: Colors.white,
      body: FutureBuilder<ForumThread>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: AppColors.gold400));
          }
          if (snap.hasError) return ErrorView(message: snap.error.toString(), onRetry: () => setState(() => _future = _load()));
          final t = snap.data!;
          const brown = AppColors.wood700;
          return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), children: [
            Container(
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 12),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: brown, width: 1.2))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.category.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: brown)),
                const SizedBox(height: 2),
                Text(t.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, height: 1.35, color: brown)),
                const SizedBox(height: 2),
                Text('${t.userName} - ${formatDateLong(t.date)} - ${t.replies.length} balasan',
                    style: const TextStyle(fontSize: 14, color: brown)),
                if (t.content.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(t.content, style: const TextStyle(height: 1.5, fontSize: 15, color: brown)),
                ],
              ]),
            ),
            const SizedBox(height: 14),
            Text('${t.replies.length} balasan', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: brown)),
            const SizedBox(height: 10),
            for (final r in t.replies)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: brown, width: 1.2),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(r.userName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: brown))),
                      Text(formatDateLong(r.date), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: brown)),
                    ]),
                    const SizedBox(height: 4),
                    Text(r.content, style: const TextStyle(height: 1.45, fontSize: 15, color: brown)),
                  ]),
                ),
              ),
            const SizedBox(height: 4),
            if (!loggedIn)
              GestureDetector(
                onTap: () => ensureLogin(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDCB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: brown, width: 1.5),
                  ),
                  child: const Text('Masuk untuk membalas diskusi ini.', style: TextStyle(fontSize: 16, color: brown)),
                ),
              )
            else
              Form(
                key: _form,
                child: Column(children: [
                  TextFormField(
                    controller: _reply,
                    maxLines: 3,
                    inputFormatters: InputFormats.maxLen(1000),
                    decoration: InputDecoration(
                      hintText: 'Tulis balasan',
                      hintStyle: const TextStyle(color: AppColors.inkSoft),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                      border: _border(brown),
                      enabledBorder: _border(brown),
                      focusedBorder: _border(AppColors.gold400, 2),
                      errorBorder: _border(AppColors.danger),
                      focusedErrorBorder: _border(AppColors.danger, 2),
                    ),
                    validator: Validators.text('Balasan', min: 2, max: 1000),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brown,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: _busy ? null : _send,
                      child: Text(_busy ? 'Mengirim...' : 'Kirim balasan', style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ]),
              ),
          ]);
        },
      ),
    );
  }
}