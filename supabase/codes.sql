-- قدّها · redeemable codes (night passes and unlimited-time plans).
-- Run once in Supabase → SQL Editor, after schema.sql and auth.sql. Safe to re-run.
-- Then make yourself an admin (one time), with your own account's email:
--   insert into public.admins(user_id) select id from auth.users where email = 'YOUR-EMAIL' on conflict do nothing;

-- who may create codes (filled by hand in the SQL editor, never from the app)
create table if not exists public.admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);
alter table public.admins enable row level security;   -- no policies: nobody reads it through the API

create table if not exists public.codes (
  code         text primary key,
  nights       int  not null default 0 check (nights between 0 and 100),
  days         int  not null default 0 check (days between 0 and 3660),
  note         text check (char_length(note) <= 80),
  created_by   uuid references auth.users(id) on delete set null,
  created_at   timestamptz not null default now(),
  redeemed_by  uuid references auth.users(id) on delete set null,
  redeemed_at  timestamptz,
  check (nights > 0 or days > 0)
);
alter table public.codes enable row level security;     -- only reachable through the functions below

-- what each account owns: night passes left, and unlimited play until a date
create table if not exists public.entitlements (
  user_id      uuid primary key references auth.users(id) on delete cascade,
  nights_left  int not null default 0 check (nights_left >= 0),
  until        timestamptz,
  updated_at   timestamptz not null default now()
);
alter table public.entitlements enable row level security;
drop policy if exists "entitlements: read own" on public.entitlements;
create policy "entitlements: read own" on public.entitlements for select to authenticated using (auth.uid() = user_id);

-- failed redeem attempts, to stop guessing
create table if not exists public.code_attempts (
  user_id  uuid not null references auth.users(id) on delete cascade,
  at       timestamptz not null default now()
);
create index if not exists code_attempts_idx on public.code_attempts(user_id, at);
alter table public.code_attempts enable row level security;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public, extensions as $$
  select exists (select 1 from admins where user_id = auth.uid());
$$;

-- admin: make n codes like QD-7K3M-P9XA
create or replace function public.create_codes(p_count int, p_nights int, p_days int, p_note text)
returns setof text language plpgsql security definer set search_path = public, extensions as $$
declare a text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789'; c text; i int; j int; b bytea;
begin
  if not is_admin() then raise exception 'not admin'; end if;
  if p_count < 1 or p_count > 50 then raise exception 'count 1-50'; end if;
  for i in 1..p_count loop
    loop
      b := gen_random_bytes(8); c := 'QD-';
      for j in 0..7 loop
        if j = 4 then c := c || '-'; end if;
        c := c || substr(a, (get_byte(b, j) % length(a)) + 1, 1);
      end loop;
      exit when not exists (select 1 from codes where code = c);
    end loop;
    insert into codes(code, nights, days, note, created_by)
    values (c, greatest(coalesce(p_nights,0),0), greatest(coalesce(p_days,0),0), left(p_note, 80), auth.uid());
    return next c;
  end loop;
end $$;

-- admin: recent codes and who used them
create or replace function public.list_codes(p_limit int default 100)
returns table(code text, nights int, days int, note text, created_at timestamptz, redeemed_at timestamptz, redeemed_email text)
language plpgsql stable security definer set search_path = public, extensions as $$
begin
  if not is_admin() then raise exception 'not admin'; end if;
  return query
    select c.code, c.nights, c.days, c.note, c.created_at, c.redeemed_at, u.email::text
    from codes c left join auth.users u on u.id = c.redeemed_by
    order by c.created_at desc limit least(greatest(p_limit,1), 500);
end $$;

-- player: redeem a code into their own account
create or replace function public.redeem_code(p_code text)
returns json language plpgsql security definer set search_path = public, extensions as $$
declare v_uid uuid := auth.uid(); v codes; v_code text; e entitlements;
begin
  if v_uid is null then raise exception 'login'; end if;
  if (select count(*) from code_attempts where user_id = v_uid and at > now() - interval '1 hour') >= 10 then
    return json_build_object('error', 'too many');
  end if;
  v_code := upper(regexp_replace(coalesce(p_code,''), '[^A-Za-z0-9]', '', 'g'));
  if v_code like 'QD%' then v_code := substr(v_code, 3); end if;
  v_code := 'QD-' || substr(v_code, 1, 4) || '-' || substr(v_code, 5, 4);
  select * into v from codes where code = v_code for update;
  -- wrong codes return an error instead of raising, so the failed attempt is kept (a raise would roll it back)
  if not found then
    insert into code_attempts(user_id) values (v_uid);
    return json_build_object('error', 'bad code');
  end if;
  if v.redeemed_by is not null then
    if v.redeemed_by = v_uid then return json_build_object('error', 'already yours'); end if;
    insert into code_attempts(user_id) values (v_uid);
    return json_build_object('error', 'used');
  end if;
  update codes set redeemed_by = v_uid, redeemed_at = now() where code = v_code;
  insert into entitlements(user_id) values (v_uid) on conflict (user_id) do nothing;
  update entitlements set
    nights_left = nights_left + v.nights,
    until = case when v.days > 0 then greatest(coalesce(until, now()), now()) + make_interval(days => v.days) else until end,
    updated_at = now()
  where user_id = v_uid returning * into e;
  return json_build_object('nights', v.nights, 'days', v.days, 'nights_left', e.nights_left, 'until', e.until);
end $$;

-- player: what my account owns
create or replace function public.my_plan()
returns json language sql stable security definer set search_path = public, extensions as $$
  select coalesce(
    (select json_build_object('nights_left', nights_left, 'until', until) from entitlements where user_id = auth.uid()),
    json_build_object('nights_left', 0, 'until', null));
$$;

revoke all on function public.create_codes(int,int,int,text), public.list_codes(int), public.redeem_code(text), public.my_plan(), public.is_admin() from public, anon;
grant execute on function public.create_codes(int,int,int,text), public.list_codes(int), public.redeem_code(text), public.my_plan(), public.is_admin() to authenticated;
