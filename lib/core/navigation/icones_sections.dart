import 'package:flutter/material.dart';

/// Icônes Material des codes Font Awesome du registre de navigation du
/// portail (`student_portal/navigation.py`) : le serveur décrit le menu, le
/// téléphone le dessine avec ses propres icônes.
const Map<String, IconData> _icones = {
  'fa-th-large': Icons.dashboard_rounded,
  'fa-graduation-cap': Icons.school_rounded,
  'fa-calendar-check': Icons.event_available_rounded,
  'fa-clipboard-check': Icons.fact_check_rounded,
  'fa-chart-line': Icons.insights_rounded,
  'fa-book-open': Icons.menu_book_rounded,
  'fa-archive': Icons.inventory_2_rounded,
  'fa-book-reader': Icons.local_library_rounded,
  'fa-user-check': Icons.how_to_reg_rounded,
  'fa-folder-open': Icons.folder_open_rounded,
  'fa-file-invoice-dollar': Icons.receipt_long_rounded,
  'fa-hand-holding-usd': Icons.price_change_rounded,
  'fa-user-shield': Icons.verified_user_rounded,
  'fa-hand-paper': Icons.back_hand_rounded,
  'fa-users-cog': Icons.manage_accounts_rounded,
  'fa-star': Icons.star_rate_rounded,
  'fa-vote-yea': Icons.how_to_vote_rounded,
  'fa-landmark': Icons.account_balance_rounded,
  'fa-lightbulb': Icons.lightbulb_rounded,
  'fa-users': Icons.forum_rounded,
  'fa-comments': Icons.chat_rounded,
  'fa-bell': Icons.notifications_rounded,
  'fa-user-circle': Icons.account_circle_rounded,
  // Portail enseignant (`lecturers/navigation.py`).
  'fa-calendar-week': Icons.calendar_view_week_rounded,
  'fa-calendar-plus': Icons.edit_calendar_rounded,
  'fa-redo': Icons.replay_rounded,
  'fa-file-signature': Icons.draw_rounded,
  'fa-chalkboard-teacher': Icons.co_present_rounded,
  'fa-file-upload': Icons.upload_file_rounded,
  'fa-user-clock': Icons.schedule_rounded,
  'fa-money-check-alt': Icons.payments_rounded,
  'fa-id-card': Icons.badge_rounded,
};

/// L'icône d'une section ; une icône inconnue (section ajoutée côté serveur
/// après la sortie de l'application) a un repli, jamais un trou.
IconData iconeDeSection(String code) =>
    _icones[code.trim()] ?? Icons.apps_rounded;
