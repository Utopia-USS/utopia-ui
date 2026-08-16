/// A themeable, general-purpose Flutter design system: tables, dialogs,
/// sidebar navigation and form primitives.
library;

// Third-party types appearing in this package's public API surface
// (UtopiaTable.rows, UtopiaTableEntry lists, useUtopiaTableState), re-exported so the
// barrel alone suffices to use them: IList plus the `toIList()` extension.
export 'package:fast_immutable_collections/fast_immutable_collections.dart' show FicIterableExtension, IList;

export 'src/theme/utopia_theme.dart';
export 'src/theme/utopia_theme_colors.dart';
export 'src/theme/utopia_theme_data.dart';
export 'src/theme/utopia_theme_text_styles.dart';
export 'src/theme/utopia_tokens.dart';

// utils
/// `DateTime` display-formatting and calendar-arithmetic helpers used by the
/// date picker.
export 'src/util/date_time_extension.dart';
export 'src/util/utopia_context_extensions.dart';

// widgets
export 'src/widget/button/utopia_button.dart';
export 'src/widget/button/utopia_ghost_button.dart';
export 'src/widget/button/utopia_remove_icon_button.dart';
export 'src/widget/chip/utopia_chip.dart';
export 'src/widget/chip/utopia_chip_list.dart';
export 'src/widget/date_picker/utopia_date_picker.dart';
export 'src/widget/dialog/utopia_confirm_dialog.dart';
export 'src/widget/dialog/utopia_dialog.dart';
export 'src/widget/dropdown/utopia_dropdown_field.dart';
export 'src/widget/layout/utopia_breakpoints.dart';
export 'src/widget/layout/utopia_card.dart';
export 'src/widget/layout/utopia_divider.dart';
export 'src/widget/layout/utopia_form_layout.dart';
export 'src/widget/layout/utopia_gradient_background.dart';
export 'src/widget/layout/utopia_page_wrapper.dart';
export 'src/widget/loading/utopia_loader.dart';
export 'src/widget/loading/utopia_loading_box.dart';
export 'src/widget/loading/utopia_three_bounce.dart';
export 'src/widget/misc/utopia_collapsible.dart';
export 'src/widget/misc/utopia_multi_widget.dart';
export 'src/widget/overlay/utopia_overlay_anchor.dart';
export 'src/widget/select/utopia_check_row.dart';
export 'src/widget/select/utopia_checkbox.dart';
export 'src/widget/select/utopia_radio.dart';
export 'src/widget/sidebar/utopia_sidebar.dart';
export 'src/widget/sidebar/utopia_sidebar_item.dart';
export 'src/widget/slider/utopia_slider.dart';
export 'src/widget/switch/utopia_switch.dart';
export 'src/widget/switch/utopia_switch_field.dart';
export 'src/widget/table/utopia_table.dart';
export 'src/widget/table/utopia_table_empty.dart';
export 'src/widget/table/utopia_table_entry.dart';
export 'src/widget/table/utopia_table_search_panel.dart';
export 'src/widget/table/utopia_table_state.dart';
export 'src/widget/text/utopia_copyable_text.dart';
export 'src/widget/text/utopia_header.dart';
export 'src/widget/text/utopia_title.dart';
export 'src/widget/text_field/utopia_search_field.dart';
export 'src/widget/text_field/utopia_text_field.dart';
export 'src/widget/wrapper/utopia_field_wrapper.dart';
export 'src/widget/wrapper/utopia_labeled_field.dart';
