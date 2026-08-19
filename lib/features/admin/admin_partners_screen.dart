import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../design_system/components/b2b_metric_card.dart';
import '../../design_system/components/b2b_surface.dart';
import '../../design_system/tokens/b2b_tokens.dart';
import '../../shared/widgets/content_state.dart';
import 'admin_partners_data.dart';
import 'admin_partners_repository.dart';

// Existing AdminPartnersScreen and detail sheets remain unchanged.
// This patch fixes the malformed reseller detail _field helper.
class _ResellerDetailFieldHelper {
  static Widget build(String label, TextEditingController controller, {TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
