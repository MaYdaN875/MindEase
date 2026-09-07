# 🌿 MindEase - Plataforma Integral de Salud Mental

Bienvenido al repositorio central de **MindEase**. Este proyecto es una solución integral compuesta por tres módulos interconectados:

1. **📱 MindEase Mobile App (`/`)**: Aplicación móvil multiplataforma desarrollada en Flutter.
2. **⚙️ MindEase Backend (`/MindEase-back`)**: API REST construida con Node.js, Express, TypeScript, Prisma ORM y PostgreSQL.
3. **💻 MindEase Admin Panel (`/MindEase-Admin`)**: Panel de control administrativo y revisión clínica desarrollado en React 19, TypeScript, Vite y Tailwind CSS.

---

## 📋 Requisitos Previos

Antes de comenzar, asegúrate de tener instalado en tu equipo:

* **[Git](https://git-scm.com/)** (v2.30 o superior)
* **[Node.js](https://nodejs.org/)** (v20.x LTS o superior) y **npm** (v10+)
* **[Docker Desktop](https://www.docker.com/)** y **Docker Compose** (recomendado para la base de datos y backend)
* **[Flutter SDK](https://docs.flutter.dev/get-started/install)** (v3.19 o superior / Dart SDK ^3.12.0)
* **[Android Studio](https://developer.android.com/studio)** o **VS Code** con extensiones de Flutter/Dart (para compilar la app móvil)

---

## 📁 Estructura del Repositorio

```text
flutter_application_1/
├── lib/                     # Código fuente de la app móvil Flutter
├── android/                 # Configuración de compilación Android
├── ios/                     # Configuración de compilación iOS
├── pubspec.yaml             # Dependencias de Flutter
├── MindEase-back/           # Backend (Node.js + Express + Prisma)
│   ├── prisma/              # Esquema de base de datos PostgreSQL
│   ├── src/                 # Controladores, rutas, middlewares y servicios
│   ├── storage/             # Almacenamiento persistente de documentos privados
│   ├── Dockerfile           # Dockerfile del backend
│   └── docker-compose.yml   # Orquestación de Backend y Base de Datos PostgreSQL
└── MindEase-Admin/          # Frontend Administrativo (React + Vite)
    ├── src/                 # Vistas, componentes y servicios de conexión
    ├── package.json         # Dependencias del Admin
    └── vite.config.ts       # Configuración de empaquetado Vite
```

---

## 🚀 Guía de Instalación y Compilación Paso a Paso

### 1️⃣ Paso 1: Levantar el Backend y la Base de Datos (`MindEase-back`)

El backend expone la API REST en `http://localhost:3000` y gestiona la base de datos PostgreSQL en el puerto `5432`.

#### Opción A: Ejecución con Docker Compose (Recomendada)
1. Abre una terminal y navega a la carpeta del backend:
   ```bash
   cd MindEase-back
   ```
2. Construye e inicia los contenedores (PostgreSQL + Node.js):
   ```bash
   docker compose up -d --build
   ```
3. Verifica que los contenedores estén corriendo:
   ```bash
   docker ps
   ```
   * Contenedor DB: `mindease-db` (Puerto 5432)
   - Contenedor App: `mindease-app` (Puerto 3000)

#### Opción B: Ejecución Local sin Docker
1. Asegúrate de tener una instancia de PostgreSQL corriendo localmente.
2. Navega a `MindEase-back`:
   ```bash
   cd MindEase-back
   npm install
   ```
3. Crea un archivo `.env` en `MindEase-back/`:
   ```env
   PORT=3000
   DATABASE_URL="postgresql://postgres:postgres@localhost:5432/mindease?schema=public"
   JWT_SECRET="super-secret-mindease-jwt-key-change-in-production"
   JWT_EXPIRES_IN="7d"
   ```
4. Genera el cliente de Prisma y aplica los esquemas:
   ```bash
   npx prisma generate
   npx prisma db push
   ```
5. Compila e inicia el servidor en modo desarrollo:
   ```bash
   # Modo desarrollo (recarga en caliente)
   npm run dev

   # O compilar para producción
   npm run build
   npm start
   ```

---

### 2️⃣ Paso 2: Compilar y Ejecutar el Panel Administrativo (`MindEase-Admin`)

El panel administrativo web se conecta al backend para gestionar usuarios, validar documentos clínicos, revisar expedientes y descargar reportes forenses.

1. Abre una nueva terminal y navega a la carpeta del panel:
   ```bash
   cd MindEase-Admin
   ```
2. Instala las dependencias:
   ```bash
   npm install
   ```
3. Ejecuta el servidor de desarrollo local:
   ```bash
   npm run dev
   ```
   * Accede desde tu navegador en: **[http://localhost:5173](http://localhost:5173)**

4. Para compilar el bundle optimizado para producción:
   ```bash
   npm run build
   ```
   * Los archivos estáticos compilados se generarán en la carpeta `MindEase-Admin/dist/`.
   * Puedes probar la versión compilada localmente con:
     ```bash
     npm run preview
     ```

---

### 3️⃣ Paso 3: Compilar y Ejecutar la App Móvil (`flutter_application_1`)

La aplicación móvil de Flutter permite el registro, inicio de sesión, carga de expedientes y consulta de sesiones de pacientes y psicólogos.

1. Abre una nueva terminal en la raíz del proyecto:
   ```bash
   cd flutter_application_1
   ```
2. Descarga y sincroniza las dependencias de Flutter:
   ```bash
   flutter pub get
   ```
3. Verifica que tu entorno esté listo:
   ```bash
   flutter doctor
   ```

#### Ejecución en Modo Desarrollo (Debug)
* Para ejecutar en un emulador Android / iOS o navegador Web:
  ```bash
  # Ver dispositivos disponibles
  flutter devices

  # Ejecutar en el dispositivo activo
  flutter run

  # O ejecutar específicamente en Chrome / Windows
  flutter run -d chrome
  flutter run -d windows
  ```

#### Compilación para Producción (Release Builds)
* **Android (APK instalable):**
  ```bash
  flutter build apk --release
  ```
  *(El archivo `.apk` se ubicará en `build/app/outputs/flutter-apk/app-release.apk`)*

* **Android (App Bundle para Google Play Store):**
  ```bash
  flutter build appbundle --release
  ```

* **Web (Archivos estáticos HTML/JS/Wasm):**
  ```bash
  flutter build web --release
  ```

* **Windows Desktop:**
  ```bash
  flutter build windows --release
  ```

* **iOS (Requiere macOS con Xcode):**
  ```bash
  flutter build ipa --release
  ```

---

## 🔐 Cuentas y Accesos por Defecto

Al inicializar la base de datos, puedes crear o utilizar usuarios administradores con roles `ADMIN` y `SUPERADMIN` para acceder a todas las funciones del panel web en `http://localhost:5173`.

---

## 🛠️ Comandos de Mantenimiento y Utilidades

| Componente | Comando | Descripción |
| :--- | :--- | :--- |
| **Backend** | `npm run prisma:studio` | Abre la interfaz visual de base de datos de Prisma en `http://localhost:5555`. |
| **Backend** | `npx tsc --noEmit` | Valida errores de tipos TypeScript en el backend sin compilar. |
| **Backend** | `docker compose logs -f app` | Muestra los registros y logs en vivo del backend en Docker. |
| **Admin Web** | `npm run build` | Compila y valida el tipado de React con Vite y TypeScript. |
| **Admin Web** | `npm run lint` | Ejecuta ESLint para validar buenas prácticas de código. |
| **Flutter App** | `flutter clean` | Limpia los archivos temporales de compilación y caché de Flutter. |
| **Flutter App** | `flutter analyze` | Analiza el código Dart en busca de advertencias y lints. |

---

## ❓ Preguntas Frecuentes y Resolución de Problemas

#### 1. ¿Cómo conectar la App de Flutter al Backend local en Android?
* Si estás usando el **Emulador Oficial de Android Studio**, recuerda que `localhost` dentro del emulador apunta a su propio sistema. Debes configurar la URL base de la API hacia:
  * `http://10.0.2.2:3000/api`
* Si estás probando en un **Dispositivo Físico vía Wi-Fi**, utiliza la IP local de tu computadora (ej. `http://192.168.1.XX:3000/api`).

#### 2. Error al descargar documentos o subir archivos
* Los archivos PDF y credenciales subidos se almacenan en el volumen persistente `MindEase-back/storage/private_documents`.
* Si usas Docker, el volumen `./storage:/usr/src/app/storage` asegura que tus archivos se mantengan intactos incluso tras reiniciar los contenedores.

#### 3. Error de conexión con PostgreSQL
* Si el contenedor `mindease-app` indica problemas de conexión, verifica que el contenedor `mindease-db` esté en estado `healthy` ejecutando `docker ps`.

---

## 📄 Licencia

Este proyecto está bajo la licencia privada de **MindEase**. Todos los derechos reservados.
