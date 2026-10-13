-- Datos de demostración: los mismos de app/lib/core/app_store.dart. Se cargan
-- con `npx supabase db reset` (o al primer `npx supabase start`).

-- Cuentas del personal con las credenciales locales de la app
-- (app/lib/core/auth_service.dart). El trigger al_crear_usuario crea su perfil.
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change, email_change_token_new,
  email_change_token_current, phone_change, phone_change_token,
  reauthentication_token
)
select
  '00000000-0000-0000-0000-000000000000', u.id::uuid, 'authenticated',
  'authenticated', u.correo, extensions.crypt(u.clave, extensions.gen_salt('bf')),
  now(), '{"provider":"email","providers":["email"]}',
  jsonb_build_object('nombre', u.nombre), now(), now(),
  '', '', '', '', '', '', '', ''
from (values
  ('11111111-1111-4111-8111-111111111111', 'ana.torres@example.com', 'salud123', 'Ana Torres'),
  ('22222222-2222-4222-8222-222222222222', 'carlos.rojas@example.com', 'admin123', 'Carlos Rojas'),
  ('33333333-3333-4333-8333-333333333333', 'elena.vargas@example.com', 'salud123', 'Elena Vargas')
) as u(id, correo, clave, nombre);

insert into auth.identities (
  provider_id, user_id, identity_data, provider, last_sign_in_at, created_at,
  updated_at
)
select
  id::text, id,
  jsonb_build_object('sub', id::text, 'email', email, 'email_verified', true),
  'email', now(), now(), now()
from auth.users
where id in (
  '11111111-1111-4111-8111-111111111111',
  '22222222-2222-4222-8222-222222222222',
  '33333333-3333-4333-8333-333333333333'
);

update public.perfiles set rol = 'Personal de salud'
where id = '11111111-1111-4111-8111-111111111111';
update public.perfiles set rol = 'Administrador'
where id = '22222222-2222-4222-8222-222222222222';
update public.perfiles set rol = 'Personal de salud', activo = false
where id = '33333333-3333-4333-8333-333333333333';

insert into public.vacunas (nombre) values
  ('Influenza estacional'), ('COVID-19'), ('SRP'), ('Hepatitis B');

-- Coordenadas aproximadas en La Paz.
insert into public.centros (nombre, direccion, horario, abierto, lat, lng) values
  ('Centro San Martín', 'Av. Arce 1250, La Paz', 'Lun–Vie · 08:00–17:00', true, -16.5095, -68.1255),
  ('Centro Norte', 'Av. Busch 740, La Paz', 'Lun–Sáb · 09:00–16:00', true, -16.4960, -68.1195),
  ('Centro Sur', 'Calle 21 de Calacoto 88, La Paz', 'Lun–Vie · 08:00–15:00', false, -16.5415, -68.0775);

insert into public.campanas (
  nombre, descripcion, vacuna_id, poblacion_objetivo, centro_id,
  responsable_id, estado, fecha_inicio, fecha_fin, meta, aplicadas
)
select c.nombre, c.descripcion, v.id, c.poblacion, ce.id,
  '11111111-1111-4111-8111-111111111111', c.estado, c.inicio::date,
  c.fin::date, c.meta, c.aplicadas
from (values
  ('Campaña Influenza 2026', 'Protección para personas mayores durante la temporada 2026',
   'Influenza estacional', 'Personas mayores de 60 años', 'Centro San Martín',
   'Activa', '2026-10-06', '2026-10-30', 800, 486),
  ('Refuerzo infantil', '', 'SRP', 'Niñas y niños de 1 a 5 años', 'Centro Norte',
   'Próxima', '2026-10-18', '2026-10-25', 320, 0),
  ('Semana de la Hepatitis', '', 'Hepatitis B', 'Personas mayores de 60 años', 'Centro Sur',
   'Finalizada', '2026-09-01', '2026-09-07', 800, 486)
) as c(nombre, descripcion, vacuna, poblacion, centro, estado, inicio, fin, meta, aplicadas)
join public.vacunas v on v.nombre = c.vacuna
join public.centros ce on ce.nombre = c.centro;

insert into public.pacientes (
  nombres, apellidos, documento, fecha_nacimiento, sexo, telefono, direccion,
  contacto_emergencia
) values
  ('Lucía', 'Mendoza Rojas', 'CI 6842917', '1998-03-12', 'Femenino', '+591 712 458 90',
   'Av. Los Pinos 245, La Paz', 'Carlos Mendoza · +591 765 230 11'),
  ('Juan Pablo', 'Martínez', 'CI 7538204', '1990-06-03', 'Masculino', '', '', ''),
  ('Ana Sofía', 'Álvarez', 'CI 8125590', '2000-02-05', 'Femenino', '', '', '');

insert into public.lotes (codigo, vacuna_id, centro_id, cantidad, vence)
select l.codigo, v.id, ce.id, l.cantidad, l.vence::date
from (values
  ('INF-2601', 'Influenza estacional', 'Centro San Martín', 420, '2026-11-30'),
  ('COV-2603', 'COVID-19', 'Centro Norte', 680, '2026-12-15'),
  ('SRP-2602', 'SRP', 'Centro Sur', 148, '2026-10-28')
) as l(codigo, vacuna, centro, cantidad, vence)
join public.vacunas v on v.nombre = l.vacuna
join public.centros ce on ce.nombre = l.centro;

-- Historial de Lucía. COV-2511 es un lote anterior que ya no está en inventario.
insert into public.vacunaciones (
  paciente_id, vacuna_id, dosis, lote_codigo, lote_id, centro_id,
  responsable_id, fecha
)
select p.id, v.id, h.dosis, h.lote, l.id, ce.id,
  '11111111-1111-4111-8111-111111111111', h.fecha::date
from (values
  ('Influenza estacional', 'Dosis 1', 'INF-2601', 'Centro San Martín', '2026-04-15'),
  ('COVID-19', 'Dosis de refuerzo', 'COV-2511', 'Centro Norte', '2025-11-08')
) as h(vacuna, dosis, lote, centro, fecha)
join public.pacientes p on p.documento = 'CI 6842917'
join public.vacunas v on v.nombre = h.vacuna
join public.centros ce on ce.nombre = h.centro
left join public.lotes l on l.codigo = h.lote;
