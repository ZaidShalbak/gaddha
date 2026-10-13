# قدّها · Gaddha

لعبة أسئلة عربية لفريقين على شاشة وحدة: أسئلة صعبة، «غشّشني» بتنزّل قيمة السؤال، سبع مساعدات، تحديات تمثيل ودندنة ووصف بكود QR، وسؤال أخير بالرهان.

- `index.html`: اللعبة كاملة (ملف واحد).
- `r/index.html`: صفحة السر اللي بيفتحها كود QR بجوال اللاعب. السر بيكون بعد «#» بالرابط، فما بيوصل للسيرفر.
- `manifest.webmanifest` و `icon*`: عشان «أضف إلى الشاشة الرئيسية».

يُنشر على Vercel كموقع ثابت بدون أي إعدادات بناء.

## لوحة التحكم (`/admin`)
مراجعة الأسئلة وتغيير حالتها (مسودة، تمت المراجعة، منشور)، إضافة أسئلة وفئات ومجموعات، نقل الفئات بين المجموعات، وإخفاؤها عن اللاعبين.
التعديلات بتنحفظ كـ commit واحد بهالمستودع، وVercel بينشرها تلقائيًا. الدخول بمفتاح GitHub (fine-grained token) إله صلاحية Contents: Read and write على `gaddha` بس.

## Online features (Supabase)

`sb.js` holds the Supabase project URL and **publishable** key (public by design). The database is set up by running `supabase/schema.sql` once in the Supabase SQL Editor; tables are locked and only reachable through its functions.

- **Live drawing** («ارسمها» on the phone): the phone page `/r/` broadcasts strokes on the Realtime channel `gaddha-draw-<room>`; the main screen mirrors them.
- **Host phone** (`/h/#<room>`): from the «جوال المضيف» button during a game. The host sees answers and hints and can open categories, use «غشّشني», steal, reveal and award. Channel `gaddha-host-<room>`.
- **«قدّنا؟» by link** (`/w/#<circle>`): the family screen creates a circle (`create_circle`), shares the link on WhatsApp, and pulls secrets with the private host key (`get_secrets`). The key stays in that device's browser.

If the keys are removed or Supabase is unreachable, these features hide or fall back and the game works offline as before.

## Accounts (Supabase Auth)

Optional login with a 6-digit email code (Google can be switched on later with `google:true` in `sb.js`). Run `supabase/auth.sql` once; it adds `profiles` (name, group name, colour), `nights` (one row per finished game) and `delete_my_account()`. The email templates "Magic Link" and "Confirm signup" must include `{{ .Token }}` so the email carries the code. The supabase-js library loads only when someone signs in or already has a saved session.

## Codes («عندي كود»)

Hand-sold night passes and plans, before any payment provider is connected.

- **Setup (once):** run `supabase/codes.sql` in Supabase → SQL Editor, then make your account an admin with the one-line insert at the top of that file (the admin page shows it with your email filled in).
- **Create:** admin → «الأكواد» → sign in with your Gaddha account → choose the kind and how many → copy the message or send it on WhatsApp. Codes look like `QD-7K3M-P9XA` and work once.
- **Redeem:** players open the link (`/?redeem=CODE`) or «عندي كود» in the home footer, log in, and the code is added to their account. A second year stacks on the first.
- **Safety:** codes and plans are only reachable through database functions; only admins can create codes; 10 wrong guesses in an hour blocks an account for an hour.
- **Today:** all categories are open to everyone during the trial, so a code is stored as a pre-order and takes effect once the free plan limits switch on.
