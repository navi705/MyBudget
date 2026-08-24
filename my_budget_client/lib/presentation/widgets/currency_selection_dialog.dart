import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';

/// Picking several currencies at once - the accounts filter, and the set the
/// total-balance widget adds up.
///
/// Ordered the same way the single-currency picker is, and off the same stars:
/// a currency that sits at the top of one list and ninety rows down another is
/// two different lists to the person reading them.
class CurrencySelectionDialog extends StatefulWidget {
  final List<Currency> allCurrencies;
  final List<Currency> selectedCurrencies;

  /// Where the stars and usage counts come from. Left null it is read from the
  /// widget tree, which is where the app puts it; a caller with no
  /// [CurrencyRepository] above it - a widget test pumping one screen - gets
  /// the plain list rather than a crash.
  final CurrencyRepository? repository;

  const CurrencySelectionDialog({
    super.key,
    required this.allCurrencies,
    required this.selectedCurrencies,
    this.repository,
  });

  @override
  State<CurrencySelectionDialog> createState() =>
      _CurrencySelectionDialogState();
}

/// How many unstarred currencies the usage history may lift out of the
/// alphabetical list. Same limit as the single picker, for the same reason: a
/// shortcut that grows into a second full list stops being a shortcut.
const int _kFrequentLimit = 8;

class _CurrencySelectionDialogState extends State<CurrencySelectionDialog> {
  late TextEditingController _searchController;
  late List<Currency> _tempSelectedCurrencies;

  CurrencyRepository? _repository;
  List<String> _favorites = const [];
  Map<String, int> _usage = const {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _tempSelectedCurrencies = List.from(widget.selectedCurrencies);
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

  /// Headers ([String]) and rows ([Currency]) in one list, so the sections stay
  /// lazily built: the last one holds every currency there is.
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
      // The full list keeps the codes lifted above it, so a currency stays
      // where the user last saw it as well as at the top.
      if (favorites.isNotEmpty || frequent.isNotEmpty) l10n.allCurrenciesHeader,
      ...matched,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final rows = _buildRows(l10n);

    return AlertDialog(
      title: Text(l10n.fltSelectCurrenciesLabel),
      content: SizedBox(
        width: double.maxFinite,
        height: screenHeight * 0.7,
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
                  final isSelected = _tempSelectedCurrencies.any(
                    (c) => c.code == currency.code,
                  );
                  final isFavorite = _favorites.contains(currency.code);

                  return CheckboxListTile(
                    title: Text('${currency.name} (${currency.code})'),
                    value: isSelected,
                    controlAffinity: ListTileControlAffinity.leading,
                    // Hidden with no repository behind it: a star that cannot
                    // be saved is a control that does nothing.
                    secondary: _repository == null
                        ? null
                        : IconButton(
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
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          // The same currency can be on screen twice - starred
                          // at the top and again in the full list - and ticking
                          // it in one place must not add it to the filter
                          // twice.
                          if (!isSelected) {
                            _tempSelectedCurrencies.add(currency);
                          }
                        } else {
                          _tempSelectedCurrencies.removeWhere(
                            (c) => c.code == currency.code,
                          );
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text(l10n.pckClearAll),
          onPressed: () {
            setState(() {
              _tempSelectedCurrencies.clear();
            });
          },
        ),
        TextButton(
          child: Text(l10n.cancelButton),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: Text(l10n.okButton),
          onPressed: () {
            Navigator.of(context).pop(_tempSelectedCurrencies);
          },
        ),
      ],
    );
  }
}
