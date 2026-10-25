-- Aadam Son's: Supabase SQL Editor mein poora run karein

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  email text,
  role text not null default 'teacher' check (role in ('teacher','admin')),
  class_name text,
  created_at timestamptz default now()
);

create table public.students (
  id uuid primary key default gen_random_uuid(),
  class_name text not null,
  roll_no text,
  name text not null,
  father_name text,
  gender text,
  dob date,
  phone text,
  created_by uuid default auth.uid(),
  created_at timestamptz default now()
);

-- Naya user register ho to profile khud ban jaye (default role: teacher)
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, full_name, email)
  values (new.id, new.raw_user_meta_data->>'full_name', new.email);
  return new;
end $$;

create trigger on_auth_user_created after insert on auth.users
for each row execute function public.handle_new_user();

-- Helper functions (RLS recursion se bachne ke liye)
create or replace function public.is_admin() returns boolean
language sql security definer stable set search_path = public as $$
  select exists (select 1 from profiles where id = auth.uid() and role = 'admin');
$$;

create or replace function public.my_class() returns text
language sql security definer stable set search_path = public as $$
  select class_name from profiles where id = auth.uid();
$$;

alter table public.profiles enable row level security;
alter table public.students enable row level security;

-- PROFILES
create policy "own or admin read" on public.profiles for select
  using (id = auth.uid() or public.is_admin());
create policy "admin update" on public.profiles for update
  using (public.is_admin()) with check (public.is_admin());

-- STUDENTS: teacher sirf apni class dekh aur add kar sakta hai, edit/delete nahi
create policy "teacher read own class" on public.students for select
  using (public.is_admin() or class_name = public.my_class());
create policy "teacher add own class" on public.students for insert
  with check (public.is_admin() or class_name = public.my_class());
create policy "admin edit" on public.students for update
  using (public.is_admin()) with check (public.is_admin());
create policy "admin delete" on public.students for delete
  using (public.is_admin());

-- Pehla admin banane ke liye (apni email likhein, register karne ke BAAD run karein):
-- update public.profiles set role = 'admin' where email = 'your@email.com';
