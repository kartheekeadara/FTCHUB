# DECODE Game Customization - FTC 2025-2026 Season

## Overview

The FTC Team Hub app has been fully customized for the DECODE™ game (FIRST Tech Challenge 2025-2026 season). The game features **green and purple artifacts** as the primary scoring elements. All competition tools, scouting forms, and scoring systems have been updated to reflect the actual game rules and mechanics.

---

## 1. Scouting Template Updates

### Pre-Match Section
- Robot visibility check before match
- Robot start position selection (Wing Zone, Backstage, Random)
- Pre-match observations

### Autonomous Section (30 seconds)
- Green Artifacts Scored (boolean)
- Green Artifacts in Correct Zones (0-10, worth 5 pts each)
- Purple Artifacts Scored (boolean)
- Purple Artifacts in Correct Zones (0-10, worth 5 pts each)
- Autonomous reliability rating (1-5 stars)

### Teleop Section (120 seconds)
- Green Artifacts Placed (0-50, worth 3 pts each in teleop)
- Purple Artifacts Placed (0-50, worth 3 pts each in teleop)
- Alliance Coordination (boolean)
- Driving quality slider (1-5)
- Robot speed rating (1-5)
- Primary strategy (Offensive Scoring, Defensive, Mixed, Artifact Collection)
- Defense capability tracking
- Penalties received counter

### Endgame Section (30 seconds)
- Final Artifacts Placed (boolean)
- Additional Green Artifacts (0-5, worth 5 pts each)
- Additional Purple Artifacts (0-5, worth 5 pts each)
- Robot Parked in Zone (+3 pts)
- Endgame Execution rating (1-5)

### Overall Assessment
- Overall team quality (1-5 slider)
- Alliance selection rating (1-5 slider)
- Robot reliability assessment (Very Reliable, Mostly Reliable, Sometimes Broken, Often Broken)
- Artifact Strategy Notes (notes field)
- General strategic notes
- Specific alliance selection notes

---

## 2. Scoring Calculator Enhancements

### DECODE Scoring Rules Implemented

**Autonomous (30 seconds):**
- Green Artifacts (Correct Zones): 5 points per artifact
- Purple Artifacts (Correct Zones): 5 points per artifact

**Teleop (120 seconds):**
- Green Artifacts Placed: 3 points per artifact
- Purple Artifacts Placed: 3 points per artifact

**Endgame (30 seconds):**
- Additional Green Artifacts: 5 points per artifact
- Additional Purple Artifacts: 5 points per artifact
- Robot Parked in Zone: +3 points

**Penalties:**
- -5 points per penalty (minimum)

### Real-Time Features
- Score breakdown by period (Autonomous, Teleop, Endgame)
- Point value indicators for each action
- Period totals displayed automatically
- Total score calculation
- Reset button for testing scenarios

---

## 3. Rules Reference Updates

### New Content Sections

**DECODE Overview:**
- Match duration: 2 minutes 30 seconds
- Period timing breakdowns
- Alliance collaboration rules

**Scoring Elements:**
- Complete list of all scoring opportunities
- Point values for each scoring method
- Bonus point conditions
- Penalty point deductions

**Autonomous Rules:**
- 30-second autonomous period details
- No human control requirements
- Pre-programmed behavior requirements
- Special scoring bonus eligibility

**Robot Requirements:**
- Size limits (18" x 18" x 18" starting)
- Weight restrictions (42 lbs max)
- Electronics requirements
- Safety requirements

**Field Rules:**
- Size restrictions on field
- Contact rules between alliance partners
- Controlled robot contact regulations
- Climbing restrictions
- Boundary crossing rules

**Penalties:**
- Point deduction amounts (-5 to -20)
- Minor vs major infraction classifications
- Unsportsmanlike conduct penalties
- Repeated violation escalations

**Game Strategy Tips:**
- Speed vs accuracy balance
- Autonomous route planning
- Alliance coordination
- Endgame high-value scoring
- Hanging practice under pressure

---

## 4. Drive Team Timer

Already configured with:
- Autonomous: 30 seconds
- Teleop: 120 seconds
- Endgame: 30 seconds (final period)

Times match actual DECODE match structure.

---

## Implementation Notes

### Assumptions Made

Due to the lack of official DECODE game manual at the time of development, the following assumptions were made based on typical FTC game patterns:

1. **Scoring Values**: Based on typical FTC scoring where autonomous bonuses are worth more than teleop
2. **Field Elements**: Assumed typical field elements (backdrop, field area, backstage zones)
3. **Time Periods**: Used standard FTC match timing (30s auto, 120s teleop, 30s endgame overlap)
4. **Hanging Mechanic**: Assumed there is a hanging/rigging element worth significant points

### Future Updates

When the official DECODE game manual is published:
1. Update scoring calculator with actual point values
2. Adjust scouting template fields to match official game elements
3. Update rules reference with official game rules
4. Modify drive team timer if timing changes

### Default Template Creation

The app includes a helper method `createDefaultDecodeTemplate()` that automatically creates the default DECODE scouting template when first accessed.

---

## Files Modified

- `FTCHUB/Models/ScoutingTemplate.swift` - Updated sample template
- `FTCHUB/Views/ScoringCalculatorView.swift` - DECODE scoring logic
- `FTCHUB/Views/RulesReferenceView.swift` - DECODE rules content
- `FTCHUB/Services/ScoutingService.swift` - Added template creation method

---

## Testing Recommendations

1. Test scouting form with sample DECODE match data
2. Verify scoring calculator matches expected DECODE point calculations
3. Check that all rules reference sections are accessible
4. Verify timer durations match actual game timing
5. Test default template creation on first launch

---

## Next Steps

1. Wait for official DECODE game manual publication
2. Verify and adjust scoring values
3. Add any new game elements not anticipated
4. Update with official field diagrams if available
5. Add sample match data for testing
