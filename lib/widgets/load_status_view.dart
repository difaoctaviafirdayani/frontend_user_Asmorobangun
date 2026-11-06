import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../viewmodels/base_viewmodel.dart';
import 'common.dart';

class LoadStatusView extends StatelessWidget {
  final LoadStatus status;
  final String? error;
  final VoidCallback onRetry;
  final WidgetBuilder builder;
  const LoadStatusView({
    super.key,
    required this.status,
    required this.error,
    required this.onRetry,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case LoadStatus.loading:
        return const Center(
          child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.gold400)),
        );
      case LoadStatus.error:
        return ErrorView(message: error ?? 'Terjadi kesalahan. Coba lagi.', onRetry: onRetry);
      case LoadStatus.success:
        return builder(context);
    }
  }
}
