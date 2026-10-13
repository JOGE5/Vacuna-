# VacunaPlus — Interfaces Flutter

Entrega basada en las 15 pantallas del PDF de referencia. Cada pantalla tiene su propio archivo Dart. `main.dart` solo inicia la aplicación; `app.dart` configura tema y rutas. Incluye un menú adicional «Más» para acceder a las secciones administrativas.

## Ejecutar

Requiere Flutter 3.44 o posterior (comprobado con Flutter 3.44.9 y Dart 3.12.2). Los paquetes del mapa (`flutter_map`, `url_launcher`) no funcionan con versiones anteriores: si `flutter pub get` falla, ejecuta `flutter upgrade`.

```bash
cd app
flutter pub get
flutter run -d chrome
```

Para Android, inicia un emulador o conecta un dispositivo y ejecuta `flutter run`. Se comprobaron la compilación web y un APK de depuración (`flutter build apk --debug`). En el teléfono la app se llama «VacunaPlus» (`com.vacunaplus.app`).

Credenciales de demostración (locales, sin base de datos):

| Correo | Contraseña | Rol |
| --- | --- | --- |
| `ana.torres@example.com` | `salud123` | Personal de salud |
| `carlos.rojas@example.com` | `admin123` | Administrador |
| `elena.vargas@example.com` | `salud123` | Personal de salud (inactivo: se rechaza) |

Otro correo o contraseña muestra «Correo o contraseña incorrectos». Inicio y Perfil muestran al usuario que inició sesión; «Cerrar sesión» la termina.

Sin cuenta del personal, «Entrar como invitado» abre la vista ciudadana. «Continuar con Google» avisa que se activa al conectar Supabase.

### Autenticación y Supabase

Las credenciales están en `LocalAuthService` (`app/lib/core/auth_service.dart`), que implementa la interfaz `AuthService` (`signIn`, `signInWithGoogle` y `signOut`). Para conectar Supabase se crea otra implementación de `AuthService` que devuelva un `AppUser` (con el `id` del usuario de Supabase) o lance `AuthException` con el mensaje a mostrar, y se pasa en `app/lib/app.dart`: `AppStore(auth: SupabaseAuthService())`. Las pantallas no cambian. `AppStore.signIn` rechaza además a los usuarios marcados como inactivos en Gestión de usuarios.

## Organización y navegación

| N.º | Pantalla / archivo en `app/lib/screens/` | Ruta |
| --- | --- | --- |
| 01 | `login_screen.dart` | `/` |
| 02 | `dashboard_screen.dart` | `/home` |
| 03 | `campaign_list_screen.dart` | `/campaigns` |
| 04 | `create_campaign_screen.dart` | `/campaign/new` |
| 05 | `campaign_detail_screen.dart` | `/campaign/detail` |
| 06 | `edit_campaign_screen.dart` | `/campaign/edit` |
| 07 | `patient_registration_screen.dart` | `/patient/new` |
| 08 | `patient_list_screen.dart` | `/patients` |
| 09 | `vaccination_registration_screen.dart` | `/vaccination` |
| 10 | `vaccination_history_screen.dart` | `/history` |
| 11 | `inventory_screen.dart` | `/inventory` |
| 12 | `centers_screen.dart` | `/centers` |
| 13 | `reports_screen.dart` | `/reports` |
| 14 | `users_screen.dart` | `/users` |
| 15 | `profile_screen.dart` | `/profile` |
| + | `more_screen.dart` | `/more` |
| + | `citizen_home_screen.dart` (vista ciudadana) | `/explorar` |

La barra inferior abre Inicio, Campañas, Pacientes y Más. El menú Más conecta Inventario, Centros, Reportes, Usuarios y Perfil. Los botones «Ver detalle» seleccionan una campaña; «Editar campaña» reutiliza un formulario compartido con datos precargados. Desde Pacientes, «Ver historial» y «Registrar vacunación» conservan el paciente seleccionado. Las flechas regresan con `Navigator.pop`; la barra inferior cambia la sección principal y limpia la pila. Entrar y cerrar sesión también limpian la pila. Debajo del inicio de sesión, «¿Buscas dónde vacunarte?» lleva a la vista ciudadana, que no tiene acceso a las pantallas del personal.

`widgets/` contiene tarjetas, botones, búsquedas, pestañas, campos, selector de fechas, gráficos, diálogo de edición, formulario de campaña compartido y el mapa (`centers_map.dart`). `core/` contiene el tema, los validadores, la autenticación y el estado observable. `models/` contiene las entidades.

## Vista ciudadana y mapa

