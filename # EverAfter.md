# EverAfter

### Technical Specification v0.1

> *A museum of my travels.*
>
> Every souvenir tells a story.

---

# Overview

EverAfter is a local-first interactive museum that transforms physical travel souvenirs into immersive digital exhibits.

Each travel magnet contains an NFC tag. When placed near the museum display, the system recognizes the artifact and opens a curated multimedia experience containing photos, videos, maps, journals, music and memories.

The goal is **not** to build a photo gallery.

The goal is to recreate the feeling of walking through a museum where every object tells its own story.

---



# Product Vision



## Philosophy

Travel memories deserve more than folders.

EverAfter treats every trip as an exhibition.

Instead of browsing albums, visitors interact with physical artifacts.

```
Artifact

↓

Scan

↓

Museum Exhibit

↓

Story
```

---

## Visual Inspiration

The interface should feel like:

- An old museum guide
- A travel journal
- A scrapbook
- Vintage postcards
- Archival documents
- Botanical books
- Library catalogues
- Exhibition labels

Avoid:

- Neon
- Glassmorphism
- Corporate SaaS
- Dashboard UI
- Material Design
- Generic mobile apps

---



## Color Palette



### Paper

```
#F6F1E8
```



### Aged Paper

```
#E8DDCA
```



### Ink

```
#2A2725
```



### Warm Brown

```
#8A6546
```



### Olive

```
#76826A
```



### Burgundy

```
#7B4A43
```



### Brass

```
#B98C48
```

---



## Typography



### Display

Elegant serif.

Examples:

- Cormorant Garamond
- Canela
- EB Garamond

Used for:

- Destination names
- Titles
- Section headers

---



### Body

Readable serif.

Examples:

- Crimson Pro
- Spectral
- Libre Baskerville

---



### Metadata

Small caps.

Used for:

- Dates
- Coordinates
- Countries
- Museum labels

---



# Interaction Principles

The interface should feel:

- Calm
- Intentional
- Slow
- Cinematic

Animations should never feel "app-like."

Every interaction should resemble opening an exhibit.

---



# User Flow

```
Idle

↓

NFC detected

↓

Artifact intro

↓

Tap to begin

↓

Exhibit

↓

Explore

↓

Exit

↓

Idle
```

---



# Idle State

The museum waits for an artifact.

Display shows:

- everafter logo
- Ambient particles
- Paper textures
- Slowly changing light
- Current collection count (trips)

Example:

```
Museum of My Travels

28 Artifacts

12 Countries

Waiting for an artifact...
```

---



# Artifact Detection

User places magnet near reader.

System immediately:

- detects NFC UID
- loads exhibit metadata
- prepares media
- starts intro animation

---



# Intro Experience

The intro is the emotional hook.

Instead of immediately showing photos:

Display:

- scanned 3D souvenir
- floating pedestal
- soft spotlight
- slow rotation

```
Hong Kong

May 2026

Tap to Begin
```



---



# Exhibit Structure

Every trip follows the same museum layout.

```
Cover

↓

Journey (TBD)

↓


End
```

---



# Collection

Shows all trips as museum artifacts.

Not folders.

```
Japan

Hong Kong

Iceland

Norway

Italy
```

---

# Software Architecture

```
            Flutter UI

                  ↑

           Event Bus

                  ↑

          NFC Service

                  ↑

             PN532

```

---



# Tech Stack



## UI

Flutter

---



## Language

Dart

---



## State Management

Riverpod

---



## Navigation

GoRouter

---



## Animations

Flutter Animation Framework

Custom Curves

Hero

Implicit animations

---

# NFC Flow

```
Tap Magnet

↓

Read UID

↓

Lookup Trip

↓

Load Assets

↓

Play Intro

↓

Wait for Tap

↓

Enter Exhibit
```

---

# Animation Style

Motion should resemble:

- museum lighting
- theatre curtains
- gallery transitions

Avoid:

- bouncing
- flashy motion
- exaggerated easing

Preferred:

- fade
- dissolve
- slow scale
- parallax paper
- soft blur
- spotlight

---



# Sound Design

Ambient only.

Examples:

- museum ambience
- distant footsteps
- page turns
- projector hum
- birds
- train stations
- rain
- ocean

Music fades in after entering the exhibit.

---

