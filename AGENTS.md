<!-- antislop:start -->
## antislop
For UI, copy, people, mobile layout, or code comments work, read these installed skill files directly (use these paths even if a same-named global skill exists):
- Core filter, always on: `antislop`: `.agents/skills/antislop/SKILL.md`
- UI / visual: `antislop-ui`: `.agents/skills/antislop-ui/SKILL.md`
- People: `antislop-human`: `.agents/skills/antislop-human/SKILL.md`
- Mobile / responsive: `antislop-layoutmobile`: `.agents/skills/antislop-layoutmobile/SKILL.md`
- Code comments: `antislop-code`: `.agents/skills/antislop-code/SKILL.md`
Before starting, follow the core's "Two Usage Modes" section in strict order: explicit session instruction first, then global preference, then ask. A session instruction always wins. For a resolved mode, say `antislop active: <mode> (session override).` or `antislop active: <mode> (global preference).` once before presenting findings or making edits, using the actual mode and source. Acknowledging the user's request without naming the source does not replace this notice.
Only an explicit choice of antislop during or after selects a session mode. A request to review, audit, or avoid file edits does not select a mode; read the global preference in that case. Another skill's mode does not select antislop's mode.
If the mode is unresolved, ask during/after and end the response; wait for the answer before any UI review, planning, or concept. For read-only tasks, put the active-mode notice only at the start of the final answer, never in progress messages. For editing tasks, announce before the first edit and omit it from the final answer.
To update antislop later: `npx antislop-ai --update`, or run `npx antislop-ai` and pick Overwrite them.
<!-- antislop:end -->

# DOMPETKU — PROJECT CONSTITUTION

This document defines the permanent product vision, technical direction, architectural constraints, development roadmap, and collaboration rules for Dompetku.

All AI agents working inside this project MUST read and follow these instructions.

These instructions take priority over assumptions, unsolicited suggestions, or independently invented product directions.

---

# 1. PROJECT IDENTITY

Project Name: Dompetku

Product Type: Personal Finance Tracker

Primary Framework: Flutter

Programming Language: Dart

Primary Platform: Android

Web Platform: Not currently in scope. Future development is undecided and requires explicit user approval.

Development Environment: VS Code / Google Antigravity IDE

Dompetku is a personal finance application designed to help individuals record, manage, monitor, and understand their daily financial activities.

The primary purpose is to make personal financial management simple, accessible, and enjoyable.

The application must support:
- Manual income recording.
- Manual expense recording.
- Receipt scanning.
- Transaction management.
- Financial summaries.
- Financial reports.
- Spending analysis.

Dompetku is primarily a personal financial management tool, NOT an accounting system for businesses.

Do not change this product direction without explicit user approval.

## CURRENT DEVELOPMENT ENVIRONMENT

Android is the primary and intended platform for Dompetku.

Android Studio and Android Emulator are temporarily unavailable.

This is a tooling limitation, NOT a change in product direction.

Development rules:

- Continue implementing Android-compatible Flutter code.
- Do not prioritize Flutter Web.
- Do not configure browser-specific database infrastructure.
- Do not introduce Web-specific dependencies.
- Do not redesign the architecture around Web compatibility.
- Do not block implementation because Android Emulator is unavailable.
- Use flutter analyze and flutter test for available validation.
- Chrome may be used for occasional visual inspection, but it is not the primary testing target.
- Clearly identify functionality that has not yet been tested on Android.

Do not claim Android functionality has been verified until it has actually been tested on an Android emulator or physical device.

The final application must be buildable as an Android APK.

# 2. PRODUCT PRINCIPLES

The product must follow these principles:

1. Simplicity: Recording a transaction should be fast and intuitive.
2. Accuracy: Financial calculations must be reliable.
3. Privacy: Personal financial data should remain locally stored by default.
4. Offline-first: Core functionality must work without internet access.
5. Usability: Financial information must be easy to understand.
6. Consistency: All screens must follow one coherent design system.
7. Maintainability: The implementation must remain modular and maintainable.

Avoid adding features merely because they are technically interesting.

Every feature must serve the primary purpose of managing personal finances.

# 3. DESIGN SYSTEM — IMPORTANT

The initial UI implementation has already been completed and approved by the user.

The user is satisfied with the current visual direction.

Therefore:

- DO NOT redesign existing screens.
- DO NOT replace the established color palette.
- DO NOT change typography without approval.
- DO NOT replace existing components unnecessarily.
- DO NOT recreate the interface using a different design style.
- DO NOT independently reinterpret the approved visual identity.
- DO NOT make large visual changes just because another design seems better.

