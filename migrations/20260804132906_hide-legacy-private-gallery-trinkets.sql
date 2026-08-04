CREATE OR REPLACE VIEW public.gallery_layouts_public
WITH (security_barrier = true)
AS
SELECT
  trip_slug,
  jsonb_set(
    layout - 'travelStartDate' - 'travelEndDate',
    '{trinkets}',
    COALESCE(
      (
        SELECT jsonb_agg(item.trinket ORDER BY item.ordinality)
        FROM jsonb_array_elements(
          COALESCE(layout -> 'trinkets', '[]'::jsonb)
        ) WITH ORDINALITY AS item(trinket, ordinality)
        WHERE
          COALESCE(item.trinket ->> 'assetName', '')
            NOT LIKE '%/gallery-trinkets/%'
          OR COALESCE(item.trinket ->> 'assetName', '')
            LIKE '%/gallery-trinkets/published-trinkets/%'
      ),
      '[]'::jsonb
    ),
    true
  ) AS layout
FROM public.gallery_layouts;

REVOKE ALL ON public.gallery_layouts_public FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.gallery_layouts_public TO anon, authenticated;
