import 'package:flutter/material.dart';

import '../../design/glass_tokens.dart';
import '../../design/radius_tokens.dart';
import '../../design/spacing_tokens.dart';
import '../../theme/theme_extension.dart';
import 'glass_container.dart';

/// Spec §9 & §12: A translucent glassmorphic text input field with subtle focus states.
class GlassInputField extends StatefulWidget {
  const GlassInputField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.maxLength,
    this.maxLines = 1,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
  });

  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final int? maxLength;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;

  @override
  State<GlassInputField> createState() => _GlassInputFieldState();
}

class _GlassInputFieldState extends State<GlassInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kairos = KairosTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: Space.xxs, bottom: Space.xxs),
          child: Text(
            widget.labelText,
            style: kairos.typeScale.caption.copyWith(
              color: _isFocused
                  ? kairos.colours.accent
                  : kairos.colours.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        GlassContainer(
          intensity: GlassIntensity.subtle,
          borderRadius: RadiusTokens.mdRadius,
          borderColor: _isFocused
              ? kairos.colours.accent
              : kairos.glass.subtleBorder,
          borderWidth: _isFocused ? 1.5 : 1.0,
          padding: const EdgeInsets.symmetric(
            horizontal: Space.md,
            vertical: Space.xxs,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            maxLength: widget.maxLength,
            maxLines: widget.maxLines,
            keyboardType: widget.keyboardType,
            textCapitalization: widget.textCapitalization,
            style: kairos.typeScale.body.copyWith(
              color: kairos.colours.textPrimary,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: widget.hintText,
              hintStyle: kairos.typeScale.body.copyWith(
                color: kairos.colours.textTertiary,
              ),
              counterText: '',
              prefixIcon: widget.prefixIcon,
              suffixIcon: widget.suffixIcon,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: Space.xs),
            ),
            onChanged: widget.onChanged,
          ),
        ),
      ],
    );
  }
}
