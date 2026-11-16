# VacunaPlus — autenticación móvil Android con Supabase

Cambios exclusivos de la rama `feature/supabase-auth-google`. No fusionar con `main` hasta probarlos.

## 1. Configurar Google y Supabase

1. Abrir Google Cloud Console → Google Auth Platform → Clients. Crear credenciales OAuth para **Web application**. En los URI de redirección autorizados agregar exactamente:
   `https://eupodocpqoedinvpdgxk.supabase.co/auth/v1/callback`
2. Para publicar Android, configurar también un cliente OAuth **Android** para `com.vacunaplus.app` y las huellas digitales SHA-1 correspondientes a las claves de firma de depuración y producción, según el método de Google Sign-In utilizado. El flujo actual de la app es OAuth a través del navegador externo.
3. En Supabase → Authentication → Providers → Google, habilitar Google e introducir el **Web Client ID** y **Client Secret** obtenidos en Google Cloud. No guardar secretos en GitHub ni en Flutter.
4. En Supabase → Authentication → URL Configuration → Additional Redirect URLs agregar exactamente:
   `io.supabase.vacunaplus://login-callback/`

El código en `lib/core/supabase_auth_service.dart` usa esa URL para abrir VacunaPlus después del navegador. El `AndroidManifest.xml` de esta rama tiene el filtro para el esquema `io.supabase.vacunaplus` y el host `login-callback`.

## 2. Ejecutar en Android (no Chrome)

En la carpeta `app`:

```bash
git fetch origin
git switch feature/supabase-auth-google
git pull origin feature/supabase-auth-google
flutter pub get
flutter devices
flutter run -d <ID_DEL_DISPOSITIVO_ANDROID>
```

Si `flutter devices` muestra un solo dispositivo Android, puede bastar `flutter run`. Se requiere un dispositivo real con depuración USB o un emulador Android configurado.

## 3. Comportamiento esperado

Al pulsar **Continuar con Google**, se abre el navegador para autenticarse. Tras aceptar, Supabase vuelve a la URL personalizada y Android abre VacunaPlus; la aplicación restaura la sesión y muestra la vista ciudadana. Si no hay fila en `public.perfiles`, el usuario sigue siendo ciudadano: nunca se asigna automáticamente el rol Administrador.

El inicio de personal por correo/contraseña exige un usuario de Supabase Auth con un perfil activo y rol `Administrador` o `Personal de salud`.

## 4. Pendiente

- Configurar y habilitar el proveedor Google en Supabase: es obligatorio para evitar `Unsupported provider: provider is not enabled`.
- Probar en un Android real o emulador y ejecutar `flutter analyze` y `flutter test` localmente. Estos comandos no se han ejecutado en este entorno.
- Conectar campañas, pacientes, inventario y vacunaciones con consultas reales; siguen siendo datos de demostración.
- Si se requiere iOS, agregar también el esquema a Info.plist y preparar su configuración OAuth.
