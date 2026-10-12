-- قدّها · Supabase setup (run once in Supabase → SQL Editor → New query → Run)
-- Live drawing and host mode use Realtime broadcast and need no tables.
-- «قدّنا؟» secrets are stored here. Tables are locked (RLS on, no policies);
-- the site only talks to them through the functions below.

create extension if not exists pgcrypto;

create table if not exists public.circles (
  id          text primary key,
  host_key    text not null,
  kind        text not null default 'family' check (kind in ('family','friends','work')),
  title       text check (char_length(title) <= 40),
  created_at  timestamptz not null default now(),
  expires_at  timestamptz not null default now() + interval '60 days'
);

create table if not exists public.secrets (
  id          uuid primary key default gen_random_uuid(),
  circle_id   text not null references public.circles(id) on delete cascade,
  by_name     text not null check (char_length(by_name) between 1 and 24),
  team        smallint not null default -2 check (team between -2 and 1),
  q           text not null check (char_length(q) between 3 and 180),
  a           text not null check (char_length(a) between 1 and 60),
  hint        text check (char_length(hint) <= 90),
  story       text check (char_length(story) <= 220),
  created_at  timestamptz not null default now()
);
create index if not exists secrets_circle_idx on public.secrets(circle_id);

alter table public.circles enable row level security;
alter table public.secrets enable row level security;

-- host creates a circle; gets back the public id (for the link) and a private host key
create or replace function public.create_circle(p_kind text, p_title text)
returns json language plpgsql security definer set search_path = public, extensions as $$
declare v_id text; v_key text;
begin
  v_id  := translate(encode(gen_random_bytes(8), 'base64'), '+/=', 'xyz');
  v_key := encode(gen_random_bytes(24), 'hex');
  insert into circles(id, host_key, kind, title)
  values (v_id, v_key, coalesce(nullif(p_kind,''),'family'), left(p_title, 40));
  return json_build_object('id', v_id, 'key', v_key);
end $$;

-- what the writer's phone needs to show the page (never the answers)
create or replace function public.circle_info(p_id text)
returns json language sql security definer set search_path = public, extensions as $$
  select json_build_object('kind', c.kind, 'title', c.title,
           'count', (select count(*) from secrets s where s.circle_id = c.id))
  from circles c where c.id = p_id and c.expires_at > now();
$$;

create or replace function public.add_secret(p_id text, p_by text, p_team int, p_q text, p_a text, p_hint text, p_story text)
returns uuid language plpgsql security definer set search_path = public, extensions as $$
declare v uuid;
begin
  if not exists (select 1 from circles where id = p_id and expires_at > now()) then
    raise exception 'circle not found';
  end if;
  if (select count(*) from secrets where circle_id = p_id) >= 200 then
    raise exception 'circle full';
  end if;
  insert into secrets(circle_id, by_name, team, q, a, hint, story)
  values (p_id, trim(p_by), coalesce(p_team, -2), trim(p_q), trim(p_a), nullif(trim(p_hint),''), nullif(trim(p_story),''))
  returning id into v;
  return v;
end $$;

-- host device only (needs the private key)
create or replace function public.get_secrets(p_id text, p_key text)
returns setof public.secrets language sql security definer set search_path = public, extensions as $$
  select s.* from secrets s join circles c on c.id = s.circle_id
  where c.id = p_id and c.host_key = p_key order by s.created_at;
$$;

create or replace function public.delete_secret(p_id text, p_key text, p_secret uuid)
returns void language sql security definer set search_path = public, extensions as $$
  delete from secrets s using circles c
  where s.id = p_secret and s.circle_id = c.id and c.id = p_id and c.host_key = p_key;
$$;

revoke all on public.circles, public.secrets from anon, authenticated;
grant execute on function public.create_circle(text,text), public.circle_info(text),
  public.add_secret(text,text,int,text,text,text,text), public.get_secrets(text,text),
  public.delete_secret(text,text,uuid) to anon, authenticated;
