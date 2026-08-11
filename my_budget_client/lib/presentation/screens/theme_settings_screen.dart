import 'package:flutter/foundation.dart';
import 'package:my_budget_client/core/utils/platform/platform_utils.dart';
import 'package:my_budget_client/core/utils/platform/icon_helper.dart';
import 'package:my_budget_client/core/utils/window/window_effect_resolver.dart';
import 'package:my_budget_client/core/utils/window/window_effect_utils.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:my_budget_client/core/services/android_file_picker_service.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';
import 'package:my_budget_client/domain/entities/custom_theme.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/presentation/blocs/theme/theme_bloc.dart';
import 'package:my_budget_client/presentation/widgets/scaffold_with_escape_back.dart';

/// Whether flutter_acrylic has a native backend on the running platform.
///
/// It ships one for all three desktop platforms; web and mobile have no host
/// window to decorate at all.
bool get _supportsWindowEffects =>
    !kIsWeb &&
    (AppPlatform.isWindows || AppPlatform.isMacOS || AppPlatform.isLinux);

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  double? _localEffectOpacity;
  double? _localSurfaceOpacity;
  double? _localBgImageOpacity;
  double? _localBgImageBlur;

  @override
  Widget build(BuildContext context) {
    return EscapeBackHandler(
      child: Scaffold(
        appBar: AppBar(title: Text(context.l10n.themeSettingsTitle)),
        body: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, state) {
            if (!state.isLoaded || state.activeTheme == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final theme = state.activeTheme!;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildPresetsSection(context, state),
                const SizedBox(height: 24),
                _buildColorsSection(context, theme),
                const SizedBox(height: 24),
                _buildWindowEffectsSection(context, theme),
                const SizedBox(height: 24),
                _buildSurfaceSection(context, theme),
                const SizedBox(height: 24),
                _buildBackgroundImageSection(context, theme),
                const SizedBox(height: 32),
                _buildModeSection(context, theme),
                const SizedBox(height: 48),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPresetsSection(BuildContext context, ThemeState state) {
    return _PresetsSection(state: state);
  }

  Widget _buildColorsSection(BuildContext context, CustomTheme theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.colorCustomizationSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildColorRow(
              context,
              context.l10n.primaryColorLabel,
              theme.primaryColor,
              (c) => _update(context, primaryColor: c),
            ),
            _buildColorRow(
              context,
              context.l10n.secondaryColorLabel,
              theme.secondaryColor,
              (c) => _update(context, secondaryColor: c),
            ),
            _buildColorRow(
              context,
              context.l10n.surfaceColorLabel,
              theme.surfaceColor,
              (c) => _update(context, surfaceColor: c),
            ),
            _buildColorRow(
              context,
              context.l10n.backgroundLabel,
              theme.backgroundColor,
              (c) => _update(context, backgroundColor: c),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorRow(
    BuildContext context,
    String label,
    Color color,
    Function(Color) onSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          GestureDetector(
            onTap: () async {
              final newColor = await showColorPickerDialog(
                context,
                color,
                pickersEnabled: const {ColorPickerType.wheel: true},
                title: Text('Select $label Color'),
                showColorCode: true,
              );
              onSelected(newColor);
            },
            child: Container(
              width: 48,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowEffectsSection(BuildContext context, CustomTheme theme) {
    // Hide the whole section where no native backend exists; the platforms that
    // do have one differ only in how many effects they can render, which
    // effectAvailableOnPlatform filters below.
    if (!_supportsWindowEffects) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.windowEffectsSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<WindowEffectType>(
              initialValue:
                  WindowEffectType.values
                      .where(effectAvailableOnPlatform)
                      .contains(theme.windowEffectType)
                  ? theme.windowEffectType
                  : WindowEffectType.none,
              decoration: InputDecoration(
                labelText: context.l10n.windowEffectLabel,
                border: const OutlineInputBorder(),
              ),
              items: WindowEffectType.values
                  .where(effectAvailableOnPlatform)
                  .map(
                    (e) =>
                        DropdownMenuItem(value: e, child: Text(e.displayName)),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  _update(context, windowEffectType: v);
                  if (_supportsWindowEffects) {
                    _applyWindowEffect(
                      context,
                      theme.copyWith(windowEffectType: v),
                    );
                  }
                }
              },
            ),
            if (theme.windowEffectType == WindowEffectType.transparent) ...[
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.removeBackgroundColor),
                value: theme.backgroundColor.a == 0,
                onChanged: (v) {
                  if (v == true) {
                    _update(context, backgroundColor: Colors.transparent);
                  } else {
                    // Restore to a default dark color if unchecked
                    _update(context, backgroundColor: const Color(0xFF121212));
                  }
                },
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.transparentSurfaceLabel),
                value: theme.surfaceOpacity < 0.1,
                onChanged: (v) {
                  _update(context, surfaceOpacity: v == true ? 0.0 : 1.0);
                },
              ),
            ],
            if (theme.windowEffectType != WindowEffectType.none) ...[
              const SizedBox(height: 16),
              // WORKAROUND: For transparent mode, use buttons instead of slider
              // because Windows has parabolic transparency behavior
              if (theme.windowEffectType == WindowEffectType.transparent) ...[
                Text('${context.l10n.windowEffectLabel}:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // REMAPPED VALUES: Since Windows shows parabola where ~0.5 is most transparent
                    // and edges (0.0, 1.0) are opaque, we reverse the logic here
                    for (final preset in [
                      (
                        'Fully Transparent',
                        0.5,
                      ), // Middle value = most transparent!
                      ('75%', 0.35), // Between middle and edge
                      ('50%', 0.2), // Closer to edge = less transparent
                      ('25%', 0.1), // Very close to edge
                      (context.l10n.opaqueLabel, 0.0), // Edge = fully opaque
                    ])
                      ChoiceChip(
                        label: Text(preset.$1),
                        selected:
                            (theme.effectOpacity - preset.$2).abs() < 0.01,
                        onSelected: (selected) {
                          if (selected) {
                            _update(context, effectOpacity: preset.$2);
                            if (_supportsWindowEffects) {
                              _applyWindowEffect(
                                context,
                                theme.copyWith(effectOpacity: preset.$2),
                              );
                            }
                          }
                        },
                      ),
                  ],
                ),
              ] else ...[
                // For other modes, use slider as normal
                Text(
                  context.l10n.opacityLabel(
                    (theme.effectOpacity * 100).round(),
                  ),
                ),
                Slider(
                  value: _localEffectOpacity ?? theme.effectOpacity,
                  onChanged: (v) {
                    setState(() => _localEffectOpacity = v);
                    _update(context, effectOpacity: v, persist: false);
                    if (_supportsWindowEffects) {
                      _applyWindowEffect(
                        context,
                        theme.copyWith(effectOpacity: v),
                      );
                    }
                  },
                  onChangeEnd: (v) {
                    _update(context, effectOpacity: v, persist: true);
                    setState(() => _localEffectOpacity = null);
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSurfaceSection(BuildContext context, CustomTheme theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.surfaceGlassStyleTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.opacityLabel((theme.surfaceOpacity * 100).round()),
            ),
            Slider(
              value: _localSurfaceOpacity ?? theme.surfaceOpacity,
              onChanged: (v) {
                setState(() => _localSurfaceOpacity = v);
                _update(context, surfaceOpacity: v, persist: false);
              },
              onChangeEnd: (v) {
                _update(context, surfaceOpacity: v, persist: true);
                setState(() => _localSurfaceOpacity = null);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundImageSection(BuildContext context, CustomTheme theme) {
    if (kIsWeb) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.backgroundSettingsSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () async {
                      List<String>? pickedPaths;
                      FilePickerResult? result;

                      if (AppPlatform.isAndroid) {
                        pickedPaths = await GetIt.I<AndroidFilePickerService>()
                            .pickFile(
                              mimeType: 'image/*',
                              title: context.l10n.imagePickerChooserTitle,
                            );
                      } else {
                        result = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                        );
                        if (result != null &&
                            result.files.single.path != null) {
                          pickedPaths = [result.files.single.path!];
                        }
                      }

                      if (pickedPaths != null && pickedPaths.isNotEmpty) {
                        final path = pickedPaths.first;
                        final ext = path.split('.').last.toLowerCase();
                        final isImage = [
                          'jpg',
                          'jpeg',
                          'png',
                          'gif',
                          'webp',
                          'bmp',
                        ].contains(ext);

                        if (!isImage) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.l10n.selectImageFileError,
                                ),
                              ),
                            );
                          }
                          return;
                        }

                        if (context.mounted) {
                          _update(context, backgroundImagePath: path);
                        }
                      }
                    },
                    icon: const Icon(Icons.add_photo_alternate),
                    label: Text(context.l10n.chooseImageButton),
                  ),
                ),
                if (theme.backgroundImagePath != null) ...[
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    tooltip: context.l10n.deleteButton,
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text(
                            dialogContext.l10n.deleteConfirmationTitle(
                              dialogContext.l10n.backgroundLabel,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: Text(dialogContext.l10n.cancelButton),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: Text(dialogContext.l10n.deleteButton),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        _update(context, clearBackgroundImage: true);
                      }
                    },
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                  ),
                ],
              ],
            ),
            if (theme.backgroundImagePath != null) ...[
              const SizedBox(height: 16),
              Text(
                context.l10n.opacityLabel(
                  (theme.backgroundImageOpacity * 100).round(),
                ),
              ),
              Slider(
                value: _localBgImageOpacity ?? theme.backgroundImageOpacity,
                onChanged: (v) {
                  setState(() => _localBgImageOpacity = v);
                  _update(context, backgroundImageOpacity: v, persist: false);
                },
                onChangeEnd: (v) {
                  _update(context, backgroundImageOpacity: v, persist: true);
                  setState(() => _localBgImageOpacity = null);
                },
              ),
              const SizedBox(height: 8),
              Text(
                '${context.l10n.backgroundBlurLabel}: ${theme.backgroundImageBlur.round()}px',
              ),
              Slider(
                value: _localBgImageBlur ?? theme.backgroundImageBlur,
                min: 0,
                max: 20,
                onChanged: (v) {
                  setState(() => _localBgImageBlur = v);
                  _update(context, backgroundImageBlur: v, persist: false);
                },
                onChangeEnd: (v) {
                  _update(context, backgroundImageBlur: v, persist: true);
                  setState(() => _localBgImageBlur = null);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeSection(BuildContext context, CustomTheme theme) {
    return SegmentedButton<ThemeMode>(
      segments: [
        ButtonSegment(
          value: ThemeMode.system,
          label: Text(context.l10n.systemTheme),
          icon: const Icon(Icons.settings),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          label: Text(context.l10n.lightTheme),
          icon: const Icon(Icons.light_mode),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          label: Text(context.l10n.darkTheme),
          icon: const Icon(Icons.dark_mode),
        ),
      ],
      selected: {theme.themeMode},
      onSelectionChanged: (Set<ThemeMode> v) =>
          _update(context, themeMode: v.first),
    );
  }

  void _update(
    BuildContext context, {
    Color? primaryColor,
    Color? secondaryColor,
    Color? surfaceColor,
    Color? backgroundColor,
    String? backgroundImagePath,
    double? backgroundImageOpacity,
    double? backgroundImageBlur,
    WindowEffectType? windowEffectType,
    double? effectOpacity,
    double? surfaceOpacity,
    ThemeMode? themeMode,
    bool clearBackgroundImage = false,
    bool persist = true,
  }) {
    context.read<ThemeBloc>().add(
      UpdateThemeProperty(
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
        surfaceColor: surfaceColor,
        backgroundColor: backgroundColor,
        backgroundImagePath: backgroundImagePath,
        backgroundImageOpacity: backgroundImageOpacity,
        backgroundImageBlur: backgroundImageBlur,
        windowEffectType: windowEffectType,
        effectOpacity: effectOpacity,
        surfaceOpacity: surfaceOpacity,
        themeMode: themeMode,
        clearBackgroundImage: clearBackgroundImage,
        persist: persist,
      ),
    );
  }

  void _applyWindowEffect(BuildContext context, CustomTheme theme) =>
      _applyThemeWindowEffect(context, theme);
}

/// Pushes [theme]'s window effect to the host window.
///
/// Shared by the effects section and the preset row, which previously held two
/// copies of this and could drift apart from each other and from the copy that
/// runs at launch.
void _applyThemeWindowEffect(BuildContext context, CustomTheme theme) {
  if (!_supportsWindowEffects) return;

  final brightness = theme.themeMode == ThemeMode.system
      ? MediaQuery.platformBrightnessOf(context)
      : (theme.themeMode == ThemeMode.dark
            ? Brightness.dark
            : Brightness.light);

  WindowEffectUtils.applyTheme(
    type: theme.windowEffectType,
    backgroundColor: theme.backgroundColor,
    surfaceColor: theme.surfaceColor,
    effectOpacity: theme.effectOpacity,
    brightness: brightness,
  );
}

class _PresetsSection extends StatefulWidget {
  final ThemeState state;

  const _PresetsSection({required this.state});

  @override
  State<_PresetsSection> createState() => _PresetsSectionState();
}

class _PresetsSectionState extends State<_PresetsSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _applyWindowEffect(BuildContext context, CustomTheme theme) =>
      _applyThemeWindowEffect(context, theme);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.presetsLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton.icon(
              onPressed: () {
                // Find ancestor to show dialog
                // Find ancestor to show dialog
                // final themeScreen = context
                //     .findAncestorWidgetOfExactType<ThemeSettingsScreen>();
                // We can't easily call private method on ancestor.
                // For now, let's just duplicate the dialog logic or pass a callback.
                // Actually, simpler is to just let the Bloc handle the event if we can trigger the dialog.
                // We'll reimplement the dialog opener here locally as it's cleaner.
                _showSavePresetDialog(context);
              },
              icon: const Icon(Icons.add),
              label: Text(context.l10n.saveButton),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140, // Increased height for scrollbar
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            trackVisibility: true,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(
                bottom: 16,
              ), // Padding for scrollbar
              scrollDirection: Axis.horizontal,
              itemCount: widget.state.presets.length,
              itemBuilder: (context, index) {
                final preset = widget.state.presets[index];
                final isSelected = preset.id == widget.state.activeTheme?.id;

                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: GestureDetector(
                    onTap: () {
                      context.read<ThemeBloc>().add(
                        SelectThemePreset(preset.id),
                      );
                      if (_supportsWindowEffects) {
                        _applyWindowEffect(context, preset);
                      }
                    },
                    child: Container(
                      width: 140,
                      decoration: BoxDecoration(
                        color: preset.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(
                                color: Theme.of(context).primaryColor,
                                width: 3,
                              )
                            : Border.all(color: Colors.white10),
                        image:
                            (preset.backgroundImagePath != null &&
                                preset.backgroundImagePath!.isNotEmpty)
                            ? DecorationImage(
                                image:
                                    preset.backgroundImagePath!.startsWith(
                                      'assets/',
                                    )
                                    ? AssetImage(preset.backgroundImagePath!)
                                          as ImageProvider
                                    : IconPlatformHelper.getImageFromFile(
                                        preset.backgroundImagePath!,
                                      ),
                                fit: BoxFit.cover,
                                opacity: 0.6,
                                colorFilter: ColorFilter.mode(
                                  preset.backgroundColor.withValues(alpha: 0.3),
                                  BlendMode.darken,
                                ),
                              )
                            : null,
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              preset.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                shadows: const [Shadow(blurRadius: 4)],
                              ),
                            ),
                          ),
                          if (!preset.isPreset)
                            PositionedDirectional(
                              top: 4,
                              end: 4,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  size: 18,
                                  color: Colors.redAccent,
                                ),
                                tooltip: context.l10n.deleteButton,
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      title: Text(
                                        dialogContext.l10n
                                            .deleteConfirmationTitle(
                                              preset.name,
                                            ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(
                                            dialogContext,
                                            false,
                                          ),
                                          child: Text(
                                            dialogContext.l10n.cancelButton,
                                          ),
                                        ),
                                        FilledButton(
                                          onPressed: () => Navigator.pop(
                                            dialogContext,
                                            true,
                                          ),
                                          child: Text(
                                            dialogContext.l10n.deleteButton,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true && context.mounted) {
                                    context.read<ThemeBloc>().add(
                                      DeleteThemePreset(preset.id),
                                    );
                                  }
                                },
                              ),
                            ),
                          Positioned(
                            bottom: 8,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _colorDot(preset.primaryColor),
                                _colorDot(preset.secondaryColor),
                                _colorDot(preset.surfaceColor),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showSavePresetDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.saveThemePresetTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: context.l10n.presetNameLabel,
            hintText: context.l10n.presetNameHint,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<ThemeBloc>().add(SaveThemePreset(controller.text));
                Navigator.pop(context);
              }
            },
            child: Text(context.l10n.saveButton),
          ),
        ],
      ),
    );
  }

  Widget _colorDot(Color color) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white38, width: 1),
      ),
    );
  }
}
