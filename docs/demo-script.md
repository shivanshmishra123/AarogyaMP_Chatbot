# AarogyaMP — Demo Script

> Use this when demoing to stakeholders or running end-to-end manual tests.
> All personas and doctors are synthetic test data — see Reference §16.

## Prerequisites

- Backend running: `docker compose up` from `server/`
- App running: `flutter run --dart-define=USE_MOCKS=false --dart-define=API_BASE_URL=http://<IP>:8000`
- Or mock mode: `flutter run --dart-define=USE_MOCKS=true`

---

## Flow 1: Patient — MODERATE risk assessment → contact doctor

1. Login as patient (test credentials in README or `.env`)
2. Home screen → "How are you feeling today?" → tap **Text**
3. Enter: *"I have fever since two days, headache and body pain. Feeling weak."*
4. Next → Vitals form: Temp 102°F, HR 98, BP 130/85, SpO₂ 96%
5. Submit → Assessment Result card should show:
   - 🟡 **MODERATE RISK**
   - Possible causes: Viral/febrile illness (high), Influenza-like illness (medium)
   - Recommendation: "Consult a physician..."
   - ⚠ AI disclaimer rendered (mandatory)
   - Button: "Find a General Physician near me"
6. Tap button → Doctor Directory → filter General Physician
7. Tap Dr. Ananya Sharma → Profile: Call / Email / Chat buttons
8. Tap **Chat** → Chat window opens → send a message
9. ✅ PASS if all steps complete without errors

---

## Flow 2: Emergency path — vitals-triggered

1. Login as patient
2. Enter symptoms: *"I am having difficulty breathing and feel very confused."*
3. Vitals: Temp 103.5°F, HR 140, BP 85/50, SpO₂ 85%
4. Submit → **EMERGENCY screen must appear full-screen immediately**
5. ✅ PASS if:
   - Emergency screen shown (red, full-screen)
   - NO possible-causes list shown
   - NO dismiss button
   - `ai_status` in response is `"skipped"` (check logs)

---

## Flow 3: Doctor role — view queue and respond

1. Login as doctor (verified account)
2. Doctor Queue → see patient from Flow 1
3. Tap patient → Patient Detail: symptoms + vitals + AI assessment (labeled "AI-generated, not a diagnosis")
4. Tap Chat → respond to patient message
5. ✅ PASS if chat message appears on both sides

---

## What to check for in every demo

- [ ] Disclaimer line renders on every non-emergency assessment
- [ ] No screen says "diagnosis" or implies a confirmed condition
- [ ] Unverified doctors never appear in directory
- [ ] Emergency screen is visually and structurally distinct from assessment result
- [ ] Voice input shows transcript for review/edit before submit
