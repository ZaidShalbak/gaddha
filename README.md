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
