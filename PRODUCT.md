# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Arab families and friend groups at evening gatherings («سهرة»), mixed ages from teenagers to grandparents. Palestine first, then Jordan and the wider Middle East.

One person hosts: the game runs on a phone, tablet or laptop, often cast to the living-room TV, and everyone answers out loud. Two teams play against each other. Other phones join for specific moments: writing family secrets, seeing a hidden word for a challenge, judging the other team in «بزايد عليك», or running the night as host from «جوال المضيف».

## Product Purpose

«قدّها» is an Arabic trivia party game for a night together: teams pick categories, take turns on a board of questions, use helpers, and finish with a final envelope round. It exists to make family and friend nights louder, funnier and more competitive, with questions that feel like *them*. Success is a family playing a full night, arguing and laughing, and wanting to play again.

## Positioning

What a neighbouring game (Seenjeem and similar) cannot truthfully copy:

- **«قدّنا؟»**: questions the family or group writes about itself, passed around one device or collected from phones by a WhatsApp link. No app can have your family's secrets.
- **Palestinian and Levantine content**: towns and villages, grandma's food, embroidery and folk songs, the old people's words, alongside general categories.
- **Warm Levantine dialect** throughout, not formal Arabic.
- **Rounds of its own**: «بزايد عليك» (bidding, with the other team judging from their phone), «الظرف الأخير» (the final envelope with multipliers), «على النار» (streak bonus), helpers and sabotage.

## Operating Context

- Played in living rooms, usually on the TV, sometimes on one phone or tablet passed around.
- The host reads questions aloud and controls the game; players answer verbally.
- A night: choose up to 6 categories (plus «قدّنا؟») → each team picks 3 of 7 helpers → play the board → «ملك أو كتابة» and the final envelope → tie-break question if needed → titles of the night.
- Phones are secondary screens: secret words and pictures via QR, live drawing, the judge page, the host phone.

## Capabilities and Constraints

- Single-file web app (`index.html`) on Vercel, with Supabase for accounts, codes, feedback, family circles, live phone links and the question bank. Works offline from the last saved copy of the questions.
- Questions are managed in the admin page (`/admin`) by admins with a Gaddha account.
- Business model: free first game, a one-night pass, and a subscription as the main offer; redeemable codes exist now. Payments are not built yet.
- Playing without login is allowed for now; login will be required in the future.
- A mobile app is planned alongside the web app.
- The owner does not want to spend money (paid services, developer accounts) until the game is solid and bringing revenue.

## Brand Commitments

- Name: «قدّها» (Gaddha). The question it asks: «إنتو قدّها؟».
- Voice: friendly Palestinian/Levantine dialect everywhere, never formal or corporate.
- Family-safe: Palestinian identity and culture are welcome; current conflict and politics are not.

## Evidence on Hand

- About 1,100 reviewed questions in 44 categories across 6 groups (`questions/`, now in Supabase), plus challenge word lists.
- Custom category illustrations (`art.js`) and app icons (`icon.svg`, `icon-192.png`, `icon-512.png`).
- Launch teasers on the design canvas.
- No testimonials, user numbers, press or reviews yet. Do not invent any.

## Product Principles

1. **The room is the user.** Design for a group around one screen, not one person on a phone.
2. **Feels like us.** Dialect, content and humour should feel local and personal, never translated or generic.
3. **Competition with warmth.** Raise the stakes and the drama, but nobody should feel stupid or left out.
4. **The host stays in control** without slowing the night down.

## Accessibility & Inclusion

- **Readable from the couch**: game screens (board, question, scores, results) must work from across a living room on a TV.
- Right-to-left Arabic throughout.
