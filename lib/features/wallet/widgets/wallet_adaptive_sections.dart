import 'package:flutter/material.dart';

import '../../../shared/widgets/adaptive_split_view.dart';

/// Places the wallet summary and transaction history in a single column on
/// phones and side by side on tablets and desktop-sized windows.
class WalletAdaptiveSections extends StatelessWidget {
  const WalletAdaptiveSections({
    super.key,
    required this.summary,
    required this.transactions,
  });

  final Widget summary;
  final Widget transactions;

  @override
  Widget build(BuildContext context) {
    return AdaptiveSplitView(
      breakpoint: 920,
      gap: 20,
      primaryFlex: 5,
      secondaryFlex: 7,
      primary: summary,
      secondary: transactions,
    );
  }
}
