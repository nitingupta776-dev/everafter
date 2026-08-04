CREATE TABLE public.gallery_layouts (
  trip_slug TEXT PRIMARY KEY,
  layout JSONB NOT NULL,
  strip_width DOUBLE PRECISION NOT NULL,
  travel_start_date DATE,
  travel_end_date DATE,
  revision BIGINT NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT gallery_layouts_layout_is_object
    CHECK (jsonb_typeof(layout) = 'object')
);

ALTER TABLE public.gallery_layouts ENABLE ROW LEVEL SECURITY;

CREATE POLICY gallery_layouts_public_read
  ON public.gallery_layouts
  FOR SELECT TO anon, authenticated
  USING (true);

CREATE POLICY gallery_layouts_admin_insert
  ON public.gallery_layouts
  FOR INSERT TO anon, authenticated
  WITH CHECK (true);

CREATE POLICY gallery_layouts_admin_update
  ON public.gallery_layouts
  FOR UPDATE TO anon, authenticated
  USING (true)
  WITH CHECK (true);

REVOKE ALL ON public.gallery_layouts FROM anon, authenticated;
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON public.gallery_layouts TO anon, authenticated;

CREATE TRIGGER gallery_layouts_updated_at
  BEFORE UPDATE ON public.gallery_layouts
  FOR EACH ROW
  EXECUTE FUNCTION system.update_updated_at();

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

CREATE POLICY gallery_trinkets_public_read
  ON storage.objects
  FOR SELECT TO anon, authenticated
  USING (bucket = 'gallery-trinkets');

CREATE POLICY gallery_trinkets_admin_insert
  ON storage.objects
  FOR INSERT TO anon, authenticated
  WITH CHECK (bucket = 'gallery-trinkets');

CREATE POLICY gallery_trinkets_admin_update
  ON storage.objects
  FOR UPDATE TO anon, authenticated
  USING (bucket = 'gallery-trinkets')
  WITH CHECK (bucket = 'gallery-trinkets');

GRANT USAGE ON SCHEMA storage TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON storage.objects TO anon, authenticated;
