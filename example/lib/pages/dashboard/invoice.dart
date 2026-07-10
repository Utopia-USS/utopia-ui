// For IList - re-exported by the design system's barrel.
import 'package:utopia_ui/utopia_ui.dart';

/// Status of a mock [Invoice], rendered as a themed chip in the table.
enum InvoiceStatus {
  /// Fully paid.
  paid('Paid'),

  /// Awaiting payment, not yet overdue.
  pending('Pending'),

  /// Past its due date.
  overdue('Overdue');

  /// Display label shown in the status chip and dropdown.
  final String label;

  const InvoiceStatus(this.label);
}

/// A mock invoice row for the dashboard table.
class Invoice {
  /// Invoice identifier, e.g. `'INV-1042'`.
  final String id;

  /// Customer display name.
  final String customer;

  /// Invoice total.
  final double amount;

  /// Current payment status.
  final InvoiceStatus status;

  /// Issue date, shown via `toDisplayStringWithoutHours`.
  final DateTime issued;

  const Invoice({
    required this.id,
    required this.customer,
    required this.amount,
    required this.status,
    required this.issued,
  });
}

/// The rows the dashboard starts with. Ids run consecutively from INV-1042 so
/// `useDashboardPageState` can mint the next id as `1042 + length`.
final IList<Invoice> seedInvoices = IList([
  Invoice(id: 'INV-1042', customer: 'Northwind Traders', amount: 1280.00, status: InvoiceStatus.paid, issued: DateTime(2026, 5, 4)),
  Invoice(id: 'INV-1043', customer: 'Blue Harbor Studio', amount: 640.50, status: InvoiceStatus.pending, issued: DateTime(2026, 5, 18)),
  Invoice(id: 'INV-1044', customer: 'Cedar & Finch', amount: 2310.00, status: InvoiceStatus.overdue, issued: DateTime(2026, 4, 2)),
  Invoice(id: 'INV-1045', customer: 'Lighthouse Media', amount: 480.00, status: InvoiceStatus.paid, issued: DateTime(2026, 5, 27)),
  Invoice(id: 'INV-1046', customer: 'Granite Peak Co.', amount: 95.20, status: InvoiceStatus.pending, issued: DateTime(2026, 6, 3)),
  Invoice(id: 'INV-1047', customer: 'Salt & Pepper Kitchens', amount: 1560.75, status: InvoiceStatus.paid, issued: DateTime(2026, 6, 9)),
  Invoice(id: 'INV-1048', customer: 'Riverstone Analytics', amount: 3020.00, status: InvoiceStatus.overdue, issued: DateTime(2026, 4, 21)),
  Invoice(id: 'INV-1049', customer: 'Amber Fields Farm', amount: 210.00, status: InvoiceStatus.pending, issued: DateTime(2026, 6, 15)),
  Invoice(id: 'INV-1050', customer: 'Northwind Traders', amount: 875.40, status: InvoiceStatus.paid, issued: DateTime(2026, 6, 22)),
  Invoice(id: 'INV-1051', customer: 'Cobalt Works', amount: 1420.00, status: InvoiceStatus.overdue, issued: DateTime(2026, 5, 11)),
  Invoice(id: 'INV-1052', customer: 'Juniper & Sage', amount: 730.25, status: InvoiceStatus.paid, issued: DateTime(2026, 6, 24)),
  Invoice(id: 'INV-1053', customer: 'Harbor Light Logistics', amount: 4890.00, status: InvoiceStatus.pending, issued: DateTime(2026, 6, 26)),
  Invoice(id: 'INV-1054', customer: 'Foxglove Florists', amount: 156.80, status: InvoiceStatus.paid, issued: DateTime(2026, 6, 27)),
  Invoice(id: 'INV-1055', customer: 'Ironwood Furniture', amount: 2745.50, status: InvoiceStatus.overdue, issued: DateTime(2026, 4, 30)),
  Invoice(id: 'INV-1056', customer: 'Willow Creek Dental', amount: 980.00, status: InvoiceStatus.paid, issued: DateTime(2026, 6, 28)),
  Invoice(id: 'INV-1057', customer: 'Bluebell Bakery', amount: 64.90, status: InvoiceStatus.pending, issued: DateTime(2026, 6, 29)),
  Invoice(id: 'INV-1058', customer: 'Stonebridge Consulting', amount: 6200.00, status: InvoiceStatus.pending, issued: DateTime(2026, 6, 30)),
  Invoice(id: 'INV-1059', customer: 'Maple & Main Realty', amount: 1875.00, status: InvoiceStatus.paid, issued: DateTime(2026, 7)),
  Invoice(id: 'INV-1060', customer: 'Copper Kettle Brewing', amount: 445.60, status: InvoiceStatus.overdue, issued: DateTime(2026, 5, 2)),
  Invoice(id: 'INV-1061', customer: 'Seabreeze Charters', amount: 3350.00, status: InvoiceStatus.paid, issued: DateTime(2026, 7, 2)),
  Invoice(id: 'INV-1062', customer: 'Thistle & Thorn Tattoo', amount: 290.00, status: InvoiceStatus.pending, issued: DateTime(2026, 7, 3)),
  Invoice(id: 'INV-1063', customer: 'Golden Gate Tutoring', amount: 1120.75, status: InvoiceStatus.paid, issued: DateTime(2026, 7, 5)),
  Invoice(id: 'INV-1064', customer: 'Redwood Robotics', amount: 8480.00, status: InvoiceStatus.pending, issued: DateTime(2026, 7, 6)),
  Invoice(id: 'INV-1065', customer: 'Blue Harbor Studio', amount: 512.30, status: InvoiceStatus.overdue, issued: DateTime(2026, 5, 20)),
  Invoice(id: 'INV-1066', customer: 'Pinecrest Publishing', amount: 1990.00, status: InvoiceStatus.paid, issued: DateTime(2026, 7, 7)),
  Invoice(id: 'INV-1067', customer: 'Cascade Cleaners', amount: 138.45, status: InvoiceStatus.pending, issued: DateTime(2026, 7, 8)),
]);
