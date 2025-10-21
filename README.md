# PaySnip

A mobile app to simplify group bill splitting by snapping receipts, parsing items with AI, and sharing payment links (Venmo/PayPal) via a web page.

## Features

- **Receipt Capture & OCR**: Snap a photo and extract text using MLKit OCR
- **AI Parsing**: OpenAI GPT-4o-mini parses receipt into structured JSON
- **Smart Splitting**: Split bills evenly or assign items to specific people
- **Payment Links**: Generate shareable web links with Venmo/PayPal buttons
- **PDF Export**: Export split summaries as PDF
- **Privacy-First**: No friend data stored, stateless links

## Tech Stack

- **Frontend**: Flutter (iOS 14+, Android 9+)
- **OCR**: Google MLKit
- **AI**: OpenAI GPT-4o-mini
- **Backend**: Supabase (Auth, Database, Storage)

## Setup Instructions

### Prerequisites

1. Flutter SDK 3.35.5 or higher
2. Xcode (for iOS development)
3. Android Studio (for Android development)
4. Supabase account
5. OpenAI API key from https://platform.openai.com/api-keys

### Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Set up environment variables:
```bash
cp .env.example .env
# Edit .env and add your credentials:
# - OPENAI_API_KEY
# - SUPABASE_URL
# - SUPABASE_ANON_KEY
```

3. Set up Supabase:
   - Create a new project at https://supabase.com
   - Get your project URL and anon key from Settings > API
   - Add them to your `.env` file
   - Create the following tables in Supabase SQL Editor:

```sql
-- Users table (extends Supabase auth.users)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users PRIMARY KEY,
  venmo_username TEXT,
  paypal_email TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Splits table
CREATE TABLE splits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users,
  receipt_text TEXT,
  parsed_items JSONB,
  total DECIMAL(10, 2),
  assignments JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE splits ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can view own splits"
  ON splits FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own splits"
  ON splits FOR INSERT
  WITH CHECK (auth.uid() = user_id);
```

4. Run the app:
```bash
# For iOS
flutter run -d ios

# For Android
flutter run -d android
```

## Project Structure

```
lib/
├── main.dart           # App entry point
├── models/             # Data models (Receipt, SplitItem, etc.)
├── services/           # Business logic (OCR, Grok API, Supabase)
├── screens/            # UI screens (Camera, Split, Settings)
├── widgets/            # Reusable widgets
└── utils/              # Helper functions
```

## Development Roadmap

### Week 1
- [ ] Flutter UI (camera, payment input)
- [ ] MLKit OCR integration
- [ ] Grok JSON parsing

### Week 2
- [ ] Split logic (even/custom)
- [ ] Supabase web links
- [ ] Share sheet integration
- [ ] PDF export

## Monetization

- **Freemium**: 5 free scans/month
- **Premium**: $4.99/month or $29/year for unlimited scans
- **Micro-Pays**: $0.49/scan or $2.99 for 10 scans

## Environment Variables

Required environment variables (see `.env.example`):

- `OPENAI_API_KEY`: Your OpenAI API key from https://platform.openai.com/api-keys
- `OPENAI_API_URL`: OpenAI API endpoint (default: https://api.openai.com/v1/chat/completions)
- `OPENAI_MODEL`: OpenAI model to use (default: gpt-4o-mini)
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_ANON_KEY`: Your Supabase anonymous key

## License

Proprietary - All rights reserved
