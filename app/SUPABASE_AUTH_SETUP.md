# VacunaPlus: autenticación con Supabase

`lib/main.dart` usa Supabase Auth de forma predeterminada. Las cuentas locales de demostración solo están disponibles con `--dart-define=VACUNAPLUS_DEMO=true`.

## Configuración necesaria fuera de GitHub

1. En Supabase: **Authentication → Sign In / Providers → Google**, habilitar Google e introducir el **Client ID** y **Client Secret** creados en Google Cloud. No subir nunca el Client Secret al repositorio.
2. En Google Cloud: crear un cliente OAuth de tipo **Web application**. Incluir en **Authorized redirect URIs**:
   `https://eupodocpqoedinvpdgxk.supabase.co/auth/v1/callback`
3. En Supabase: **Authentication → URL Configuration → Redirect URLs**, agregar para desarrollo el mismo origen y puerto que se abre en Brave:
   `http://localhost:41287/**`
4. Para iniciar el servidor web con un puerto fijo, en `app/` ejecutar:
   ```bash
   flutter pub get
   flutter run -d web-server --web-hostname localhost --web-port 41287
   ```
   Abrir `http://localhost:41287` en Brave. Si se usa `127.0.0.1` u otro puerto, registrar también ese origen en Redirect URLs.
5. Iniciar sesión con Google. El navegador debe volver a VacunaPlus y abrir la vista ciudadana. La sesión se restaura al recargar la página.

Para probar la maqueta con las cuentas locales, ejecutar `flutter run -d web-server --web-hostname localhost --web-port 41287 --dart-define=VACUNAPLUS_DEMO=true` y abrir el mismo URL en Brave.

## Acceso del personal

Para acceder con correo y contraseña, el usuario debe existir en Supabase Auth y tener una fila activa en `public.perfiles` con el mismo UUID de `auth.users` y rol `Administrador` o `Personal de salud`. Los usuarios sin perfil tienen acceso ciudadano, nunca administrativo.

## Limitaciones actuales

- Los módulos de campañas, pacientes e inventario siguen utilizando listas locales. Esta rama solo implementa el sistema de autenticación.
- OAuth en Android/iOS requiere añadir los esquemas de retorno/deep linking y registrar los clientes móviles de Google.
- `flutter analyze`, 30 pruebas funcionales, 18 pruebas de capturas y `flutter build web --release` se verificaron en la integración local. El flujo OAuth requiere la configuración externa indicada arriba y una prueba manual en Brave.
