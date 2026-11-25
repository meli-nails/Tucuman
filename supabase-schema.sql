-- ============================================================
-- MELI NAILS · Esquema inicial de Supabase
-- Ejecutar en Supabase > SQL Editor > New query.
-- ============================================================

create extension if not exists pgcrypto;

create table if not exists public.meli_admins (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.meli_services (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  detail text not null default '',
  price integer not null default 0 check (price >= 0),
  active boolean not null default true,
  sort_order integer not null default 100,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.meli_designs (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category text not null default 'Otros',
  price integer not null default 0 check (price >= 0),
  description text not null default '',
  tone text not null default 'pink',
  image_url text not null default '',
  active boolean not null default true,
  sort_order integer not null default 100,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.meli_bookings (
  id uuid primary key default gen_random_uuid(),
  client_name text not null,
  client_phone text not null,
  client_note text not null default '',
  option_type text not null check (option_type in ('service', 'design')),
  option_name text not null,
  extras jsonb not null default '[]'::jsonb,
  booking_date date not null,
  booking_time text not null,
  location text not null default 'En el espacio de Meli',
  base_price integer not null default 0 check (base_price >= 0),
  total_price integer not null default 0 check (total_price >= 0),
  deposit integer not null default 0 check (deposit >= 0),
  status text not null default 'pending' check (status in ('pending', 'confirmed', 'completed', 'cancelled')) ,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Índices para consultas frecuentes del panel.
create index if not exists meli_bookings_date_idx on public.meli_bookings (booking_date, booking_time);
create index if not exists meli_bookings_status_idx on public.meli_bookings (status);
create index if not exists meli_designs_active_order_idx on public.meli_designs (active, sort_order);
create index if not exists meli_services_active_order_idx on public.meli_services (active, sort_order);

-- Función segura para comprobar si el usuario autenticado es administrador.
create or replace function public.is_meli_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.meli_admins
    where user_id = (select auth.uid())
  );
$$;

revoke all on function public.is_meli_admin() from public;
grant execute on function public.is_meli_admin() to anon, authenticated;

-- Activar Row Level Security en todas las tablas.
alter table public.meli_admins enable row level security;
alter table public.meli_services enable row level security;
alter table public.meli_designs enable row level security;
alter table public.meli_bookings enable row level security;

-- Permitir que cada usuario autenticado consulte solamente su propia membresía.
drop policy if exists "meli_admins_read_own" on public.meli_admins;
create policy "meli_admins_read_own"
  on public.meli_admins for select to authenticated
  using (user_id = (select auth.uid()));

-- Catálogo: público solo lee registros activos. Administradores gestionan todo.
drop policy if exists "meli_services_public_read_active" on public.meli_services;
create policy "meli_services_public_read_active"
  on public.meli_services for select to anon, authenticated
  using (active = true or public.is_meli_admin());

drop policy if exists "meli_services_admin_manage" on public.meli_services;
create policy "meli_services_admin_manage"
  on public.meli_services for all to authenticated
  using (public.is_meli_admin())
  with check (public.is_meli_admin());

drop policy if exists "meli_designs_public_read_active" on public.meli_designs;
create policy "meli_designs_public_read_active"
  on public.meli_designs for select to anon, authenticated
  using (active = true or public.is_meli_admin());

drop policy if exists "meli_designs_admin_manage" on public.meli_designs;
create policy "meli_designs_admin_manage"
  on public.meli_designs for all to authenticated
  using (public.is_meli_admin())
  with check (public.is_meli_admin());

-- Reservas: cualquier visitante puede crear una solicitud pendiente,
-- pero únicamente administradores pueden leerlas o modificarlas.
drop policy if exists "meli_bookings_public_insert" on public.meli_bookings;
create policy "meli_bookings_public_insert"
  on public.meli_bookings for insert to anon, authenticated
  with check (
    status = 'pending'
    and char_length(trim(client_name)) between 1 and 100
    and char_length(trim(client_phone)) between 8 and 30
    and char_length(trim(option_name)) between 1 and 160
  );

drop policy if exists "meli_bookings_admin_read" on public.meli_bookings;
create policy "meli_bookings_admin_read"
  on public.meli_bookings for select to authenticated
  using (public.is_meli_admin());

drop policy if exists "meli_bookings_admin_update" on public.meli_bookings;
create policy "meli_bookings_admin_update"
  on public.meli_bookings for update to authenticated
  using (public.is_meli_admin())
  with check (public.is_meli_admin());

-- Permisos SQL; RLS sigue determinando qué filas se pueden usar.
grant select on public.meli_services, public.meli_designs to anon, authenticated;
grant insert, select, update on public.meli_services, public.meli_designs to authenticated;
grant insert on public.meli_bookings to anon, authenticated;
grant select, update on public.meli_bookings to authenticated;
grant select on public.meli_admins to authenticated;

-- ============================================================
-- CREAR EL PRIMER ADMINISTRADOR (hacerlo DESPUÉS de crear el usuario)
-- 1. En Authentication > Users, creá un usuario con email y contraseña.
-- 2. Reemplazá el email de abajo por el email real y ejecutá el INSERT.
-- ============================================================
-- insert into public.meli_admins (user_id)
-- select id from auth.users where email = 'TU_CORREO_ADMIN'
-- on conflict (user_id) do nothing;
