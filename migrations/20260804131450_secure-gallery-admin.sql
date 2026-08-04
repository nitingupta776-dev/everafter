CREATE TABLE public.gallery_admins (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.gallery_admins ENABLE ROW LEVEL SECURITY;

CREATE POLICY gallery_admins_self_read
  ON public.gallery_admins
  FOR SELECT TO authenticated
  USING (user_id = (SELECT auth.uid()));

REVOKE ALL ON public.gallery_admins FROM PUBLIC, anon, authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT ON public.gallery_admins TO authenticated;

CREATE FUNCTION public.is_gallery_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.gallery_admins
    WHERE user_id = (SELECT auth.uid())
  );
$$;

REVOKE ALL ON FUNCTION public.is_gallery_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_gallery_admin() TO authenticated;

DROP POLICY IF EXISTS gallery_layouts_public_read
  ON public.gallery_layouts;
DROP POLICY IF EXISTS gallery_layouts_admin_insert
  ON public.gallery_layouts;
DROP POLICY IF EXISTS gallery_layouts_admin_update
  ON public.gallery_layouts;

CREATE POLICY gallery_layouts_admin_read
  ON public.gallery_layouts
  FOR SELECT TO authenticated
  USING ((SELECT public.is_gallery_admin()));

CREATE POLICY gallery_layouts_admin_insert
  ON public.gallery_layouts
  FOR INSERT TO authenticated
  WITH CHECK ((SELECT public.is_gallery_admin()));

CREATE POLICY gallery_layouts_admin_update
  ON public.gallery_layouts
  FOR UPDATE TO authenticated
  USING ((SELECT public.is_gallery_admin()))
  WITH CHECK ((SELECT public.is_gallery_admin()));

REVOKE ALL ON public.gallery_layouts FROM anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON public.gallery_layouts TO authenticated;

CREATE VIEW public.gallery_layouts_public
WITH (security_barrier = true)
AS
SELECT
  trip_slug,
  layout - 'travelStartDate' - 'travelEndDate' AS layout
FROM public.gallery_layouts;

REVOKE ALL ON public.gallery_layouts_public FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.gallery_layouts_public TO anon, authenticated;

CREATE TABLE public.gallery_upload_windows (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  window_started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  upload_count INTEGER NOT NULL DEFAULT 0 CHECK (upload_count >= 0)
);

ALTER TABLE public.gallery_upload_windows ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.gallery_upload_windows FROM PUBLIC, anon, authenticated;

CREATE FUNCTION public.claim_gallery_upload_slot(
  p_user_id UUID,
  p_limit INTEGER DEFAULT 10
)
RETURNS BOOLEAN
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = pg_catalog, public, pg_temp
AS $$
DECLARE
  allowed BOOLEAN;
BEGIN
  IF p_limit < 1 OR p_limit > 60 OR NOT EXISTS (
    SELECT 1
    FROM public.gallery_admins
    WHERE user_id = p_user_id
  ) THEN
    RETURN FALSE;
  END IF;

  INSERT INTO public.gallery_upload_windows AS windows (
    user_id,
    window_started_at,
    upload_count
  )
  VALUES (p_user_id, clock_timestamp(), 1)
  ON CONFLICT (user_id) DO UPDATE
  SET
    window_started_at = CASE
      WHEN windows.window_started_at < clock_timestamp() - INTERVAL '1 minute'
        THEN clock_timestamp()
      ELSE windows.window_started_at
    END,
    upload_count = CASE
      WHEN windows.window_started_at < clock_timestamp() - INTERVAL '1 minute'
        THEN 1
      ELSE windows.upload_count + 1
    END
  WHERE
    windows.window_started_at < clock_timestamp() - INTERVAL '1 minute'
    OR windows.upload_count < p_limit
  RETURNING TRUE INTO allowed;

  RETURN COALESCE(allowed, FALSE);
END;
$$;

REVOKE ALL ON FUNCTION public.claim_gallery_upload_slot(UUID, INTEGER)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.claim_gallery_upload_slot(UUID, INTEGER)
  TO project_admin;

DROP POLICY IF EXISTS gallery_trinkets_admin_insert
  ON storage.objects;
DROP POLICY IF EXISTS gallery_trinkets_admin_update
  ON storage.objects;

REVOKE INSERT, UPDATE, DELETE ON storage.objects FROM anon, authenticated;
