import 'package:flutter/material.dart';
import 'package:crm/core/theme/theme.dart';
import 'package:crm/core/state/state.dart';
import '../../domain/controller/support_controller.dart';
import '../state/support_state.dart';

class SupportSection extends StatefulWidget {
  final SupportController controller;
  const SupportSection({super.key, required this.controller});

  @override
  State<SupportSection> createState() => _SupportSectionState();
}

class _SupportSectionState extends State<SupportSection> {
  String? _filter;

  void _applyFilter(String? status) {
    setState(() => _filter = status);
    widget.controller.load(status: status);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(filter: _filter, onFilter: _applyFilter),
        Expanded(
          child: StreamBuilder<AsyncState<List<SupportTicket>>>(
            stream: widget.controller.stream,
            initialData: widget.controller.state,
            builder: (_, snapshot) {
              final state = snapshot.data!;
              return switch (state) {
                AsyncLoading() => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                AsyncError(:final message) => Center(child: Text(message, style: AppStyling.bodySm)),
                AsyncData(:final data) => data.isEmpty
                    ? Center(child: Text('No tickets', style: AppStyling.bodySm))
                    : _TicketList(tickets: data, controller: widget.controller),
              };
            },
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String? filter;
  final ValueChanged<String?> onFilter;

  const _Header({required this.filter, required this.onFilter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyling.spaceXl,
        vertical: AppStyling.spaceLg,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Support', style: AppStyling.headingLg),
              Text('Tickets submitted from the landing page', style: AppStyling.bodySm),
            ],
          ),
          const Spacer(),
          _FilterChip(label: 'All', selected: filter == null, onTap: () => onFilter(null)),
          const SizedBox(width: AppStyling.spaceSm),
          _FilterChip(label: 'Open', selected: filter == 'open', onTap: () => onFilter('open')),
          const SizedBox(width: AppStyling.spaceSm),
          _FilterChip(label: 'In Review', selected: filter == 'in-review', onTap: () => onFilter('in-review')),
          const SizedBox(width: AppStyling.spaceSm),
          _FilterChip(label: 'Resolved', selected: filter == 'resolved', onTap: () => onFilter('resolved')),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppStyling.spaceMd, vertical: AppStyling.spaceSm),
        decoration: BoxDecoration(
          color: selected ? AppColors.accentKeepTrack.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppStyling.radiusMd),
          border: Border.all(
            color: selected ? AppColors.accentKeepTrack.withValues(alpha: 0.4) : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppStyling.bodySm.copyWith(
            color: selected ? AppColors.accentKeepTrack : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _TicketList extends StatelessWidget {
  final List<SupportTicket> tickets;
  final SupportController controller;

  const _TicketList({required this.tickets, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppStyling.spaceXl),
      itemCount: tickets.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppStyling.spaceMd),
      itemBuilder: (_, i) => _TicketCard(ticket: tickets[i], controller: controller),
    );
  }
}

class _TicketCard extends StatefulWidget {
  final SupportTicket ticket;
  final SupportController controller;

  const _TicketCard({required this.ticket, required this.controller});

  @override
  State<_TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<_TicketCard> {
  bool _expanded = false;
  late bool _seen;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.ticket.adminNote ?? '');
    _seen = widget.controller.isSeen(widget.ticket.id);
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Color _typeColor(TicketType t) => switch (t) {
        TicketType.bug => AppColors.error,
        TicketType.question => AppColors.info,
        TicketType.feature => AppColors.success,
        TicketType.other => AppColors.textMuted,
      };

  Color _statusColor(TicketStatus s) => switch (s) {
        TicketStatus.open => AppColors.warning,
        TicketStatus.inReview => AppColors.info,
        TicketStatus.resolved => AppColors.success,
      };

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    final typeColor = _typeColor(t.type);
    final statusColor = _statusColor(t.status);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppStyling.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() => _expanded = !_expanded);
              if (!_seen) {
                widget.controller.markTicketSeen(widget.ticket.id);
                setState(() => _seen = true);
              }
            },
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.all(AppStyling.spaceLg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type strip
                  Container(
                    width: 3,
                    height: 40,
                    margin: const EdgeInsets.only(right: AppStyling.spaceMd),
                    decoration: BoxDecoration(
                      color: typeColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _Badge(label: t.type.label, color: typeColor),
                            const SizedBox(width: AppStyling.spaceSm),
                            _Badge(label: t.status.label, color: statusColor),
                            const Spacer(),
                            Text(_timeAgo(t.createdAt), style: AppStyling.monoSm.copyWith(color: AppColors.textMuted)),
                          ],
                        ),
                        const SizedBox(height: AppStyling.spaceSm),
                        Row(
                          children: [
                            if (!_seen)
                              Container(
                                width: 7,
                                height: 7,
                                margin: const EdgeInsets.only(right: AppStyling.spaceSm),
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Expanded(
                              child: Text(t.subject, style: AppStyling.bodyLg.copyWith(fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        Text('${t.name} · ${t.email}', style: AppStyling.bodySm.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppStyling.spaceMd),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, thickness: 0.5, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(AppStyling.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Message', style: AppStyling.label),
                  const SizedBox(height: AppStyling.spaceSm),
                  Text(t.message, style: AppStyling.bodySm),
                  if (t.imageUrls.isNotEmpty) ...[
                    const SizedBox(height: AppStyling.spaceLg),
                    Text('Attachments', style: AppStyling.label),
                    const SizedBox(height: AppStyling.spaceSm),
                    Wrap(
                      spacing: AppStyling.spaceSm,
                      runSpacing: AppStyling.spaceSm,
                      children: t.imageUrls.map((url) => GestureDetector(
                        onTap: () => showDialog(
                          context: context,
                          builder: (_) => _ImagePreviewDialog(url: url),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                          child: Image.network(
                            url,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 80,
                              height: 80,
                              color: AppColors.border,
                              child: Icon(Icons.broken_image_outlined, size: 20, color: AppColors.textMuted),
                            ),
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: AppStyling.spaceLg),
                  Text('Status', style: AppStyling.label),
                  const SizedBox(height: AppStyling.spaceSm),
                  Row(
                    children: TicketStatus.values.map((s) => Padding(
                      padding: const EdgeInsets.only(right: AppStyling.spaceSm),
                      child: GestureDetector(
                        onTap: t.status == s ? null : () => widget.controller.updateStatus(t.id, s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppStyling.spaceMd, vertical: AppStyling.spaceSm),
                          decoration: BoxDecoration(
                            color: t.status == s ? _statusColor(s).withValues(alpha: 0.12) : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                            border: Border.all(
                              color: t.status == s ? _statusColor(s).withValues(alpha: 0.4) : AppColors.border,
                            ),
                          ),
                          child: Text(
                            s.label,
                            style: AppStyling.bodySm.copyWith(
                              color: t.status == s ? _statusColor(s) : AppColors.textSecondary,
                              fontWeight: t.status == s ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                  const SizedBox(height: AppStyling.spaceLg),
                  Text('Admin Note', style: AppStyling.label),
                  const SizedBox(height: AppStyling.spaceSm),
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 3,
                    style: AppStyling.bodySm,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      hintText: 'Add a private note…',
                      hintStyle: AppStyling.bodySm.copyWith(color: AppColors.textMuted),
                      contentPadding: const EdgeInsets.all(AppStyling.spaceMd),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                        borderSide: const BorderSide(color: AppColors.accentKeepTrack),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppStyling.spaceMd),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => widget.controller.delete(t.id),
                        child: Icon(Icons.delete_outline, size: 16, color: AppColors.textMuted),
                      ),
                      const SizedBox(width: AppStyling.spaceLg),
                      GestureDetector(
                        onTap: () => widget.controller.saveNote(t.id, _noteCtrl.text.trim()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppStyling.spaceLg, vertical: AppStyling.spaceSm),
                          decoration: BoxDecoration(
                            color: AppColors.accentKeepTrack,
                            borderRadius: BorderRadius.circular(AppStyling.radiusMd),
                          ),
                          child: Text('Save Note', style: AppStyling.bodySm.copyWith(color: Colors.black, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImagePreviewDialog extends StatelessWidget {
  final String url;
  const _ImagePreviewDialog({required this.url});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppStyling.radiusLg),
            child: Image.network(url, fit: BoxFit.contain),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              margin: const EdgeInsets.all(AppStyling.spaceSm),
              padding: const EdgeInsets.all(AppStyling.spaceSm),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(AppStyling.radiusMd),
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppStyling.spaceSm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppStyling.radiusSm),
      ),
      child: Text(label, style: AppStyling.monoSm.copyWith(color: color, fontSize: 10)),
    );
  }
}
