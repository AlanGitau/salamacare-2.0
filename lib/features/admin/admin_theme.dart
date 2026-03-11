import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin Panel Design Tokens — TailAdmin / Linear aesthetic
// NO gradients · NO shadows · NO colored icon boxes · single sky-blue accent
//
// Fonts are bundled locally in assets/fonts/ — no network fetching.
// Use 'DM Sans' (registered in pubspec.yaml) for all UI text.
// Use 'IBM Plex Mono' (registered in pubspec.yaml) for numbers and timestamps.
// ─────────────────────────────────────────────────────────────────────────────

// Canvas & surfaces
const Color adminBgCanvas   = Color(0xFFF1F5F9);
const Color adminBgSurface  = Color(0xFFFFFFFF);
const Color adminBgSubtle   = Color(0xFFF8FAFC);

// Borders
const Color adminBorderLight = Color(0xFFE8ECF0);
const Color adminBorderFocus = Color(0xFFB0BEC5);

// Sidebar
const Color adminSidebarBg       = Color(0xFFFFFFFF);
const Color adminSidebarBorder   = Color(0xFFE8ECF0);
const Color adminSidebarLabel    = Color(0xFF637381);
const Color adminSidebarActive   = Color(0xFF0EA5E9);
const Color adminSidebarActiveBg = Color(0xFFEFF8FF);

// Text
const Color adminTextHeading = Color(0xFF1A2332);
const Color adminTextBody    = Color(0xFF637381);
const Color adminTextMuted   = Color(0xFF9EAAB5);

// Accent — single sky blue, used sparingly
const Color adminAccent     = Color(0xFF0EA5E9);
const Color adminAccentDark = Color(0xFF0284C7);
const Color adminAccentTint = Color(0xFFEFF8FF);

// Status
const Color adminSuccess     = Color(0xFF22C55E);
const Color adminSuccessTint = Color(0xFFF0FDF4);
const Color adminWarning     = Color(0xFFF59E0B);
const Color adminWarningTint = Color(0xFFFFFBEB);
const Color adminDanger      = Color(0xFFEF4444);
const Color adminDangerTint  = Color(0xFFFFF1F1);
const Color adminNeutral     = Color(0xFF6B7280);

// Font family name constants — match pubspec.yaml font registrations exactly
const _dmSans     = 'DM Sans';
const _ibmMono    = 'IBM Plex Mono';

// ─── Typography helpers ───────────────────────────────────────────────────────

TextStyle adminPageTitle() => const TextStyle(
    fontFamily: _dmSans, fontSize: 20, fontWeight: FontWeight.w600, color: adminTextHeading);

TextStyle adminSectionHeading() => const TextStyle(
    fontFamily: _dmSans, fontSize: 15, fontWeight: FontWeight.w600, color: adminTextHeading);

TextStyle adminKpiNumber() => const TextStyle(
    fontFamily: _ibmMono, fontSize: 30, fontWeight: FontWeight.w600, color: adminTextHeading);

TextStyle adminDeltaStyle({required bool positive}) => TextStyle(
    fontFamily: _dmSans,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: positive ? adminSuccess : adminDanger);

TextStyle adminNavLabel({bool active = false}) => TextStyle(
    fontFamily: _dmSans,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: active ? adminSidebarActive : adminSidebarLabel);

TextStyle adminBodyText() => const TextStyle(
    fontFamily: _dmSans, fontSize: 13, fontWeight: FontWeight.w400, color: adminTextBody);

TextStyle adminMetadata() => const TextStyle(
    fontFamily: _ibmMono, fontSize: 11, fontWeight: FontWeight.w400, color: adminTextMuted);

TextStyle adminTableHeader() => const TextStyle(
    fontFamily: _dmSans, fontSize: 11, fontWeight: FontWeight.w600, color: adminTextMuted);

TextStyle adminButtonText({Color? color}) => TextStyle(
    fontFamily: _dmSans,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: color ?? adminTextBody);

// ─── Reusable button builders ─────────────────────────────────────────────────

Widget adminPrimaryButton({
  required String label,
  required VoidCallback onTap,
  IconData? icon,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: adminAccent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: const TextStyle(
                  fontFamily: _dmSans,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white)),
        ],
      ),
    ),
  );
}

Widget adminSecondaryButton({
  required String label,
  required VoidCallback onTap,
  IconData? icon,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: adminBgSurface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: adminBorderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: adminTextBody),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: const TextStyle(
                  fontFamily: _dmSans,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: adminTextBody)),
        ],
      ),
    ),
  );
}

Widget adminDangerButton({required String label, required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: adminDangerTint,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: adminDanger),
      ),
      alignment: Alignment.center,
      child: Text(label,
          style: const TextStyle(
              fontFamily: _dmSans,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: adminDanger)),
    ),
  );
}

// ─── Status badge ─────────────────────────────────────────────────────────────

Widget adminStatusBadge(String status) {
  late Color bg, textColor;
  Border? border;
  String label;

  switch (status) {
    case 'scheduled':
      bg = adminAccentTint; textColor = adminAccent; label = 'Scheduled';
      break;
    case 'confirmed':
      bg = adminSuccessTint; textColor = adminSuccess; label = 'Confirmed';
      break;
    case 'completed':
      bg = adminSuccessTint; textColor = adminSuccess; label = 'Completed';
      break;
    case 'in_progress':
      bg = adminWarningTint; textColor = adminWarning; label = 'In Progress';
      break;
    case 'checked_in':
      bg = adminAccentTint; textColor = adminAccent; label = 'Checked In';
      break;
    case 'cancelled':
      bg = adminDangerTint; textColor = adminDanger; label = 'Cancelled';
      break;
    case 'no_show':
      bg = adminDangerTint;
      textColor = adminDanger;
      border = Border.all(color: adminDanger, width: 1);
      label = 'No Show';
      break;
    default:
      bg = adminBgSubtle; textColor = adminTextMuted; label = status;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(4),
      border: border ?? Border.all(color: Colors.transparent),
    ),
    child: Text(
      label,
      style: TextStyle(
          fontFamily: _dmSans,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor),
    ),
  );
}
