import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/auth_state.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../core/validators.dart';
import '../repositories/forum_repository.dart';
import '../viewmodels/base_viewmodel.dart';
import '../viewmodels/forum_list_viewmodel.dart';
import '../viewmodels/new_thread_viewmodel.dart';
import '../viewmodels/thread_detail_viewmodel.dart';
import '../widgets/common.dart';
import '../widgets/load_status_view.dart';
import 'auth_screens.dart';

class ForumScreen extends StatelessWidget {
  const ForumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => ForumListViewModel(c.read<ForumRepository>())..load(),
      child: const _ForumView(),
    );
  }
}

class _ForumView extends StatefulWidget {
  const _ForumView();

  @override
  State<_ForumView> createState() => _ForumViewState();
}

class _ForumViewState extends State<_ForumView> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _newThread() async {
    final vm = context.read<ForumListViewModel>();
    if (!await ensureLogin(context)) return;
    if (!mounted) return;
    final created = await showNewThreadSheet(context);
    if (created == true) vm.load();
  }

  OutlineInputBorder _noBorder() =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none);

  Widget _searchBar(ForumListViewModel vm) => TextField(
        controller: _search,
        onChanged: vm.setQuery,
        cursorColor: Colors.white,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Cari topik diskusi',
          hintStyle: const TextStyle(color: Colors.white, fontSize: 16),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white),
          suffixIcon: vm.query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () {
                    _search.clear();
                    vm.setQuery('');
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

  Widget _filterDropdown(ForumListViewModel vm) {
    final items = ['', ...ForumListViewModel.filterCategories];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.wood700, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: vm.category,
          isExpanded: true,
          borderRadius: BorderRadius.circular(16),
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.wood700),
          style: const TextStyle(fontSize: 15, color: AppColors.wood700),
          items: [
            for (final c in items) DropdownMenuItem(value: c, child: Text(c.isEmpty ? 'Semua kategori' : c)),
          ],
          onChanged: (v) => vm.setCategory(v ?? ''),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ForumListViewModel>();
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
          child: _searchBar(vm),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: _filterDropdown(vm),
        ),
        Expanded(child: _list(vm)),
      ]),
    );
  }

  Widget _list(ForumListViewModel vm) {
    switch (vm.status) {
      case LoadStatus.loading:
        return const Center(child: CircularProgressIndicator(color: AppColors.gold400));
      case LoadStatus.error:
        return ErrorView(message: vm.error ?? '', onRetry: vm.load);
      case LoadStatus.success:
        final items = vm.threads;
        if (items.isEmpty) {
          return EmptyState(
            vm.isEmptyOnServer ? 'Belum ada diskusi. Mulai yang pertama!' : 'Tidak ada diskusi yang cocok.',
            icon: Icons.forum_outlined,
          );
        }
        return RefreshIndicator(
          onRefresh: () async => vm.load(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final t = items[i];
              return InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ThreadScreen(id: t.id)))
                    .then((_) => vm.load()),
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
    }
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

class NewThreadSheet extends StatelessWidget {
  const NewThreadSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => NewThreadViewModel(c.read<ForumRepository>())..loadCategories(),
      child: const _NewThreadForm(),
    );
  }
}

class _NewThreadForm extends StatefulWidget {
  const _NewThreadForm();

  @override
  State<_NewThreadForm> createState() => _NewThreadFormState();
}

class _NewThreadFormState extends State<_NewThreadForm> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _content = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final vm = context.read<NewThreadViewModel>();
    final ok = await vm.submit(title: _title.text, content: _content.text);
    if (!mounted) return;
    if (ok) {
      showSnack(context, 'Diskusi dibuat!');
      Navigator.pop(context, true);
    } else {
      showSnack(context, vm.error ?? 'Terjadi kesalahan. Coba lagi.');
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
    final vm = context.watch<NewThreadViewModel>();
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
                DropdownButtonFormField<String>(
                  key: ValueKey('${vm.categories.length}-${vm.selectedCategory}'),
                  initialValue: vm.selectedCategory,
                  isExpanded: true,
                  decoration: _dec(''),
                  borderRadius: BorderRadius.circular(16),
                  dropdownColor: Colors.white,
                  items: [for (final c in vm.categories) DropdownMenuItem(value: c, child: Text(c))],
                  onChanged: (v) {
                    if (v != null) vm.selectCategory(v);
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
                      onPressed: vm.busy ? null : () => Navigator.pop(context),
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
                      onPressed: vm.busy ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(vm.busy ? 'Mengirim...' : 'Kirim', style: const TextStyle(fontSize: 18)),
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

class ThreadScreen extends StatelessWidget {
  final String id;
  const ThreadScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => ThreadDetailViewModel(c.read<ForumRepository>(), id)..load(),
      child: const _ThreadView(),
    );
  }
}

class _ThreadView extends StatefulWidget {
  const _ThreadView();

  @override
  State<_ThreadView> createState() => _ThreadViewState();
}

class _ThreadViewState extends State<_ThreadView> {
  final _form = GlobalKey<FormState>();
  final _reply = TextEditingController();

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_form.currentState!.validate()) return;
    if (!await ensureLogin(context)) return;
    if (!mounted) return;
    final vm = context.read<ThreadDetailViewModel>();
    final ok = await vm.sendReply(_reply.text);
    if (!mounted) return;
    if (ok) {
      _reply.clear();
      FocusScope.of(context).unfocus();
    } else {
      showSnack(context, vm.sendError ?? 'Terjadi kesalahan. Coba lagi.');
    }
  }

  OutlineInputBorder _border(Color c, [double w = 1.5]) =>
      OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c, width: w));

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ThreadDetailViewModel>();
    final loggedIn = context.watch<AuthState>().isLoggedIn;
    return AppScaffold(
      title: 'Forum Diskusi',
      backgroundColor: Colors.white,
      body: LoadStatusView(
        status: vm.status,
        error: vm.error,
        onRetry: vm.load,
        builder: (context) {
          final t = vm.thread!;
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
                      onPressed: vm.sending ? null : _send,
                      child: Text(vm.sending ? 'Mengirim...' : 'Kirim balasan', style: const TextStyle(fontSize: 16)),
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