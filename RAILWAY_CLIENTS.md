# Clientes conectados a Railway

Flutter usa por defecto https://mindease-backend-production-3a83.up.railway.app.
AuthService centraliza esta URL para los servicios existentes. No incluye /api porque cada servicio agrega su ruta.

Ejecutar contra Railway: `flutter run`.
Desarrollo local Android: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000`.
Desarrollo local escritorio/web: `flutter run --dart-define=API_BASE_URL=http://localhost:3000`.
Hay que reconstruir/reiniciar la app al cambiar el define. Las sesiones se almacenan por servidor; iniciar sesión nuevamente tras este cambio. No se incluyen claves privadas en la app.

## Panel administrativo en Railway

El repositorio configurado del panel es MindEase-AdminPanel. Los cambios deben subirse a ese repositorio antes de desplegar. No se realizó push automático.

Crear un servicio independiente desde ese repositorio, sin sustituir el backend o PostgreSQL:

- Root Directory: / (cuando el repositorio contiene directamente package.json y Dockerfile.railway).
- Variable RAILWAY_DOCKERFILE_PATH: Dockerfile.railway.
- Variable PORT: 8080.
- Variable VITE_API_URL: https://mindease-backend-production-3a83.up.railway.app/api.
- Healthcheck Path: /health.
- Sin Start Command personalizado: usar el comando de nginx de la imagen.
- Generar dominio público con puerto destino 8080.

VITE_API_URL es pública y se incorpora durante la compilación; cambiarla requiere reconstruir. No poner DATABASE_URL, JWT_SECRET, claves Stripe privadas o claves JaaS en el panel.

La imagen Railway sirve la SPA y llama directamente al backend HTTPS. El Dockerfile/nginx original permanece para Docker Compose local con proxy app:3000. El backend actual permite CORS para estos clientes; revisar una lista de orígenes permitidos cuando exista el dominio definitivo del panel.

## Validaciones y límites

Tres pruebas de configuración Flutter; imagen Docker Railway compilada. Validar login con una cuenta autorizada y un flujo real de lectura después de publicar. No se han realizado cobros ni modificado la base remota.

Pendientes separados: traslado de archivos persistentes, rotación de la contraseña PostgreSQL expuesta y autenticación obligatoria de JaaS antes de habilitar consultas. No se implementa videollamada en este cambio.
