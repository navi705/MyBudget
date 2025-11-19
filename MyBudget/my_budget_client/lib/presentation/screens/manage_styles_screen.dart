import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/widgets/add_style_dialog.dart';

class ManageStylesScreen extends StatelessWidget {
  const ManageStylesScreen({super.key});

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse("0x$hexColor"));
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'wallet': return Icons.account_balance_wallet;
      case 'savings': return Icons.savings;
      case 'credit_card': return Icons.credit_card;
      default: return Icons.account_balance;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Styles'),
      ),
      body: BlocBuilder<StylesBloc, StylesState>(
        builder: (context, state) {
          if (state is StylesLoadInProgress) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is StylesLoadSuccess) {
            if (state.styles.isEmpty) {
              return const Center(child: Text('No styles created yet.'));
            }
            return ListView.builder(
              itemCount: state.styles.length,
              itemBuilder: (context, index) {
                final style = state.styles[index];
                final color = _getColorFromHex(style.colorHex);
                final icon = _getIconData(style.iconName);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color,
                    child: Icon(icon, color: Colors.white),
                  ),
                  title: Text(style.name),
                  subtitle: Text('${style.iconName} - ${style.colorHex}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          if (style.id != null) {
                            context.push(
                              AppRoutes.editAccountStyle.replaceFirst(':id', style.id!.toString()),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Delete Style'),
                              content: Text('Are you sure you want to delete "${style.name}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context.read<StylesBloc>().add(DeleteStyle(style.id!));
                                    Navigator.of(dialogContext).pop();
                                  },
                                  child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }
          return const Center(child: Text('Failed to load styles.'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => BlocProvider.value(
              value: BlocProvider.of<StylesBloc>(context),
              child: const AddStyleDialog(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