The original design references were provided as inspiration, not templates.

Dompetku must maintain its own visual identity.

When implementing functionality, preserve the existing UI as much as reasonably possible.

Only modify UI when required to support functionality, usability, responsiveness, or error handling.

Any substantial visual modification requires user approval.

# 4. APPLICATION NAVIGATION

The intended main navigation contains five destinations:

1. Home
2. Scan Receipt
3. Add Transaction
4. Transactions
5. Reports

The Add Transaction action may receive stronger visual emphasis in the bottom navigation.

Each destination has a specific responsibility.

## Home

Displays:
- Total balance.
- Monthly income.
- Monthly expenses.
- Recent transactions.
- Financial overview.
- Relevant shortcuts.

## Scan Receipt

Allows users to:
- Capture receipt images.
- Process images using OCR.
- Extract transaction information.
- Review extracted information.
- Correct information manually.
- Confirm before saving.

## Add Transaction

Allows users to:
- Record income.
- Record expenses.
- Enter amounts.
- Select categories.
- Select transaction dates.
- Select wallets.
- Add optional notes.

## Transactions

Allows users to:
- View transaction history.
- Filter transactions.
- Search transactions.
- Edit transactions.
- Delete transactions.

## Reports

Displays:
- Monthly financial reports.
- Quarterly reports.
- Yearly reports.
- Custom date ranges.
- Income and expense summaries.
- Category spending breakdown.
- Financial statistics.

Do not invent additional primary navigation destinations without approval.

# 5. TECHNICAL STACK

The agreed technical direction is:

| Component | Technology |
|---|---|
| Mobile Framework | Flutter |
| Language | Dart |
| Local Database | SQLite |
| Database Abstraction | Drift |
| State Management | Riverpod, if not already using another suitable solution |
| OCR | Google ML Kit |
| Primary Currency | Indonesian Rupiah (IDR) |

Important:

Before adding dependencies or replacing existing packages, inspect the current project.

Do not introduce duplicate solutions for problems that are already solved.

If the project already has an established implementation, evaluate whether it should be reused before replacing it.

Do not introduce a backend, cloud database, or authentication infrastructure at this stage.

# 6. APPLICATION ARCHITECTURE

Dompetku follows an offline-first architecture.

The initial application must work without:
- Dedicated hosting.
- A custom domain.
- A VPS.
- A backend server.
- Cloud database services.

The intended data flow is:

UI
 |
State Management
 |
Repository
 |
Local Database
 |
SQLite

Responsibilities must be separated.

UI components must not contain complex database queries or financial business logic.

Keep the implementation modular.

Recommended structure:

lib/
  core/
    constants/
    theme/
    utils/

  data/
    database/
    models/
    repositories/

  features/
    dashboard/
      screens/
      widgets/

    transactions/
      screens/
      widgets/

    receipt_scanner/
      screens/
      widgets/

    reports/
      screens/
      widgets/

  shared/
    widgets/

  main.dart

This is a guideline, not permission to unnecessarily restructure an already working project.

# 7. DATA MODEL AND FINANCIAL RULES

The initial data entities are:

## Transactions

- id
- title
- type
- amount
- categoryId
- walletId
- transactionDate
- note
- source
- createdAt
- updatedAt

Transaction types:
- income
- expense

Transaction sources:
- manual
- receipt

## Categories

- id
- name
- type
- icon

## Wallets

- id
- name
- initialBalance
- createdAt

The application initially provides a wallet named:

Dompet Utama

## Monetary Rules

The primary currency is IDR.

Store monetary values as integers, not floating-point values.

Financial calculation:

Total Balance =
Initial Balance + Total Income - Total Expenses

Monthly Income =
Sum of income transactions within the selected month.

Monthly Expenses =
Sum of expense transactions within the selected month.

Net Balance =
Monthly Income - Monthly Expenses

Financial calculations must be implemented in an appropriate business logic or repository layer.

Do not duplicate financial calculation logic across multiple screens.

# 8. DEVELOPMENT ROADMAP

Follow this roadmap in order.

Do not independently create a new roadmap or jump between phases.

## PHASE 1 — FOUNDATION AND TRANSACTION MANAGEMENT

Current priority.

Objectives:

- Inspect existing implementation.
- Configure local database.
- Create database tables.
- Initialize default wallet and categories.
- Implement repository layer.
- Implement transaction CRUD.
- Connect existing transaction form.
- Connect transaction history.
- Connect dashboard financial summaries.
- Persist transactions after application restart.

Completion criteria:

A user can add, edit, delete, and view income and expense transactions.

Financial summaries update correctly.

