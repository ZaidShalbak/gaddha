-- قدّها · the question bank lives in the database (instead of files on GitHub).
-- Run once in Supabase → SQL Editor, after codes.sql (it uses is_admin()). Safe to re-run.
-- Then open /admin, log in, and press «انقل الأسئلة» once to copy the current questions in.
--
-- Same shapes as the old files, so the game and the admin page barely changed:
--   q_config  = questions/index.json   (groups, categories, finals file name)
--   q_files   = the top of each file   (e.g. {"category":"act","type":"act"}) + which key holds the list
--   q_items   = one row per question   (body = the question exactly as it was in the file)
-- Players only ever receive published questions. Drafts are visible to admins only.

create table if not exists public.q_config (
  id          int primary key default 1 check (id = 1),
  body        jsonb not null,
  updated_at  timestamptz not null default now()
);
create table if not exists public.q_files (
  file        text primary key check (file ~ '^[a-z0-9-]+\.json$'),
  head        jsonb not null default '{}',
  list_key    text not null check (list_key in ('questions','items','finals')),
  updated_at  timestamptz not null default now()
);
create table if not exists public.q_items (
  file        text not null references public.q_files(file) on delete cascade,
  id          text not null,
  sort        int  not null,
  status      text not null default 'draft',
  body        jsonb not null,
  updated_at  timestamptz not null default now(),
  updated_by  uuid references auth.users(id) on delete set null,
  primary key (file, id)
);
create index if not exists q_items_file_sort on public.q_items(file, sort);
-- no policies: only reachable through the functions below
alter table public.q_config enable row level security;
alter table public.q_files  enable row level security;
alter table public.q_items  enable row level security;

-- build {index, files:{"act.json":{...file...}}}; p_all = include drafts
create or replace function public._q_bank(p_all boolean)
returns json language sql stable security definer set search_path = public, extensions as $$
  select json_build_object(
    'index', (select body from q_config where id = 1),
    'files', coalesce((
      select json_object_agg(f.file, f.head || jsonb_build_object(f.list_key, coalesce((
        select jsonb_agg(i.body order by i.sort) from q_items i
        where i.file = f.file and (p_all or i.status = 'published')), '[]'::jsonb)))
      from q_files f), '{}'::json));
$$;
revoke all on function public._q_bank(boolean) from public, anon, authenticated;

-- the game: published questions only, anyone can read (like the old public files)
create or replace function public.get_bank()
returns json language sql stable security definer set search_path = public, extensions as $$
  select public._q_bank(false);
$$;

-- admin: everything, drafts included
create or replace function public.admin_bank()
returns json language plpgsql stable security definer set search_path = public, extensions as $$
begin
  if not is_admin() then raise exception 'not admin'; end if;
  return public._q_bank(true);
end $$;

-- admin: save the changed files in one go.
-- p_index: the whole index (or null when unchanged). p_files: {"act.json": {...whole file...}, ...}
-- Each file's list replaces what was there: rows not in the new list are deleted.
create or replace function public.admin_save(p_index jsonb, p_files jsonb)
returns json language plpgsql security definer set search_path = public, extensions as $$
declare v_file text; v_body jsonb; k text; n int := 0;
begin
  if not is_admin() then raise exception 'not admin'; end if;
  if p_index is not null then
    if jsonb_typeof(p_index->'categories') <> 'array' or jsonb_typeof(p_index->'groups') <> 'array' then
      raise exception 'bad index';
    end if;
    insert into q_config(id, body, updated_at) values (1, p_index, now())
    on conflict (id) do update set body = excluded.body, updated_at = now();
  end if;
  for v_file, v_body in select * from jsonb_each(coalesce(p_files, '{}'::jsonb)) loop
    k := case when v_body ? 'finals' then 'finals' when v_body ? 'items' then 'items' when v_body ? 'questions' then 'questions' end;
    if k is null or jsonb_typeof(v_body->k) <> 'array' then raise exception 'bad file %', v_file; end if;
    insert into q_files(file, head, list_key, updated_at) values (v_file, v_body - k, k, now())
    on conflict (file) do update set head = excluded.head, list_key = excluded.list_key, updated_at = now();
    delete from q_items i where i.file = v_file
      and not exists (select 1 from jsonb_array_elements(v_body->k) e where e->>'id' = i.id);
    insert into q_items(file, id, sort, status, body, updated_at, updated_by)
    select v_file, e->>'id', o::int, coalesce(e->>'status', 'draft'), e, now(), auth.uid()
    from jsonb_array_elements(v_body->k) with ordinality as t(e, o)
    where coalesce(e->>'id', '') <> ''
    on conflict (file, id) do update set sort = excluded.sort, status = excluded.status, body = excluded.body,
      updated_at = case when q_items.body is distinct from excluded.body then now() else q_items.updated_at end,
      updated_by = case when q_items.body is distinct from excluded.body then excluded.updated_by else q_items.updated_by end;
    n := n + 1;
  end loop;
  return json_build_object('files', n);
end $$;

revoke all on function public.get_bank(), public.admin_bank(), public.admin_save(jsonb, jsonb) from public, anon;
grant execute on function public.get_bank() to anon, authenticated;
grant execute on function public.admin_bank(), public.admin_save(jsonb, jsonb) to authenticated;

-- pictures for photo questions: a public bucket, only admins can upload or replace
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('qimg', 'qimg', true, 2000000, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = true;
drop policy if exists "qimg: admin select" on storage.objects;
drop policy if exists "qimg: admin insert" on storage.objects;
drop policy if exists "qimg: admin update" on storage.objects;
drop policy if exists "qimg: admin delete" on storage.objects;
create policy "qimg: admin select" on storage.objects for select to authenticated using (bucket_id = 'qimg' and public.is_admin());
create policy "qimg: admin insert" on storage.objects for insert to authenticated with check (bucket_id = 'qimg' and public.is_admin());
create policy "qimg: admin update" on storage.objects for update to authenticated using (bucket_id = 'qimg' and public.is_admin());
create policy "qimg: admin delete" on storage.objects for delete to authenticated using (bucket_id = 'qimg' and public.is_admin());
