# CineTrekker Supabase Row Level Security

Authorization for user-owned data **must** be enforced in Supabase via RLS.
The Android client sends `user_id` / `follower_id` in payloads for convenience only —
never treat client filters as security.

Apply these policies (or equivalent) in the Supabase SQL editor before Play Store release.
Adjust table/column names if your schema differs.

```sql
-- Enable RLS on all user-owned tables
alter table public.profiles enable row level security;
alter table public.comments enable row level security;
alter table public.comment_likes enable row level security;
alter table public.notifications enable row level security;
alter table public.user_follows enable row level security;
alter table public.watchlist enable row level security;
alter table public.favorites enable row level security;
alter table public.watched enable row level security;
alter table public.tv_progress enable row level security;
alter table public.collections_user enable row level security;

-- Profiles: public read for public profiles; owner write
create policy "profiles_select_public_or_own"
  on public.profiles for select
  using (is_public = true or auth.uid() = user_id);

create policy "profiles_insert_own"
  on public.profiles for insert
  with check (auth.uid() = user_id);

create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "profiles_delete_own"
  on public.profiles for delete
  using (auth.uid() = user_id);

-- Comments: anyone authenticated can read; author writes
create policy "comments_select_authenticated"
  on public.comments for select
  to authenticated
  using (true);

create policy "comments_insert_own"
  on public.comments for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "comments_update_own"
  on public.comments for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "comments_delete_own"
  on public.comments for delete
  to authenticated
  using (auth.uid() = user_id);

-- Comment likes
create policy "comment_likes_select_authenticated"
  on public.comment_likes for select
  to authenticated
  using (true);

create policy "comment_likes_insert_own"
  on public.comment_likes for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "comment_likes_delete_own"
  on public.comment_likes for delete
  to authenticated
  using (auth.uid() = user_id);

-- Notifications: owner only
create policy "notifications_select_own"
  on public.notifications for select
  to authenticated
  using (auth.uid() = user_id);

create policy "notifications_update_own"
  on public.notifications for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "notifications_delete_own"
  on public.notifications for delete
  to authenticated
  using (auth.uid() = user_id);

-- Follows: visible to authenticated; mutate own edges
create policy "user_follows_select_authenticated"
  on public.user_follows for select
  to authenticated
  using (true);

create policy "user_follows_insert_as_follower"
  on public.user_follows for insert
  to authenticated
  with check (auth.uid() = follower_id);

create policy "user_follows_delete_own_edges"
  on public.user_follows for delete
  to authenticated
  using (auth.uid() = follower_id or auth.uid() = following_id);

-- Library tables (watchlist / favorites / watched / tv_progress): owner only
-- Repeat the pattern below for each library table, substituting table name.
-- Example for watchlist:

create policy "watchlist_select_own"
  on public.watchlist for select
  to authenticated
  using (auth.uid() = user_id);

create policy "watchlist_insert_own"
  on public.watchlist for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "watchlist_update_own"
  on public.watchlist for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "watchlist_delete_own"
  on public.watchlist for delete
  to authenticated
  using (auth.uid() = user_id);
```

## Verification checklist

1. Sign in as User A and create watchlist / follow / comment rows.
2. Sign in as User B with the anon key + User B JWT.
3. Confirm User B cannot `select`/`update`/`delete` User A's private rows via REST.
4. Confirm account deletion removes both `follower_id` and `following_id` edges.
5. Confirm public profiles remain readable when `is_public = true`.

> Table names in this repo’s client code: `comments`, `comment_likes`, `notifications`,
> `user_follows`, `profiles`, plus library tables used by `UserLibraryRepository`.
> Align policy names with your actual schema before applying in production.
