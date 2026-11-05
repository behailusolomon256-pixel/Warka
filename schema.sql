-- WARKA NEWS initial database schema.
-- Run in Supabase SQL Editor. Keep RLS enabled.
create table if not exists public.news_tips (
  id uuid primary key default gen_random_uuid(),
  subject text not null,
  message text not null,
  contact text,
  is_anonymous boolean not null default false,
  media_path text,
  status text not null default 'new' check (status in ('new','reviewing','verified','rejected')),
  created_at timestamptz not null default now()
);

create table if not exists public.publisher_messages (
  id uuid primary key default gen_random_uuid(),
  sender_name text,
  contact text,
  message text not null,
  status text not null default 'new' check (status in ('new','read','replied','closed')),
  created_at timestamptz not null default now()
);

create table if not exists public.articles (
  id uuid primary key default gen_random_uuid(),
  title_en text not null,
  title_am text not null,
  body_en text not null,
  body_am text not null,
  category text not null,
  cover_image_path text,
  published boolean not null default false,
  published_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.news_tips enable row level security;
alter table public.publisher_messages enable row level security;
alter table public.articles enable row level security;

-- Public can submit tips and messages. Only authenticated newsroom staff can read them.
create policy "public submit tips" on public.news_tips for insert to anon, authenticated
  with check (true);
create policy "public send publisher messages" on public.publisher_messages for insert to anon, authenticated
  with check (true);

-- Public can read published stories only.
create policy "read published articles" on public.articles for select to anon, authenticated
  using (published = true);

-- IMPORTANT:
-- Do not add public SELECT policies to tips/messages.
-- Create staff accounts and staff-only policies before building the publisher dashboard.
-- Create a private storage bucket named news-tips. Do not make it public.
