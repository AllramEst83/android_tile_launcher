import 'package:android_tile_launcher/messages.dart';
import 'package:android_tile_launcher/model/conversion.dart';
import 'package:android_tile_launcher/model/rates.dart';
import 'package:android_tile_launcher/model/units.dart';
import 'package:android_tile_launcher/services/rates_repository.dart';
import 'package:android_tile_launcher/ui/pad_key.dart';
import 'package:android_tile_launcher/ui/theme.dart';
import 'package:flutter/material.dart';

/// Keys so tests can find the parts.
Key convertKindKey(String label) => ValueKey<String>('convert-kind-$label');
Key convertFromKey(String label) => ValueKey<String>('convert-from-$label');
Key convertToKey(String label) => ValueKey<String>('convert-to-$label');
Key convertKey(String key) => ValueKey<String>('convert-key-$key');
const Key convertValueKey = ValueKey<String>('convert-value');
const Key convertResultKey = ValueKey<String>('convert-result');
const Key convertNoteKey = ValueKey<String>('convert-note');
const Key convertRetryKey = ValueKey<String>('convert-retry');

/// The converter: pick a kind (or money), a unit to convert from and one to
/// convert to, key a number, and read the answer under it. Units convert
/// offline; money uses the European Central Bank's rates, kept for offline use
/// with the date they are from.
class ConvertPad extends StatefulWidget {
  const ConvertPad({super.key, required this.rates});

  final RatesRepository rates;

  @override
  State<ConvertPad> createState() => _ConvertPadState();
}

class _ConvertPadState extends State<ConvertPad> {
  // `null` is money.
  UnitKind? _kind = UnitKind.length;
  UnitDef _from = findUnit(defaultUnits(UnitKind.length).from)!;
  UnitDef _to = findUnit(defaultUnits(UnitKind.length).to)!;
  String _fromCode = defaultCurrencies.from;
  String _toCode = defaultCurrencies.to;
  String _value = '';

  RatesResult? _rates;
  bool _loadingRates = false;

  Future<void> _loadRates() async {
    setState(() => _loadingRates = true);
    final RatesResult result = await widget.rates.rates();
    if (!mounted) return;
    setState(() {
      _loadingRates = false;
      _rates = result;
    });
  }

  void _chooseKind(UnitKind? kind) {
    setState(() {
      _kind = kind;
      if (kind != null) {
        final ({String from, String to}) units = defaultUnits(kind);
        _from = findUnit(units.from)!;
        _to = findUnit(units.to)!;
      }
    });
    if (kind == null && _rates is! RatesLoaded && !_loadingRates) _loadRates();
  }

  void _swap() => setState(() {
    final UnitDef unit = _from;
    _from = _to;
    _to = unit;
    final String code = _fromCode;
    _fromCode = _toCode;
    _toCode = code;
  });

  void _key(String key) => setState(() {
    _value = key == 'C' ? '' : keyNumber(_value, key);
  });

