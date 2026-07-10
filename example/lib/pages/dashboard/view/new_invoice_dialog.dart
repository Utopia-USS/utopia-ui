import 'package:flutter/material.dart';
import 'package:utopia_hooks/utopia_hooks.dart';
import 'package:utopia_ui/utopia_ui.dart';

import '../invoice.dart';

/// The "New invoice" [UtopiaDialog.form]: customer and amount fields, a status
/// dropdown and an issue-date picker; "Create" pops with the built [Invoice].
///
/// A self-contained widget-level form (the composable-hooks widget archetype):
/// its four field states live and die with the dialog, so they stay local
/// instead of polluting the dashboard's page state.
class NewInvoiceDialog extends HookWidget {
  /// The id the created invoice will carry, minted by the dashboard state.
  final String nextId;

  /// Creates the new-invoice dialog.
  const NewInvoiceDialog({super.key, required this.nextId});

  @override
  Widget build(BuildContext context) {
    final customerState = useState('');
    final amountState = useState('');
    final statusState = useState(InvoiceStatus.pending);
    final issuedState = useState<DateTime?>(DateTime(2026, 7, 9));

    final amount = double.tryParse(amountState.value);
    final isValid = customerState.value.trim().isNotEmpty && amount != null && issuedState.value != null;

    final fieldGap = SizedBox(height: context.spacing.lg);
    return UtopiaDialog.form(
      title: Text('New invoice - $nextId'),
      sliver: SliverList.list(
        children: [
          UtopiaTextField(
            value: customerState.value,
            label: const Text('Customer'),
            onChanged: (value) => customerState.value = value ?? '',
          ),
          fieldGap,
          UtopiaTextField(
            value: amountState.value,
            label: const Text('Amount'),
            hint: const Text('0.00'),
            suffix: const Padding(padding: EdgeInsets.only(left: 8), child: Icon(Icons.attach_money, size: 18)),
            error: amountState.value.isNotEmpty && amount == null ? const Text('Enter a number') : null,
            onChanged: (value) => amountState.value = value ?? '',
          ),
          fieldGap,
          UtopiaDropdownField<InvoiceStatus>(
            label: 'Status',
            value: statusState.value,
            values: InvoiceStatus.values,
            valueLabelBuilder: (value) => value.label,
            onChanged: (value) => statusState.value = value,
          ),
          fieldGap,
          UtopiaDatePicker(
            label: 'Issued',
            date: issuedState.value,
            onDateChanged: (value) => issuedState.value = value,
          ),
        ],
      ),
      bottom: UtopiaButton(
        isEnabled: isValid,
        onTap: () => Navigator.of(context).pop(
          Invoice(
            id: nextId,
            customer: customerState.value.trim(),
            amount: amount ?? 0,
            status: statusState.value,
            issued: issuedState.value ?? DateTime(2026, 7, 9),
          ),
        ),
        child: const Text('Create'),
      ),
    );
  }
}