La vista ciudadana (`/explorar`) muestra dónde vacunarse: un mapa con los puntos de vacunación (verde abierto, gris cerrado), filtros por vacuna disponible, campañas vigentes y la lista de centros. Al tocar un marcador, una campaña o un centro se abre su ficha con horario, campañas, vacunas disponibles y «Cómo llegar», que abre la ruta en Google Maps (los enlaces de Google Maps no necesitan clave de API). En el personal, Centros → Mapa muestra lo mismo y «Añadir centro» pide marcar la ubicación en el mapa.

El mapa usa OpenStreetMap con `flutter_map`, igual que La Selva (allí con Leaflet). Cada centro necesita latitud y longitud (`lat`, `lng`); los tres de ejemplo tienen coordenadas aproximadas en La Paz.

**Sin internet:** centros y campañas siempre se ven y los marcadores se dibujan igual. En Android, las zonas del mapa ya vistas se guardan en el teléfono y siguen vigentes 30 días; cuando una zona no carga, aparece «Sin conexión» debajo del mapa. En el navegador depende de la caché del navegador.

**Condiciones de OpenStreetMap:** sus servidores son donados y aptos para uso ligero (proyecto y presentación). La app se identifica con `mapUserAgent` en `centers_map.dart`, que debe coincidir con `applicationId` en `android/app/build.gradle.kts`, y muestra «© OpenStreetMap contributors». Para uso real con muchos usuarios, cambia de proveedor sin tocar código: `flutter run --dart-define=MAP_TILE_URL=https://…/{z}/{x}/{y}.png` (MapTiler, Stadia, OpenFreeMap u otro).

## Base de datos local (Supabase)

`supabase/` contiene la base de datos para correr en este equipo con Docker: PostgreSQL con la API y el inicio de sesión de Supabase. Las mismas migraciones sirven luego para un proyecto de Supabase en la nube (`npx supabase db push`).

```bash
npx supabase start      # primera vez: descarga imágenes, crea tablas y carga datos de ejemplo
npx supabase status     # URL de la API y claves
npx supabase db reset   # vuelve a crear las tablas y los datos de ejemplo
npx supabase stop
```

- Panel (Studio): http://127.0.0.1:54323 · API: http://127.0.0.1:54321 · PostgreSQL: `postgresql://postgres:postgres@127.0.0.1:54322/postgres`.
- Esquema en `supabase/migrations/`; datos de ejemplo (los mismos de la app) en `supabase/seed.sql`.
- Tablas: `vacunas` (catálogo común de campañas y lotes), `centros` (con `lat` y `lng` para el mapa), `campanas`, `pacientes`, `lotes`, `vacunaciones`, `movimientos` y `perfiles` (personal y ciudadanos, ligados a Supabase Auth).
- Las cuentas del personal tienen las mismas credenciales del inicio de sesión de la app. Toda cuenta nueva (por ejemplo, un ciudadano con Google) se crea como «Ciudadano»; solo un administrador cambia roles o desactiva cuentas.
- Seguridad por filas: invitados y ciudadanos leen centros, campañas y vacunas; pacientes, vacunaciones, lotes y movimientos son solo del personal activo.
- Funciones: `registrar_vacunacion` valida y registra una aplicación en un paso (lote con dosis y sin vencer, vacuna del lote igual a la de la campaña, campaña no finalizada; descuenta la dosis, suma a la campaña y deja el movimiento); `registrar_entrada` suma dosis a un lote; `vacunas_disponibles` da, sin cantidades, qué vacunas hay en cada centro para la vista ciudadana.

**Para conectar la app** (paquete `supabase_flutter`): usar la URL de la API (en el emulador de Android `http://10.0.2.2:54321`; en un teléfono real, la IP del equipo en la red local) y la clave pública de `npx supabase status`. `SupabaseAuthService` debe leer el perfil para conocer el rol y rechazar cuentas inactivas, como hace hoy `AppStore.signIn`. Google se activa en `supabase/config.toml` (`[auth.external.google]`) con las credenciales de Google Cloud en variables de entorno. Para seguir viendo datos sin internet, conviene guardar en el teléfono la última copia de centros y campañas.

## Validaciones

