# Back Button Implementation Audit

## Views Analysis

### ✅ Views WITH Proper Back Buttons
1. **AuthenticationView** - ❌ No back button (CORRECT - root view)
2. **MainTabView** - ❌ No back button (CORRECT - root tab view)
3. **InventoryItemDetailView** - ✅ Has "Close" button in toolbar
4. **ScoutingReportDetailView** - ❌ Missing back button (needs one)
5. **QuickScoutView** - ✅ Has "Cancel" button in toolbar
6. **CreateScoutingReportView** - ✅ Has "Cancel" button in toolbar
7. **CreateScoutingTemplateView** - ✅ Has "Cancel" button in toolbar
8. **EditScoutingSectionView** - ✅ Has "Cancel" button in toolbar
9. **AddScoutingFieldView** - ✅ Has "Cancel" button in toolbar
10. **AddScoutingSectionView** - ✅ Has "Cancel" button in toolbar
11. **TemplatePickerView** - ✅ Has "Cancel" button in toolbar
12. **StockAdjustmentView** - ✅ Has "Cancel" button in toolbar
13. **TeamCreationView** - ✅ Has "Cancel" button in toolbar
14. **TeamJoinView** - ✅ Has "Cancel" button in toolbar
15. **EditInventoryItemView** - ✅ Has "Cancel" button in toolbar
16. **AddInventoryItemView** - ✅ Has "Cancel" button in toolbar
17. **PasswordResetView** - ✅ Has "Cancel" button in toolbar

### ❌ Views MISSING Back Buttons
1. **ScoringCalculatorView** - Missing back button (needs one)
2. **RulesReferenceView** - Missing back button (needs one)
3. **MatchScheduleView** - Missing back button (needs one)
4. **DriveTeamTimerView** - Missing back button (needs one)

### 🤔 Views That DON'T Need Back Buttons
1. **AuthenticationView** - Root authentication view
2. **MainTabView** - Root tab navigation
3. **TeamView** - Part of main tab
4. **InventoryView** - Part of main tab
5. **ScoutingView** - Part of main tab
6. **CompetitionView** - Part of main tab
7. **SettingsView** - Part of main tab
8. **ScoutingTemplatesView** - Part of scouting tab
9. **ScoutingReportsView** - Part of scouting tab
10. **ScoutingAnalyticsView** - Part of scouting tab

## Implementation Plan

### Phase 1: Add Missing Back Buttons
Add back buttons to the 4 views that are missing them:
1. ScoringCalculatorView
2. RulesReferenceView
3. MatchScheduleView
4. DriveTeamTimerView

### Phase 2: Standardize Back Button Style
Ensure all back buttons use consistent styling and placement.

## Back Button Design Guidelines

### Placement
- **Leading position** in navigation bar toolbar
- **Text**: "Back" or "Close" depending on context
- **Icon**: Optional chevron.left icon

### Styling
- Use `minimalButtonStyle()` from design system
- Consistent with app's design language
- Accessible touch targets (44x44pt minimum)

### Context-Specific Labels
- **Detail views**: "Back"
- **Modal sheets**: "Close" or "Cancel"
- **Form views**: "Cancel"
- **Tool views**: "Back"
