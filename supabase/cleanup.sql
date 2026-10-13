-- قدّها · daily cleanup of expired «قدّنا؟» links and their secrets.
-- The privacy policy promises secrets are deleted once a link expires (60 days).
-- Run once in Supabase → SQL Editor. Needs the pg_cron extension
-- (Supabase → Database → Extensions → enable "pg_cron"). Safe to re-run.

create or replace function public.delete_expired_circles()
returns integer language sql security definer set search_path = public, extensions as $$
  with gone as (delete from circles where expires_at < now() returning 1)  -- secrets go with them (on delete cascade)
  select count(*)::int from gone;
$$;
revoke all on function public.delete_expired_circles() from public, anon, authenticated;

create extension if not exists pg_cron;
select cron.unschedule('gaddha-cleanup') where exists (select 1 from cron.job where jobname = 'gaddha-cleanup');
select cron.schedule('gaddha-cleanup', '17 3 * * *', $$select public.delete_expired_circles()$$);
