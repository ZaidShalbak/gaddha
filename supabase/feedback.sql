-- قدّها · after-game feedback («كيف كانت السهرة؟»).
-- Run once in Supabase → SQL Editor, after codes.sql (it uses is_admin()). Safe to re-run.

create table if not exists public.feedback (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz not null default now(),
  user_id     uuid references auth.users(id) on delete set null,   -- filled when the host is logged in
  rating      smallint check (rating between 1 and 5),
  liked       text[] not null default '{}',
  pain        text check (char_length(pain) <= 500),
  pay         text check (pay in ('no','night','year','depends')),
  price       text check (price in ('lt10','10-20','20-30','gt30')),
  cats        jsonb,
  minutes     int check (minutes between 0 and 1440),
  device      text check (char_length(device) <= 20)
);
create index if not exists feedback_created_idx on public.feedback(created_at desc);
alter table public.feedback enable row level security;   -- no policies: only reachable through the functions below

-- anyone who just finished a game (logged in or not) can send one
create or replace function public.submit_feedback(p jsonb)
returns void language plpgsql security definer set search_path = public, extensions as $$
declare v_liked text[];
begin
  -- light flood guard: at most 300 feedbacks in any 10 minutes, across everyone
  if (select count(*) from feedback where created_at > now() - interval '10 minutes') >= 300 then
    raise exception 'busy';
  end if;
  select coalesce(array_agg(left(x, 30)), '{}') into v_liked
  from (select jsonb_array_elements_text(coalesce(p->'liked', '[]'::jsonb)) x limit 10) t;
  insert into feedback(user_id, rating, liked, pain, pay, price, cats, minutes, device)
  values (
    auth.uid(),
    nullif((p->>'rating')::int, 0),
    v_liked,
    nullif(left(trim(p->>'pain'), 500), ''),
    nullif(p->>'pay', ''),
    nullif(p->>'price', ''),
    case when jsonb_typeof(p->'cats') = 'array' and jsonb_array_length(p->'cats') <= 12 then p->'cats' end,
    least(greatest((p->>'minutes')::int, 0), 1440),
    left(p->>'device', 20)
  );
end $$;

-- admin: everything, newest first
create or replace function public.list_feedback(p_limit int default 300)
returns table(created_at timestamptz, email text, rating smallint, liked text[], pain text, pay text, price text, cats jsonb, minutes int, device text)
language plpgsql stable security definer set search_path = public, extensions as $$
begin
  if not is_admin() then raise exception 'not admin'; end if;
  return query
    select f.created_at, u.email::text, f.rating, f.liked, f.pain, f.pay, f.price, f.cats, f.minutes, f.device
    from feedback f left join auth.users u on u.id = f.user_id
    order by f.created_at desc limit least(greatest(p_limit,1), 1000);
end $$;

revoke all on function public.submit_feedback(jsonb), public.list_feedback(int) from public;
grant execute on function public.submit_feedback(jsonb) to anon, authenticated;
grant execute on function public.list_feedback(int) to authenticated;
