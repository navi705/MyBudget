import 'dart:io' show Platform, File;

import 'package:file_picker/file_picker.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';
import 'package:my_budget_client/domain/entities/custom_theme.dart';
import 'package:my_budget_client/presentation/blocs/theme/theme_bloc.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theme Customization')),
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
    );
  }

  Widget _buildPresetsSection(BuildContext context, ThemeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Presets', style: Theme.of(context).textTheme.titleLarge),
            TextButton.icon(
              onPressed: () => _showSavePresetDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Save Current'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: state.presets.length,
            itemBuilder: (context, index) {
              final preset = state.presets[index];
              final isSelected = preset.id == state.activeTheme?.id;

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    context.read<ThemeBloc>().add(SelectThemePreset(preset.id));
                    if (Platform.isWindows) {
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
                                  : FileImage(
                                      File(preset.backgroundImagePath!),
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
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                size: 18,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => context.read<ThemeBloc>().add(
                                DeleteThemePreset(preset.id),
                              ),
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
      ],
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

  Widget _buildColorsSection(BuildContext context, CustomTheme theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme Colors',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildColorRow(
              context,
              'Primary',
              theme.primaryColor,
              (c) => _update(context, primaryColor: c),
            ),
            _buildColorRow(
              context,
              'Secondary',
              theme.secondaryColor,
              (c) => _update(context, secondaryColor: c),
            ),
            _buildColorRow(
              context,
              'Surface',
              theme.surfaceColor,
              (c) => _update(context, surfaceColor: c),
            ),
            _buildColorRow(
              context,
              'Background',
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
    if (!Platform.isWindows && !Platform.isMacOS && !Platform.isLinux) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Window Effects',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<WindowEffectType>(
              initialValue: theme.windowEffectType,
              decoration: const InputDecoration(
                labelText: 'Effect Type',
                border: OutlineInputBorder(),
              ),
              items: WindowEffectType.values
                  .map(
                    (e) =>
                        DropdownMenuItem(value: e, child: Text(e.displayName)),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  _update(context, windowEffectType: v);
                  if (Platform.isWindows) {
                    _applyWindowEffect(
                      context,
                      theme.copyWith(windowEffectType: v),
                    );
                  }
                }
              },
            ),
            if (theme.windowEffectType != WindowEffectType.none) ...[
              const SizedBox(height: 16),
              Text(
                'Window Tint Opacity: ${(theme.effectOpacity * 100).round()}%',
              ),
              Slider(
                value: theme.effectOpacity,
                onChanged: (v) {
                  _update(context, effectOpacity: v);
                  if (Platform.isWindows) {
                    _applyWindowEffect(
                      context,
                      theme.copyWith(effectOpacity: v),
                    );
                  }
                },
              ),
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
              'Surface/Glass Style',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text('Surface Opacity: ${(theme.surfaceOpacity * 100).round()}%'),
            Slider(
              value: theme.surfaceOpacity,
              onChanged: (v) => _update(context, surfaceOpacity: v),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundImageSection(BuildContext context, CustomTheme theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Background Image',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                      );
                      if (result != null && result.files.single.path != null) {
                        if (context.mounted) {
                          _update(
                            context,
                            backgroundImagePath: result.files.single.path,
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Change Image'),
                  ),
                ),
                if (theme.backgroundImagePath != null) ...[
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    onPressed: () =>
                        _update(context, clearBackgroundImage: true),
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                  ),
                ],
              ],
            ),
            if (theme.backgroundImagePath != null) ...[
              const SizedBox(height: 16),
              Text(
                'Image Intensity (Opacity): ${(theme.backgroundImageOpacity * 100).round()}%',
              ),
              Slider(
                value: theme.backgroundImageOpacity,
                onChanged: (v) => _update(context, backgroundImageOpacity: v),
              ),
              const SizedBox(height: 8),
              Text('Image Blur: ${theme.backgroundImageBlur.round()}px'),
              Slider(
                value: theme.backgroundImageBlur,
                min: 0,
                max: 20,
                onChanged: (v) => _update(context, backgroundImageBlur: v),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeSection(BuildContext context, CustomTheme theme) {
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(
          value: ThemeMode.system,
          label: Text('System'),
          icon: Icon(Icons.settings),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          label: Text('Light'),
          icon: Icon(Icons.light_mode),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          label: Text('Dark'),
          icon: Icon(Icons.dark_mode),
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
    double? surfaceBlur,
    ThemeMode? themeMode,
    bool clearBackgroundImage = false,
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
      ),
    );
  }

  void _showSavePresetDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Theme Preset'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Preset Name',
            hintText: 'My Amazing Theme',
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _applyWindowEffect(BuildContext context, CustomTheme theme) {
    if (!Platform.isWindows) return;

    final brightness = theme.themeMode == ThemeMode.system
        ? MediaQuery.platformBrightnessOf(context)
        : (theme.themeMode == ThemeMode.dark
              ? Brightness.dark
              : Brightness.light);

    WindowEffect windowEffect;
    switch (theme.windowEffectType) {
      case WindowEffectType.none:
        windowEffect = WindowEffect.disabled;
        break;
      case WindowEffectType.acrylic:
        windowEffect = WindowEffect.acrylic;
        break;
      case WindowEffectType.mica:
        windowEffect = WindowEffect.mica;
        break;
      case WindowEffectType.aero:
        windowEffect = WindowEffect.aero;
        break;
      case WindowEffectType.vibrancy:
        windowEffect = WindowEffect.disabled; // Not on Windows
        break;
      case WindowEffectType.transparent:
        windowEffect = WindowEffect.transparent;
        break;
    }

    Window.setEffect(
      effect: windowEffect,
      color: AppTheme.getWindowTintColor(
        theme.backgroundColor,
        brightness,
        1.0 - theme.effectOpacity,
        theme.windowEffectType,
      ),
    );
  }
}
