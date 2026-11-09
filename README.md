# Dompetku — Personal Finance Tracker

<p align="center">
  <strong>A modern, friendly, and tactile personal finance mobile application built with Flutter & Dart.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Material_3-4285F4?style=for-the-badge&logo=google&logoColor=white" alt="Material 3" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-brightgreen?style=for-the-badge" alt="Platforms" />
  <img src="https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge" alt="License" />
</p>

---

## About Dompetku

**Dompetku** is a personal finance tracker designed to make everyday money management intuitive, tactile, and stress-free. Unlike sterile corporate banking dashboards or generic AI templates, Dompetku features an original **Tactile Craft** visual identity, combining solid ink borders, micro-translated tactile drop shadows, and an original vector mascot named **Meemo** — your pocket vault guardian.

Dompetku is architected **offline-first**, prioritizing information clarity, ergonomic touch targets (>= 44px), and strict WCAG AA contrast standards.

---

## Key Features

### 1. Home Dashboard
- **Personalized Greeting**: Welcoming hero banner with avatar and date context.
- **Balance Hero Card**: Prominent available balance with privacy toggle (`Rp ••••••••`), reactive wallet switcher (*Semua Dompet*, *Dompet Utama*, *Rekening Bank*, *E-Wallet*), and monthly income/expense chips.
- **Quick Action Bar**: High-contrast, one-tap shortcut buttons for *Catat Pemasukan* and *Catat Pengeluaran*.
- **Meemo Daily Insight Card**: Dynamic daily tips and financial ratio advice (emergency fund recommendations, spending alerts).
- **Recent Transactions Section**: Quick overview of recent activity with inline editing, deletion, and full history navigation.

### 2. Receipt Scanner
- **Dedicated Viewfinder Interface**: Simulated camera viewport featuring an animated laser scanning beam, flashlight toggle, and gallery image picker.
- **AI OCR Extraction Workflow**: Three-step state machine (Viewfinder -> Processing Animation -> Review & Edit).
- **Itemized Extraction Review**: Extracts merchant name, transaction date, individual purchased items with unit quantities, and computed total.
- **Verification & Confirmation**: Fully editable receipt items before committing the transaction to the repository.

### 3. Add & Edit Transaction
- **Fast Input Experience**: Toggle between *Pengeluaran* (expense) and *Pemasukan* (income).
- **Ergonomic Quick Chips**: Instant denomination buttons (`+10rb`, `+25rb`, `+50rb`, `+100rb`, `+500rb`).
- **Comprehensive Categorization**: Category picker featuring custom icons and high-contrast color badges (*Makan & Minum*, *Transportasi*, *Belanja*, *Hiburan*, *Tagihan*, *Gaji*, *Investasi*, etc.).
- **Account & Date Picker**: Select payment account, choose transaction date, add optional notes, and flag recurring transactions.

### 4. Transaction History
- **Real-Time Search**: Instant search filtering across titles, category names, and custom notes.
- **Multi-Level Filtering**: Filter by type (*Semua*, *Masuk*, *Keluar*) and horizontal category chips.
- **Date Grouping**: Transactions grouped by calendar day (*Minggu, 25 Oktober 2026*) with automatic daily net balance calculation (+Rp / -Rp).
- **Actionable Empty States**: Helpful empty state views with Meemo when filters yield no matches.

### 5. Financial Reports & Analytics
- **Flexible Periods**: Inspect performance by *Bulan*, *Kuartal*, *Tahun*, or *Kustom*.
- **Cashflow Summary Cards**: High-contrast cards for *Pemasukan*, *Pengeluaran*, and *Selisih Net* (Net Savings).
- **Meemo AI Financial Summary**: Automatic saving rate calculation and contextual health diagnoses.
- **Spending Allocation Breakdown**: Proportional multi-segment progress bar and ranked category breakdown with percentages and Rupiah values.
- **Portfolio & Asset View**: Track balance distribution across cash, bank accounts, and digital wallets.

### 6. Persistent Bottom Navigation
- 5 primary destinations: **Home**, **Scan Struk**, **Catat (+)**, **Transaksi**, and **Report**.
- Ergonomic elevated center action button with physical tap response.
- Safe-area compliance and scroll-clearance padding preventing content occlusion.

---

## Visual Identity & Design System

