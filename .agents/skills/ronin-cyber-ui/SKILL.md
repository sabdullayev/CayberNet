---
name: ronin-cyber-ui
description: Flutter-specific Cyberpunk / Tactical HUD UI kit rules for ronin_mesenger. Use alongside ui-ux-pro-max whenever creating or redesigning Flutter screens.
---

# Ronin Messenger — Flutter Cyberpunk UI Rules

1. **Preserve Logic**: NEVER break or delete existing controllers, state management, navigation, or API bindings. Only replace the visual presentation tree.
2. **Colors (Arasaka / Tactical HUD)**:
   - Void Background: `Color(0xFF07090E)`
   - Surface / Panel: `Color(0xFF0F141F)` with `0.85` opacity
   - Primary Accent (Ronin Crimson): `Color(0xFFFF2A54)`
   - Secondary Accent (Cyber Cyan): `Color(0xFF00F0FF)`
   - Tech Yellow (Badges/Warnings): `Color(0xFFFCEE0A)`
   - Text Primary: `Color(0xFFEAEDF3)` | Muted: `Color(0xFF64748B)`
3. **Flutter Geometry (NO standard rounded cards)**:
   - Do NOT use `BorderRadius.circular(16)` for cards or buttons.
   - Use chamfered/cut corners via `ShapeDecoration` + `BeveledRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomRight: Radius.circular(10)))`.
   - Add 1px glowing borders (`BorderSide(color: Color(0xFF00F0FF).withOpacity(0.3), width: 1)`) and subtle `BoxShadow` glow (`blurRadius: 12, spreadRadius: -2`).
4. **HUD Micro-Details**:
   - Add small monospace uppercase technical labels (`fontSize: 10, letterSpacing: 1.5`) on card corners and headers (e.g., `SYS.ONLINE // 04`, `[ CYBER_ID ]`, `NET: SECURE`).
   - Input fields must have a dark `#0B0E17` fill and a thick `3px` glowing accent bar on the left border.
   - Use `ClipPath` or `BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10))` for navigation bars and overlays.
