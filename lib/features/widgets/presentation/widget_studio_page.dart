import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/design/radius_tokens.dart';
import '../../../core/design/spacing_tokens.dart';
import '../../../core/theme/theme_extension.dart';
import '../../../core/widgets/kairos_scaffold.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../core/widgets/widget_suite/widget_artwork_renderer.dart';
import '../../../core/widgets/widget_suite/widget_config.dart';
import '../../../core/widgets/widget_suite/widget_sync_service.dart';
import '../../moments/presentation/moment_controller.dart';
import '../data/look_presets_manager.dart';
import '../domain/widget_look.dart';

/// Interactive Widget Studio for tailoring Android and iOS home screen widgets.
class WidgetStudioPage extends ConsumerStatefulWidget {
  const WidgetStudioPage({super.key});

  @override
  ConsumerState<WidgetStudioPage> createState() => _WidgetStudioPageState();
}

enum _WidgetFamily {
  clock,
  nextMoment,
  worldClock,
  thenMoment,
  interactive,
  combo,
}

enum _StudioTab { looks, timeBuilder, momentBuilder, styleTypography }

class _WidgetStudioPageState extends ConsumerState<WidgetStudioPage> {
  _WidgetFamily _selectedFamily = _WidgetFamily.clock;
  _StudioTab _activeTab = _StudioTab.looks;

  List<WidgetLook> _availableLooks = WidgetLook.all;
  WidgetLook _activeLook = WidgetLook.all[0];
  WidgetConfig? _previousConfig;

  // Style properties
  String _backgroundType = 'warm_paper';
  double _backgroundOpacity = 1.0;
  double _cornerRoundness = 28.0;
  bool _borderEnabled = true;
  double _borderWidthDp = 1.0;
  String _fontStyle = 'modern';
  double _scaleFactor = 1.0;
  String _accentHex = '#E8895A';
  String _alignment = 'center';

  // Time Builder properties
  bool _use24Hour = true;
  bool _leadingZero = true;
  bool _showHours = true;
  bool _showMinutes = true;
  bool _showSeconds = false;
  bool _showAmPm = false;
  bool _showDate = true;
  bool _showDayName = true;
  bool _showMonth = true;
  bool _showYear = false;
  bool _showWeekNumber = false;
  bool _showDayOfYear = false;
  bool _showTimeZone = false;
  bool _batterySafeMode = true;
  bool _secondsScreenOnOnly = true;
  String _timeLayout = 'inline';
  String _timeSeparator = 'colon';
  String _secondsStyle = 'hidden';
  final TextEditingController _customFormatController = TextEditingController();

  // Moment Builder properties
  String _momentVisual = 'ring';
  String _momentUnit = 'days';
  String _momentDirection = 'auto';
  bool _showMomentTitle = true;
  bool _showMomentCategory = true;
  bool _showMomentDate = true;
  bool _showMomentProgress = true;
  bool _showMomentNote = false;
  String? _selectedMomentId;

  bool _isSaving = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadCustomLooks();
    _accentHex = _colorToHex(_activeLook.accentColor);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _customFormatController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomLooks() async {
    final looks = await LookPresetsManager.loadAllLooks();
    if (mounted) {
      setState(() => _availableLooks = looks);
    }
  }

