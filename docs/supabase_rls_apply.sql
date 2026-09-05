-- CineTrekker social + library RLS hardening
-- Safe to re-run: uses IF NOT EXISTS / DROP POLICY IF EXISTS patterns.
-- Aligns with Android + web clients (tables: comments, comment_likes,
-- follows / user_follows, notifications, profiles, library tables).

-- ---------------------------------------------------------------------------
-- Helper: enable RLS when table exists
-- ---------------------------------------------------------------------------
do $$
declare
  t text;
begin
  foreach t in array array[
    'profiles',
    'comments',
    'comment_likes',
    'notifications',
    'follows',
    'user_follows',
    'user_watchlist',
    'user_watched',
    'watched_episodes',
    'followed_shows',
    'collections',
    'collection_items'
  ]
  loop
    if to_regclass('public.' || t) is not null then
      execute format('alter table public.%I enable row level security', t);
    end if;
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- Profiles: public profiles readable; owner write
-- ---------------------------------------------------------------------------
do $$
begin
  if to_regclass('public.profiles') is null then
    return;
  end if;

  drop policy if exists "profiles_select_public_or_own" on public.profiles;
  drop policy if exists "Users can view their own profile" on public.profiles;
  drop policy if exists "Users can view public profiles" on public.profiles;

  create policy "profiles_select_public_or_own"
    on public.profiles for select
    using (coalesce(is_public, false) = true or auth.uid() = user_id);

  drop policy if exists "Users can insert their own profile" on public.profiles;
  drop policy if exists "profiles_insert_own" on public.profiles;
  create policy "profiles_insert_own"
    on public.profiles for insert
    with check (auth.uid() = user_id);

  drop policy if exists "Users can update their own profile" on public.profiles;
  drop policy if exists "profiles_update_own" on public.profiles;
  create policy "profiles_update_own"
    on public.profiles for update
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

  drop policy if exists "profiles_delete_own" on public.profiles;
  create policy "profiles_delete_own"
    on public.profiles for delete
    using (auth.uid() = user_id);
end $$;

-- ---------------------------------------------------------------------------
-- Comments
-- ---------------------------------------------------------------------------
do $$
begin
  if to_regclass('public.comments') is null then
    return;
  end if;

  drop policy if exists "comments_select_authenticated" on public.comments;
  drop policy if exists "comments_select_all" on public.comments;
  create policy "comments_select_authenticated"
    on public.comments for select
    to authenticated
    using (true);

  drop policy if exists "comments_insert_own" on public.comments;
  create policy "comments_insert_own"
    on public.comments for insert
    to authenticated
    with check (auth.uid() = user_id);

  drop policy if exists "comments_update_own" on public.comments;
  create policy "comments_update_own"
    on public.comments for update
    to authenticated
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

  drop policy if exists "comments_delete_own" on public.comments;
  create policy "comments_delete_own"
    on public.comments for delete
    to authenticated
    using (auth.uid() = user_id);
end $$;

-- ---------------------------------------------------------------------------
-- Comment likes
-- ---------------------------------------------------------------------------
do $$
begin
  if to_regclass('public.comment_likes') is null then
    return;
  end if;

  drop policy if exists "comment_likes_select_authenticated" on public.comment_likes;
  create policy "comment_likes_select_authenticated"
    on public.comment_likes for select
    to authenticated
    using (true);

  drop policy if exists "comment_likes_insert_own" on public.comment_likes;
  create policy "comment_likes_insert_own"
    on public.comment_likes for insert
    to authenticated
    with check (auth.uid() = user_id);

  drop policy if exists "comment_likes_delete_own" on public.comment_likes;
  create policy "comment_likes_delete_own"
    on public.comment_likes for delete
    to authenticated
    using (auth.uid() = user_id);
end $$;

-- ---------------------------------------------------------------------------
-- Notifications (owner only)
-- ---------------------------------------------------------------------------
do $$
begin
  if to_regclass('public.notifications') is null then
    return;
  end if;

  drop policy if exists "notifications_select_own" on public.notifications;
  create policy "notifications_select_own"
    on public.notifications for select
    to authenticated
    using (auth.uid() = user_id);

  drop policy if exists "notifications_update_own" on public.notifications;
  create policy "notifications_update_own"
    on public.notifications for update
    to authenticated
    using (auth.uid() = user_id)
    with check (auth.uid() = user_id);

  drop policy if exists "notifications_delete_own" on public.notifications;
  create policy "notifications_delete_own"
    on public.notifications for delete
    to authenticated
    using (auth.uid() = user_id);
end $$;

-- ---------------------------------------------------------------------------
-- Follows (web table name) and user_follows (Android table name)
-- ---------------------------------------------------------------------------
do $$
declare
  follow_table text;
begin
  foreach follow_table in array array['follows', 'user_follows']
  loop
    if to_regclass('public.' || follow_table) is null then
      continue;
    end if;

    execute format('drop policy if exists %I on public.%I', follow_table || '_select_authenticated', follow_table);
    execute format(
      'create policy %I on public.%I for select to authenticated using (true)',
      follow_table || '_select_authenticated',
      follow_table
    );

    execute format('drop policy if exists %I on public.%I', follow_table || '_insert_as_follower', follow_table);
    execute format(
      'create policy %I on public.%I for insert to authenticated with check (auth.uid() = follower_id)',
      follow_table || '_insert_as_follower',
      follow_table
    );

    execute format('drop policy if exists %I on public.%I', follow_table || '_delete_own_edges', follow_table);
    execute format(
      'create policy %I on public.%I for delete to authenticated using (auth.uid() = follower_id or auth.uid() = following_id)',
      follow_table || '_delete_own_edges',
      follow_table
    );
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- Library tables: owner-only CRUD when present
-- ---------------------------------------------------------------------------
do $$
declare
  lib text;
begin
  foreach lib in array array[
    'user_watchlist',
    'user_watched',
    'watched_episodes',
    'followed_shows',
    'collections'
  ]
  loop
    if to_regclass('public.' || lib) is null then
      continue;
    end if;

    execute format('drop policy if exists %I on public.%I', lib || '_select_own', lib);
    execute format(
      'create policy %I on public.%I for select to authenticated using (auth.uid() = user_id)',
      lib || '_select_own', lib
    );

    execute format('drop policy if exists %I on public.%I', lib || '_insert_own', lib);
    execute format(
      'create policy %I on public.%I for insert to authenticated with check (auth.uid() = user_id)',
      lib || '_insert_own', lib
    );

    execute format('drop policy if exists %I on public.%I', lib || '_update_own', lib);
    execute format(
      'create policy %I on public.%I for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id)',
      lib || '_update_own', lib
    );

    execute format('drop policy if exists %I on public.%I', lib || '_delete_own', lib);
    execute format(
      'create policy %I on public.%I for delete to authenticated using (auth.uid() = user_id)',
      lib || '_delete_own', lib
    );
  end loop;
end $$;
