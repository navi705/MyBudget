import 'dart:io' show Platform, File;

import 'package:file_picker/file_picker.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/theme/app_theme.dart';
import 'package:my_budget_client/presentation/blocs/theme/theme_bloc.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theme Settings')),
      body: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildAppearanceSection(context, state),
              const SizedBox(height: 16),
              _buildColorSection(context, state),
              const SizedBox(height: 24),
              _buildBackgroundImageSection(context, state),
              const SizedBox(height: 24),
              if (Platform.isWindows)
                _buildWindowEffectsSection(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context, ThemeState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.settings_brightness),
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode),
                  label: Text('Dark'),
                ),
              ],
              selected: {state.themeMode},
              onSelectionChanged: (Set<ThemeMode> selected) {
                context.read<ThemeBloc>().add(ChangeThemeMode(selected.first));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSection(BuildContext context, ThemeState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Theme Color', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const Text('Preset Colors'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AppTheme.presetColors.map((color) {
                final isSelected = state.themeColor.value == color.value;
                return GestureDetector(
                  onTap: () {
                    context.read<ThemeBloc>().add(ChangeThemeColor(color));
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.color_lens),
              label: const Text('Custom Color'),
              onPressed: () async {
                final color = await showColorPickerDialog(
                  context,
                  state.themeColor,
                  pickersEnabled: const {
                    ColorPickerType.wheel: true,
                    ColorPickerType.accent: false,
                    ColorPickerType.primary: false,
                  },
                  title: Text(
                    'Pick a color',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  showColorCode: true,
                  colorCodeHasColor: true,
                );
                if (context.mounted) {
                  context.read<ThemeBloc>().add(ChangeThemeColor(color));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundImageSection(BuildContext context, ThemeState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Background Image',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (state.backgroundImagePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(state.backgroundImagePath!),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.image),
                    label: Text(
                      state.backgroundImagePath == null
                          ? 'Select Image'
                          : 'Change Image',
                    ),
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        type: FileType.image,
                      );
                      if (result != null && result.files.single.path != null) {
                        if (context.mounted) {
                          context.read<ThemeBloc>().add(
                            ChangeBackgroundImage(result.files.single.path),
                          );
                        }
                      }
                    },
                  ),
                ),
                if (state.backgroundImagePath != null) ...[
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
                      context.read<ThemeBloc>().add(
                        const ChangeBackgroundImage(null),
                      );
                    },
                    color: Colors.red,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowEffectsSection(BuildContext context, ThemeState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Window Effects (Windows Only)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SegmentedButton<WindowEffectType>(
              segments: WindowEffectType.values.map((effect) {
                return ButtonSegment(
                  value: effect,
                  label: Text(effect.displayName),
                );
              }).toList(),
              selected: {state.windowEffect},
              onSelectionChanged: (Set<WindowEffectType> selected) {
                final effect = selected.first;
                context.read<ThemeBloc>().add(ChangeWindowEffect(effect));
                _applyWindowEffect(
                  context,
                  effect,
                  state.windowOpacity,
                  state.themeColor,
                );
              },
            ),
            if (state.windowEffect != WindowEffectType.none) ...[
              const SizedBox(height: 16),
              Text(
                'Material Transparency: ${(state.windowOpacity * 100).round()}%',
              ),
              Slider(
                value: state.windowOpacity,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                label: '${(state.windowOpacity * 100).round()}%',
                onChanged: (value) {
                  context.read<ThemeBloc>().add(ChangeWindowOpacity(value));
                  _applyWindowEffect(
                    context,
                    state.windowEffect,
                    value,
                    state.themeColor,
                  );
                },
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '100% = Fully see-through blur | 0% = Solid background',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _applyWindowEffect(
    BuildContext context,
    WindowEffectType effect,
    double transparency,
    Color themeColor,
  ) {
    if (!Platform.isWindows) return;

    final brightness = Theme.of(context).brightness;
    // Map transparency to tint opacity:
    // 100% transparency (1.0) = 0.0 tint opacity (Clear)
    // 0% transparency (0.0) = 1.0 tint opacity (Solid)
    final tintOpacity = 1.0 - transparency;

    WindowEffect windowEffect;
    switch (effect) {
      case WindowEffectType.none:
        windowEffect = WindowEffect.disabled;
        break;
      case WindowEffectType.acrylic:
        windowEffect = WindowEffect.acrylic;
        break;
      case WindowEffectType.mica:
        windowEffect = WindowEffect.mica;
        break;
      case WindowEffectType.transparent:
        windowEffect = WindowEffect.transparent;
        break;
    }

    Window.setEffect(
      effect: windowEffect,
      color: AppTheme.getWindowTintColor(
        themeColor,
        brightness,
        tintOpacity,
        effect,
      ),
    );
  }
}
