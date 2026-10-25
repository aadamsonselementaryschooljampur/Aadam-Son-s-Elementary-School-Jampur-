-- Aadam Son's v5: Supabase SQL Editor mein run karein
-- 1) Jin users ki profile ban'ne se reh gayi thi unki profile bana do
insert into public.profiles (id, email, full_name)
select u.id, u.email, u.raw_user_meta_data->>'full_name' from auth.users u
on conflict (id) do nothing;

-- 2) User apni profile khud bhi bana sake (sirf teacher role ke saath)
create policy "self insert" on public.profiles for insert
  with check (id = auth.uid() and role = 'teacher');
