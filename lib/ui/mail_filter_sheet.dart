import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/mail.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
const Key mailFilterCloseKey = ValueKey<String>('mail-filter-close');
const Key mailFilterTextKey = ValueKey<String>('mail-filter-text');
const Key mailFilterFromKey = ValueKey<String>('mail-filter-from');
const Key mailFilterToKey = ValueKey<String>('mail-filter-to');
const Key mailFilterOlderThanAmountKey = ValueKey<String>(
  'mail-filter-older-amount',
);
Key mailFilterUnitKey(MailAgeUnit unit) =>
    ValueKey<String>('mail-filter-unit-${unit.name}');
const Key mailFilterApplyKey = ValueKey<String>('mail-filter-apply');
const Key mailFilterClearKey = ValueKey<String>('mail-filter-clear');

/// The pane FILTER opens: free text (subject or body), From, To, and an
/// "older than" cutoff (a number and a unit). Opened with whatever filter is
/// already applied, so reopening shows what is currently in effect. APPLY
/// returns the filter built from what is typed and chosen; CLEAR ALL returns
/// an empty one; the X returns null (no change, whatever was applied stays
/// applied).
Future<MailFilter?> showMailFilterSheet(
  BuildContext context, {
  required MailFilter initial,
}) {
  return showModalBottomSheet<MailFilter?>(
    context: context,
    backgroundColor: TileColors.canvas,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _MailFilterSheet(initial: initial),
    ),
  );
}

class _MailFilterSheet extends StatefulWidget {
  const _MailFilterSheet({required this.initial});

  final MailFilter initial;

  @override
  State<_MailFilterSheet> createState() => _MailFilterSheetState();
}

class _MailFilterSheetState extends State<_MailFilterSheet> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initial.text,
  );
  late final TextEditingController _from = TextEditingController(
    text: widget.initial.from,
  );
  late final TextEditingController _to = TextEditingController(
    text: widget.initial.to,
  );
  late final TextEditingController _amount = TextEditingController(
    text: widget.initial.olderThan == null
        ? ''
        : '${widget.initial.olderThan!.amount}',
  );
  late MailAgeUnit _unit = widget.initial.olderThan?.unit ?? MailAgeUnit.days;

  @override
  void dispose() {
    _text.dispose();
    _from.dispose();
    _to.dispose();
    _amount.dispose();
    super.dispose();
  }

  MailFilter _build() {
    final int? amount = int.tryParse(_amount.text.trim());
    return MailFilter(
      text: _text.text.trim(),
      from: _from.text.trim(),
      to: _to.text.trim(),
      olderThan: amount == null || amount <= 0
          ? null
          : MailOlderThan(amount, _unit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(TileMetrics.margin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      Messages.mailFilterTitle,
                      style: text.bodyMedium?.copyWith(
                        color: TileColors.textBright,
                      ),
                    ),
                  ),
                  _Button(
                    key: mailFilterCloseKey,
                    label: 'X',
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(height: 2, color: TileColors.bezel),
              const SizedBox(height: TileMetrics.margin),
              _Field(
                fieldKey: mailFilterTextKey,
                label: Messages.mailFilterText,
                controller: _text,
              ),
              _Field(
                fieldKey: mailFilterFromKey,
                label: Messages.mailFilterFrom,
                controller: _from,
                keyboardType: TextInputType.emailAddress,
              ),
              _Field(
                fieldKey: mailFilterToKey,
                label: Messages.mailFilterTo,
                controller: _to,
                keyboardType: TextInputType.emailAddress,
              ),
              Text(
                Messages.mailFilterOlderThan,
                style: text.bodySmall?.copyWith(
                  fontSize: 8,
                  color: TileColors.muted,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 56,
                    child: TextField(
                      key: mailFilterOlderThanAmountKey,
                      controller: _amount,
                      keyboardType: TextInputType.number,
                      style: text.bodySmall?.copyWith(
                        fontSize: 12,
                        color: TileColors.textBright,
                      ),
                      cursorColor: TileColors.textBright,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: TileColors.bezel),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: TileColors.textBright),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: <Widget>[
                          for (final MailAgeUnit unit in MailAgeUnit.values)
                            _UnitChip(
                              key: mailFilterUnitKey(unit),
                              label: unit.label,
                              selected: _unit == unit,
                              onTap: () => setState(() => _unit = unit),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: TileMetrics.gutter),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _Button(
                      key: mailFilterClearKey,
                      label: Messages.mailFilterClear,
                      onTap: () => Navigator.pop(context, const MailFilter()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _Button(
                      key: mailFilterApplyKey,
                      label: Messages.mailFilterApply,
                      onTap: () => Navigator.pop(context, _build()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One text field: a small muted label over an underline-bordered
/// `TextField`, the same shape every other sheet's own fields take.
class _Field extends StatelessWidget {
  const _Field({
    required this.fieldKey,
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: TileMetrics.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: text.bodySmall?.copyWith(
              fontSize: 8,
              color: TileColors.muted,
            ),
          ),
          TextField(
            key: fieldKey,
            controller: controller,
            keyboardType: keyboardType,
            style: text.bodySmall?.copyWith(
              fontSize: 12,
              color: TileColors.textBright,
            ),
            cursorColor: TileColors.textBright,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: TileColors.bezel),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: TileColors.textBright),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small bordered text button in the launcher's own look.
class _Button extends StatelessWidget {
  const _Button({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: TileColors.textBright,
            width: TileMetrics.bevel,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(fontSize: 11, color: TileColors.textBright),
        ),
      ),
    );
  }
}

/// One of the four "older than" units, boxed like the size-grid picker's own
/// cells: filled when selected.
class _UnitChip extends StatelessWidget {
  const _UnitChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? TileColors.accent : Colors.transparent,
          border: Border.all(color: TileColors.bezel, width: TileMetrics.bevel),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: selected ? TileColors.canvas : TileColors.textBright,
          ),
        ),
      ),
    );
  }
}
