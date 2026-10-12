# VacunaPlus — Interfaces Flutter

Entrega basada en las 15 pantallas del PDF de referencia. Cada pantalla tiene su propio archivo Dart. `main.dart` solo inicia la aplicación; `app.dart` configura tema y rutas. Incluye un menú adicional «Más» para acceder a las secciones administrativas.

## Ejecutar

Requiere Flutter 3.35.4 o posterior con Dart compatible (comprobado con Dart 3.9.2).

```bash
cd app
flutter pub get
flutter run -d chrome
```

Para Android, inicia un emulador o conecta un dispositivo y ejecuta `flutter run`. La compilación comprobada en esta entrega es web; no se generó un APK.

Acceso de demostración: `ana@example.com` / `123456`. Cualquier correo con formato válido y contraseña de seis o más caracteres permite entrar. No se autentican credenciales contra un servidor.

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

La barra inferior abre Inicio, Campañas, Pacientes y Más. El menú Más conecta Inventario, Centros, Reportes, Usuarios y Perfil. Los botones «Ver detalle» seleccionan una campaña; «Editar campaña» reutiliza un formulario compartido con datos precargados. Desde Pacientes, «Ver historial» y «Registrar vacunación» conservan el paciente seleccionado. Las flechas regresan con `Navigator.pop`; la barra inferior cambia la sección principal y limpia la pila. Entrar y cerrar sesión también limpian la pila.

`widgets/` contiene tarjetas, botones, búsquedas, pestañas, campos, selector de fechas, gráficos, diálogo de edición y formulario de campaña compartido. `core/` contiene el tema, los validadores y el estado observable. `models/` contiene las entidades.

## Validaciones

| Formulario | Reglas |
| --- | --- |
| Inicio de sesión | Correo con formato válido; contraseña de al menos seis caracteres. Botón para mostrar/ocultar contraseña. |
| Crear/editar campaña | Nombre y descripción obligatorios; nombre único; vacuna, población, centro y responsable obligatorios; fechas requeridas; fecha final igual o posterior a la inicial; meta entera positiva y nunca inferior a las dosis ya aplicadas. |
| Nuevo paciente | Nombre, apellido, documento, nacimiento y sexo obligatorios; documento de 5–25 caracteres y no duplicado; nacimiento sin fechas futuras; teléfono opcional con formato básico. |
| Registrar vacunación | Selección de campaña, vacuna, dosis, centro y responsable; lote obligatorio y existente para esa vacuna y centro; disponibilidad positiva; lote no vencido en la fecha indicada; fecha de aplicación requerida sin fechas futuras; próxima cita opcional, posterior a la aplicación. |
| Usuarios / perfil | Nombre requerido; correo válido y único. |
| Entrada de inventario | Lote y cantidad obligatorios; entero positivo; lote existente. |
| Añadir centro | Nombre, dirección y horario obligatorios. |

Los errores se muestran debajo del campo; no se guarda el formulario inválido. Al guardar se actualizan las listas en memoria y se muestra una confirmación. Registrar una vacunación añade un elemento al historial, descuenta una dosis del lote, incrementa las dosis de la campaña y registra un movimiento.

## Prueba manual breve

1. Pulsa Ingresar sin datos: aparecen errores. Ingresa con los datos de demostración.
2. Abre Campañas → Crear campaña; verifica que una fecha final anterior al inicio y una meta de cero impidan guardar. Completa y guarda una campaña válida: aparece en la lista.
3. Abre Pacientes → Nuevo paciente; usa `CI 6842917`: se rechaza por duplicado. Usa un documento distinto, completa los campos y guarda.
4. Desde ese paciente registra una aplicación con vacuna «Influenza estacional», lote `INF-2601` y centro «Centro San Martín». Selecciona una campaña, dosis y responsable; usa una fecha de aplicación no futura y anterior al vencimiento del lote.
5. Consulta su historial y revisa la cantidad del lote en Inventario → Movimientos.
6. Usa búsquedas y filtros, edita una campaña, crea un usuario y cambia el interruptor de notificaciones.

## Capturas y comprobaciones

`capturas/` incluye 17 PNG: las 15 pantallas, el menú Más y un formulario con errores. Son renders del código Flutter ejecutado con el motor de pruebas de widgets, no imágenes copiadas del PDF ni capturas de un emulador Android. Las alturas varían para mostrar los formularios completos.

```bash
cd app
flutter analyze
flutter test
flutter build web
```

Se verificaron 23 pruebas, incluida la presentación de las 16 rutas con un ancho móvil de 390 px, correo/contraseña/documento/teléfono/cantidades, navegación, búsqueda, rechazo de documento duplicado y actualización del inventario. El analizador terminó sin incidencias y la compilación web pasó. `test/screenshots_test.dart` regenera las capturas; necesita `FLUTTER_ROOT` apuntando al SDK para cargar la fuente de iconos en el motor de pruebas.

## Alcance y fidelidad visual

Se conservan la paleta verde y blanca, los textos principales, las tarjetas, las secciones y las ilustraciones de equipo médico y vacuna extraídas del PDF suministrado. Las interfaces se construyen con widgets Material editables, no como una imagen de pantalla con zonas pulsables.

La entrega es una adaptación funcional; **no es una réplica idéntica píxel por píxel**. Los iconos Material, tipografía, tamaños, espaciado y adaptación al ancho tienen diferencias respecto a los mockups rasterizados. Los formularios de creación empiezan vacíos. El botón de historial «Ver comprobante» muestra el texto en un diálogo; «Compartir» lo copia al portapapeles. No se implementó descarga de un comprobante como archivo.

Los datos son ficticios y duran hasta recargar/cerrar la aplicación. No hay base de datos, autenticación real, recuperación de contraseña por correo, cambio de contraseña real, mapa geográfico ni geolocalización. La opción Mapa muestra direcciones y explica su alcance. Los reportes iniciales reproducen las cifras de la referencia; al filtrar consultan solamente los registros disponibles en memoria. Los enlaces de soporte, privacidad e idioma abren información local.

El proyecto Next.js del adjunto no se utiliza: esta entrega implementa las interfaces Flutter solicitadas sin depender de un servidor. La fuente Roboto conserva su licencia en `app/assets/fonts/Roboto_LICENSE.txt`.
