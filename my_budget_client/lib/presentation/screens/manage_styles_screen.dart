import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/widgets/account_list_item.dart'
    show kContentMaxWidth, kFabScrollBottomInset;
import 'package:my_budget_client/presentation/widgets/add_style_dialog.dart';
import 'package:my_budget_client/presentation/widgets/scaffold_with_escape_back.dart';

class ManageStylesScreen extends StatelessWidget {
  const ManageStylesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StylesBloc, StylesState>(
      builder: (context, state) {
        final isSelectionMode =
            state is StylesLoadSuccess && state.isSelectionModeActive;
        final selectedCount = state is StylesLoadSuccess
            ? state.selectedStyleIds.length
            : 0;

        return EscapeBackHandler(
          onBack: () {
            if (isSelectionMode) {
              context.read<StylesBloc>().add(
                const ToggleStyleSelectionMode(false),
              );
            } else {
              context.pop();
            }
          },
          child: Scaffold(
            appBar: isSelectionMode
                ? AppBar(
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        context.read<StylesBloc>().add(
                          const ToggleStyleSelectionMode(false),
                        );
                      },
                    ),
                    title: Text(
                      context.l10n.selectedCountLabel(selectedCount.toString()),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          final selectedIds = state.selectedStyleIds.toList();
                          // Filter out 'Transfer' style just in case UI selection allowed it
                          // Ideally UI shouldn't allow selecting it for deletion, or we warn.
                          // But per requirements, just prevent deletion.
                          // We will prompt user.
                          _showDeleteConfirmation(
                            context,
                            selectedIds,
                            state.styles,
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  )
                : AppBar(title: Text(context.l10n.manageIconsTitle)),
            body: Builder(
              builder: (context) {
                if (state is StylesLoadInProgress) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is StylesLoadSuccess) {
                  if (state.styles.isEmpty) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onSecondaryTapUp: (details) => _showEmptyAreaContextMenu(
                        context,
                        details.globalPosition,
                      ),
                      onLongPressStart: (details) => _showEmptyAreaContextMenu(
                        context,
                        details.globalPosition,
                      ),
                      child: Center(child: Text(context.l10n.noIconsCreated)),
                    );
                  }
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onSecondaryTapUp: (details) => _showEmptyAreaContextMenu(
                      context,
                      details.globalPosition,
                    ),
                    onLongPressStart: (details) => _showEmptyAreaContextMenu(
                      context,
                      details.globalPosition,
                    ),
                    // The row's edit and delete buttons sat ~1270px from the
                    // label they act on at 1440x900. Capping and centring the
                    // column - the same measure and the same
                    // Center/ConstrainedBox pattern as settings_screen.dart -
                    // puts the control back beside its subject. The
                    // GestureDetector stays full-bleed so a right-click in the
                    // margin still opens the empty-area menu.
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: kContentMaxWidth,
                        ),
                        child: ListView.builder(
                          // Room for the FAB floating over the last row.
                          padding: const EdgeInsets.only(
                            bottom: kFabScrollBottomInset,
                          ),
                          itemCount: state.styles.length,
                          itemBuilder: (context, index) {
                            final style = state.styles[index];
                            final isSelected = state.selectedStyleIds.contains(
                              style.id,
                            );

                            return _StyleListItem(
                              style: style,
                              isSelected: isSelected,
                              isSelectionMode: isSelectionMode,
                              onTap: () {
                                if (isSelectionMode) {
                                  if (style.id != null) {
                                    context.read<StylesBloc>().add(
                                      ToggleStyleSelection(style.id!),
                                    );
                                  }
                                } else {
                                  // Edit mode navigation
                                  if (style.id != null) {
                                    context.push(
                                      AppRoutes.editAccountStyle.replaceFirst(
                                        ':id',
                                        style.id!.toString(),
                                      ),
                                    );
                                  }
                                }
                              },
                              onLongPress: () {
                                if (style.id != null) {
                                  if (!isSelectionMode) {
                                    context.read<StylesBloc>().add(
                                      const ToggleStyleSelectionMode(true),
                                    );
                                  }
                                  context.read<StylesBloc>().add(
                                    ToggleStyleSelection(style.id!),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  );
                }
                return Center(child: Text(context.l10n.failedToLoadIcons));
              },
            ),
            floatingActionButton: isSelectionMode
                ? null
                : FloatingActionButton(
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
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    List<String> ids,
    List<Style> allStyles,
  ) {
    if (ids.isEmpty) return;

    // Check if "Transfer" is in the selection
    final stylesToDelete = allStyles.where((s) => ids.contains(s.id)).toList();
    final hasTransfer = stylesToDelete.any((s) => s.name == 'Transfer');

    final countToDelete = hasTransfer
        ? stylesToDelete.length - 1
        : stylesToDelete.length;

    if (countToDelete <= 0) {
      // Only Transfer was selected
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.cannotDeleteTransferIcon)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteIconsDialogTitle),
        content: Text(
          hasTransfer
              ? context.l10n.deleteIconsWithSkipTransferMessage(
                  countToDelete.toString(),
                )
              : context.l10n.deleteIconsConfirmationMessage(
                  ids.length.toString(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancelButton),
          ),
          TextButton(
            onPressed: () {
              context.read<StylesBloc>().add(DeleteMultipleStyles(ids));
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              context.l10n.deleteButton,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showEmptyAreaContextMenu(BuildContext context, Offset position) async {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem(
          value: 'add_style',
          child: Row(
            children: [
              const Icon(Icons.add),
              const SizedBox(width: 8),
              Flexible(child: Text(context.l10n.styAddIcon)),
            ],
          ),
        ),
      ],
    );

    if (!context.mounted || value == null) return;

    if (value == 'add_style') {
      showDialog(
        context: context,
        builder: (_) => BlocProvider.value(
          value: BlocProvider.of<StylesBloc>(context),
          child: const AddStyleDialog(),
        ),
      );
    }
  }
}

class _StyleListItem extends StatefulWidget {
  final Style style;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _StyleListItem({
    required this.style,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  State<_StyleListItem> createState() => _StyleListItemState();
}

class _StyleListItemState extends State<_StyleListItem> {
  bool _isHovering = false;

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return Color(int.parse("0x$hexColor"));
  }

  void _showContextMenu(Offset position) {
    final bloc = context.read<StylesBloc>();
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<dynamic>>[
        PopupMenuItem(
          value: 'select',
          child: Text(
            widget.isSelected
                ? context.l10n.contextMenuDeselect
                : context.l10n.contextMenuSelect,
          ),
        ),
        PopupMenuItem(
          value: 'select_all',
          child: Text(context.l10n.contextMenuSelectAll),
        ),
        if (widget.isSelectionMode)
          PopupMenuItem(
            value: 'deselect_all',
            child: Text(context.l10n.contextMenuDeselectAll),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(value: 'edit', child: Text(context.l10n.contextMenuEdit)),
        if (widget.style.name != 'Transfer')
          PopupMenuItem(
            value: 'delete',
            child: Text(context.l10n.contextMenuDelete),
          ),
      ],
    ).then((value) {
      if (!mounted) return;
      if (value == 'select') {
        if (!widget.isSelectionMode) {
          bloc.add(const ToggleStyleSelectionMode(true));
        }
        if (widget.style.id != null) {
          bloc.add(ToggleStyleSelection(widget.style.id!));
        }
      } else if (value == 'select_all') {
        if (!widget.isSelectionMode) {
          bloc.add(const ToggleStyleSelectionMode(true));
        }
        bloc.add(const SelectAllStyles());
      } else if (value == 'deselect_all') {
        bloc.add(const ClearStyleSelection());
      } else if (value == 'edit') {
        // If in selection mode, maybe exit it? or just navigate?
        // Navigating is generic behavior
        if (widget.style.id != null) {
          context.push(
            AppRoutes.editAccountStyle.replaceFirst(
              ':id',
              widget.style.id!.toString(),
            ),
          );
        }
      } else if (value == 'delete') {
        // Single delete confirmation
        _showSingleDeleteDialog(context, bloc);
      }
    });
  }

  void _showSingleDeleteDialog(BuildContext context, StylesBloc bloc) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deleteIconDialogTitle),
        content: Text(
          context.l10n.deleteIconConfirmationMessage(widget.style.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancelButton),
          ),
          TextButton(
            onPressed: () {
              if (widget.style.id != null) {
                bloc.add(DeleteStyle(widget.style.id!));
              }
              Navigator.of(dialogContext).pop();
            },
            child: Text(
              context.l10n.deleteButton,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColorFromHex(widget.style.colorHex);
    final iconWidget = IconUtils.getIconWidget(widget.style);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onSecondaryTapUp: (details) {
          if (kIsWeb ||
              defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.linux ||
              defaultTargetPlatform == TargetPlatform.windows) {
            _showContextMenu(details.globalPosition);
          }
        },
        child: ListTile(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          selected: widget.isSelected,
          leading: CircleAvatar(backgroundColor: color, child: iconWidget),
          title: Text(widget.style.name),
          tileColor: widget.isSelected
              ? Theme.of(context).highlightColor
              : _isHovering
              ? Colors.grey.withValues(alpha: 0.1)
              : null,
          trailing: widget.isSelectionMode
              ? (widget.isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: Theme.of(context).primaryColor,
                      )
                    : const Icon(Icons.circle_outlined))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        if (widget.style.id != null) {
                          context.push(
                            AppRoutes.editAccountStyle.replaceFirst(
                              ':id',
                              widget.style.id!.toString(),
                            ),
                          );
                        }
                      },
                    ),
                    if (widget.style.name != 'Transfer')
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _showSingleDeleteDialog(
                          context,
                          context.read<StylesBloc>(),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
