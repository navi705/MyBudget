import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/widgets/add_style_dialog.dart';
import 'package:my_budget_client/presentation/widgets/budget_icon.dart';
import 'package:my_budget_client/core/utils/dialog_utils.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';

Future<String?> showIconSelectionDialog(
  BuildContext context,
  String? currentIconId,
) {
  return DialogUtils.showAppDialog<String>(
    context: context,
    resizeToAvoidBottomInset: false,
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: BlocProvider.of<StylesBloc>(context)),
      ],
      child: IconSelectionDialog(currentIconId: currentIconId),
    ),
  );
}

class IconSelectionDialog extends StatefulWidget {
  final String? currentIconId;

  const IconSelectionDialog({super.key, required this.currentIconId});

  @override
  State<IconSelectionDialog> createState() => _IconSelectionDialogState();
}

class _IconSelectionDialogState extends State<IconSelectionDialog> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.pckSelectIcon),
      content: SizedBox(
        width: double.maxFinite,
        height:
            MediaQuery.of(context).size.height * 0.7, // 70% of screen height
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  DialogUtils.showAppDialog(
                    context: context,
                    resizeToAvoidBottomInset: false,
                    child: BlocProvider.value(
                      value: BlocProvider.of<StylesBloc>(context),
                      child: const AddStyleDialog(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.addNewIconLabel),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BlocBuilder<StylesBloc, StylesState>(
                builder: (context, state) {
                  if (state is StylesLoadSuccess) {
                    final styles = state.styles;
                    return AnimatedBuilder(
                      animation: _searchController,
                      builder: (context, child) {
                        final query = _searchController.text.toLowerCase();
                        final filteredIcons = styles.where((style) {
                          return style.name.toLowerCase().contains(query);
                        }).toList();

                        if (filteredIcons.isEmpty) {
                          return Center(child: Text(l10n.noIconsFoundLabel));
                        }

                        return GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 80,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                mainAxisExtent: 80,
                              ),
                          itemCount: filteredIcons.length,
                          itemBuilder: (context, index) {
                            final style = filteredIcons[index];
                            final bool isSelected =
                                widget.currentIconId == style.id;

                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop(style.id);
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    BudgetIcon(style: style, radius: 20),
                                    const SizedBox(height: 4),
                                    Text(
                                      style.name,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
      ],
    );
  }
}
