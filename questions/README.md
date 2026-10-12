# بنك أسئلة قدّها

كل فئة بملف لحالها، و`index.json` بيعرّف الفئات والمجموعات وترتيبها. اللعبة بتقرأ الملفات وقت التشغيل.

## سؤال عادي
| الحقل | المعنى |
|---|---|
| `id` | معرّف ثابت، ما بيتغيّر أبدًا (مثلاً `bab-alhara-007`). اللعبة بتستعمله لتتذكّر شو انلعب. |
| `status` | `draft` مسودة، `reviewed` تمّت مراجعته، `published` بيطلع باللعبة. **اللعبة بتعرض `published` بس.** |
| `difficulty` | 1 سهل · 2 متوسط · 3 صعب (اختياري) |
| `q` / `a` | السؤال والجواب |
| `hints` | غشّتين، من الأبعد للأقرب |
| `w` | الخيار الغلط لـ«نُصّ بنُصّ» |
| `sources` | روابط للتأكد من الجواب |

## تحدّي (مثّلها، دندنها، بلا ما تقول)
`id`, `status`, `s` السر، `k` النوع أو المغني، `b` الكلمات الممنوعة.

## السؤال الأخير
`finals.json`: `id`, `status`, `category`, `q`, `a`.

لما ننتقل لقاعدة بيانات، كل ملف بيتحوّل لصفوف بجدول `questions` بنفس الحقول.

## Photo questions («مين هاد بالصورة؟»)

A regular question can carry a picture:

- `img`: path to the image, usually `/questions/img/<id>-<stamp>.jpg` (uploaded from the admin page, resized to 1200px JPEG).
- `f`: where the zoom starts, as `"x% y%"` (default `"50% 35%"`). Set it by clicking the preview in admin.
- `credit`: optional photo credit, shown after the answer.

The picture starts zoomed in ×3; each «غشّة» zooms out (×1.8, then full), and the answer shows it whole. Text hints are optional for photo questions. Photo questions never appear in the final round or the tiebreak.

## Closest-number questions («أقرب رقم»)

A category with `"mode": "num"` in `index.json` holds questions whose answer is a number:

- `n`: the answer as a number (e.g. `1889`, `42.195`).
- `unit`: optional unit shown with the answer («متر», «دولة»). Leave empty for years.
- `a`: display text, filled automatically from `n` and `unit` in admin.

Both teams write a number on paper, then type both into the game. The closest team gets 3 (an exact hit gets +1); equal distance gives each team 1. With «قدّها وقدود»: closest +6, otherwise −3. In-question helpers are off for these. Published number questions are also used for the tiebreaker («سؤال الحسم»); if none are left, the tiebreaker falls back to a written regular question.
