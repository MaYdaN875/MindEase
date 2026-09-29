# Chat privado — primer bloque funcional

## Actualización 25/09/2026

El módulo ahora incluye contacto previo separado. Ver [CONTACT_CHAT.md](CONTACT_CHAT.md).
La regla de seguimiento de siete días fue sustituida: las sesiones completadas,
canceladas o fuera de su horario final quedan en lectura. Se conserva el historial.
Las notificaciones de mensajes ahora permiten abrir la bandeja.

## Alcance

- Texto persistente por cita, no un canal de Community ni el chat interno de Jitsi.
- Entrada desde el icono Mensajes privados en Mis Consultas (paciente) y Consultas
  Clínicas (psicólogo). Bandeja paginada con interlocutor, fecha y no leídos.
- Historial de 50 mensajes por página, ordenado por secuencia; cargar anteriores.
- Actualización cada 5 segundos en conversación visible y cada 10 en la primera
  página de la bandeja. No WebSocket ni push. Se detiene en segundo plano.
- Texto máximo 4000 caracteres; 20 mensajes nuevos/minuto por emisor.
- UUID de cliente estable durante el reintento del mismo texto: no duplica envíos.
  El borrador se conserva en memoria al fallar; no sobrevive al cierre del proceso.
- Marcas de lectura hasta un mensaje existente de esa conversación. Son una señal
  de apertura del chat, no una garantía de atención o comprensión del contenido.
- Aviso interno genérico por conversación con mensajes sin leer; sin vista previa
  del contenido. Acceder desde la bandeja de chat; no se añadió navegación desde
  la notificación ni push del sistema en este bloque.

## Reglas

La política actual habilita escritura desde CONFIRMED hasta endAt, mientras no
pase a COMPLETED/CANCELLED. No hay seguimiento escrito posterior dentro de la sesión. Requiere ambas
cuentas ACTIVE, profesional VERIFICADO y rol PSYCHOLOGIST_VERIFIED. Una cita con
precio necesita pago SUCCEEDED coincidente; las gratuitas no generan pagos.
No se modifica el precio, agenda, disponibilidad ni estados para abrir el chat.

Canceladas, NO_SHOW, vencidas o con profesional no habilitado quedan en lectura.
Una reserva PENDING sin mensajes no abre una conversación. Las cuentas inactivas
no pueden autenticarse. Solo paciente y profesional asignados acceden al historial:
ADMIN/SUPERADMIN no tienen excepción de lectura. Nunca se proyectan notas clínicas.

No es atención de emergencias, no hay vigilancia humana permanente ni promesa de
respuesta inmediata. No adjuntos, audios, edición, borrado, búsqueda o moderación
de texto privado. No se envían mensajes a proveedores de IA.

HTTPS protege el transporte en Railway, pero esto NO es cifrado de extremo a
extremo: el contenido se almacena en PostgreSQL y puede ser accesible al operador
de la base/respaldos. Antes de uso real, definir retención, borrado, tratamiento de
reportes y revisar controles operativos de acceso a datos sensibles.

## Backend y despliegue

Rutas autenticadas:

- GET /api/chats?before=<appointmentId>: 30 conversaciones por página.
- GET /api/chats/:appointmentId/messages?before=<sequence>: 50 mensajes.
- POST /api/chats/:appointmentId/messages: {clientId: UUID, content: string}.
- POST /api/chats/:appointmentId/read: {through: sequence}.

Migración aditiva: `20260924000000_private_chat`, únicamente tabla PrivateMessage,
índices, claves foráneas y límite SQL de longitud. No se aplicó a Railway ni al
esquema local real. No se cambió el seed existente del usuario.

Para habilitarlo: publicar los cambios de MindEase-back, respaldar la base y
revisar `npx prisma migrate status`. Aplicar `npx prisma migrate deploy` en el
entorno backend de Railway con su DATABASE_URL, verificando antes que no haya
otras migraciones pendientes inesperadas. Compilar/generar Prisma con el esquema
nuevo antes de iniciar el servidor. Después instalar el APK nuevo.

No utilizar `db push` ni `migrate reset` en Railway. La referencia de variables
`${{Postgres.DATABASE_URL}}` solo se resuelve en Railway, no en un .env local.

## Comprobaciones

Backend: `npm run build` y `npm run test:chat` con TEST_DATABASE_URL apuntando
exclusivamente a localhost. El test crea y elimina su propio esquema aleatorio;
valida la migración SQL real y 29 condiciones de acceso, pagos, suspensión,
concurrencia, historial, límites, lecturas y privacidad de notificaciones.

Flutter: análisis de archivos nuevos/modificados y pruebas en
`test/private_chat_test.dart`, más regresiones de estados y video.

Pendiente de aceptación: desplegar y probar con dos cuentas/dispositivos reales,
envío bidireccional, no leídos, retorno del segundo plano, error/reintento y chat
de cita cancelada/seguimiento vencido. No confundir compilación con prueba E2E.
