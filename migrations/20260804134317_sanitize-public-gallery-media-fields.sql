CREATE VIEW public.gallery_layouts_public_safe
WITH (security_barrier = true)
AS
SELECT
  trip_slug,
  jsonb_set(
    jsonb_set(
      layout - 'travelStartDate' - 'travelEndDate',
      '{frames}',
      COALESCE(
        (
          SELECT jsonb_agg(
            item.frame - 'photoAssetPaths' - 'photoEdits' - 'title'
            ORDER BY item.ordinality
          )
          FROM jsonb_array_elements(
            COALESCE(layout -> 'frames', '[]'::jsonb)
          ) WITH ORDINALITY AS item(frame, ordinality)
        ),
        '[]'::jsonb
      ),
      true
    ),
    '{trinkets}',
    COALESCE(
      (
        SELECT jsonb_agg(
          jsonb_set(
            item.trinket - 'storageKey',
            '{label}',
            to_jsonb('Gallery decoration'::text),
            true
          )
          ORDER BY item.ordinality
        )
        FROM jsonb_array_elements(
          COALESCE(layout -> 'trinkets', '[]'::jsonb)
        ) WITH ORDINALITY AS item(trinket, ordinality)
        WHERE
          COALESCE(item.trinket ->> 'assetName', '')
            LIKE '%/gallery-trinkets/published-trinkets/%'
          OR (
            COALESCE(item.trinket ->> 'assetName', '') NOT LIKE 'http://%'
            AND COALESCE(item.trinket ->> 'assetName', '') NOT LIKE 'https://%'
            AND COALESCE(item.trinket ->> 'assetName', '') NOT LIKE 'data:%'
            AND COALESCE(item.trinket ->> 'assetName', '')
              !~ '(^|/)assets/(memories|images/japan|images/trips)/'
            AND COALESCE(item.trinket ->> 'assetName', '')
              NOT LIKE '%reference_images/%'
            AND COALESCE(item.trinket ->> 'assetName', '')
              NOT LIKE '/Users/%'
            AND COALESCE(item.trinket ->> 'assetName', '')
              NOT LIKE '/home/%'
          )
      ),
      '[]'::jsonb
    ),
    true
  ) AS layout
FROM public.gallery_layouts;

REVOKE ALL ON public.gallery_layouts_public_safe
  FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.gallery_layouts_public_safe TO anon, authenticated;

-- Full backend branches restore copied views as the managed postgres role,
-- while branch migrations run as project_admin. Skip the legacy-view revoke
-- in that one test-only case; the privileged merge applies it on the parent.
-- Fresh installations create the legacy view as project_admin, so they revoke
-- it here as well.
DO $$
DECLARE
  legacy_owner name;
BEGIN
  SELECT pg_get_userbyid(c.relowner)
  INTO legacy_owner
  FROM pg_class AS c
  WHERE c.oid = 'public.gallery_layouts_public'::regclass;

  IF legacy_owner = current_user THEN
    REVOKE ALL ON public.gallery_layouts_public
      FROM PUBLIC, anon, authenticated;
  END IF;
END;
$$;
