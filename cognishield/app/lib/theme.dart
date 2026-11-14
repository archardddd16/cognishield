import 'package:flutter/material.dart';

const kPrimary = Color(0xFF2F5BEA);
const kDanger = Color(0xFFEF4444);
const kWarning = Color(0xFFF59E0B);
const kSafe = Color(0xFF22C55E);
const kGraphSafe = Color(0xFF5B7CFA);

extension ColorSoft on Color {
  /// Same color with the given opacity (works on every Flutter version).
  Color soft(double opacity) => withAlpha((opacity.clamp(0.0, 1.0) * 255).round());
}

Color levelColor(String level) {
  switch (level) {
    case 'danger':
      return kDanger;
    case 'warning':
      return kWarning;
    default:
      return kSafe;
  }
}

IconData levelIcon(String level) {
  switch (level) {
    case 'danger':
      return Icons.warning_rounded;
    case 'warning':
      return Icons.priority_high_rounded;
    default:
      return Icons.check_rounded;
  }
}

class Palette {
  const Palette(this.dark);
  final bool dark;

  factory Palette.of(BuildContext context) => Palette(Theme.of(context).brightness == Brightness.dark);

  Color get card => dark ? const Color(0xFF1B2547) : Colors.white;
  Color get tint => dark ? const Color(0xFF243059) : const Color(0xFFE6EDFF);
  Color get text => dark ? const Color(0xFFF2F5FF) : const Color(0xFF0F1A3D);
  Color get muted => dark ? const Color(0xFF9CA8CB) : const Color(0xFF6A7595);
  Color get line => dark ? const Color(0x1FFFFFFF) : const Color(0x142F5BEA);
  List<Color> get bg => dark
      ? const [Color(0xFF0D1430), Color(0xFF121B3C)]
      : const [Color(0xFFE8EEFF), Color(0xFFF8FAFF)];
}

ThemeData buildTheme(Brightness b) {
  final p = Palette(b == Brightness.dark);
  final scheme = ColorScheme.fromSeed(seedColor: kPrimary, brightness: b)
      .copyWith(primary: kPrimary, onPrimary: Colors.white);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg.last,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      foregroundColor: p.text,
      titleTextStyle: TextStyle(color: p.text, fontSize: 18, fontWeight: FontWeight.w700),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith((s) {
        final sel = s.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
          color: sel ? kPrimary : p.muted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((s) {
        return IconThemeData(color: s.contains(WidgetState.selected) ? kPrimary : p.muted);
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? kPrimary : p.muted.soft(0.4),
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
  );
}

/// Soft gradient background with two faint decorative blobs.
class GradientBox extends StatelessWidget {
  const GradientBox({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: p.bg),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(shape: BoxShape.circle, color: kPrimary.soft(p.dark ? 0.12 : 0.08)),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -110,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(shape: BoxShape.circle, color: kPrimary.soft(p.dark ? 0.10 : 0.06)),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.onTap,
    this.radius = 20,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = Palette.of(context);
    final r = BorderRadius.circular(radius);
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? p.card,
        borderRadius: r,
        border: Border.all(color: p.line),
        boxShadow: [
          BoxShadow(
            color: (p.dark ? Colors.black : kPrimary).soft(p.dark ? 0.35 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: r,
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

String timeAgo(DateTime? t) {
  if (t == null) return '';
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 45) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} hr ago';
  return '${d.inDays} d ago';
}
