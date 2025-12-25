import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart';
import 'package:my_budget_client/domain/entities/style.dart';
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

class StylePickerDialog extends StatelessWidget {
  final String currentStyleId;

  const StylePickerDialog({super.key, required this.currentStyleId});
  
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
        child: BlocBuilder<StylesBloc, StylesState>(
          builder: (context, state) {
            if (state is StylesLoadSuccess) {
              return GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 80,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: state.styles.length,
                itemBuilder: (context, index) {
                  final style = state.styles[index];
                  final bool isSelected = currentStyleId == style.id;
                  
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
                            backgroundColor: _getColorFromHex(style.colorHex),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
