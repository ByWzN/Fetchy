FETCHY MOTION ASSETS
====================

1. fetchy_logo.svg
   Final approved Fetchy mark as a lightweight SVG vector.
   viewBox: 0 0 512 512
   Use for the static final logo.

2. fetchy_logo_anim.svg
   Animation-only duplicate of the final approved geometry.
   viewBox: 0 0 512 512
   Single named path: #morph-final
   Use as the morph destination. Keep the production logo asset untouched.

3. fetchy_hook_start.svg
   Initial hook state for the opening animation.
   viewBox: 0 0 512 512
   Single named path: #hook-start
   Designed as one closed vector shape for path interpolation.

4. fetchy_link.svg
   One chain-link element; repeat 3 times.
   viewBox: 0 0 160 96

5. fetchy_app_icon.svg
   Static preview/composite: dark rounded-square background + final mark.
   viewBox: 0 0 512 512

IMPORTANT MORPH NOTE
Both hook-start and morph-final use one main closed path and the same canvas.
For true path interpolation, a Flutter developer should normalize both SVG paths
to the same number/order of cubic line segments before interpolating numeric points.
Do not morph arbitrary raw SVG commands without normalization.

Flutter suggestion:
- Store under assets/fetchy_motion/
- SVG rendering can use flutter_svg.
- For path morphing, use normalized path data with CustomPainter or another local
  vector/path interpolation approach.
- The link is independent and can be translated/rotated/scaled as needed.

COLOR DIRECTION
Cyan: #18D4F7
Blue: #19B7F2
Deep blue: #1557F2
Background: #0A1020 -> #03060D