Dompetku uses an original design language crafted specifically for approachable personal finance:

- **Color Palette**:
  - **Canvas Background**: `#F7F8F6` (Soft Chalk Canvas)
  - **Ink & Borders**: `#0F172A` (Slate 900 solid 1.5px border, 3px offset shadow)
  - **Brand Primary**: `#0D9488` (Botanical Teal)
  - **Brand Accent**: `#EA580C` (Warm Tangerine) & `#EAB308` (Sunlit Amber)
  - **Income (Positive)**: `#16A34A` / `#14532D` on `#DCFCE7` (7.4:1 contrast ratio)
  - **Expense (Negative)**: `#E11D48` / `#881337` on `#FFE4E6` (8.1:1 contrast ratio)
- **Mascot (Meemo)**:
  - 100% vector-based `CustomPainter` character with expressive states: `happy`, `thinking`, `scanning`, and `saving`.
  - Zero external raster assets, rendering smoothly at 60/120fps.
- **Typography**: Clear numerical hierarchy with Indonesian Rupiah formatting (`Rp 13.082.900`).

---

## Project Architecture

The codebase follows a modular, feature-first structure with clean separation of presentation and business logic:

```
lib/
├── main.dart                             # Application entry point & system UI configuration
├── core/
│   ├── theme/
│   │   ├── app_colors.dart               # Centralized color tokens & category palettes
│   │   ├── app_typography.dart           # Font scale, weights, and currency hierarchy
│   │   ├── app_shadows.dart              # Tactile offset shadows and border scales
│   │   └── app_theme.dart                # Material 3 centralized ThemeData
│   └── utils/
│       ├── currency_formatter.dart       # Rupiah currency formatting utilities
│       └── date_formatter.dart           # Indonesian locale date formatting
├── data/
│   ├── models/
│   │   ├── transaction_model.dart        # Core transaction entity
│   │   ├── category_model.dart           # Category models with icons & colors
│   │   └── wallet_model.dart             # Wallet and account models
│   └── repositories/
│       └── finance_repository.dart       # Reactive state repository (ChangeNotifier)
├── shared/
│   └── widgets/
│       ├── tactile_card.dart             # Card component with press micro-translations
│       ├── tactile_button.dart           # Accessible buttons (min 44px tap target)
│       ├── tactile_chip.dart             # Selectable filter and category chips
│       ├── meemo_mascot.dart             # Vector CustomPainter mascot
│       └── empty_state_view.dart         # Actionable empty state component
├── features/
│   ├── dashboard/                        # Screen 1: Home Dashboard & Hero Cards
│   ├── transactions/                     # Screen 2 & 3: History & Add Transaction
│   ├── receipt_scanner/                  # Screen 4: Dedicated Receipt Scanner
│   └── reports/                          # Screen 5: Financial Reports & Breakdown Charts
└── shell/
    ├── navigation_shell.dart             # Root indexed shell & tab coordination
    └── widgets/
        └── dompetku_bottom_nav.dart      # Persistent tactile bottom navigation bar
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (version `^3.13.7` or higher)
- Dart SDK (included with Flutter)
- Android Studio / VS Code with Flutter extension
- An Android/iOS emulator or connected physical device

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/dompetku.git
   cd dompetku
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the application:**
   ```bash
   flutter run
   ```

---

## Quality Control & Testing

Dompetku is verified against Flutter lints and unit/widget test suites:

- **Static Analysis**:
  ```bash
  flutter analyze
  ```
  *(0 errors, 0 warnings)*

- **Widget & Unit Tests**:
  ```bash
  flutter test
  ```

---

## Roadmap

- [x] Modern Tactile Craft Design System & Original Color Palette
- [x] Original Vector Mascot (Meemo) with CustomPainter
- [x] Home Dashboard with Multi-Wallet Filter
- [x] Interactive Receipt Scanner with Extraction Review
- [x] Add/Edit Transaction Flow with Quick Denominations
- [x] Transaction History with Search & Date Grouping
- [x] Financial Reporting with Category Allocation Charts
- [ ] SQLite local database persistence (sqflite / drift)
- [ ] On-device OCR extraction with Google ML Kit
- [ ] Cloud sync & backup (Supabase / Firebase)
- [ ] Export transactions to CSV / PDF

---

## License

This project is licensed under the [MIT License](LICENSE).