| Formulario | Reglas |
| --- | --- |
| Inicio de sesión | Correo con formato válido; contraseña de al menos seis caracteres; credenciales registradas y usuario activo. Botón para mostrar/ocultar contraseña. |
| Crear/editar campaña | Nombre y descripción obligatorios; nombre único; vacuna, población, centro y responsable obligatorios; fechas requeridas; fecha final igual o posterior a la inicial; meta entera positiva y nunca inferior a las dosis ya aplicadas. |
| Nuevo paciente | Nombre, apellido, documento, nacimiento y sexo obligatorios; documento de 5–25 caracteres y no duplicado; nacimiento sin fechas futuras; teléfono opcional con formato básico. |
| Registrar vacunación | Selección de campaña, vacuna, dosis, centro y responsable; lote obligatorio y existente para esa vacuna y centro; disponibilidad positiva; lote no vencido en la fecha indicada; fecha de aplicación requerida sin fechas futuras; próxima cita opcional, posterior a la aplicación. |
| Usuarios / perfil | Nombre requerido; correo válido y único. |
| Entrada de inventario | Lote y cantidad obligatorios; entero positivo; lote existente. |
| Añadir centro | Nombre, dirección y horario obligatorios; ubicación marcada en el mapa. |

Los errores se muestran debajo del campo; no se guarda el formulario inválido. Al guardar se actualizan las listas en memoria y se muestra una confirmación. Registrar una vacunación añade un elemento al historial, descuenta una dosis del lote, incrementa las dosis de la campaña y registra un movimiento.

## Prueba manual breve

1. Pulsa Ingresar sin datos: aparecen errores. Prueba una contraseña incorrecta: se rechaza. Ingresa con `ana.torres@example.com` / `salud123`.
2. Abre Campañas → Crear campaña; verifica que una fecha final anterior al inicio y una meta de cero impidan guardar. Completa y guarda una campaña válida: aparece en la lista.
3. Abre Pacientes → Nuevo paciente; usa `CI 6842917`: se rechaza por duplicado. Usa un documento distinto, completa los campos y guarda.
4. Desde ese paciente registra una aplicación con vacuna «Influenza estacional», lote `INF-2601` y centro «Centro San Martín». Selecciona una campaña, dosis y responsable; usa una fecha de aplicación no futura y anterior al vencimiento del lote.
5. Consulta su historial y revisa la cantidad del lote en Inventario → Movimientos.
6. Usa búsquedas y filtros, edita una campaña, crea un usuario y cambia el interruptor de notificaciones.
7. Cierra sesión y pulsa «Entrar como invitado»: filtra por vacuna, toca un marcador y prueba «Cómo llegar». Con el modo avión activado, los centros y campañas siguen visibles.

## Capturas y comprobaciones

`capturas/` incluye 17 PNG: las 15 pantallas, el menú Más y un formulario con errores. No incluyen la vista ciudadana ni el mapa: el motor de pruebas no tiene internet para cargar los mosaicos. Son renders del código Flutter ejecutado con el motor de pruebas de widgets, no imágenes copiadas del PDF ni capturas de un emulador Android. Las alturas varían para mostrar los formularios completos.

```bash
cd app
flutter analyze
flutter test
flutter build web
```

Se verificaron 30 pruebas (13 en `app_test.dart` y 17 de capturas), incluida la presentación de las 17 rutas con un ancho móvil de 390 px, credenciales, navegación, búsqueda, documento duplicado, inventario, la vista ciudadana sin internet, el alta de un centro con ubicación y la ruta de «Cómo llegar». El analizador terminó sin incidencias y la compilación web pasó. `test/screenshots_test.dart` regenera las capturas; necesita `FLUTTER_ROOT` apuntando al SDK para cargar la fuente de iconos en el motor de pruebas.

## Alcance y fidelidad visual

Se conservan la paleta verde y blanca, los textos principales, las tarjetas, las secciones y las ilustraciones de equipo médico y vacuna extraídas del PDF suministrado. Las interfaces se construyen con widgets Material editables, no como una imagen de pantalla con zonas pulsables.

La entrega es una adaptación funcional; **no es una réplica idéntica píxel por píxel**. Los iconos Material, tipografía, tamaños, espaciado y adaptación al ancho tienen diferencias respecto a los mockups rasterizados. Los formularios de creación empiezan vacíos. El botón de historial «Ver comprobante» muestra el texto en un diálogo; «Compartir» lo copia al portapapeles. No se implementó descarga de un comprobante como archivo.

Los datos de la app son ficticios y duran hasta recargar/cerrar la aplicación: la base local de `supabase/` está lista, pero la app todavía no se conecta a ella. No hay recuperación de contraseña por correo, cambio de contraseña real ni geolocalización del usuario. El mapa necesita internet la primera vez que se abre cada zona. Los reportes iniciales reproducen las cifras de la referencia; al filtrar consultan solamente los registros disponibles en memoria. Los enlaces de soporte, privacidad e idioma abren información local.

El proyecto Next.js del adjunto no se utiliza: esta entrega implementa las interfaces Flutter solicitadas sin depender de un servidor. La fuente Roboto conserva su licencia en `app/assets/fonts/Roboto_LICENSE.txt`.
