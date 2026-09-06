# Reforma zgjedhore

A static, Albanian-first website explaining the proposed amendments to Albania’s Electoral Code, with physical-signature instructions, volunteer recruitment, original downloads, and an English overview.

## Preview

From this folder:

```sh
python3 -m http.server 8000 --bind 127.0.0.1
```

Open http://127.0.0.1:8000. No installation or build is required. `index.html` can also be opened directly; the essential content, downloads, and contact links work without JavaScript.

## Edit

- `index.html`: Albanian content, 15 proposal topics with draft/Code references, signing, volunteering, FAQ and document library.
- `en.html`: English overview and participation instructions.
- `assets/style.css`: shared responsive design and print/reduced-motion styles.
- `assets/main.js`: mobile navigation and opening linked topics. Native HTML details provide the expandable sections.
- `assets/favicon.svg`: site icon.
- `reformazgjedhore-qr.svg`: source QR code linking to the website; it is embedded in the three downloadable leaflets.
- The downloadable PDF/DOCX source files are kept in the project root. The three leaflets have been updated visually to reflect the pending deadline extension.

Update both pages when changing the coordination contact or participation instructions. Keep `tel:+355694382248`, `https://wa.me/355694382248`, and `mailto:edmondcata@hotmail.com` consistent. Volunteer WhatsApp links include an encoded introductory message.

## Content decisions

See `CONTENT_REVIEW.md` for source precedence and unresolved drafting/source discrepancies. The page shows the 20,000-signature requirement and the announced 15 September 2026 deadline. Per the organizer’s update, an extension is expected soon; no new date or live signature count is asserted. The latest instructions offer three delivery routes after physical signing: a local collector, direct post, or a scan emailed to `veprimi.qytetar@gmail.com`. Postal and volunteer coordination remain with the team at the existing contact details.

No data is collected by the website. Contact links open telephone, WhatsApp, or email services. There is no signature submission or volunteer registration backend.

## Verification

The dependency-free `scripts/check-browser.mjs` uses Node 22+ and Chrome’s DevTools protocol. With the preview server running and an isolated Chrome debugging instance on port 9223:

```sh
node scripts/check-browser.mjs
```

On macOS, an isolated headless browser can be started with:

```sh
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless --disable-gpu --no-first-run --user-data-dir=/tmp/electoral-chrome-review --remote-debugging-port=9223 about:blank
```

The checks cover responsive overflow, local anchors/downloads, PDF responses, contact destinations, native keyboard expansion, mobile navigation, deep links, reduced motion and no-JavaScript content. Screenshots are saved under `/tmp/electoral-*.png`. Contact destinations are inspected without sending messages or initiating calls.

## Hosting later

Nothing has been publicly deployed. Serve `index.html`, `en.html`, `assets/`, and the six downloadable documents linked in the document library. Do not upload the entire working folder: private editor files, review notes, and the unrelated source documents are not site assets. Keep document filenames unchanged, because links reference them directly. Add the real production URL and a social preview image when a domain is chosen.

Verified in headless Chrome on 6 September 2026: both languages, 320–1440px layouts, all six document downloads, PDF file responses, same-page and cross-page anchors, native keyboard expansion, mobile menu/Escape, signing-section scroll position, contact URLs, reduced motion, and no-JavaScript navigation/content. No page JavaScript exceptions were reported. Main text/button color pairs exceed 4.5:1 contrast. Desktop, mobile and English screenshots were visually reviewed. Full-page captures run after interaction checks because Chrome capture can affect emulated scrolling state.
