-- VacunaPlus: esquema inicial. Sigue los modelos de app/lib/models/entities.dart.

-- Catálogo de vacunas. Campañas y lotes apuntan aquí, así una campaña de
-- "Influenza tetravalente" no queda con lotes de "Influenza estacional".
create table public.vacunas (
  id bigint generated always as identity primary key,
  nombre text not null unique check (btrim(nombre) <> '')
);

create table public.centros (
  id bigint generated always as identity primary key,
  nombre text not null unique check (btrim(nombre) <> ''),
  direccion text not null check (btrim(direccion) <> ''),
  horario text not null check (btrim(horario) <> ''),
  abierto boolean not null default true,
  -- Ubicación para el mapa (OpenStreetMap).
  lat double precision not null check (lat between -90 and 90),
  lng double precision not null check (lng between -180 and 180),
  creado_en timestamptz not null default now()
);

-- Personal de salud y ciudadanos; el id es el del usuario de Supabase Auth.
create table public.perfiles (
  id uuid primary key references auth.users (id) on delete cascade,
  nombre text not null check (btrim(nombre) <> ''),
  correo text,
  rol text not null default 'Ciudadano'
    check (rol in ('Administrador', 'Personal de salud', 'Ciudadano')),
  activo boolean not null default true,
  creado_en timestamptz not null default now()
);
create unique index perfiles_correo_key on public.perfiles (lower(correo));

create table public.campanas (
  id bigint generated always as identity primary key,
  nombre text not null check (btrim(nombre) <> ''),
  descripcion text not null default '',
  vacuna_id bigint not null references public.vacunas (id),
  poblacion_objetivo text not null,
  centro_id bigint not null references public.centros (id),
  responsable_id uuid references public.perfiles (id) on delete set null,
  estado text not null default 'Activa'
    check (estado in ('Activa', 'Próxima', 'Finalizada')),
  fecha_inicio date not null,
  fecha_fin date not null,
  meta integer not null check (meta > 0),
  aplicadas integer not null default 0 check (aplicadas >= 0),
  creado_en timestamptz not null default now(),
  check (fecha_fin >= fecha_inicio)
);
-- Igual que la app: el nombre no se repite aunque cambien las mayúsculas.
create unique index campanas_nombre_key on public.campanas (lower(nombre));
create index campanas_centro_idx on public.campanas (centro_id);

create table public.pacientes (
  id bigint generated always as identity primary key,
  nombres text not null check (btrim(nombres) <> ''),
  apellidos text not null check (btrim(apellidos) <> ''),
  documento text not null
    check (char_length(btrim(documento)) between 5 and 25),
  fecha_nacimiento date not null check (fecha_nacimiento <= current_date),
  sexo text not null check (sexo in ('Femenino', 'Masculino', 'Otro')),
  telefono text not null default '',
  direccion text not null default '',
  contacto_emergencia text not null default '',
  creado_en timestamptz not null default now()
);
-- Igual que la app: "CI 6842917" y "ci6842917" son el mismo documento.
create unique index pacientes_documento_key
  on public.pacientes (lower(replace(documento, ' ', '')));

create table public.lotes (
  id bigint generated always as identity primary key,
  codigo text not null unique check (btrim(codigo) <> ''),
  vacuna_id bigint not null references public.vacunas (id),
  centro_id bigint not null references public.centros (id),
  cantidad integer not null check (cantidad >= 0),
  vence date not null,
  creado_en timestamptz not null default now()
);
create index lotes_centro_idx on public.lotes (centro_id);

create table public.vacunaciones (
  id bigint generated always as identity primary key,
  paciente_id bigint not null references public.pacientes (id) on delete cascade,
  campana_id bigint references public.campanas (id) on delete set null,
  vacuna_id bigint not null references public.vacunas (id),
  dosis text not null check (dosis in ('Dosis 1', 'Dosis 2', 'Dosis de refuerzo')),
  -- Código tal como figura en el carné. lote_id queda vacío si el lote ya no
  -- está en el inventario (registros anteriores).
  lote_codigo text not null,
  lote_id bigint references public.lotes (id) on delete set null,
  centro_id bigint not null references public.centros (id),
  responsable_id uuid references public.perfiles (id) on delete set null,
  fecha date not null check (fecha <= current_date),
  proxima_cita date check (proxima_cita > fecha),
  observaciones text not null default '',
  creado_en timestamptz not null default now()
);
create index vacunaciones_paciente_idx on public.vacunaciones (paciente_id);

