# Product Requirements Document: PaySnip

## 1. Overview
### 1.1 Product Name
PaySnip

### 1.2 Purpose
A mobile app to simplify group bill splitting by snapping receipts, parsing items with AI, and sharing payment links (Venmo/PayPal) via a web page, requiring no app for recipients. Targets instant ROI: $10-20 saved per split (time/drama) for a $4.99-12 price.

### 1.3 Target Audience
- **Primary**: Freelancers, roommates, travelers (20M+ Venmo users, 400M+ PayPal users).
- **Use Cases**: Splitting dinner bills, group trip expenses, shared groceries.
- **Paying Users**: Individuals who initiate splits, seeking convenience (e.g., Splitwise’s 20M users pay $9.99/yr for premium).

### 1.4 Value Proposition
Snap a receipt, split costs in 10 seconds, send payment links—friends pay without an app. Saves time/money ($10-20 per split) with a privacy-first, crash-proof experience.

## 2. Success Metrics
- **Revenue**: $1-5k MRR in 3 months (100-1k paying users at $4.99/mo or $12 one-time).
- **Engagement**: 500 active users, avg. 5 splits/mo in month 1.
- **Retention**: 30% free-to-paid conversion (like indie apps hitting $5k MRR).
- **Virality**: 10k+ X post views via demo gifs; 5% user growth from shared links.

## 3. Key Features
### 3.1 Receipt Capture & OCR
- **Description**: User takes a photo of a receipt; app extracts text using MLKit OCR (free <1k scans/mo).
- **Requirements**:
  - Camera access for photo capture (iOS/Android permissions).
  - MLKit integration (`google_ml_kit`) for text extraction (80% accuracy on clean receipts).
  - Fallback: Manual text input for low-quality scans.
  - Cache photo locally (crash recovery).

### 3.2 AI Parsing to JSON
- **Description**: Grok API parses OCR text into structured JSON (`[{item: "Burger", price: 12.99}, ...], total: 50.99`).
- **Requirements**:
  - HTTP POST to `https://api.x.ai/v1/chat/completions` (Grok-4-fast, ~$0.0001/scan).
  - Prompt: “Parse receipt to JSON: [{item, price}], total key. Prices as numbers.”
  - ~500 input tokens, 150 output tokens per scan.
  - Cache JSON locally for retries (crash-proof).

### 3.3 Split Calculation
- **Description**: User splits costs evenly (e.g., $50/4 = $12.50) or assigns items (e.g., “Bob: Burger”).
- **Requirements**:
  - UI: Input number of people or select items per person.
  - Logic: Parse JSON for even (`total / numPeople`) or custom (sum assigned items).
  - Display split preview (e.g., “Bob: $18.98 (Burger, Fries)”).

### 3.4 Payment Link Sharing
- **Description**: Generate a web link (`paysnip.app/split/xyz123`) with split details and Venmo/PayPal buttons; friends pay without app.
- **Requirements**:
  - Firebase Firestore to store split data (`{id, items, assignments, venmo, paypal}`).
  - Firebase Hosting for web page (free <10k views/mo).
  - Web page HTML: `<a href="venmo://pay?recipients=@user&amount=12.50">Pay</a>`.
  - Share via native share sheet (`share_plus`): Text, WhatsApp, X, Email.
  - QR code option (`qr_flutter`) for in-person scans.
  - Watermark: “Split with PaySnip” for virality.

### 3.5 Payment Details Setup
- **Description**: User enters Venmo username (@user) or PayPal email/link once, stored securely.
- **Requirements**:
  - UI: Onboarding/settings screen with text fields for Venmo/PayPal.
  - Store encrypted in Firestore (`users/{userId}`).
  - Skip option (use later in settings).
  - No OAuth for MVP—manual entry (public handles, safe).

### 3.6 PDF Export
- **Description**: Export split summary as PDF (e.g., “Dinner Split: Bob $18.98”).
- **Requirements**:
  - Use `pdf` package, GZIP compress for size (SDK commit).
  - Share via email or save to device.

