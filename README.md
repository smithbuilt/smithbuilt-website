# Smithbuilt logo package

## Source files (SVG)

These are the master files. Use them whenever possible — they scale to any size without quality loss.

- **smithbuilt-logo.svg** — Primary horizontal lockup. Use for site headers, email signatures, business cards, anywhere on a light background.
- **smithbuilt-mark.svg** — The keycap mark alone. Use for favicons (modern browsers), social avatars, app icons, square contexts.
- **smithbuilt-logo-dark.svg** — Variant for dark backgrounds. Cream keycap frame, cream wordmark, brighter terracotta accent.

## PNG exports (`/exports`)

Pre-rendered raster files for places SVG isn't supported (older email clients, some social media uploaders, OS-level icons).

### Mark sizes (square)
- 16, 32, 48, 64 — favicons and small UI
- 128, 180, 192, 256 — bookmarks, iOS home screen, Android
- 512, 1024 — App Store, marketing collateral

### Logo sizes (horizontal, 4.8:1 ratio)
- 240w, 480w — small site headers, email signatures
- 720w, 960w — standard site headers
- 1200w, 1920w — hero sections, marketing assets

### Dark variant
- 480w, 960w, 1200w on transparent background
- `*-preview-*` versions composited onto a charcoal background so you can see what the dark variant actually looks like in context

## preview.html

Open this in any browser to see the logo system in real-world contexts: website header, hero, footer, business card, favicons at every size, and the color palette.

## Color reference

| Color              | Hex     | Use                           |
| ------------------ | ------- | ----------------------------- |
| Charcoal           | #1A1A1A | Mark frame, "Smith" text      |
| Terracotta · mark  | #C25524 | Keycap inner panel            |
| Terracotta · text  | #A8451F | Wordmark "built" italic       |
| Cream              | #FBF8F2 | Asterisk, dark-variant text   |
| Gray · text        | #5F5E5A | Tagline                       |

## Quick usage

### Favicon in your site `<head>`:
```html
<link rel="icon" href="/smithbuilt-mark.svg" type="image/svg+xml">
<link rel="icon" href="/exports/smithbuilt-mark-32.png" type="image/png">
<link rel="apple-touch-icon" href="/exports/smithbuilt-mark-180.png">
```

### Site header logo:
```html
<img src="/smithbuilt-logo.svg" alt="Smithbuilt" height="36">
```

### Email signature (PNG works in more email clients than SVG):
```html
<img src="https://smithbuilt.com/exports/smithbuilt-logo-480w.png" alt="Smithbuilt" width="240" height="50">
```

## Notes and limitations

The wordmark uses Georgia as the serif. Georgia is on virtually every device, so rendering is consistent. For pixel-perfect type control across all platforms, eventually convert the wordmark text to outlined paths in a vector editor (Inkscape, Figma, Illustrator) — you'll lose the ability to edit the text but gain perfect rendering.

These are working logo files, not a finalized brand identity from a designer. The proportions, curves, and spacing are tuned but not professionally drawn. When you have client revenue justifying it, consider passing this to a designer who can refine the exact letterform spacing, hand-tune the asterisk, and pick a licensed display serif (something like Recoleta, Tiempos, or Fraunces) to replace Georgia.