create table public.movimientos (
  id bigint generated always as identity primary key,
  lote_id bigint not null references public.lotes (id) on delete cascade,
  tipo text not null check (tipo in ('Entrada', 'Salida')),
  cantidad integer not null check (cantidad > 0),
  detalle text not null default '',
  creado_en timestamptz not null default now()
);
create index movimientos_lote_idx on public.movimientos (lote_id);

-- Roles ---------------------------------------------------------------------

-- Personal de salud activo (incluye administradores).
create function public.es_personal() returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.perfiles
    where id = (select auth.uid())
      and activo
      and rol in ('Administrador', 'Personal de salud')
  );
$$;

create function public.es_admin() returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.perfiles
    where id = (select auth.uid()) and activo and rol = 'Administrador'
  );
$$;

-- Toda cuenta nueva (p. ej. un ciudadano que entra con Google) recibe su
-- perfil como "Ciudadano"; un administrador lo pasa a personal de salud.
create function public.crear_perfil() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.perfiles (id, nombre, correo)
  values (
    new.id,
    coalesce(
      new.raw_user_meta_data ->> 'nombre',
      new.raw_user_meta_data ->> 'full_name',
      new.raw_user_meta_data ->> 'name',
      split_part(coalesce(new.email, 'Usuario'), '@', 1)
    ),
    new.email
  );
  return new;
end;
$$;

create trigger al_crear_usuario
  after insert on auth.users
  for each row execute function public.crear_perfil();

-- Solo un administrador cambia el rol o el estado de una cuenta. Sin sesión
-- (SQL del servidor, datos de prueba) no hay restricción.
create function public.proteger_rol() returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if (select auth.uid()) is not null
     and not public.es_admin()
     and (new.rol <> old.rol or new.activo <> old.activo) then
    raise exception 'Solo un administrador puede cambiar el rol o el estado';
  end if;
  return new;
end;
$$;

create trigger antes_de_actualizar_perfil
  before update on public.perfiles
  for each row execute function public.proteger_rol();

-- Seguridad por filas ---------------------------------------------------------

alter table public.vacunas enable row level security;
alter table public.centros enable row level security;
alter table public.perfiles enable row level security;
alter table public.campanas enable row level security;
alter table public.pacientes enable row level security;
alter table public.lotes enable row level security;
alter table public.vacunaciones enable row level security;
alter table public.movimientos enable row level security;

-- Información pública para la vista ciudadana (invitados incluidos).
create policy "Lectura pública" on public.vacunas
  for select to anon, authenticated using (true);
create policy "Lectura pública" on public.centros
  for select to anon, authenticated using (true);
create policy "Lectura pública" on public.campanas
  for select to anon, authenticated using (true);

-- El personal administra catálogo, centros, campañas e inventario.
create policy "Personal gestiona" on public.vacunas
  for all to authenticated
  using (public.es_personal()) with check (public.es_personal());
create policy "Personal gestiona" on public.centros
  for all to authenticated
  using (public.es_personal()) with check (public.es_personal());
create policy "Personal gestiona" on public.campanas
  for all to authenticated
  using (public.es_personal()) with check (public.es_personal());
create policy "Personal gestiona" on public.lotes
  for all to authenticated
  using (public.es_personal()) with check (public.es_personal());

-- Datos de salud: solo el personal.
create policy "Solo personal" on public.pacientes
  for all to authenticated
  using (public.es_personal()) with check (public.es_personal());
create policy "Solo personal" on public.vacunaciones
  for all to authenticated
  using (public.es_personal()) with check (public.es_personal());
create policy "Solo personal" on public.movimientos
  for all to authenticated
  using (public.es_personal()) with check (public.es_personal());

-- Cada uno ve y edita su perfil; el personal ve todos; el administrador los
-- gestiona (proteger_rol impide que otros cambien rol o estado).
create policy "Ver perfiles" on public.perfiles
  for select to authenticated
  using (id = (select auth.uid()) or public.es_personal());
create policy "Editar mi perfil" on public.perfiles
  for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy "Administrador gestiona" on public.perfiles
  for all to authenticated
  using (public.es_admin()) with check (public.es_admin());

-- Operaciones -----------------------------------------------------------------

