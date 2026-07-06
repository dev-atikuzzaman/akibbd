# Supabase দিয়ে Real-Time Sync + Auth সেটআপ

## ১. Database তৈরি করুন
1. https://supabase.com/dashboard → তোমার প্রজেক্ট (spvmhipozacxsczlzpuy) খুলো
2. বাম পাশে **SQL Editor** → **New query**
3. `supabase_schema.sql` ফাইলের পুরো কন্টেন্ট paste করে **Run** চাপো
4. এটা ৪টা টেবিল (posts, courses, infos, embeds), Row-Level Security, একটা like-counter function, আর Realtime enable করে দেবে।

## ২. Auth সেটিংস (জরুরি — নাহলে email link কাজ করবে না)
**Authentication → URL Configuration** এ যাও:
- **Site URL**: তোমার deploy করা URL দাও, যেমন `https://dev-atikuzzaman.github.io/akibbd/`
- **Redirect URLs**: একই URL add করো (Add URL বাটনে)

**Authentication → Providers → Email** এ:
- "Confirm email" ON রাখো (recommended) — signup করলে email confirm করা লাগবে
- Supabase এর ডিফল্ট email service দিয়েই শুরুতে কাজ চলবে (rate-limited, কিন্তু personal ব্যবহারের জন্য যথেষ্ট)। চাইলে পরে নিজের SMTP (Gmail, Resend, ইত্যাদি) যোগ করতে পারো **Authentication → Providers → SMTP Settings** থেকে।

## ৩. নিজের Admin Account বানাও
1. ওয়েবসাইট খুলো → নিচের ডান কোণায় লক আইকনে ক্লিক করো (বা Ctrl+Shift+A)
2. **Sign Up** ট্যাবে গিয়ে নিজের email + password দাও
3. Inbox চেক করে confirmation email এ ক্লিক করো
4. এবার **Sign In** করে ফেলো — তুমি এখন Admin!

## ৪. (Strongly recommended) শুধু তোমার email দিয়েই সাইনআপ আটকাও
এখন যেকেউ ওয়েবসাইটে গিয়ে "Sign Up" চেপে নিজের account বানাতে পারবে (যদিও RLS এর কারণে তারা শুধু নিজেদের content control করতে পারবে, তোমারটা না) — তবু personal site এ এটা বন্ধ রাখাই ভালো:
1. `supabase_schema.sql` ফাইলের একদম শেষে থাকা `/* ... */` কমেন্ট করা অংশটা দেখো
2. `atikuzzaman@example.com` এর জায়গায় তোমার আসল email বসাও
3. `/*` আর `*/` লাইন দুটো মুছে দিয়ে পুরো ব্লকটা SQL Editor এ আলাদাভাবে Run করো

এটা করার **আগেই** নিজের account সাইনআপ করে নিও (ধাপ ৩), কারণ এরপর থেকে ওই একটা email ছাড়া কেউ সাইনআপ করতে পারবে না।

## ৫. Deploy
`index.html`, `manifest.json`, `sw.js`, `icon-192.png`, `icon-512.png` — এই ফাইলগুলো GitHub repo তে upload করো (আগের মতোই GitHub web interface দিয়ে)। `supabase_schema.sql` আর এই `SETUP.md` ফাইল দুটো ডিপ্লয় করার দরকার নেই — শুধু নিজের রেফারেন্সের জন্য রাখো।

## যা যা এখন কাজ করছে
- ✅ **Real Sign Up / Sign In / Forgot Password / Email confirmation** — Supabase Auth দিয়ে, পুরোপুরি সার্ভার-সাইড
- ✅ **Real-time sync** — তুমি যেকোনো ডিভাইস থেকে নতুন Note/Course/Info/Embed যোগ করলে, খোলা থাকা সব ব্রাউজার ট্যাবে সাথে সাথে দেখা যাবে (nav bar এ 🟢 Live ব্যাজ দেখাবে)
- ✅ প্রতিটা Post/Course/Info Section/Embed এ **Edit** ও **Delete** বাটন (শুধু নিজের content এর উপর)
- ✅ প্রতিটাতে **Privacy টগল**: 🌐 সবার জন্য (All) বা 🔒 শুধু আমার জন্য (Only Me) — এটা Postgres Row-Level Security দিয়ে সার্ভার সাইডে enforce করা হয়, শুধু UI hide না
- ✅ Post-এ **Like counter** এখন সার্ভারে সেভ হয় ও সবার কাছে live sync হয়
- ✅ পুরনো localStorage-only content সরিয়ে ফেলা হয়েছে — এখন থেকে সব ডেটা Supabase-এ

## নিরাপত্তা নোট
- এখানে যে "anon key" ব্যবহার হয়েছে সেটা Supabase-এর ডিজাইন অনুযায়ীই client-side কোডে খোলাখুলি থাকার জন্য বানানো (এটা publishable key, secret key না) — আসল সুরক্ষা আসে Row-Level Security policy থেকে, key লুকানো থেকে না।
- `service_role` key (যেটা RLS bypass করে) — এটা **কখনোই** কোনো client-side ফাইলে বসিও না। এই সেটআপে সেটার দরকারও নেই।
