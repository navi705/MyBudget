import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';

Future<String?> showStylePickerDialog(
    BuildContext context, String currentStyleId) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return BlocProvider.value(
        value: BlocProvider.of<StylesBloc>(context),
        child: StylePickerDialog(currentStyleId: currentStyleId),
      );
    },
  );
}

class StylePickerDialog extends StatefulWidget {
  final String currentStyleId;

  const StylePickerDialog({super.key, required this.currentStyleId});

  @override
  State<StylePickerDialog> createState() => _StylePickerDialogState();
}

class _StylePickerDialogState extends State<StylePickerDialog> {
  late TextEditingController _searchController;
  List<dynamic> _filteredStyles = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    final stylesState = context.read<StylesBloc>().state;
    if (stylesState is StylesLoadSuccess) {
      _filteredStyles = stylesState.styles;
    }
    _searchController.addListener(_filterStyles);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterStyles);
    _searchController.dispose();
    super.dispose();
  }

  void _filterStyles() {
    final stylesState = context.read<StylesBloc>().state;
    if (stylesState is StylesLoadSuccess) {
      final query = _searchController.text.toLowerCase();
      setState(() {
        _filteredStyles = stylesState.styles.where((style) {
          return style.name.toLowerCase().contains(query);
        }).toList();
      });
    }
  }

  Color _getColorFromHex(String? hexColor) {
    hexColor = (hexColor ?? '#FF5733').replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    if (hexColor.length == 8) {
      return Color(int.parse("0x$hexColor"));
    }
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Style'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<StylesBloc, StylesState>(
                builder: (context, state) {
                  if (state is StylesLoadSuccess) {
                    return GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 80,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _filteredStyles.length,
                      itemBuilder: (context, index) {
                        final style = _filteredStyles[index];
                        final bool isSelected = widget.currentStyleId == style.id;

                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop(style.id);
                          },
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
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor:
                                      _getColorFromHex(style.colorHex),
                                  child: IconUtils.getIconWidget(style),
                                ),
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
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

