import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/core/utils/dialog_utils.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';

/// The one currency picker in the app.
///
/// Every screen that asks for a currency used to open its own list — a flat
/// alphabetical run of all 341 currencies the app knows — so picking EUR meant
/// scrolling past 90 of them or typing a search, every time, on every screen.
/// This one puts what the user has starred at the top, then what they already
/// hold money in, then the same alphabetical list as before.
Future<Currency?> showCurrencyPicker({
  required BuildContext context,
  required List<Currency> currencies,
  String? selectedCurrencyCode,
  String? title,
}) {
  return DialogUtils.showAppDialog<Currency>(
    context: context,
    resizeToAvoidBottomInset: false,
    child: CurrencyPickerDialog(
      allCurrencies: currencies,
      selectedCurrencyCode: selectedCurrencyCode,
      title: title,
    ),
  );
}

class CurrencyPickerDialog extends StatefulWidget {
  final List<Currency> allCurrencies;
  final String? selectedCurrencyCode;
  final String? title;

  /// Where stars and usage counts come from. Left null it is read from the
  /// widget tree, which is where the app puts it; a caller that has no
  /// [CurrencyRepository] above it — a widget test pumping one screen — gets a
  /// plain alphabetical list rather than a crash.
  final CurrencyRepository? repository;

  const CurrencyPickerDialog({
    super.key,
    required this.allCurrencies,
    this.selectedCurrencyCode,
    this.title,
    this.repository,
  });

  @override
  State<CurrencyPickerDialog> createState() => _CurrencyPickerDialogState();
}

/// How many unstarred currencies the usage history is allowed to lift out of
/// the alphabetical list. Enough for the accounts a person keeps, short enough
/// that the section stays a shortcut and not a second full list.
const int _kFrequentLimit = 8;

class _CurrencyPickerDialogState extends State<CurrencyPickerDialog> {
  final TextEditingController _searchController = TextEditingController();

  CurrencyRepository? _repository;
  List<String> _favorites = const [];
  Map<String, int> _usage = const {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _repository = widget.repository ?? _repositoryFromTree();
    _loadOrdering();
  }

  CurrencyRepository? _repositoryFromTree() {
    // flutter_bloc reports a missing provider as a FlutterError.
    try {
      return RepositoryProvider.of<CurrencyRepository>(context);
    } on FlutterError {
      return null;
    }
  }

  Future<void> _loadOrdering() async {
    final repository = _repository;
    if (repository == null) return;
    final favorites = await repository.getFavoriteCurrencyCodes();
    final usage = await repository.getCurrencyUsageCounts();
    if (!mounted) return;
    setState(() {
      _favorites = favorites;
      _usage = usage;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() => _query = _searchController.text.trim().toLowerCase());
  }

  Future<void> _toggleFavorite(Currency currency) async {
    final favorite = !_favorites.contains(currency.code);
    setState(() {
      // Applied here rather than waited for: the star is a tap the user is
      // looking at, and the write is a round trip to the database.
      _favorites = favorite
          ? [..._favorites, currency.code]
          : _favorites.where((c) => c != currency.code).toList();
    });
    await _repository?.setFavoriteCurrency(currency.code, favorite: favorite);
  }

  bool _matches(Currency currency) {
    if (_query.isEmpty) return true;
    return currency.name.toLowerCase().contains(_query) ||
        currency.code.toLowerCase().contains(_query);
  }

  /// Headers ([String]) and rows ([Currency]) in one list, so the sections
  /// stay lazily built: the last one holds every currency there is.
  List<Object> _buildRows(AppLocalizations l10n) {
    final matched = widget.allCurrencies.where(_matches).toList();
    final byCode = {for (final c in matched) c.code: c};

    final favorites = [
      for (final code in _favorites)
        if (byCode[code] != null) byCode[code]!,
    ];

    final favoriteCodes = _favorites.toSet();
    final frequent =
        matched
            .where(
              (c) => !favoriteCodes.contains(c.code) && _usage[c.code] != null,
            )
            .toList()
          ..sort((a, b) {
            final byUse = (_usage[b.code] ?? 0).compareTo(_usage[a.code] ?? 0);
            return byUse != 0 ? byUse : a.code.compareTo(b.code);
          });

    return [
      if (favorites.isNotEmpty) ...[
        l10n.favoriteCurrenciesHeader,
        ...favorites,
      ],
      if (frequent.isNotEmpty) ...[
        l10n.frequentCurrenciesHeader,
        ...frequent.take(_kFrequentLimit),
      ],
      // The full list keeps the codes lifted above it: a currency stays where
      // the user last saw it, and the shortcut is a shortcut rather than a
      // move.
      if (favorites.isNotEmpty || frequent.isNotEmpty) l10n.allCurrenciesHeader,
      ...matched,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final rows = _buildRows(l10n);

    return AlertDialog(
      title: Text(widget.title ?? l10n.selectCurrencyTitle),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 8.0,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final row = rows[index];
                  if (row is String) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(8, 16, 8, 4),
                      child: Text(
                        row,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }

                  final currency = row as Currency;
                  final isSelected =
                      currency.code == widget.selectedCurrencyCode;
                  final isFavorite = _favorites.contains(currency.code);

                  return ListTile(
                    title: Text('${currency.name} (${currency.code})'),
                    selected: isSelected,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          const Icon(Icons.check, color: Colors.green),
                        // Hidden with no repository behind it: a star that
                        // cannot be saved is a control that does nothing.
                        if (_repository != null)
                          IconButton(
                            icon: Icon(
                              isFavorite ? Icons.star : Icons.star_border,
                              color: isFavorite
                                  ? theme.colorScheme.primary
                                  : theme.hintColor,
                            ),
                            tooltip: isFavorite
                                ? l10n.removeFavoriteCurrencyTooltip
                                : l10n.addFavoriteCurrencyTooltip,
                            onPressed: () => _toggleFavorite(currency),
                          ),
                      ],
                    ),
                    onTap: () => Navigator.of(context).pop(currency),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(l10n.cancelButton),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