  @override
  Widget build(BuildContext context) {
    final UnitKind? kind = _kind;
    final RatesResult? rates = _rates;
    final bool money = kind == null;

    final List<String> fromLabels;
    final List<String> toLabels;
    final String? selectedFrom;
    final String? selectedTo;
    if (money) {
      final List<String> codes = rates is RatesLoaded
          ? orderedCurrencies(rates.rates.codes)
          : const <String>[];
      fromLabels = toLabels = codes;
      selectedFrom = _fromCode;
      selectedTo = _toCode;
    } else {
      final List<UnitDef> units = <UnitDef>[
        for (final UnitDef u in allUnits)
          if (u.kind == kind) u,
      ];
      fromLabels = toLabels = <String>[
        for (final UnitDef u in units) unitLabel(u),
      ];
      selectedFrom = unitLabel(_from);
      selectedTo = unitLabel(_to);
    }

    final String fromName = money ? _fromCode : unitLabel(_from);
    final String toName = money ? _toCode : unitLabel(_to);
    final String? result = money
        ? (rates is RatesLoaded
              ? convertedMoney(_value, rates.rates, _fromCode, _toCode)
              : null)
        : convertedUnits(_value, _from, _to);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _Chips(
          height: 40,
          items: <(String, bool, Key)>[
            for (final UnitKind k in UnitKind.values)
              (kindLabel(k), k == kind, convertKindKey(kindLabel(k))),
            (Messages.calcMoney, money, convertKindKey(Messages.calcMoney)),
          ],
          onTap: (int i) => _chooseKind(
            i < UnitKind.values.length ? UnitKind.values[i] : null,
          ),
        ),
        const SizedBox(height: TileMetrics.gutter),
        _Label(text: Messages.calcFrom),
        _Chips(
          items: <(String, bool, Key)>[
            for (final String l in fromLabels)
              (l, l == selectedFrom, convertFromKey(l)),
          ],
          onTap: (int i) => setState(() {
            if (money) {
              _fromCode = fromLabels[i];
            } else {
              _from = _unitsOf(kind)[i];
            }
          }),
        ),
        _Label(text: Messages.calcTo),
        _Chips(
          items: <(String, bool, Key)>[
            for (final String l in toLabels)
              (l, l == selectedTo, convertToKey(l)),
          ],
          onTap: (int i) => setState(() {
            if (money) {
              _toCode = toLabels[i];
            } else {
              _to = _unitsOf(kind)[i];
            }
          }),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: TileMetrics.gutter),
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  '${_value.isEmpty ? '0' : _value} $fromName',
                  key: convertValueKey,
                  style: TextStyle(
                    fontFamily: kPixelFontFamily,
                    fontSize: 20,
                    color: _value.isEmpty
                        ? TileColors.textDim
                        : TileColors.textBright,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  '= ${result ?? '...'} $toName',
                  key: convertResultKey,
                  style: TextStyle(
                    fontFamily: kPixelFontFamily,
                    fontSize: 14,
                    color: TileColors.accent,
                  ),
                ),
              ),
              if (money)
                _MoneyNote(
                  rates: rates,
                  loading: _loadingRates,
                  onRetry: _loadRates,
                ),
            ],
          ),
        ),
        PadRow(
          keys: <(Widget, int)>[
            (_pad('7'), 1),
            (_pad('8'), 1),
            (_pad('9'), 1),
            (_pad(Messages.calcDelete, key: 'DEL', accent: true), 1),
          ],
        ),
        PadRow(
          keys: <(Widget, int)>[
            (_pad('4'), 1),
            (_pad('5'), 1),
            (_pad('6'), 1),
            (_pad(Messages.calcClear, key: 'C', accent: true), 1),
          ],
        ),
        PadRow(
          keys: <(Widget, int)>[
            (_pad('1'), 1),
            (_pad('2'), 1),
            (_pad('3'), 1),
            (_pad('+/-'), 1),
          ],
        ),
        PadRow(
          keys: <(Widget, int)>[
            (_pad('0'), 2),
            (_pad('.'), 1),
            (
              PadKey(
                key: convertKey('SWAP'),
                label: Messages.calcSwap,
                fontSize: 10,
                accent: true,
                onTap: _swap,
              ),
              1,
            ),
          ],
        ),
      ],
    );
  }

  List<UnitDef> _unitsOf(UnitKind? kind) => <UnitDef>[
    for (final UnitDef u in allUnits)
      if (u.kind == kind) u,
  ];

  Widget _pad(String label, {String? key, bool accent = false}) => PadKey(
    key: convertKey(key ?? label),
    label: label,
    accent: accent,
    onTap: () => _key(key ?? label),
  );
}

class _Label extends StatelessWidget {
  const _Label({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: kPixelFontFamily,
          fontSize: 8,
          color: TileColors.muted,
        ),
      ),
    );
  }
}

/// A row of chips that scrolls sideways; the one that is [selected] is lit.
class _Chips extends StatelessWidget {
  const _Chips({required this.items, required this.onTap, this.height = 40});

  final List<(String, bool, Key)> items;
  final ValueChanged<int> onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      // A plain scrolling row, not a lazy list: every chip exists, so a chip
      // that is off the edge can still be scrolled to.
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            for (final (int i, (String, bool, Key) item)
                in items.indexed) ...<Widget>[
              PadKey(
                key: item.$3,
                label: item.$1,
                selected: item.$2,
                height: height,
                fontSize: 10,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                onTap: () => onTap(i),
              ),
              const SizedBox(width: 4),
            ],
          ],
        ),
      ),
    );
  }
}

/// Under the answer, when converting money: where the rates are from, that
/// they are loading, or why there are none (with a way to try again).
class _MoneyNote extends StatelessWidget {
  const _MoneyNote({
    required this.rates,
    required this.loading,
    required this.onRetry,
  });

  final RatesResult? rates;
  final bool loading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final TextStyle style = TextStyle(
      fontFamily: kPixelFontFamily,
      fontSize: 8,
      color: TileColors.muted,
    );
    final RatesResult? current = rates;
    if (current is RatesLoaded) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          Messages.calcRateNote(current.rates.day, stale: current.rates.stale),
          key: convertNoteKey,
          style: style,
        ),
      );
    }
    if (current is RatesFailed && !loading) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              current.reason.toUpperCase(),
              key: convertNoteKey,
              textAlign: TextAlign.right,
              style: style.copyWith(color: TileColors.danger),
            ),
            const SizedBox(height: 6),
            PadKey(
              key: convertRetryKey,
              label: Messages.calcTryAgain,
              height: 36,
              fontSize: 10,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              onTap: onRetry,
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(top: 6),
      child: Text(Messages.calcRatesLoading, key: convertNoteKey, style: style),
    );
  }
}
