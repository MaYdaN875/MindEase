# Calificaciones, reseñas e identidad

## Implementado

- Una calificación de 1 a 5 por cita, solo por su paciente, cuando tanto Appointment como Consultation estén COMPLETED. Colgar Jitsi no completa una consulta.
- Reintentos idénticos idempotentes; otra calificación para la misma cita devuelve 409. La cuenta debe estar activa.
- Comentario opcional de hasta 1000 caracteres. No se publica sin moderación. El público no recibe nombre, identificador del paciente, cita, fecha de consulta ni notas clínicas.
- El promedio incluye todas las calificaciones legítimas, independientemente de la publicación del texto, para no sesgarlo por moderación. Sin valoraciones se muestra «Sin calificaciones».
- Paciente: botón «Calificar / ver mi reseña» en consultas completadas; nuevas notificaciones de finalización abren el formulario. Es voluntario, sin ventanas obligatorias.
- Perfil público: comentarios aprobados, paginación de 20 y promedio real.
- Administración: «Reseñas de consultas», solo ADMIN, SUPERADMIN y MODERATOR. Motivo obligatorio; registra último moderador, fecha y motivo. No incluye un historial de dictámenes completo.
- Inicio y perfil usan el nombre de la cuenta. Directorio sin profesionales, fotos ni reseñas de demostración. Perfiles profesionales y citas usan photoUrl; si falta o falla la foto, muestran iniciales.

## Alcance de fotografías

Se corrigió la presentación de identidad, no se asignaron fotografías a personas sin autorización. User no tiene un campo de fotografía: los pacientes muestran iniciales. PsychologistProfile ya tiene photoUrl. La carga y edición de nuevas fotos de pacientes/profesionales es un flujo adicional pendiente (almacenamiento persistente, validación y controles de acceso); no se ha añadido un formulario de subida en este cambio.

## Despliegue

Los cambios son locales; no se ejecutó ninguna migración en Railway.

1. Respaldar PostgreSQL y revisar las migraciones pendientes.
2. Desplegar MindEase-back con la migración aditiva `20260924010000_patient_reviews`; ejecutar `npx prisma migrate deploy` y generar Prisma durante la compilación. No usar reset ni db push sobre la base existente.
3. Desplegar MindEase-Admin con la nueva vista de moderación.
4. Compilar/instalar Flutter actualizado después de desplegar el backend.
5. Con una consulta completada: enviar estrellas y comentario, comprobar el promedio, aprobar el texto desde administración y verificar que solo entonces aparece públicamente sin identidad.

## Pruebas

`npm run test:reviews` usa TEST_DATABASE_URL local y un esquema temporal exclusivo. Prueba la migración SQL, permisos, estado clínico, valores inválidos, concurrencia, moderación, privacidad y agregados. El esquema temporal se elimina al finalizar; no modifica los registros existentes.

`flutter test test/reviews_and_identity_test.dart test/private_chat_test.dart test/appointment_status_test.dart test/video_service_test.dart`

Pendiente de prueba manual integrada contra Railway y dispositivos reales tras el despliegue. Las reseñas no son un indicador de eficacia clínica; el moderador debe revisar posibles datos sensibles antes de publicarlas.
