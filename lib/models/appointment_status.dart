// Presentation only: Appointment remains CONFIRMED while Consultation is IN_PROGRESS.
String appointmentDisplayStatus(Map<dynamic, dynamic> appointment) {
  final status = appointment['status'] as String? ?? 'PENDING';
  return status == 'CONFIRMED' && appointment['consultation']?['status'] == 'IN_PROGRESS'
      ? 'IN_PROGRESS' : status;
}

bool appointmentMatchesFilter(Map<dynamic, dynamic> appointment, String filter) {
  final status = appointmentDisplayStatus(appointment);
  return switch (filter) {
    'Solicitudes' => status == 'PENDING',
    'Próximas' => status == 'CONFIRMED',
    'En curso' => status == 'IN_PROGRESS',
    'Finalizadas' => status == 'COMPLETED',
    'Canceladas' => status == 'CANCELLED',
    _ => true,
  };
}
