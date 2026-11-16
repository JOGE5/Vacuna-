# VacunaPlus: prueba de autenticación con Supabase (rama feature/supabase-auth-google)

Esta rama no cambia `main`. Sustituye el inicio de sesión de demostración al ejecutar `lib/main.dart`, mantiene la autenticación local en las pruebas existentes y agrega el inicio de Google mediante OAuth.

## Configuración necesaria fuera de GitHub

1. En Supabase: **Authentication → Sign In / Providers → Google**, habilitar Google e introducir el **Client ID** y **Client Secret** creados en Google Cloud. No subir nunca el Client Secret al repositorio.
2. En Google Cloud: crear un cliente OAuth de tipo **Web application**. Incluir en **Authorized redirect URIs**:
   `https://eupodocpqoedinvpdgxk.supabase.co/auth/v1/callback`
3. En Supabase: **Authentication → URL Configuration → Redirect URLs**, agregar para desarrollo:
   `http://localhost:41287/**`
4. Para iniciar Chrome con un puerto fijo, en `app/` ejecutar:
   ```bash
   flutter pub get
   flutter run -d chrome --web-port 41287
   ```
5. Iniciar sesión con Google. El navegador debe volver a VacunaPlus y abrir la vista ciudadana. La sesión se restaura al recargar la página.

## Acceso del personal

Para acceder con correo y contraseña, el usuario debe existir en Supabase Auth y tener una fila activa en `public.perfiles` con el mismo UUID de `auth.users` y rol `Administrador` o `Personal de salud`. Los usuarios sin perfil tienen acceso ciudadano, nunca administrativo.

## Limitaciones actuales

- Los módulos de campañas, pacientes e inventario siguen utilizando listas locales. Esta rama solo implementa el sistema de autenticación.
- OAuth en Android/iOS requiere añadir los esquemas de retorno/deep linking y registrar los clientes móviles de Google.
- No se han ejecutado pruebas de Flutter en el entorno de ChatGPT; verificar `flutter analyze`, `flutter test` y el flujo OAuth en Chrome.
