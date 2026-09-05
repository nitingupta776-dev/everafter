#!/usr/bin/env python3
"""
Sync assets/memories/ subfolders → assets/data/memory_collections.json

Run after dropping photos into any assets/memories/<folder>/ directory:
    python3 tool/sync_memory_collections.py

The script:
  - Scans every subfolder of assets/memories/
  - Adds or updates that trip's collection entry with all found photos/videos
  - Does NOT touch trip entries for slugs not present on disk
  - Preserves all other collections unchanged
"""

import json
import os
import sys

MEMORIES_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'memories')
COLLECTIONS_JSON = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data', 'memory_collections.json')

PHOTO_EXTS = {'.jpg', '.jpeg', '.png', '.heic', '.gif', '.webp'}
VIDEO_EXTS = {'.mp4', '.mov'}
FALLBACK_POSTER = 'assets/images/experience/earth-globe-fallback.png'


def slug_from_folder(folder_name: str) -> str:
    """Convert a folder name like 'tulip_farms' to the trip slug 'tulip-farms'."""
    return folder_name.lower().replace('_', '-').replace(' ', '-')


def scan_folder(folder_path: str, folder_name: str, label: str) -> dict:
    files = sorted(os.listdir(folder_path))
    asset_paths = []
    video_poster_paths = {}

    for f in files:
        ext = os.path.splitext(f)[1].lower()
        if ext not in PHOTO_EXTS and ext not in VIDEO_EXTS:
            continue
        path = f'assets/memories/{folder_name}/{f}'
        asset_paths.append(path)
        if ext in VIDEO_EXTS:
            video_poster_paths[path] = FALLBACK_POSTER

    return {
        'slug': f'{slug_from_folder(folder_name)}-trip',
        'label': label,
        'assetPaths': asset_paths,
        'videoPosterPaths': video_poster_paths,
    }


def title_case(name: str) -> str:
    return ' '.join(word.capitalize() for word in name.replace('_', ' ').replace('-', ' ').split())


def main():
    memories_dir = os.path.normpath(MEMORIES_DIR)
    collections_path = os.path.normpath(COLLECTIONS_JSON)

    if not os.path.isdir(memories_dir):
        print(f'ERROR: memories folder not found: {memories_dir}', file=sys.stderr)
        sys.exit(1)

    with open(collections_path, 'r', encoding='utf-8') as f:
        data = json.load(f)

    collections = data.setdefault('collections', {})
    updated = []

    for folder_name in sorted(os.listdir(memories_dir)):
        folder_path = os.path.join(memories_dir, folder_name)
        if not os.path.isdir(folder_path):
            continue

        trip_slug = slug_from_folder(folder_name)
        label = title_case(folder_name)
        entry = scan_folder(folder_path, folder_name, label)

        if not entry['assetPaths']:
            if collections.get(trip_slug):
                collections[trip_slug] = []
                updated.append((folder_name, 0, 0))
                print(f'  clear {folder_name}/  (folder is empty, references cleared)')
            else:
                print(f'  skip  {folder_name}/  (no recognized files)')
            continue

        # Preserve existing slug/label if already set
        existing = collections.get(trip_slug, [])
        if existing and isinstance(existing, list) and existing:
            entry['slug'] = existing[0].get('slug', entry['slug'])
            entry['label'] = existing[0].get('label', entry['label'])

        collections[trip_slug] = [entry]
        updated.append((folder_name, len(entry['assetPaths']), len(entry['videoPosterPaths'])))
        print(f'  sync  {folder_name}/  {len(entry["assetPaths"])} files ({len(entry["videoPosterPaths"])} videos)')

    with open(collections_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write('\n')

    print(f'\nDone: {len(updated)} folder(s) synced into {os.path.basename(collections_path)}')
    if updated:
        print('Restart the app (hot restart) to pick up the changes.')


if __name__ == '__main__':
    main()
