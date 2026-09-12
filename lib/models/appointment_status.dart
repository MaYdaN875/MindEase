// Presentation only: Appointment remains CONFIRMED while Consultation is IN_PROGRESS.
String appointmentDisplayStatus(Map<dynamic, dynamic> appointment) {
  final status = appointment['status'] as String? ?? 'PENDING';
  return status == 'CONFIRMED' && appointment['consultation']?['status'] == 'IN_PROGRESS'
      ? 'IN_PROGRESS' : status;
}