  String _colorToHex(Color c) {
    final val = c.toARGB32();
    return '#${val.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  Color _parseHex(String hex, Color fallback) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return fallback;
    }
  }

  WidgetConfig _buildCurrentConfig() {
    return WidgetConfig(
      themeMode: _activeLook.isDark ? 'dark' : 'light',
      accentHex: _accentHex,
      textColor: _colorToHex(_activeLook.primaryTextColor),
      textSecondaryColor: _colorToHex(_activeLook.secondaryTextColor),
      backgroundColor: _colorToHex(_activeLook.backgroundColor),
      backgroundOpacity: _backgroundOpacity,
      backgroundType: _backgroundType,
      cornerRadius: _cornerRoundness,
      borderEnabled: _borderEnabled,
      borderWidthDp: _borderWidthDp,
      fontStyle: _fontStyle,
      lookId: _activeLook.id,
      use24Hour: _use24Hour,
      showSeconds: _showSeconds,
      showAmPm: _showAmPm,
      showDate: _showDate,
      showAlarm: true,
      timeLayout: _timeLayout,
      timeSeparator: _timeSeparator,
      secondsStyle: _secondsStyle,
      customFormat: _customFormatController.text.trim(),
      scaleFactor: _scaleFactor,
      momentVisual: _momentVisual,
      momentUnit: _momentUnit,
      leadingZero: _leadingZero,
      batterySafeMode: _batterySafeMode,
      secondsScreenOnOnly: _secondsScreenOnOnly,
      showHours: _showHours,
      showMinutes: _showMinutes,
      showDayName: _showDayName,
      showMonth: _showMonth,
      showYear: _showYear,
      showWeekNumber: _showWeekNumber,
      showDayOfYear: _showDayOfYear,
      showTimeZone: _showTimeZone,
      momentDirection: _momentDirection,
      showMomentTitle: _showMomentTitle,
      showMomentCategory: _showMomentCategory,
      showMomentDate: _showMomentDate,
      showMomentProgress: _showMomentProgress,
      showMomentNote: _showMomentNote,
      selectedMomentId: _selectedMomentId,
      alignment: _alignment,
      version: 2,
    );
  }

  void _scheduleSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 1000), () async {
      final config = _buildCurrentConfig();
      await ref.read(widgetSyncServiceProvider).syncConfig(config);
    });
  }

  void _recordPreviousState() {
    _previousConfig = _buildCurrentConfig();
  }

  void _undo() {
    if (_previousConfig == null) return;
    HapticFeedback.mediumImpact();
    setState(() {
      final c = _previousConfig!;
      _accentHex = c.accentHex;
      _backgroundOpacity = c.backgroundOpacity;
      _backgroundType = c.backgroundType;
      _cornerRoundness = c.cornerRadius;
      _borderEnabled = c.borderEnabled;
      _borderWidthDp = c.borderWidthDp;
      _fontStyle = c.fontStyle;
      _scaleFactor = c.scaleFactor;
      _use24Hour = c.use24Hour;
      _showSeconds = c.showSeconds;
      _showAmPm = c.showAmPm;
      _showDate = c.showDate;
      _timeLayout = c.timeLayout;
      _timeSeparator = c.timeSeparator;
      _secondsStyle = c.secondsStyle;
      _customFormatController.text = c.customFormat;
      _momentVisual = c.momentVisual;
      _momentUnit = c.momentUnit;
      _previousConfig = null;
    });
    _scheduleSync();
  }

  void _resetToDefaults() {
    _recordPreviousState();
    HapticFeedback.heavyImpact();
    setState(() {
      _activeLook = WidgetLook.all[0];
      _backgroundType = 'warm_paper';
      _backgroundOpacity = 1.0;
      _cornerRoundness = 28.0;
      _borderEnabled = true;
      _borderWidthDp = 1.0;
      _fontStyle = 'modern';
      _scaleFactor = 1.0;
      _accentHex = '#E8895A';
      _use24Hour = true;
      _leadingZero = true;
      _showHours = true;
      _showMinutes = true;
      _showSeconds = false;
      _showAmPm = false;
      _showDate = true;
      _showDayName = true;
      _showMonth = true;
      _showYear = false;
      _timeLayout = 'inline';
      _timeSeparator = 'colon';
      _secondsStyle = 'hidden';
      _customFormatController.clear();
      _momentVisual = 'ring';
      _momentUnit = 'days';
      _alignment = 'center';
    });
    _scheduleSync();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reset widget settings to defaults')),
    );
  }

  Future<void> _applyAndSync() async {
    _debounceTimer?.cancel();
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    try {
      final config = _buildCurrentConfig();
      await ref.read(widgetSyncServiceProvider).syncAllWidgets(config: config);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _activeLook.surfaceColor,
            content: Text(
              'All placed widgets synchronized with ${_activeLook.name} Look!',
              style: TextStyle(color: _activeLook.primaryTextColor),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showSaveLookDialog() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Custom Look'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Amber Minimalist',
            labelText: 'Look Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final config = _buildCurrentConfig();
      final savedLook = await LookPresetsManager.saveCustomLook(
        name: result,
        config: config,
      );
      await _loadCustomLooks();
      setState(() => _activeLook = savedLook);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Look "$result" saved successfully!')),
        );
      }
    }
  }

  Future<void> _showExportDialog() async {
    final config = _buildCurrentConfig();
    final code = LookPresetsManager.exportConfig(config);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Share Look Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Copy this short code to share your widget Look across devices:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                code,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Look code copied to clipboard!')),
              );
            },
            child: const Text('Copy to Clipboard'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _showImportDialog() async {
    final controller = TextEditingController();
    final imported = await showDialog<WidgetConfig>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Look'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Paste Look code or JSON here...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final c = LookPresetsManager.importConfig(controller.text);
              Navigator.pop(ctx, c);
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (imported != null) {
      _recordPreviousState();
      setState(() {
        _accentHex = imported.accentHex;
        _backgroundType = imported.backgroundType;
        _backgroundOpacity = imported.backgroundOpacity;
        _cornerRoundness = imported.cornerRadius;
        _borderEnabled = imported.borderEnabled;
        _borderWidthDp = imported.borderWidthDp;
        _fontStyle = imported.fontStyle;
        _use24Hour = imported.use24Hour;
        _showSeconds = imported.showSeconds;
        _timeLayout = imported.timeLayout;
        _momentVisual = imported.momentVisual;
        _momentUnit = imported.momentUnit;
      });
      _scheduleSync();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Look imported and applied!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);
    final colours = kairos.colours;

    return KairosScaffold(
      title: 'Widget Studio',
      padding: EdgeInsets.zero,
      actions: [
        IconButton(
          tooltip: 'Reset to Defaults',
          icon: const Icon(LucideIcons.rotateCcw, size: 20),
          onPressed: _resetToDefaults,
        ),
        if (_previousConfig != null)
          IconButton(
            tooltip: 'Undo',
            icon: const Icon(LucideIcons.undo, size: 20),
            onPressed: _undo,
          ),
        IconButton(
          tooltip: 'Share Look',
          icon: const Icon(LucideIcons.share2, size: 20),
          onPressed: _showExportDialog,
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Space.md,
          Space.md,
          Space.md,
          120, // Clear floating bottom nav bar
        ),
        children: <Widget>[
          // 1. Live Interactive Widget Preview Canvas
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 330,
              height: 184,
              padding: const EdgeInsets.all(18),
              decoration: _buildPreviewDecoration(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  (_cornerRoundness - 2).clamp(0.0, 38.0),
                ),
                child: _buildLiveWidgetPreview(),
              ),
            ),
          ),

          const SizedBox(height: Space.md),

          // 2. Widget Family Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _WidgetFamily.values.map((family) {
                final isSelected = family == _selectedFamily;
                final label = switch (family) {
                  _WidgetFamily.clock => 'Clock',
                  _WidgetFamily.nextMoment => 'Next Moment',
                  _WidgetFamily.worldClock => 'World Clock',
                  _WidgetFamily.thenMoment => 'Memories',
                  _WidgetFamily.interactive => 'Instruments',
                  _WidgetFamily.combo => 'Combo',
                };

                return Padding(
                  padding: const EdgeInsets.only(right: Space.xs),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedFamily = family);
                      }
                    },
                    selectedColor: colours.accent.withValues(alpha: 0.2),
                    backgroundColor: colours.surfaceElevated,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? colours.accent
                          : colours.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      fontSize: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RadiusTokens.pill),
                      side: BorderSide(
                        color: isSelected ? colours.accent : colours.border,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: Space.md),

          // 3. Tab Navigation: Looks / Time / Moment / Style
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colours.surfaceElevated,
              borderRadius: BorderRadius.circular(RadiusTokens.md),
              border: Border.all(color: colours.border),
            ),
            child: Row(
              children: [
                _buildTabButton('Looks', _StudioTab.looks, LucideIcons.palette),
                _buildTabButton(
                  'Time',
                  _StudioTab.timeBuilder,
                  LucideIcons.clock,
                ),
                _buildTabButton(
                  'Moment',
                  _StudioTab.momentBuilder,
                  LucideIcons.calendar,
                ),
                _buildTabButton(
                  'Style',
                  _StudioTab.styleTypography,
                  LucideIcons.sliders,
                ),
              ],
            ),
          ),

          const SizedBox(height: Space.lg),

          // 4. Tab Content
          switch (_activeTab) {
            _StudioTab.looks => _buildLooksTab(colours),
            _StudioTab.timeBuilder => _buildTimeBuilderTab(colours),
            _StudioTab.momentBuilder => _buildMomentBuilderTab(colours),
            _StudioTab.styleTypography => _buildStyleTypographyTab(colours),
          },

          const SizedBox(height: Space.xl),

          // 5. Actions Bar: Apply to All Placed Widgets
          PillButton(
            onPressed: _isSaving ? null : _applyAndSync,
            label: _isSaving ? 'Synchronizing...' : 'Apply to Placed Widgets',
            icon: const Icon(LucideIcons.sparkles, size: 18),
            variant: PillButtonVariant.primary,
          ),
          const SizedBox(height: Space.md),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showSaveLookDialog,
                  icon: const Icon(LucideIcons.bookmarkPlus, size: 16),
                  label: const Text('Save Look'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RadiusTokens.pill),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showImportDialog,
                  icon: const Icon(LucideIcons.download, size: 16),
                  label: const Text('Import Code'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RadiusTokens.pill),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: Space.huge),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, _StudioTab tab, IconData icon) {
    final isSelected = _activeTab == tab;
    final theme = KairosTheme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _activeTab = tab);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? theme.colours.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(RadiusTokens.sm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? theme.colours.onAccent
                    : theme.colours.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? theme.colours.onAccent
                      : theme.colours.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildPreviewDecoration() {
    final accent = _parseHex(_accentHex, _activeLook.accentColor);
    final borderColor = _borderEnabled
        ? accent.withValues(alpha: 0.35)
        : Colors.transparent;

    Gradient? bgGradient;
    Color bgColor;

    switch (_backgroundType) {
      case 'dark_ink':
        bgColor = const Color(0xFF141210).withValues(alpha: _backgroundOpacity);
        bgGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1C1A).withValues(alpha: _backgroundOpacity),
            const Color(0xFF0C0A09).withValues(alpha: _backgroundOpacity),
          ],
        );
        break;
      case 'terracotta':
        bgColor = const Color(0xFFC85A32).withValues(alpha: _backgroundOpacity);
        bgGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFD96B43).withValues(alpha: _backgroundOpacity),
            const Color(0xFFB34A24).withValues(alpha: _backgroundOpacity),
          ],
        );
        break;
      case 'glass':
        bgColor = Colors.white.withValues(alpha: _backgroundOpacity * 0.18);
        bgGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: _backgroundOpacity * 0.25),
            Colors.white.withValues(alpha: _backgroundOpacity * 0.08),
          ],
        );
        break;
      case 'transparent':
        bgColor = Colors.transparent;
        break;
      case 'warm_paper':
      default:
        bgColor = const Color(0xFFFAF7F2).withValues(alpha: _backgroundOpacity);
        bgGradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFCFAF6).withValues(alpha: _backgroundOpacity),
            const Color(0xFFF3EEE7).withValues(alpha: _backgroundOpacity),
          ],
        );
        break;
    }

    return BoxDecoration(
      color: bgColor,
      gradient: bgGradient,
      borderRadius: BorderRadius.circular(_cornerRoundness),
      border: Border.all(color: borderColor, width: _borderWidthDp),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: _activeLook.isDark ? 0.35 : 0.08,
          ),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  // --- TAB 1: LOOKS & BACKGROUND ---
  Widget _buildLooksTab(dynamic colours) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '10 CURATED LUXURY LOOKS',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: colours.textTertiary,
          ),
        ),
        const SizedBox(height: Space.xs),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _availableLooks.length,
            separatorBuilder: (_, __) => const SizedBox(width: Space.sm),
            itemBuilder: (context, index) {
              final look = _availableLooks[index];
              final isSelected = look.id == _activeLook.id;

              return GestureDetector(
                onTap: () {
                  _recordPreviousState();
                  HapticFeedback.selectionClick();
                  setState(() {
                    _activeLook = look;
                    _accentHex = _colorToHex(look.accentColor);
                    _backgroundType = switch (look.id) {
                      'midnight_ink' ||
                      'mono_graphite' ||
                      'neon_dial' ||
                      'minimal_dots' => 'dark_ink',
                      'terracotta_paper' || 'poster' => 'terracotta',
                      'sunset_glass' => 'glass',
                      _ => 'warm_paper',
                    };
                  });
                  _scheduleSync();
                },
                child: Container(
                  width: 148,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: look.surfaceColor,
                    borderRadius: BorderRadius.circular(RadiusTokens.md),
                    border: Border.all(
                      color: isSelected ? colours.accent : look.borderColor,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 5,
                            backgroundColor: look.accentColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              look.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: look.primaryTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        look.isDark ? 'Obsidian' : 'Paper',
                        style: TextStyle(
                          fontSize: 10,
                          color: look.secondaryTextColor,
                        ),
                      ),
                      Text(
                        look.description,
                        style: TextStyle(
                          fontSize: 9,
                          color: look.secondaryTextColor.withValues(alpha: 0.8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: Space.lg),

        Text(
          'BACKGROUND CANVAS',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: colours.textTertiary,
          ),
        ),
        const SizedBox(height: Space.xs),
        Wrap(
          spacing: Space.xs,
          runSpacing: Space.xs,
          children: [
            for (final bg in [
              ('Warm Paper', 'warm_paper'),
              ('Dark Ink', 'dark_ink'),
              ('Terracotta', 'terracotta'),
              ('Glass', 'glass'),
              ('Transparent', 'transparent'),
            ])
              ChoiceChip(
                label: Text(bg.$1),
                selected: _backgroundType == bg.$2,
                onSelected: (selected) {
                  if (selected) {
                    _recordPreviousState();
                    HapticFeedback.selectionClick();
                    setState(() => _backgroundType = bg.$2);
                    _scheduleSync();
                  }
                },
              ),
          ],
        ),

        const SizedBox(height: Space.lg),

        SurfaceCard(
          padding: const EdgeInsets.all(Space.md),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Background Opacity'),
                  Text(
                    '${(_backgroundOpacity * 100).toInt()}%',
                    style: TextStyle(
                      color: colours.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _backgroundOpacity,
                min: 0.05,
                max: 1.0,
                activeColor: colours.accent,
                onChanged: (val) {
                  setState(() => _backgroundOpacity = val);
                  _scheduleSync();
                },
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Corner Radius'),
                  Text(
                    '${_cornerRoundness.toInt()} dp',
                    style: TextStyle(
                      color: colours.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _cornerRoundness,
                min: 0.0,
                max: 40.0,
                activeColor: colours.accent,
                onChanged: (val) {
                  setState(() => _cornerRoundness = val);
                  _scheduleSync();
                },
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Hairline Highlight Border'),
                subtitle: const Text('Enhances contrast on busy wallpapers'),
                value: _borderEnabled,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _borderEnabled = val);
                  _scheduleSync();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 2: TIME BUILDER ---
  Widget _buildTimeBuilderTab(dynamic colours) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Battery warning banner for live seconds
        if (_showSeconds)
          Container(
            margin: const EdgeInsets.only(bottom: Space.md),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colours.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(RadiusTokens.md),
              border: Border.all(color: colours.accent.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.batteryCharging,
                  size: 20,
                  color: colours.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Live seconds update every second. Kairos restricts updates to screen-on to protect battery life.',
                    style: TextStyle(fontSize: 12, color: colours.textPrimary),
                  ),
                ),
              ],
            ),
          ),

        Text(
          'TIME LAYOUT',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: colours.textTertiary,
          ),
        ),
        const SizedBox(height: Space.xs),
        Wrap(
          spacing: Space.xs,
          children: [
            for (final layout in [
              ('Inline', 'inline'),
              ('Stacked', 'stacked'),
              ('Split', 'split'),
              ('Words', 'words'),
            ])
              ChoiceChip(
                label: Text(layout.$1),
                selected: _timeLayout == layout.$2,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _timeLayout = layout.$2);
                    _scheduleSync();
                  }
                },
              ),
          ],
        ),

        const SizedBox(height: Space.md),

        Text(
          'SEPARATOR STYLE',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: colours.textTertiary,
          ),
        ),
        const SizedBox(height: Space.xs),
        Wrap(
          spacing: Space.xs,
          children: [
            for (final sep in [
              ('Colon (:)', 'colon'),
              ('Dot (.)', 'dot'),
              ('Dash (-)', 'dash'),
              ('Space', 'space'),
              ('None', 'none'),
            ])
              ChoiceChip(
                label: Text(sep.$1),
                selected: _timeSeparator == sep.$2,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _timeSeparator = sep.$2);
                    _scheduleSync();
                  }
                },
              ),
          ],
        ),

        const SizedBox(height: Space.md),

        Text(
          'SECONDS STYLE',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: colours.textTertiary,
          ),
        ),
        const SizedBox(height: Space.xs),
        Wrap(
          spacing: Space.xs,
          children: [
            for (final sec in [
              ('Hidden', 'hidden'),
              ('Inline', 'inline'),
              ('Superscript', 'superscript'),
              ('Ring Around Time', 'ring'),
            ])
              ChoiceChip(
                label: Text(sec.$1),
                selected: _secondsStyle == sec.$2,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _secondsStyle = sec.$2;
                      _showSeconds = sec.$2 != 'hidden';
                    });
                    _scheduleSync();
                  }
                },
              ),
          ],
        ),

        const SizedBox(height: Space.lg),

        SurfaceCard(
          padding: const EdgeInsets.all(Space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ELEMENT TOGGLES',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: colours.textTertiary,
                ),
              ),
              SwitchListTile(
                title: const Text('Show Hours'),
                value: _showHours,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _showHours = val);
                  _scheduleSync();
                },
              ),
              SwitchListTile(
                title: const Text('Show Minutes'),
                value: _showMinutes,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _showMinutes = val);
                  _scheduleSync();
                },
              ),
              SwitchListTile(
                title: const Text('Show Seconds'),
                value: _showSeconds,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() {
                    _showSeconds = val;
                    if (val && _secondsStyle == 'hidden') {
                      _secondsStyle = 'inline';
                    } else if (!val) {
                      _secondsStyle = 'hidden';
                    }
                  });
                  _scheduleSync();
                },
              ),
              SwitchListTile(
                title: const Text('24-Hour Format'),
                subtitle: const Text('Toggle between 12h (AM/PM) and 24h'),
                value: _use24Hour,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _use24Hour = val);
                  _scheduleSync();
                },
              ),
              SwitchListTile(
                title: const Text('Leading Zero (e.g. 09:30)'),
                value: _leadingZero,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _leadingZero = val);
                  _scheduleSync();
                },
              ),
              SwitchListTile(
                title: const Text('Show AM / PM Indicator'),
                value: _showAmPm,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _showAmPm = val);
                  _scheduleSync();
                },
              ),
              SwitchListTile(
                title: const Text('Show Day of Week (e.g. TUE)'),
                value: _showDayName,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _showDayName = val);
                  _scheduleSync();
                },
              ),
              SwitchListTile(
                title: const Text('Show Date & Month'),
                value: _showDate,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _showDate = val);
                  _scheduleSync();
                },
              ),
              SwitchListTile(
                title: const Text('Show Year'),
                value: _showYear,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _showYear = val);
                  _scheduleSync();
                },
              ),
              SwitchListTile(
                title: const Text('Show Week Number'),
                value: _showWeekNumber,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _showWeekNumber = val);
                  _scheduleSync();
                },
              ),
              SwitchListTile(
                title: const Text('Show Day of Year'),
                value: _showDayOfYear,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _showDayOfYear = val);
                  _scheduleSync();
                },
              ),
              SwitchListTile(
                title: const Text('Show Time Zone'),
                value: _showTimeZone,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _showTimeZone = val);
                  _scheduleSync();
                },
              ),
              SwitchListTile(
                title: const Text('Battery Safe Mode'),
                subtitle: const Text('Throttles seconds when screen turns off'),
                value: _batterySafeMode,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _batterySafeMode = val);
                  _scheduleSync();
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: Space.md),

        // Custom Format Field with Tokens
        SurfaceCard(
          padding: const EdgeInsets.all(Space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CUSTOM FORMAT TOKENS (OPTIONAL)',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: colours.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _customFormatController,
                decoration: InputDecoration(
                  hintText: 'e.g. HH:mm EEE, d MMM',
                  suffixIcon: _customFormatController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 16),
                          onPressed: () {
                            _customFormatController.clear();
                            setState(() {});
                            _scheduleSync();
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  setState(() {});
                  _scheduleSync();
                },
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in [
                    'HH:mm',
                    'hh:mm a',
                    'EEE, d MMM',
                    'yyyy',
                    'w',
                    'D',
                  ])
                    ActionChip(
                      label: Text(t, style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        _customFormatController.text = t;
                        setState(() {});
                        _scheduleSync();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 3: MOMENT BUILDER ---
  Widget _buildMomentBuilderTab(dynamic colours) {
    final momentsAsync = ref.watch(momentListProvider);
    final moments = momentsAsync.value ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MOMENT SOURCE',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: colours.textTertiary,
          ),
        ),
        const SizedBox(height: Space.xs),
        DropdownButtonFormField<String?>(
          initialValue: _selectedMomentId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Automatically Next Upcoming'),
            ),
            for (final m in moments)
              DropdownMenuItem<String?>(
                value: m.id,
                child: Text(
                  '${m.title} (${m.targetUtc.day}/${m.targetUtc.month})',
                ),
              ),
          ],
          onChanged: (val) {
            setState(() => _selectedMomentId = val);
            _scheduleSync();
          },
        ),

        const SizedBox(height: Space.md),

        Text(
          'VISUAL PRESENTATION',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: colours.textTertiary,
          ),
        ),
        const SizedBox(height: Space.xs),
        Wrap(
          spacing: Space.xs,
          children: [
            for (final v in [
              ('Hero Ring', 'ring'),
              ('Big Numeral', 'hero_number'),
              ('Progress Bar', 'bar'),
              ('Minimal Chip', 'minimal_chip'),
              ('Poster Block', 'poster'),
            ])
              ChoiceChip(
                label: Text(v.$1),
                selected: _momentVisual == v.$2,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _momentVisual = v.$2);
                    _scheduleSync();
                  }
                },
              ),
          ],
        ),

        const SizedBox(height: Space.md),

        Text(
          'UNIT STYLE',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: colours.textTertiary,
          ),
        ),
        const SizedBox(height: Space.xs),
        Wrap(
          spacing: Space.xs,
          children: [
            for (final u in [
              ('Continuous (D H M S)', 'continuous'),
              ('Days', 'days'),
              ('Hours', 'hours'),
              ('Minutes', 'minutes'),
              ('Seconds', 'seconds'),
              ('Weeks', 'weeks'),
              ('Months & Days', 'months_days'),
              ('Years/Months/Days', 'ymd'),
              ('Percentage', 'percent'),
              ('Live Countdown', 'live_countdown'),
            ])
              ChoiceChip(
                label: Text(u.$1),
                selected: _momentUnit == u.$2,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _momentUnit = u.$2);
                    _scheduleSync();
                  }
                },
              ),
          ],
        ),

        const SizedBox(height: Space.md),

        SurfaceCard(
          padding: const EdgeInsets.all(Space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MOMENT DETAILS TO SHOW',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: colours.textTertiary,
                ),
              ),
              SwitchListTile(
                title: const Text('Show Title'),
                value: _showMomentTitle,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _showMomentTitle = val);
                  _scheduleSync();
                },
              ),
              SwitchListTile(
                title: const Text('Show Category Badge'),
                value: _showMomentCategory,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _showMomentCategory = val);
                  _scheduleSync();
                },
              ),
              SwitchListTile(
                title: const Text('Show Target Date'),
                value: _showMomentDate,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _showMomentDate = val);
                  _scheduleSync();
                },
              ),
              SwitchListTile(
                title: const Text('Show Progress Ring / Indicator'),
                value: _showMomentProgress,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  setState(() => _showMomentProgress = val);
                  _scheduleSync();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- TAB 4: STYLE & TYPOGRAPHY ---
  Widget _buildStyleTypographyTab(dynamic colours) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TYPOGRAPHY FAMILY',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: colours.textTertiary,
          ),
        ),
        const SizedBox(height: Space.xs),
        Wrap(
          spacing: Space.xs,
          children: [
            for (final f in [
              ('Modern Sans', 'modern'),
              ('Editorial Serif', 'serif'),
              ('Monospace', 'mono'),
              ('Rounded', 'rounded'),
              ('Display', 'display'),
            ])
              ChoiceChip(
                label: Text(f.$1),
                selected: _fontStyle == f.$2,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _fontStyle = f.$2);
                    _scheduleSync();
                  }
                },
              ),
          ],
        ),

        const SizedBox(height: Space.lg),

        Text(
          'ACCENT COLOR PALETTE',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
            color: colours.textTertiary,
          ),
        ),
        const SizedBox(height: Space.xs),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final hex in [
              '#E8895A', // Terracotta
              '#4FACFE', // Cyan Ink
              '#E25B7B', // Sakura Pink
              '#60A5FA', // Sky Blue
              '#34D399', // Emerald
              '#F59E0B', // Amber Gold
              '#A78BFA', // Violet
              '#F4EFE8', // Linen White
            ])
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _accentHex = hex);
                  _scheduleSync();
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _parseHex(hex, colours.accent),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _accentHex.toUpperCase() == hex.toUpperCase()
                          ? colours.textPrimary
                          : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: Space.lg),

        SurfaceCard(
          padding: const EdgeInsets.all(Space.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Numeral & Scale Factor'),
                  Text(
                    '${(_scaleFactor * 100).toInt()}%',
                    style: TextStyle(
                      color: colours.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _scaleFactor,
                min: 0.6,
                max: 1.6,
                activeColor: colours.accent,
                onChanged: (val) {
                  setState(() => _scaleFactor = val);
                  _scheduleSync();
                },
              ),
              const Divider(),
              Text(
                'TEXT ALIGNMENT',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: colours.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final a in [
                    ('Left', 'left', LucideIcons.alignLeft),
                    ('Center', 'center', LucideIcons.alignCenter),
                    ('Right', 'right', LucideIcons.alignRight),
                  ])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() => _alignment = a.$2);
                            _scheduleSync();
                          },
                          icon: Icon(a.$3, size: 14),
                          label: Text(
                            a.$1,
                            style: const TextStyle(fontSize: 11),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: _alignment == a.$2
                                ? colours.accent.withValues(alpha: 0.2)
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- LIVE WIDGET PREVIEW CANVAS RENDERING ---
  Widget _buildLiveWidgetPreview() {
    final accent = _parseHex(_accentHex, _activeLook.accentColor);
    final isDark =
        _backgroundType == 'dark_ink' ||
        (_backgroundType != 'warm_paper' && _activeLook.isDark);
    final textPrimary = isDark
        ? const Color(0xFFF4EFE8)
        : const Color(0xFF14120E);
    final textSecondary = isDark
        ? const Color(0xFF9E968D)
        : const Color(0xFF68625B);

    final String fontFamily = switch (_fontStyle) {
      'serif' => 'serif',
      'mono' => 'monospace',
      _ => 'sans-serif',
    };

    switch (_selectedFamily) {
      case _WidgetFamily.clock:
        String timeStr = '10:30';
        if (_timeSeparator == 'dot') timeStr = '10.30';
        if (_timeSeparator == 'dash') timeStr = '10-30';
        if (_timeSeparator == 'space') timeStr = '10 30';

        if (_timeLayout == 'stacked') {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '10',
                style: TextStyle(
                  fontSize: 48 * _scaleFactor,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                  fontFamily: fontFamily,
                  height: 0.9,
                ),
              ),
              Text(
                '30',
                style: TextStyle(
                  fontSize: 48 * _scaleFactor,
                  fontWeight: FontWeight.w600,
                  color: accent,
                  fontFamily: fontFamily,
                  height: 0.9,
                ),
              ),
              if (_showDate)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'TUE, 17 NOV',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
            ],
          );
        }

        if (_timeLayout == 'words') {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'half past',
                  style: TextStyle(
                    fontSize: 20 * _scaleFactor,
                    fontFamily: 'serif',
                    color: textSecondary,
                  ),
                ),
                Text(
                  'TEN',
                  style: TextStyle(
                    fontSize: 42 * _scaleFactor,
                    fontWeight: FontWeight.w800,
                    color: accent,
                    letterSpacing: 2.0,
                  ),
                ),
                if (_showDate)
                  Text(
                    'Tuesday, November 17',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
              ],
            ),
          );
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 50 * _scaleFactor,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                    fontFamily: fontFamily,
                    letterSpacing: -1.0,
                  ),
                ),
                if (_showSeconds) ...[
                  const SizedBox(width: 4),
                  Text(
                    '45',
                    style: TextStyle(
                      fontSize: _secondsStyle == 'superscript' ? 18 : 26,
                      fontWeight: FontWeight.w400,
                      color: accent,
                      fontFamily: fontFamily,
                    ),
                  ),
                ],
              ],
            ),
            if (_showDate) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _showDayName ? 'TUE, 17 NOV' : '17 NOV',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );

      case _WidgetFamily.nextMoment:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_showMomentCategory)
                  Text(
                    'TRAVEL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: accent,
                      letterSpacing: 1.2,
                    ),
                  ),
                Builder(
                  builder: (context) {
                    final (valStr, unitStr, sz) = switch (_momentUnit) {
                      'continuous' ||
                      'live_countdown' => ('42d 14h 32m 45s', '', 22.0),
                      'hours' => ('1,022', 'hours', 38.0),
                      'minutes' => ('61,352', 'mins', 34.0),
                      'seconds' => ('3,681,120', 'secs', 30.0),
                      'weeks' => ('6.0', 'weeks', 42.0),
                      'months_days' => ('1m 12d', 'left', 36.0),
                      'percent' => ('72%', 'done', 44.0),
                      _ => ('42', 'days', 48.0),
                    };
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          valStr,
                          style: TextStyle(
                            fontSize: sz * _scaleFactor,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                            fontFamily: fontFamily,
                          ),
                        ),
                        if (unitStr.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            unitStr,
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                if (_showMomentTitle)
                  Text(
                    'Trip to Kyoto',
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'serif',
                      color: textPrimary,
                    ),
                  ),
                if (_showMomentDate)
                  Text(
                    'Dec 29, 2026',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
              ],
            ),
            if (_showMomentProgress)
              WidgetProgressRing(
                progress: 0.72,
                accentColor: accent,
                size: 82,
                strokeWidth: 6.5,
              ),
          ],
        );

      case _WidgetFamily.worldClock:
        return Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'London',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                  Text(
                    '05:00',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      fontFamily: fontFamily,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tokyo',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                  Text(
                    '14:00',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      fontFamily: fontFamily,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New York',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                  Text(
                    '00:00',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      fontFamily: fontFamily,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mumbai',
                    style: TextStyle(fontSize: 11, color: textSecondary),
                  ),
                  Text(
                    '10:30',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      fontFamily: fontFamily,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case _WidgetFamily.thenMoment:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MEMORIES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: textSecondary,
                letterSpacing: 1.2,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '520',
                  style: TextStyle(
                    fontSize: 48 * _scaleFactor,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    fontFamily: fontFamily,
                  ),
                ),
                Text(
                  ' days ago',
                  style: TextStyle(fontSize: 14, color: textSecondary),
                ),
              ],
            ),
            Text(
              'Graduation Day',
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'serif',
                color: accent,
              ),
            ),
          ],
        );

      case _WidgetFamily.interactive:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NEXT ALARM',
                      style: TextStyle(
                        fontSize: 10,
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '06:30',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w400,
                        color: textPrimary,
                        fontFamily: fontFamily,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(RadiusTokens.pill),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            WidgetStreakBars(
              activeDays: const [true, true, true, true, false, true, true],
              accentColor: accent,
            ),
          ],
        );

      case _WidgetFamily.combo:
        return Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '10:30',
                    style: TextStyle(
                      fontSize: 34 * _scaleFactor,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                      fontFamily: fontFamily,
                    ),
                  ),
                  Text(
                    'TUE, 17 NOV',
                    style: TextStyle(
                      fontSize: 10,
                      color: textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(RadiusTokens.pill),
                    ),
                    child: Text(
                      'Alarm 06:30',
                      style: TextStyle(
                        fontSize: 10,
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 80,
              color: textSecondary.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NEXT MOMENT',
                    style: TextStyle(
                      fontSize: 9,
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '42 days',
                    style: TextStyle(
                      fontSize: 20 * _scaleFactor,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      fontFamily: fontFamily,
                    ),
                  ),
                  Text(
                    'Trip to Kyoto',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'serif',
                      color: textSecondary,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }
}
