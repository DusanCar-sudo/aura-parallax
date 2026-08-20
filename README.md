# Aura — scroll site

Single-page site for Aura. One HTML file, five image plates, no build step and no
framework.

## Structure

    index.html          markup, styles and the scroll timeline
    layers/graded/      the five plates the page loads
    prompts/            the image-generation prompts that produced them
    scripts/gimg.sh     regenerate a plate (needs GOOGLE_API_KEY in the env)

## How the scroll works

One sticky stage drives everything from a single normalised scroll value.

1. **AURA** rises out of the dark, then LOOP / MEMORY / ARCHIMEDES each fade up,
   hold, and drift forward.
2. Three hardware plates parallax at different depths underneath.
3. A CRT arrives, powers on, and types its transcript — the typing is a pure
   function of scroll position, so it scrubs backwards.
4. The screen scales up and hands over to the site content.

Two details that matter if you edit it:

- The plates are **black-backgrounded and screen-blended**. Black becomes
  transparent, which is why the stack needs no alpha cutouts.
- The content reveal keys off **raw scroll**, not the eased value. The sticky
  stage releases at a fixed scroll position, so an eased reveal would drop a
  fast scroller into a blank gap.

## Local

    python3 -m http.server 8920

## Deploy

    vercel deploy --prod