-- Vacunas disponibles por centro para la vista ciudadana, sin exponer
-- cantidades ni códigos de lote.
create function public.vacunas_disponibles()
returns table (centro_id bigint, vacuna text)
language sql stable security definer set search_path = ''
as $$
  select distinct l.centro_id, v.nombre
  from public.lotes l
  join public.vacunas v on v.id = l.vacuna_id
  where l.cantidad > 0 and l.vence >= current_date
  order by 1, 2;
$$;

-- Registra una aplicación en un solo paso: valida el lote, descuenta una
-- dosis, suma la dosis a la campaña y deja el movimiento de inventario. El
-- centro es el del lote, así lote y centro siempre coinciden.
create function public.registrar_vacunacion(
  p_paciente_id bigint,
  p_campana_id bigint,
  p_lote_id bigint,
  p_dosis text,
  p_fecha date,
  p_proxima_cita date default null,
  p_observaciones text default ''
) returns bigint
language plpgsql security definer set search_path = ''
as $$
declare
  v_lote public.lotes;
  v_campana public.campanas;
  v_id bigint;
begin
  if not public.es_personal() then
    raise exception 'Solo el personal de salud registra vacunaciones';
  end if;
  select * into v_lote from public.lotes where id = p_lote_id for update;
  if not found then
    raise exception 'El lote no existe';
  end if;
  select * into v_campana from public.campanas where id = p_campana_id for update;
  if not found then
    raise exception 'La campaña no existe';
  end if;
  if v_campana.estado = 'Finalizada' then
    raise exception 'La campaña ya finalizó';
  end if;
  if v_lote.vacuna_id <> v_campana.vacuna_id then
    raise exception 'El lote no corresponde a la vacuna de la campaña';
  end if;
  if v_lote.cantidad <= 0 then
    raise exception 'No hay dosis disponibles en el lote';
  end if;
  if v_lote.vence < p_fecha then
    raise exception 'El lote está vencido en la fecha indicada';
  end if;

  insert into public.vacunaciones (
    paciente_id, campana_id, vacuna_id, dosis, lote_codigo, lote_id,
    centro_id, responsable_id, fecha, proxima_cita, observaciones
  ) values (
    p_paciente_id, p_campana_id, v_lote.vacuna_id, p_dosis, v_lote.codigo,
    v_lote.id, v_lote.centro_id, (select auth.uid()), p_fecha, p_proxima_cita,
    coalesce(p_observaciones, '')
  ) returning id into v_id;

  update public.lotes set cantidad = cantidad - 1 where id = v_lote.id;
  update public.campanas set aplicadas = aplicadas + 1 where id = v_campana.id;
  insert into public.movimientos (lote_id, tipo, cantidad, detalle)
  select v_lote.id, 'Salida', 1, 'Vacunación · ' || p.nombres || ' ' || p.apellidos
  from public.pacientes p where p.id = p_paciente_id;
  return v_id;
end;
$$;

-- Entrada de dosis a un lote existente, con su movimiento.
create function public.registrar_entrada(p_lote_id bigint, p_cantidad integer)
returns void
language plpgsql security definer set search_path = ''
as $$
begin
  if not public.es_personal() then
    raise exception 'Solo el personal de salud registra entradas';
  end if;
  if p_cantidad is null or p_cantidad <= 0 then
    raise exception 'La cantidad debe ser un entero mayor que cero';
  end if;
  update public.lotes set cantidad = cantidad + p_cantidad where id = p_lote_id;
  if not found then
    raise exception 'El lote no existe';
  end if;
  insert into public.movimientos (lote_id, tipo, cantidad, detalle)
  values (p_lote_id, 'Entrada', p_cantidad, 'Entrada de dosis');
end;
$$;

-- Las operaciones son solo para cuentas con sesión; la disponibilidad es pública.
revoke execute on function
  public.registrar_vacunacion(bigint, bigint, bigint, text, date, date, text),
  public.registrar_entrada(bigint, integer),
  public.es_personal(),
  public.es_admin()
from public, anon;
grant execute on function
  public.registrar_vacunacion(bigint, bigint, bigint, text, date, date, text),
  public.registrar_entrada(bigint, integer),
  public.es_personal(),
  public.es_admin()
to authenticated;
revoke execute on function public.crear_perfil(), public.proteger_rol()
from public, anon, authenticated;
grant execute on function public.vacunas_disponibles() to anon, authenticated;
