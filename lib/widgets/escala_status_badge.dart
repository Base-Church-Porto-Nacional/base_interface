import 'package:flutter/material.dart';

import '../models/models.dart';
import 'common.dart';

class EscalaItemStatusBadge extends StatelessWidget {
  const EscalaItemStatusBadge({
    super.key,
    required this.status,
    this.aprovadoPeloVoluntario = false,
  });

  final EscalaItemStatus status;
  final bool aprovadoPeloVoluntario;

  @override
  Widget build(BuildContext context) {
    final badge = StatusBadge(
      label: escalaItemStatusLabel(status).toUpperCase(),
      success: status == EscalaItemStatus.confirmado,
    );
    if (!aprovadoPeloVoluntario) return badge;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        badge,
        const SizedBox(height: 4),
        const StatusBadge(label: 'APROVADO PELO VOLUNTÁRIO', success: true),
      ],
    );
  }
}
