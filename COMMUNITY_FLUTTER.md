# Bloque 5.6 — Community en Flutter

Implementado el 20 de septiembre de 2026 sobre los contratos REST de los bloques 5.1–5.5. No se modificó el backend ni la base de datos de la aplicación.

## Acceso

- Pacientes: pestaña **Community** de la navegación principal y acceso **Explorar canales** desde Inicio. Se retiró la pantalla de discusión simulada y el acceso al supuesto chat grupal.
- Profesionales: pestaña **Community** de su interfaz. El módulo consulta el perfil actual; exige rol `PSYCHOLOGIST_VERIFIED` y acreditación `VERIFICADO` para mostrar gestión. La autorización definitiva sigue correspondiendo al servidor.
- La URL y el token se obtienen de `AuthService`. En Android se conserva el host del emulador `10.0.2.2`; las rutas `/uploads/community/...` se resuelven contra el mismo servidor.

## Funciones

- Modelos `CommunityCategory`, `CommunityChannel`, `CommunityPost`, `PostMedia`, `PostComment` y página genérica con cursor en `lib/models/community.dart`.
- `CommunityService`: categorías, canales, seguimiento, feed, creación/edición, borradores, archivado, likes, comentarios, reportes y carga multipart. Cliente HTTP y proveedor de token inyectables para pruebas.
- Exploración de canales por categoría, texto y seguimiento; feed general o de canales seguidos. Recarga manual, paginación, deduplicación de filas, estados vacíos y reintento de lectura.
- Detalle del canal, seguir/dejar de seguir con contador confirmado por el servidor.
- Publicaciones con likes, etiquetas, comentarios planos y reportes de canales, publicaciones o comentarios. El autor del comentario y el dueño del canal pueden eliminar comentarios con confirmación.
- Imágenes con visor ampliable. PDF y enlaces se abren en una aplicación externa tras confirmar el dominio; no se incluyó un renderizador PDF incrustado. Se rechazan esquemas como `javascript:`, `file:` y `data:`.
- Panel profesional para crear/editar canales, portada, categoría y especialidades; redactar publicaciones, guardar borradores, editar/publicar y archivar. Hasta cinco adjuntos, de hasta 10 MB cada uno: JPG, PNG, WEBP, GIF, PDF o enlaces HTTP(S).
- Se preserva el texto ante fallos de guardado y se confirma el abandono de cambios locales en el editor de publicaciones. No hay autoguardado: el borrador se persiste al pulsar **Guardar borrador**.

## Privacidad y límites heredados

**Los adjuntos se sirven públicamente por el backend, incluso cuando la publicación es un borrador.** Los editores lo advierten antes de la subida. No se deben cargar historias clínicas, expedientes ni datos de pacientes. Quitar un adjunto del editor no elimina el archivo del servidor: el contrato actual no tiene endpoint de eliminación de medios.

No se reintentan automáticamente mutaciones: seguir y dar like son toggles. Ante una respuesta desconocida hay que comprobar el estado antes de repetir una creación; el backend actual no proporciona llaves de idempotencia para publicaciones o comentarios. Los formularios desactivan sus controles durante el envío.

Community es difusión psicoeducativa con comentarios de un nivel, no chat grupal, consulta privada ni canal de atención urgente.

## Verificación ejecutada

- `flutter test --no-pub`: **25/25**, incluidas **17 pruebas nuevas** de Community.
- Análisis de modelos, servicio, pantallas de Community y sus pruebas: **sin incidencias**.
- Análisis adicional de navegación y Home: sin errores; Home conserva 12 avisos preexistentes por `withOpacity`.
- Suite existente `MindEase-back/tests/community.integration.js`: **36/36** contra PostgreSQL en un esquema temporal aislado, eliminado al finalizar.
- La única dependencia directa añadida es `http_parser`, versión 4.1.2 ya presente en el lockfile, para indicar correctamente el MIME multipart.

Las pruebas Flutter usan respuestas HTTP simuladas; la suite del backend utiliza PostgreSQL real. No se realizó una sesión completa en dispositivo físico ni se verificó allí el selector nativo de archivos o la apertura externa de PDF.

## Prueba manual recomendada en emulador

1. Iniciar sesión como profesional verificado, abrir Community y crear un canal con categoría activa.
2. Guardar un borrador con texto educativo y un archivo de prueba no sensible. Volver a abrirlo, editarlo y publicarlo.
3. Como paciente, buscar el canal, seguirlo, abrir su publicación, dar/quitar like y escribir un comentario.
4. Abrir una imagen con zoom, un PDF con visor externo y enviar un reporte. Comprobar errores de conexión y sesión vencida.
5. Como dueño del canal, revisar/eliminar un comentario y archivar la publicación; verificar que deja de aparecer en el feed público.
