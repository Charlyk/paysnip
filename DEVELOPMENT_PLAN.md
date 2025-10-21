# PaySnip MVP Development Plan

## Overview
Build a mobile app for splitting bills by snapping receipts, using AI to parse them, and sharing payment links.

**Timeline**: 6 sessions (following PRD's 2-week MVP scope)
**Tech Stack**: Flutter, Supabase, OpenAI GPT-4o-mini, Google MLKit

---

## Data Architecture

### Database Schema (Supabase)

**profiles**
```sql
CREATE TABLE profiles (
  id UUID REFERENCES auth.users PRIMARY KEY,
  venmo_username TEXT,
  paypal_email TEXT,
  scan_count INTEGER DEFAULT 0,
  scan_reset_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_premium BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**receipts**
```sql
CREATE TABLE receipts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users,
  ocr_text TEXT,
  parsed_data JSONB,  -- [{item: "Burger", price: 12.99}, ...]
  total DECIMAL(10, 2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**splits**
```sql
CREATE TABLE splits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  receipt_id UUID REFERENCES receipts,
  user_id UUID REFERENCES auth.users,
  split_type TEXT,  -- 'even' or 'custom'
  num_people INTEGER,
  assignments JSONB,  -- [{name: "Bob", items: [...], total: 12.50}, ...]
  share_link_id TEXT UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Data Flow
```
User signs in → Snap receipt → OCR → OpenAI parse → Save receipt data → 
Create split → Save split with assignments → Generate shareable link → Share
```

**Key Decision**: No image storage - only save OCR text + parsed JSON data

---

## Phase 1: Core Infrastructure & Authentication

### 1.1 App Initialization
**File**: `lib/main.dart`
- Load environment variables using flutter_dotenv
- Initialize Supabase client
- Set up MaterialApp with theme and routing
- Check auth state on launch
- Setup Provider for state management

### 1.2 Service Layer

**File**: `lib/services/supabase_service.dart`
- Singleton pattern for Supabase client
- Auth methods:
  - `signIn(email, password)`
  - `signUp(email, password)`
  - `signInWithGoogle()`
  - `signOut()`
  - `getCurrentUser()`
- Database operations:
  - `getProfile(userId)`
  - `updateProfile(userId, data)`
  - `saveReceipt(ocrText, parsedData, total)`
  - `saveSplit(receiptId, splitData)`
  - `getSplitByLinkId(linkId)`
  - `getUserSplits(userId)`

**File**: `lib/services/openai_service.dart`
- Parse OCR text to structured JSON
- Request format:
  ```json
  {
    "model": "gpt-4o-mini",
    "messages": [
      {
        "role": "system",
        "content": "Parse receipt text to JSON: {items: [{item, price}], total}. Prices as numbers."
      },
      {
        "role": "user",
        "content": "[OCR text here]"
      }
    ],
    "response_format": { "type": "json_object" }
  }
  ```
- Handle API errors and retries
- Validate response format

**File**: `lib/services/ocr_service.dart`
- MLKit integration for text recognition
- `processImage(File image) -> String`
- Handle OCR errors
- Return extracted text

**File**: `lib/services/scan_limit_service.dart`
- `checkScanLimit(userId) -> bool`
- `incrementScanCount(userId)`
- `resetMonthlyScans(userId)`
- `isPremium(userId) -> bool`
- Handle 5 free scans/month logic

### 1.3 Data Models

**File**: `lib/models/user_profile.dart`
```dart
class UserProfile {
  String id;
  String? venmoUsername;
  String? paypalEmail;
  int scanCount;
  DateTime scanResetDate;
  bool isPremium;
  DateTime createdAt;
  DateTime updatedAt;
}
```

**File**: `lib/models/receipt.dart`
```dart
class Receipt {
  String id;
  String userId;
  String ocrText;
  List<SplitItem> items;
  double total;
  DateTime createdAt;
}
```

**File**: `lib/models/split_item.dart`
```dart
class SplitItem {
  String name;
  double price;
}
```

**File**: `lib/models/split.dart`
```dart
class Split {
  String id;
  String receiptId;
  String userId;
  String splitType; // 'even' or 'custom'
  int? numPeople;
  List<PersonAssignment> assignments;
  String shareLinkId;
  DateTime createdAt;
}
```

**File**: `lib/models/person_assignment.dart`
```dart
class PersonAssignment {
  String name;
  List<SplitItem> items;
  double total;
}
```

### 1.4 Utilities

**File**: `lib/utils/constants.dart`
- Load environment variables
- API endpoints
- App constants (colors, strings)

**File**: `lib/utils/validators.dart`
- Email validation
- Venmo username validation (@handle)
- PayPal email validation

**File**: `lib/utils/error_handler.dart`
- Centralized error handling
- User-friendly error messages
- Logging

---

## Phase 2: Authentication & Onboarding

### 2.1 Authentication Screens

**File**: `lib/screens/auth/login_screen.dart`
- Email/password input fields
- Sign-in button
- Google SSO button
- Apple SSO button (for iPhones)
- Link to signup screen
- Forgot password option
- Error handling

**File**: `lib/screens/auth/signup_screen.dart`
- Email/password input fields
- Confirm password
- Sign-up button
- Create profile in Supabase
- Navigate to onboarding
- Terms acceptance checkbox

**File**: `lib/screens/auth/auth_wrapper.dart`
- Stream Supabase auth state
- Route to login or home based on auth status
- Handle deep links

### 2.2 Onboarding

**File**: `lib/screens/onboarding/payment_setup_screen.dart`
- Welcome message
- Input Venmo username (optional)
- Input PayPal email (optional)
- Save to user profile in Supabase
- Skip button (can add later in settings)
- Navigate to home screen

---

## Phase 3: Receipt Capture & AI Parsing

### 3.1 Camera & OCR

**File**: `lib/screens/camera/camera_screen.dart`
- Request camera permissions
- Initialize camera controller
- Live camera preview
- Capture button
- Flash toggle
- Gallery picker option (image_picker)
- Handle permission denial

**File**: `lib/screens/camera/image_preview_screen.dart`
- Display captured image
- Retake button
- Confirm button
- Start OCR processing on confirm
- Loading indicator
- Navigate to parsing screen

### 3.2 AI Parsing & Review

**File**: `lib/screens/receipt/parsing_screen.dart`
- Check scan limit before processing
- Call OCR service with image
- Display extracted text (editable)
- Call OpenAI service with OCR text
- Show loading with progress messages
- Handle API errors with retry option
- Navigate to parsed items screen

**File**: `lib/screens/receipt/parsed_items_screen.dart`
- Display parsed items in editable list
- Add item button
- Edit item (tap to edit name/price)
- Delete item (swipe to delete)
- Validate total = sum of items
- Recalculate total button
- Confirm button → Save to Supabase
- Increment scan count
- Navigate to split method screen

### 3.3 Scan Limit Handling

**File**: `lib/widgets/scan_limit_banner.dart`
- Show remaining scans (e.g., "3/5 scans left")
- Display reset date
- Premium badge if applicable

**File**: `lib/screens/upgrade/upgrade_screen.dart`
- Pricing plans
- Benefits of premium
- Purchase buttons (placeholder for now)
- Navigate back or to home

---

## Phase 4: Split Logic

### 4.1 Split Method Selection

**File**: `lib/screens/split/split_method_screen.dart`
- Display receipt total
- Two cards:
  - "Split Evenly" option
  - "Custom Assignment" option
- Pass receipt data to selected screen

### 4.2 Even Split

**File**: `lib/screens/split/even_split_screen.dart`
- Input number of people (stepper or text field)
- Calculate: total ÷ number
- Show preview: "$X.XX per person"
- Optional: Add person names (list of text fields)
- Generate assignments automatically
- Save button → Save split to Supabase
- Navigate to share screen

### 4.3 Custom Split

**File**: `lib/screens/split/custom_split_screen.dart`
- Add person button (opens dialog for name)
- List of added people
- For each person:
  - Expandable card showing their items
  - Checkbox list of all receipt items
  - Running total for that person
- Handle shared items (future: split cost between people)
- Show unassigned items warning
- Validate all items assigned
- Save button → Save split to Supabase
- Navigate to share screen

**File**: `lib/widgets/split/item_selector_widget.dart`
- Checkbox with item name and price
- Visual feedback when selected
- Disable if already assigned (for non-shared mode)

**File**: `lib/widgets/split/person_summary_card.dart`
- Person name
- List of assigned items with prices
- Total owed prominently displayed
- Edit button to reassign items

### 4.4 Split Calculator

**File**: `lib/utils/split_calculator.dart`
- `calculateEvenSplit(total, numPeople) -> List<PersonAssignment>`
- `calculateCustomSplit(items, assignments) -> List<PersonAssignment>`
- Handle rounding (ensure sum = total)
- Tax distribution logic (proportional)

---

## Phase 5: Sharing & Payment Links

### 5.1 Link Generation

**File**: `lib/services/link_service.dart`
- `generateShareLink(splitId) -> String`
- Generate unique share_link_id (UUID short hash or readable string)
- Update split in Supabase with link ID
- Build shareable URL: `https://paysnip.app/split/{link_id}`
- Return link for sharing

### 5.2 Share Screen

**File**: `lib/screens/share/share_screen.dart`
- Display split summary:
  - Receipt total
  - Number of people
  - List of person assignments (name + total)
- Generate QR code using qr_flutter
- Share button with options:
  - Native share sheet (share_plus)
  - Copy link to clipboard
  - Email
  - WhatsApp
- Share text template: 
  ```
  "Split the bill with PaySnip!
  
  [Person1]: $X.XX
  [Person2]: $Y.YY
  
  View details and pay: https://paysnip.app/split/{link_id}
  
  Split with PaySnip 🧾✨"
  ```
- View PDF button
- Done button → Navigate to home

**File**: `lib/widgets/share/qr_code_widget.dart`
- Generate QR code with payment link
- Download QR as image option
- Share QR code directly

### 5.3 Public Split View (Web/App)

**File**: `lib/screens/share/public_split_view_screen.dart`
- Handle deep link: `paysnip://split/{link_id}`
- Fetch split data by link_id from Supabase (public access)
- Display:
  - Receipt items
  - Each person's assignment
  - Total per person
- For each person:
  - Venmo button: `venmo://pay?recipients=@user&amount=12.50`
  - PayPal button: `https://paypal.me/{user}/12.50`
  - Open in browser if app not installed
- No authentication required
- Watermark: "Split with PaySnip"

---

## Phase 6: PDF Export

### 6.1 PDF Generation

**File**: `lib/services/pdf_service.dart`
- `generateSplitPDF(Split split) -> Uint8List`
- Format PDF with:
  - Header: "PaySnip Bill Split"
  - Date and time
  - Receipt items list
  - Divider
  - Each person's section:
    - Name
    - Items assigned
    - Total owed
  - Payment instructions (Venmo/PayPal)
- GZIP compression
- Return PDF bytes

**File**: `lib/screens/pdf/pdf_preview_screen.dart`
- Display PDF preview using printing package
- Share button (email, save to device)
- Print button
- Done button

---

## Phase 7: History & Settings

### 7.1 Home Screen

**File**: `lib/screens/home/home_screen.dart`
- AppBar with:
  - App logo/title
  - Settings icon
- Scan limit banner at top
- Large "New Scan" FAB
  - Check scan limit before navigating
  - Show upgrade dialog if limit reached
- Recent splits section:
  - List of last 5 splits
  - Tap to view details
  - "View All" button
- Bottom navigation (future: stats, history)

### 7.2 Split History

**File**: `lib/screens/history/split_history_screen.dart`
- Fetch all user's splits from Supabase (ordered by date)
- Display list with:
  - Date
  - Total amount
  - Number of people
  - Preview of person names
- Pull to refresh
- Tap to view details
- Search/filter option (future)

**File**: `lib/screens/history/split_detail_screen.dart`
- Display full split details:
  - Receipt items
  - Assignments
  - Person totals
- Re-share button → Open share screen
- Generate PDF button
- Delete split button (confirmation dialog)

### 7.3 Settings

**File**: `lib/screens/settings/settings_screen.dart`
- Profile section:
  - User email
  - Edit payment info button
- Subscription section:
  - Current plan (Free/Premium)
  - Scan usage: X/5 this month
  - Reset date
  - Upgrade button
- App settings:
  - Notifications (future)
  - Theme (future)
- Legal:
  - Terms of service
  - Privacy policy
- Sign out button

**File**: `lib/screens/settings/edit_payment_screen.dart`
- Input Venmo username (@handle)
- Input PayPal email
- Validate format
- Save button → Update Supabase profile
- Success message

---

## Phase 8: Polish & Error Handling

### 8.1 Common Widgets

**File**: `lib/widgets/common/loading_indicator.dart`
- Branded loading spinner
- Optional loading message

**File**: `lib/widgets/common/error_dialog.dart`
- User-friendly error messages
- Retry button
- Close button

**File**: `lib/widgets/common/app_button.dart`
- Primary button style
- Secondary button style
- Disabled state

**File**: `lib/widgets/common/scan_limit_dialog.dart`
- Show when limit reached
- Display upgrade benefits
- Upgrade button
- Cancel button

### 8.2 State Management (Provider)

**File**: `lib/providers/auth_provider.dart`
- User auth state
- Current user profile
- Sign in/out methods
- Listen to auth changes

**File**: `lib/providers/receipt_provider.dart`
- Current receipt data
- OCR text
- Parsed items
- Methods to update items

**File**: `lib/providers/split_provider.dart`
- Current split data
- Assignments
- Methods to add/remove people
- Methods to assign items

### 8.3 Error Handling

**Scenarios to handle:**
- Network errors (retry logic with exponential backoff)
- OCR failures (manual text input fallback)
- OpenAI API errors (retry or manual edit items)
- Scan limit exceeded (upgrade prompt)
- Invalid payment info (validation feedback)
- Camera permission denied (show instructions)
- Image quality too low (retake prompt)

**File**: `lib/utils/network_helper.dart`
- Check network connectivity
- Retry logic wrapper
- Timeout handling

---

## Implementation Order (6 Sessions)

### Session 1: Foundation ⚙️
**Deliverables:**
- Setup `main.dart` with Supabase initialization
- Create all service files (Supabase, OpenAI, OCR, scan limit)
- Create all data models
- Setup constants and utilities
- Setup Provider for state management
- Test Supabase connection

**Files to create:**
- `lib/main.dart`
- `lib/services/*.dart` (4 files)
- `lib/models/*.dart` (5 files)
- `lib/utils/*.dart` (3 files)
- `lib/providers/*.dart` (3 files)

---

### Session 2: Auth & Onboarding 🔐
**Deliverables:**
- Login screen with email/password
- Signup screen
- Google SSO integration (optional)
- Payment setup onboarding screen
- Auth wrapper for routing
- Profile creation in Supabase

**Files to create:**
- `lib/screens/auth/*.dart` (3 files)
- `lib/screens/onboarding/*.dart` (1 file)

**Testing:**
- Sign up new user
- Sign in existing user
- Add payment info
- Verify profile in Supabase

---

### Session 3: Camera & Parsing 📸
**Deliverables:**
- Camera screen with live preview
- Image preview screen
- OCR integration (MLKit)
- OpenAI parsing integration
- Parsed items review screen
- Scan limit check before processing
- Save receipt to Supabase

**Files to create:**
- `lib/screens/camera/*.dart` (2 files)
- `lib/screens/receipt/*.dart` (2 files)
- `lib/widgets/scan_limit_banner.dart`

**Testing:**
- Capture receipt photo
- OCR extracts text correctly
- OpenAI parses to JSON
- Edit parsed items
- Save to database
- Verify scan count increments

---

### Session 4: Splitting 🧮
**Deliverables:**
- Split method selection screen
- Even split screen with calculation
- Custom split screen with item assignment
- Person assignment widgets
- Split calculator utilities
- Save split to Supabase

**Files to create:**
- `lib/screens/split/*.dart` (3 files)
- `lib/widgets/split/*.dart` (2 files)
- `lib/utils/split_calculator.dart`

**Testing:**
- Create even split (3 people)
- Create custom split (assign items)
- Verify calculations correct
- Save to database
- Check split linked to receipt

---

### Session 5: Sharing 🔗
**Deliverables:**
- Link generation service
- Share screen with QR code
- Native share integration
- Public split view screen
- Payment deep links (Venmo/PayPal)
- Shareable link format

**Files to create:**
- `lib/services/link_service.dart`
- `lib/screens/share/*.dart` (2 files)
- `lib/widgets/share/qr_code_widget.dart`

**Testing:**
- Generate share link
- View QR code
- Share via text/email
- Open public link (unauthenticated)
- Test Venmo/PayPal deep links
- Verify link works on another device

---

### Session 6: History, PDF & Polish ✨
**Deliverables:**
- Home screen with recent splits
- Split history screen
- Split detail screen
- Settings screen
- Edit payment screen
- PDF generation and preview
- Error dialogs and loading states
- Upgrade screen (UI only)
- Final testing and bug fixes

**Files to create:**
- `lib/screens/home/home_screen.dart`
- `lib/screens/history/*.dart` (2 files)
- `lib/screens/settings/*.dart` (2 files)
- `lib/screens/pdf/pdf_preview_screen.dart`
- `lib/screens/upgrade/upgrade_screen.dart`
- `lib/services/pdf_service.dart`
- `lib/widgets/common/*.dart` (4 files)

**Testing:**
- View split history
- Re-share old split
- Generate PDF
- Update payment info
- Test all error scenarios
- Test scan limit enforcement
- End-to-end flow testing

---

## Key Technical Decisions

1. **State Management**: Provider pattern (simple, sufficient for MVP scope)
2. **Navigation**: Named routes with MaterialPageRoute
3. **Database**: Supabase with Row Level Security (RLS) policies
4. **Authentication**: Supabase Auth (email/password + optional Google)
5. **Freemium Logic**: Track scans in profiles table, reset monthly
6. **No Image Storage**: Only save OCR text + parsed JSON to reduce costs
7. **Public Links**: Accessible without auth via unique share_link_id
8. **Payment Deep Links**: Platform-specific URL schemes (venmo://, paypal.me)
9. **AI Model**: OpenAI GPT-4o-mini (cost-effective, fast, structured outputs)
10. **OCR**: Google MLKit (free, on-device processing)

---

## Environment Variables Required

```env
# OpenAI API Configuration
OPENAI_API_KEY=sk-proj-...
OPENAI_API_URL=https://api.openai.com/v1/chat/completions
OPENAI_MODEL=gpt-4o-mini

# Supabase Configuration
SUPABASE_URL=https://[project].supabase.co
SUPABASE_ANON_KEY=eyJ...
```

---

## Supabase Setup Checklist

- [ ] Create Supabase project
- [ ] Enable Email authentication
- [ ] Enable Google OAuth (optional)
- [ ] Create `profiles` table with RLS policies
- [ ] Create `receipts` table with RLS policies
- [ ] Create `splits` table with RLS policies
- [ ] Add triggers for `updated_at` timestamps
- [ ] Add function to auto-create profile on signup
- [ ] Add function to reset monthly scans
- [ ] Test RLS policies

---

## Success Criteria (MVP)

**Technical:**
- [ ] Users can sign up and log in
- [ ] Camera captures receipt images
- [ ] OCR extracts text with >80% accuracy
- [ ] OpenAI parses text to JSON correctly
- [ ] Even split calculates correctly
- [ ] Custom split assigns items properly
- [ ] Share links are publicly accessible
- [ ] Venmo/PayPal deep links work
- [ ] PDF exports successfully
- [ ] Split history displays correctly
- [ ] Scan limit enforced (5/month for free users)
- [ ] <5% crash rate

**User Experience:**
- [ ] Complete flow in <60 seconds (snap to share)
- [ ] Intuitive UI, no confusion
- [ ] Error messages are clear and helpful
- [ ] Loading states provide feedback
- [ ] Works on iOS and Android

**Business:**
- [ ] Freemium model implemented (5 free scans)
- [ ] Upgrade prompt shows benefits
- [ ] Viral share message includes branding
- [ ] Ready for beta testing with 10 users

---

## Out of Scope for MVP

- Payment tracking/confirmation
- In-app payments (Stripe integration)
- Contact syncing
- Analytics dashboard
- Tip calculation
- Currency conversion
- Multiple currencies
- Expense categories
- Group expense tracking over time
- Push notifications
- Social features (friends, groups)
- Receipt templates
- Bulk operations
- Advanced reporting

---

## Next Steps After MVP

1. **Beta Testing**: 10 users from X/Threads
2. **Feedback Collection**: Survey + TestimonialKit
3. **Bug Fixes**: Address critical issues
4. **Payment Integration**: Stripe for premium subscriptions
5. **Marketing**: Product Hunt launch, build-in-public posts
6. **Analytics**: Track user behavior, conversion rates
7. **Premium Features**: Unlimited scans, advanced reports, export options

---

## Notes

- Focus on core flow: snap → parse → split → share
- Prioritize speed and simplicity over features
- Test on real devices early and often
- Get receipts from different restaurants to test OCR
- Monitor OpenAI API costs during development
- Keep UI minimal and fast (Material Design 3)
- Add "Split with PaySnip" branding everywhere for virality

---

**Ready to build!** 🚀

Start with Session 1: Foundation