Transactions remain available after closing and reopening the application.

## PHASE 2 — FINANCIAL REPORTS

After Phase 1 is complete:

- Integrate real transaction data into reports.
- Implement date filtering.
- Implement monthly summaries.
- Implement quarterly and yearly summaries.
- Calculate category spending.
- Implement income versus expense visualization.

## PHASE 3 — RECEIPT SCANNER

After Phases 1 and 2:

- Integrate camera.
- Implement receipt image capture.
- Integrate Google ML Kit OCR.
- Extract transaction information.
- Parse date and currency values.
- Display extracted information for review.
- Allow manual correction.
- Save confirmed information as a transaction.

Never automatically save unverified OCR results.

## PHASE 4 — TESTING AND REFINEMENT

- Test database persistence.
- Test transaction calculations.
- Test application navigation.
- Test different screen sizes.
- Test Android-specific behavior.
- Fix identified bugs.
- Improve error handling.
- Improve application reliability.

## PHASE 5 — RELEASE

- Prepare release configuration.
- Generate Android APK.
- Test the release build.
- Verify installation on a physical Android device.

Future features such as cloud synchronization or multi-device support are outside the current scope.

They must not be implemented unless explicitly requested.

# 9. DEVELOPMENT AND COLLABORATION RULES

These rules are mandatory.

## Rule 1 — Stay Within Scope

Only implement the feature or development phase currently requested by the user.

Do not add unrelated features.

Do not expand requirements without permission.

## Rule 2 — No Independent Product Decisions

Do not independently change:
- Product direction.
- Navigation structure.
- Business requirements.
- Approved UI design.
- Database strategy.
- Application architecture.

If a major decision is necessary and has not been agreed upon, explain the options and ask the user before proceeding.

## Rule 3 — Inspect Before Modifying

Always inspect existing files before modifying them.

Do not assume the project is empty or that previous implementations are incorrect.

Reuse working code whenever reasonable.

## Rule 4 — No Unnecessary Refactoring

Do not rewrite entire files when a small modification is sufficient.

Do not restructure working folders without a clear technical reason.

Do not remove existing dependencies without justification.

## Rule 5 — Dependencies

Before adding a new package:

1. Check whether an existing dependency already provides the functionality.
2. Explain why the new dependency is needed.
3. Avoid unnecessary packages.
4. Do not replace working dependencies without a strong reason.

For architectural or significant dependency changes, obtain user approval first.

## Rule 6 — No Fake Functionality

Never present mock data as real persisted data.

Never claim OCR works if it only has a static UI.

Never claim database persistence works without testing it.

Clearly distinguish between:
- Implemented functionality.
- UI placeholders.
- Mock data.
- Pending functionality.

## Rule 7 — Preserve Existing UI

Functional implementation must not become an excuse to redesign approved screens.

Reuse existing UI components.

Maintain consistent colors, typography, spacing, borders, shadows, and interaction patterns.

## Rule 8 — Explain Technical Decisions

The user is learning Flutter and Dart.

When implementing significant functionality:

- Explain what is being implemented.
- Explain why it is necessary.
- Identify important files.
- Explain how the components interact.
- Highlight important technical decisions.

Keep explanations understandable and practical.

Do not overwhelm the user with unnecessary theoretical discussions.

# 10. WORKING PROTOCOL

For every new development request:

1. Read this project constitution.
2. Inspect the current project state.
3. Identify the applicable roadmap phase.
4. Understand the existing implementation.
5. Identify the exact scope of the requested task.
6. Present a short implementation approach.
7. Implement only the approved scope.
8. Run relevant checks and tests.
9. Report the actual results.

Do not repeatedly generate a new project architecture or roadmap.

The roadmap in this document is the agreed development direction.

If something is unclear, ask a focused clarification instead of making major assumptions.

# 11. COMPLETION REPORT

At the end of every implementation task, report:

### Completed
What functionality was actually implemented.

### Files Modified
Which files were created, modified, or deleted.

### Dependencies
Which packages were added or changed and why.

### Testing
Which commands were executed and their actual results.

### Remaining Issues
What is incomplete, broken, or still requires attention.

Do not report success without evidence.

# FINAL INSTRUCTION

Dompetku already has an established product direction and approved initial UI design.

Your role is to help implement this product according to the agreed requirements.

You are an engineering assistant working within an existing project vision.

You are NOT authorized to independently redefine the product, redesign its UI, invent new requirements, or change its architecture.

Be proactive in identifying technical problems, but conservative in changing established product decisions.

Always prioritize correctness, maintainability, consistency, and the user's agreed development roadmap.
