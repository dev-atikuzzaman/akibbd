-- ════════════════════════════════════════════════════════════════
-- akibbd portfolio — Supabase schema
-- Run this ONCE in: Supabase Dashboard → SQL Editor → New query → Run
-- ════════════════════════════════════════════════════════════════

-- pgcrypto gives us gen_random_uuid() for primary keys
create extension if not exists pgcrypto;

-- ── TABLES ─────────────────────────────────────────────────────
create table if not exists public.posts (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid not null references auth.users(id) on delete cascade,
  title       text,
  body        text not null,
  category    text not null default 'thought',
  likes       integer not null default 0,
  visibility  text not null default 'public' check (visibility in ('public','private')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table if not exists public.courses (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid not null references auth.users(id) on delete cascade,
  title       text not null,
  description text,
  source      text not null default 'youtube',
  video_id    text not null,
  thumb       text,
  tag         text,
  duration    text,
  visibility  text not null default 'public' check (visibility in ('public','private')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table if not exists public.infos (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid not null references auth.users(id) on delete cascade,
  title       text not null,
  type        text not null default 'text' check (type in ('text','skills','links','timeline')),
  content     text not null,
  visibility  text not null default 'public' check (visibility in ('public','private')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table if not exists public.embeds (
  id          uuid primary key default gen_random_uuid(),
  owner_id    uuid not null references auth.users(id) on delete cascade,
  title       text not null,
  type        text not null default 'iframe' check (type in ('gsheet','iframe','json')),
  url         text not null,
  visibility  text not null default 'public' check (visibility in ('public','private')),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- ── AUTO-SET owner_id + updated_at (server-enforced, can't be spoofed) ──
create or replace function public.set_owner_and_timestamps()
returns trigger language plpgsql security definer as $$
begin
  if TG_OP = 'INSERT' then
    new.owner_id := auth.uid();       -- always the real logged-in user, never trust client value
    new.created_at := now();
    new.updated_at := now();
  elsif TG_OP = 'UPDATE' then
    new.owner_id := old.owner_id;     -- ownership never changes on edit
    new.created_at := old.created_at;
    new.updated_at := now();
  end if;
  return new;
end;
$$;

do $$
declare t text;
begin
  foreach t in array array['posts','courses','infos','embeds'] loop
    execute format('drop trigger if exists trg_owner_ts on public.%I;', t);
    execute format('create trigger trg_owner_ts before insert or update on public.%I
                    for each row execute function public.set_owner_and_timestamps();', t);
  end loop;
end $$;

-- ── ROW LEVEL SECURITY ───────────────────────────────────────────
-- Rule for every table: visitors (anon) + everyone see PUBLIC rows.
-- The signed-in owner additionally sees their OWN private rows too.
-- Only the owner may insert/update/delete their own rows.
do $$
declare t text;
begin
  foreach t in array array['posts','courses','infos','embeds'] loop
    execute format('alter table public.%I enable row level security;', t);

    execute format('drop policy if exists "select_public_or_own" on public.%I;', t);
    execute format($p$create policy "select_public_or_own" on public.%I
      for select using ( visibility = 'public' or owner_id = auth.uid() );$p$, t);

    execute format('drop policy if exists "insert_own" on public.%I;', t);
    execute format($p$create policy "insert_own" on public.%I
      for insert with check ( auth.uid() is not null );$p$, t);

    execute format('drop policy if exists "update_own" on public.%I;', t);
    execute format($p$create policy "update_own" on public.%I
      for update using ( owner_id = auth.uid() ) with check ( owner_id = auth.uid() );$p$, t);

    execute format('drop policy if exists "delete_own" on public.%I;', t);
    execute format($p$create policy "delete_own" on public.%I
      for delete using ( owner_id = auth.uid() );$p$, t);
  end loop;
end $$;

-- ── LIKE COUNTER (public + anon visitors can bump it, nothing else) ──
create or replace function public.adjust_post_like(p_id uuid, p_delta integer)
returns void language sql security definer as $$
  update public.posts
  set likes = greatest(0, coalesce(likes,0) + p_delta)
  where id = p_id;
$$;
grant execute on function public.adjust_post_like(uuid, integer) to anon, authenticated;

-- ── REALTIME — required so the site updates live across open tabs ──
alter publication supabase_realtime add table public.posts;
alter publication supabase_realtime add table public.courses;
alter publication supabase_realtime add table public.infos;
alter publication supabase_realtime add table public.embeds;

-- ══════════════════════════════════════════════════════════════
-- OPTIONAL BUT RECOMMENDED: lock signup to just your own email
-- so a random visitor can never create their own "admin" account.
-- 1) Replace 'atikuzzaman@example.com' below with your real email.
-- 2) Uncomment the block (remove the /* and */ lines) and run it.
-- ══════════════════════════════════════════════════════════════
/*
create or replace function public.restrict_signup_email()
returns trigger language plpgsql security definer as $$
begin
  if new.email is distinct from 'atikuzzaman@example.com' then
    raise exception 'Signups are not open to the public.';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_restrict_signup on auth.users;
create trigger trg_restrict_signup
  before insert on auth.users
  for each row execute function public.restrict_signup_email();
*/
