-- قدّها · accounts (run once in Supabase → SQL Editor, after schema.sql). Safe to re-run.
-- Login itself is Supabase Auth (email code, later Google). These tables hold what an account keeps.

create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  name        text check (char_length(name) between 1 and 24),
  circle      text check (char_length(circle) <= 40),
  color       text check (color ~ '^#[0-9a-fA-F]{6}$'),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
alter table public.profiles enable row level security;
drop policy if exists "profiles: read own"   on public.profiles;
drop policy if exists "profiles: insert own" on public.profiles;
drop policy if exists "profiles: update own" on public.profiles;
create policy "profiles: read own"   on public.profiles for select to authenticated using (auth.uid() = id);
create policy "profiles: insert own" on public.profiles for insert to authenticated with check (auth.uid() = id);
create policy "profiles: update own" on public.profiles for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- one row per finished game night
create table if not exists public.nights (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  played_at  timestamptz not null default now(),
  teams      jsonb not null check (jsonb_typeof(teams) = 'array' and jsonb_array_length(teams) = 2),
  winner     smallint check (winner between -1 and 1),
  cats       jsonb
);
create index if not exists nights_user_idx on public.nights(user_id, played_at desc);
alter table public.nights enable row level security;
drop policy if exists "nights: read own"   on public.nights;
drop policy if exists "nights: insert own" on public.nights;
drop policy if exists "nights: delete own" on public.nights;
create policy "nights: read own"   on public.nights for select to authenticated using (auth.uid() = user_id);
create policy "nights: insert own" on public.nights for insert to authenticated with check (auth.uid() = user_id);
create policy "nights: delete own" on public.nights for delete to authenticated using (auth.uid() = user_id);

revoke all on public.profiles, public.nights from anon;
grant select, insert, update on public.profiles to authenticated;
grant select, insert, delete on public.nights to authenticated;

-- lets a signed-in person delete their own account (and, through cascade, their profile and nights)
create or replace function public.delete_my_account()
returns void language sql security definer set search_path = public, auth as $$
  delete from auth.users where id = auth.uid();
$$;
revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