### 3.7 Privacy & Stability
- **Description**: Privacy-first logging, crash-proof experience.
- **Requirements**:
  - WatchLane-style logging for API calls/splits (no user data leaks).
  - Cache OCR/JSON locally (crash recovery commit).
  - No friend data stored—links are stateless.

## 4. Technical Requirements
- **Platform**: iOS (14+), Android (9+).
- **Stack**:
  - **Frontend**: Flutter (cross-platform, Dart). Packages: `google_ml_kit`, `camera`, `http`, `cloud_firestore`, `firebase_auth`, `share_plus`, `pdf`, `qr_flutter`, `uuid`.
  - **Backend**: Firebase Auth (email/Google SSO), Firestore (splits/users), Hosting (web links).
  - **AI**: Grok API (`https://api.x.ai/v1`, ~$0.0001/scan, free tier via X Premium).
- **Costs**: ~$0.50/mo for 5k scans (500 users × 10). Firebase free tier (<50k writes, <10k hosting views).
- **Stability**: Cache data locally, retry on API fail (crash recovery logic).

## 5. Monetization
- **Freemium**: Free 5 scans/mo ($0.0005 Grok cost). $4.99/mo or $29/yr for unlimited scans, custom splits, ad-free PDFs.
- **Micro-Pays**: $0.49/scan post-free ($0.48 margin). Bundle: $2.99 for 10.
- **Revenue Goal**: $1k/mo at 200 subs vs. $0.50 API cost.
- **Why**: One $20 split saves $10 > $4.99 price. Splitwise’s $9.99/yr hits 20M users.

## 6. Marketing & Launch
- **Build in Public**:
  - X: “Snapped receipt, grok split $100 in 10 secs, web links sent 📸, who hates bill fights? #indiehacker #buildinpublic #PaySnip”
  - Threads: “Snapped receipt, ai split $100, web links—no app for friends, what’s your bill split mess?”
  - Gif demos (snap-to-split) hit 10-15k views.
- **Validation**: X poll: “Pay $5/mo to split bills in 10 secs, no friend app?”
- **Launch**: App Store, Product Hunt (lifestyle), r/Frugal, r/SmallBusiness.
- **Growth**: Watermarked links drive 5% user growth.

## 7. MVP Scope (2 Weeks)
- **Week 1**: Flutter UI (camera, payment input), MLKit OCR, Grok JSON parsing.
- **Week 2**: Split logic, Firebase web links, share sheet, PDF export.
- **Features**:
  - Snap receipt, parse to JSON.
  - Even/custom split, generate web link.
  - Share via text/X, QR code.
  - Payment setup (Venmo/PayPal).
  - PDF export.
- **Out of Scope**: Venmo API, contact saving, analytics (add post-MVP).

## 8. Dependencies
- **Flutter Packages**: `google_ml_kit`, `camera`, `http`, `cloud_firestore`, `firebase_auth`, `share_plus`, `pdf`, `qr_flutter`, `uuid`.
- **APIs**: Grok (key from https://x.ai/api), Firebase (free tier).
- **Claude Codegen**: Prompt for UI, OCR, API calls, sharing logic.

## 9. Risks & Mitigations
- **Risk**: OCR fails on messy receipts.
  - **Mitigation**: Manual input fallback, improve Grok prompt for accuracy.
- **Risk**: API costs scale.
  - **Mitigation**: Cap free scans, monitor usage ($0.50/mo for 5k).
- **Risk**: User adoption lag.
  - **Mitigation**: Viral gifs, X/Threads hype, Product Hunt launch.

## 10. Timeline
- **Day 1**: Flutter setup, test scaffold.
- **Week 1**: Camera UI, MLKit OCR, Grok parsing, payment input.
- **Week 2**: Split logic, Firebase links, share sheet, PDF, beta test (10 X users).
- **Launch**: Day 15, App Store + Product Hunt.

## 11. Success Criteria
- **Technical**: <5% crash rate, 80% OCR accuracy, 10-sec split flow.
- **Business**: 100 paying users in 30 days, $500 MRR.
- **User**: 90% rate split as “easier than manual” (TestimonialKit feedback).