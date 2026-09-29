# Contacto previo y chat de sesión

## Separación

- **Consultas previas**: una conversación persistente por paciente y perfil profesional, sin cita/pago. Se abre desde Explore o perfil público; no se convierte ni se fusiona al reservar.
- **Sesiones**: conserva Appointment y PrivateMessage existentes. Escritura solo en CONFIRMED, hasta endAt, con cuenta/profesional/pago habilitados. COMPLETED y CANCELLED son de lectura. Se sustituye el seguimiento anterior de siete días.
- Comparten PrivateMessage y los controladores de envío, historial, lecturas, límites y notificaciones. Conversation representa el contacto previo; la cita sigue representando el contexto de sesión, para preservar compatibilidad.
- CHECK en SQL exige exactamente un contexto (appointmentId o conversationId). No se copian ni se borran mensajes antiguos.

## Contacto previo

Solo participantes activos pueden acceder, sin excepción para administradores. Iniciar requiere profesional activo/verificado con rol correcto; no se permite contacto consigo mismo. El historial se conserva cuando el profesional deja de estar habilitado, pero no se puede escribir.

- Texto máximo 4000 caracteres, 20 mensajes nuevos/minuto por emisor entre ambos tipos de chat.
- Máximo 10 nuevas conversaciones/día por paciente; aperturas repetidas recuperan la misma.
- Bloqueo por participante: detiene ambos sentidos, persiste al reabrir. Solo quien bloqueó puede deshacer su bloqueo. No cancela citas ni altera el chat clínico.
- Reporte con descripción explícita al sistema UserReport existente; máximo 5 reportes/día. El administrador recibe lo que el denunciante escribió, no acceso irrestricto a la conversación.
- Notificación interna genérica, sin texto del mensaje. No push ni WebSocket: polling visible, detenido en segundo plano.
- No adjuntos, audio, videollamada, diagnósticos ni atención urgente en este contacto. Sin garantía de respuesta inmediata. No cifrado de extremo a extremo; protección de transporte mediante HTTPS en Railway.

## API autenticada

`POST /api/conversations/pre-booking/:psychologistId` crea o recupera.
`GET /api/conversations?before=<id>` devuelve hasta 30 contactos.
`GET /api/conversations/:id/messages?before=<sequence>` devuelve hasta 50 mensajes.
`POST /api/conversations/:id/messages` recibe clientId UUID y content; reintentos idénticos no duplican.
`POST /api/conversations/:id/read` recibe through.
`POST /api/conversations/:id/block` recibe blocked boolean.
`POST /api/conversations/:id/report` recibe description (10–2000 caracteres).

Las rutas `/api/chats` conservan el contexto de sesión y no aceptan IDs de contactos.

## Diseño

Adaptación de `desing/chat-desing`: burbujas turquesa/gris, iniciales o foto real, nombres, fecha/hora, lectura y campo redondeado. Se omiten presencia online, E2E, documentos y llamada del ejemplo porque no están disponibles en este chat. Bandeja con dos pestañas para ambos roles.

## Despliegue y aceptación

Cambios locales, no desplegados. Respaldar PostgreSQL, revisar `npx prisma migrate status` y desplegar la migración aditiva `20260925000000_contact_conversations` mediante `npx prisma migrate deploy`. Generar Prisma y compilar backend antes de arrancar. No usar db push/reset sobre datos existentes. Instalar Flutter después del backend actualizado.

Pruebas locales: `npm run test:contact`, `npm run test:chat` en esquemas desechables con TEST_DATABASE_URL local. Flutter: `flutter test test/contact_chat_test.dart test/private_chat_test.dart`. La prueba visual usa fuentes incluidas en el SDK de Flutter.

Resultados: 37 comprobaciones de contacto previo y 29 de sesión aprobadas. Las 17 pruebas Flutter de contacto, sesión, reseñas, identidad, estados y video también pasan. Se revisaron capturas de prueba en modo claro y oscuro. Backend compila; el análisis Flutter no presenta errores, aunque persisten avisos de APIs de estilo deprecadas en las pantallas anteriores.

Aceptación pendiente en Railway con dos cuentas/dispositivos: abrir desde Explore, responder desde Consultas previas, bloquear/desbloquear, enviar un reporte y reservar/completar una cita comprobando que ambas conversaciones siguen separadas.
