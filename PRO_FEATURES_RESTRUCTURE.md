# Pro Features Restructure: Outcome-Driven Monetization

## 🎯 Core Problem

**Current paywall**: Feature-focused ("dark mode", "PDF export", "advanced features")
**New approach**: Outcome-focused ("Save $3,412 on debt", "Cut concentration risk", "86% chance to hit goals")

People pay for **results**, not features.

---

## 🆓 Move to Free Tier (Retention Drivers)

These don't sell subscriptions but increase daily engagement and trust:

### 1. Dark Mode
- **Why free**: Standard expectation, not a differentiator
- **Benefit**: Increases daily usage, improves retention
- **Implementation**: Remove `isPro` check from dark mode toggle

### 2. Basic Export
- **What's free**: CSV export of accounts/liabilities
- **Why free**: Builds trust, enables backup, doesn't provide strategic value
- **What stays Pro**: Advanced exports (PDF reports with recommendations, tax-loss harvesting reports)

### 3. Basic Alerts
- **What's free**: Simple notifications ("payment due tomorrow", "drift > 10%")
- **Why free**: Keeps users engaged, prevents churn
- **What stays Pro**: Custom alerts with dollar-impact context

**Result**: Free users stay engaged → trust builds → convert to Pro when they need outcomes

---

## 💰 Pro Features (High-Value, Outcome-Driven)

### 1. Debt Payoff Optimizer 🎯 **SHIP FIRST**
**The Hook**: "Save $3,412 in interest"

**What it does**:
- User enters current debts (balance, APR, min payment)
- Calculate avalanche vs snowball strategies
- Show **total interest saved** with each method
- Display **payoff date** comparison
- Generate **month-by-month payment schedule**

**UI Copy**:
```
Current plan: Paid off in 4 years, 2 months → $8,450 interest
Avalanche: Paid off in 3 years, 8 months → $5,038 interest
💰 Save $3,412 by switching strategies
```

**Paywall Trigger**: Show comparison free, gate "Generate Payment Schedule" button

**Why it converts**: 
- Uses their actual data
- Shows immediate, quantified savings
- Actionable plan they can execute today

**Technical Complexity**: ⭐️ LOW (you already have liability data and PMT logic)

---

### 2. Rebalancing Autopilot 🎯 **SHIP FIRST**
**The Hook**: "Move $2,150 this month to cut concentration risk"

**What it does**:
- Calculate concentration risk from current allocation
- Generate **specific trade/transfer list**: "Sell $1,500 VTI, Buy $1,000 VXUS, Move $650 to BND"
- Show **before/after risk metrics**: "Concentration: 42% → 18% (cap: 20%)"
- Estimate **volatility reduction**: "Expected annual volatility: -2.3%"
- Glide path options: DCA over 1/3/6 months vs immediate

**UI Copy**:
```
Your US Equity: 89.4% (cap: 20%)
Suggested monthly move: $2,150 for 6 months

Action Plan:
1. Transfer $1,500 from Brokerage → 401k bonds
2. Within 401k: Sell $650 Company Stock → International

Risk Reduction:
• Concentration: 89.4% → 22.1% → 18.3% (on track)
• Est. volatility drop: 2.8% annual drawdown protection
```

**Paywall Trigger**: Show "Your concentration: 89%" free, gate "Generate Trade Plan"

**Why it converts**:
- Uses their exact portfolio
- Specific, executable instructions
- Quantified risk reduction

**Technical Complexity**: ⭐️⭐️ MEDIUM (you have the math, need UI for trade list)

---

### 3. What-If Scenario Engine 🎯 **SHIP SECOND**
**The Hook**: "Add $150/mo → 86% chance to hit $1M goal"

**What it does**:
- Sliders for: monthly contribution, expected return, worst-year drawdown, target amount, years to goal
- Run **Monte Carlo simulation** (1,000 scenarios) showing probability distribution
- Compare multiple scenarios side-by-side
- Save/load scenarios for comparison

**UI Copy**:
```
Base Case ($500/mo, 7% return):
→ 68% chance to hit $1M in 30 years

With $150 more/mo:
→ 86% chance to hit $1M in 30 years
→ Or hit goal 3.2 years earlier at same probability

Bad-year stress test (-30% drawdown):
→ Recover by year 4 with continued contributions
```

**Paywall Trigger**: Allow 1 free scenario, Pro gets unlimited + save/compare

**Why it converts**:
- Answers "Will I make it?" anxiety
- Shows impact of small changes
- Makes retirement planning tangible

**Technical Complexity**: ⭐️⭐️⭐️ MEDIUM-HIGH (Monte Carlo is just loops, but need good UX)

---

### 4. Tax-Smart Allocation Advisor 🎯 **SHIP THIRD**
**The Hook**: "Est. $480/year saved with smarter asset location"

**What it does**:
- Asset location optimizer: suggest which accounts hold which assets
- Basic tax-loss harvesting identification (mark lots with losses manually)
- Show estimated annual tax savings

**UI Copy**:
```
Current Setup:
• Bonds in Brokerage (taxed annually): -$320/yr
• Stocks in 401k (tax-deferred): $0 impact

Optimized Setup:
• Move bonds to 401k (tax-deferred): +$320/yr
• Keep stocks in Brokerage (long-term gains): $0
💰 Est. $480/year saved (includes rebalancing benefit)

Tax-Loss Harvesting Opportunities:
• VTI in Taxable down 12% → Harvest $1,840 loss → Est. $442 tax benefit
```

**Paywall Trigger**: Show "Tax drag: $320/yr" free, gate "Generate Tax Plan"

**Why it converts**:
- Immediate annual savings
- Often pays for Pro subscription in first year
- Advanced users love tax optimization

**Technical Complexity**: ⭐️⭐️⭐️ MEDIUM-HIGH (need tax rate assumptions, account type rules)

---

### 5. Custom Alerts with Dollar Context 🎯 **SHIP SECOND**
**The Hook**: "Alert: US Equity hit 82% → Adds ~$4,200 excess risk"

**What it does**:
- Custom thresholds for: concentration caps, drift %, DSCR, employer stock %, liquidity ratio
- Each alert shows **dollar impact** or **risk quantification**
- Priority sorting by severity

**UI Copy**:
```
🔴 CONCENTRATION BREACH
US Equity: 82% (your cap: 20%)
→ Excess concentration: 62%
→ Est. added portfolio risk: ~$4,200 in 10% drawdown scenario
→ Suggested action: Move $2,150/mo for 6 months

🟡 EMPLOYER STOCK HIGH
Company Stock: 14% (your cap: 10%)
→ Career + portfolio risk: 4% over diversified
→ Suggested action: Sell $1,840 → Reallocate to bonds/intl
```

**Paywall Trigger**: Basic alerts free (due date, > 10% drift), custom rules + context are Pro

**Why it converts**:
- Turns alerts into action items
- Quantifies the "why it matters"
- Feels like a financial advisor

**Technical Complexity**: ⭐️⭐️ MEDIUM (threshold logic easy, context calculation needs thought)

---

### 6. Advanced Allocation Tools 🎯 **SHIP THIRD**
**The Hook**: "Optimize for lower correlation → Better risk-adjusted returns"

**What it does**:
- **HHI (Herfindahl Index)**: Measure true concentration across all asset classes
- **Factor exposure**: Show US/Intl/REITs/Alts breakdown with suggested caps
- **Custom scoring weights**: Let Pro users adjust debt/liquidity/concentration weights in health score
- **Multi-portfolio tracking**: Track "Retirement" vs "Taxable" vs "Kids' 529" separately

**UI Copy**:
```
Portfolio HHI: 0.72 (Higher = more concentrated)
Target HHI: < 0.40 (diversified)

Factor Exposure:
• US Equity: 72% (cap: 60%) ⚠️
• International: 10% (cap: 30%) ✓
• Bonds: 15% (cap: 40%) ✓
• Alternatives: 3% (cap: 10%) ✓

Suggested rebalancing:
→ Reduce US to 60%
→ Increase Intl to 25%
→ Result: HHI drops to 0.38 ✓
```

**Paywall Trigger**: Show basic allocation pie chart free, advanced metrics/recommendations Pro

**Why it converts**:
- Appeals to sophisticated investors
- Provides portfolio analysis they'd pay $100+/hr for
- Differentiates from Mint/Personal Capital

**Technical Complexity**: ⭐️⭐️⭐️ MEDIUM-HIGH (math is straightforward, UI is complex)

---

## 💵 New Pricing Structure

### Current (Doesn't Work)
- ❌ $1.49/month: Signals "toy app"
- ❌ $9.99 lifetime: Kills MRR, undervalues product
- ❌ No trial: High friction to test

### New (Value Ladder)
```
FREE TIER
✓ Core tracking (unlimited accounts)
✓ Financial health score
✓ Dark mode
✓ Basic CSV export
✓ Payment reminders
✓ Basic allocation view

PRO MONTHLY: $3.99/month
✓ Everything in Free, plus:
💰 Debt optimizer → Save $X interest
📊 Rebalancing autopilot → Cut concentration
🎯 What-if scenarios → Hit retirement goals
⚡ Custom alerts with context
📈 Tax-smart allocation tips
🔬 Advanced portfolio analytics

PRO ANNUAL: $24/year
✓ Same as monthly
💰 Save $24 vs monthly (2 months free)
🎁 Priority feature requests

FOUNDER LIFETIME: $49 (Limited to first 1,000)
✓ Everything forever
✓ Early supporter badge
✓ Exclusive Discord/feedback access
🔒 Remove option after 1,000 sales
```

### Trial Strategy
- **Option A**: 7-day free trial (standard)
- **Option B**: First month $0.99 (lower barrier, more commits than trial)
- **14-day money-back guarantee** (reduces purchase anxiety)

---

## 🎨 Paywall Copy That Converts

### Replace Current Bullet List With Outcome Bullets

**Old (Feature-Focused)**:
```
Pro Features:
• Dark mode and custom themes
• Advanced charts and analytics
• PDF/CSV export
• Priority support
```

**New (Outcome-Focused)**:
```
Unlock Pro → Save Money & Reduce Risk

💰 Debt Optimizer
→ Your debts: Save est. $3,412 in interest
→ Payoff 6 months faster with avalanche method

📊 Rebalancing Autopilot  
→ Your portfolio: Cut concentration from 89% → 18%
→ Reduce volatility by 2.8% annually

🎯 What-If Planning
→ Your retirement: 68% → 86% success with +$150/mo
→ Hit $1M goal 3.2 years earlier

⚡ Smart Alerts
→ Concentration breach adds $4,200 excess risk
→ Get actionable alerts, not just notifications

💵 Tax-Smart Moves
→ Your setup: Save est. $480/year with better location
→ Identify tax-loss harvesting opportunities
```

### Add Personalized Hero Stat
Instead of generic pitch, use their data:

```
[ Unlock Pro ]

Based on your current portfolio:
"Pro would save you $3,412 in debt interest 
 and cut concentration risk by 71%"

✓ 7-day free trial • Cancel anytime
✓ 14-day money-back guarantee
```

---

## 🔒 Strategic Paywall Placement

### 1. Inline CTAs on Key Screens

**Dashboard Concentration Card**:
```
[Free View]
Your US Equity: 89.4%
⚠️ High concentration risk

[Button: "Build Rebalancing Plan" → Paywall]
```

**Debt Screen Summary**:
```
[Free View]
Total Debt: $42,150
Est. Interest: $8,450
Payoff Date: May 2029

[Button: "Optimize Payoff Strategy" → Paywall]
Shows: "Save $3,412 with Pro debt optimizer"
```

**Financial Health Score**:
```
[Free View]
Overall Health: C (72/100)
• Debt: 30/100 ⚠️
• Concentration: 0/100 ❌
• Liquidity: 80/100 ✓

[Button: "See Improvement Plan" → Paywall]
Shows: "Pro users raise their score 18 pts avg in 90 days"
```

### 2. Lock Icons on Advanced Actions
- Show preview/summary for free
- Gate actual execution/plan generation behind Pro

### 3. Comparison Table
Side-by-side Free vs Pro showing outcomes, not features:

| Feature | Free | Pro |
|---------|------|-----|
| **Debt Tracking** | ✓ Basic | ✓ + Save $3.4K avg |
| **Rebalancing** | Manual | ✓ Auto plan + trades |
| **Goal Planning** | View only | ✓ Monte Carlo + scenarios |
| **Alerts** | Basic | ✓ Custom + $ context |
| **Tax Optimization** | — | ✓ Est. $480/yr saved |

---

## 🚀 Fastest Features to Ship (No Broker Integration)

### Week 1: Debt Optimizer
- **Why first**: Simplest math, immediate payoff
- **What you have**: Liability data structure, PMT calculation
- **What you need**: Avalanche/snowball comparison UI, interest saved calc
- **Estimated time**: 8-12 hours
- **Conversion impact**: ⭐️⭐️⭐️⭐️⭐️ (everyone has debt)

### Week 2: Rebalancing Autopilot
- **Why second**: You already built the rebalancing screen
- **What you have**: Concentration calculation, target allocation logic
- **What you need**: Trade list generator, before/after risk display
- **Estimated time**: 12-16 hours
- **Conversion impact**: ⭐️⭐️⭐️⭐️⭐️ (core value prop)

### Week 3: Custom Alerts
- **Why third**: Builds on existing health score
- **What you have**: All calculation logic
- **What you need**: User-configurable thresholds, notification system, context strings
- **Estimated time**: 10-14 hours
- **Conversion impact**: ⭐️⭐️⭐️⭐️ (retention driver)

### Week 4: Scenario Engine
- **Why fourth**: More complex UX
- **What you have**: Nothing yet
- **What you need**: Monte Carlo logic (simple loops), slider UI, chart rendering
- **Estimated time**: 16-20 hours
- **Conversion impact**: ⭐️⭐️⭐️⭐️⭐️ (anxiety reducer, high perceived value)

---

## 📊 Success Metrics

### Pre-Restructure (Current)
- Free-to-Pro conversion: ~1-2% (typical for weak value prop)
- MRR per user: $1.49
- Lifetime LTV: $9.99 (most go lifetime)
- Churn: Unknown but likely high

### Post-Restructure (Target)
- Free-to-Pro conversion: 5-8% (strong outcome-driven value)
- MRR per user: $3.99 monthly OR $2/mo from annual ($24/yr)
- Lifetime LTV: $48-96 (12-24 months avg retention)
- Churn: < 5%/month (sticky due to outcomes)

### First 90 Days Goals
1. Ship debt optimizer + rebalancing autopilot
2. Update Pro screen with outcome copy
3. Add personalized CTAs on dashboard/debt screens
4. Implement 7-day free trial or $0.99 first month
5. Track: trial starts, conversions, churn

**Target**: 100 Pro users in first 90 days (assuming 2,000 free users)

---

## 🎯 Implementation Priority

### Phase 1: Quick Wins (Ship by Week 2)
1. ✅ Move dark mode to free
2. ✅ Move basic CSV export to free
3. ✅ Create debt optimizer with interest saved
4. ✅ Enhance rebalancing screen with trade list
5. ✅ Rewrite Pro screen with outcome copy
6. ✅ Add personalized CTA on dashboard

### Phase 2: Core Value (Ship by Week 4)
1. ✅ Custom alerts with dollar context
2. ✅ Scenario engine with Monte Carlo
3. ✅ Update pricing to $3.99/mo, $24/yr
4. ✅ Add 7-day trial or $0.99 first month
5. ✅ Create Free vs Pro comparison table

### Phase 3: Advanced (Ship by Week 8)
1. ✅ Tax-smart allocation advisor
2. ✅ Advanced portfolio analytics (HHI, factors)
3. ✅ Multi-portfolio tracking
4. ✅ Custom scoring weights

---

## 💬 Key Messaging Principles

### 1. Always Show Their Data
❌ "Optimize your debt"  
✅ "Save $3,412 on your $42K debt"

### 2. Quantify Everything
❌ "Reduce concentration risk"  
✅ "Cut concentration from 89% → 18% (2.8% volatility reduction)"

### 3. Make It Actionable
❌ "Advanced rebalancing tools"  
✅ "Move $2,150 this month → Specific trade list"

### 4. Use Social Proof
❌ "Join Pro today"  
✅ "Pro users raise health scores 18 pts avg in 90 days"

### 5. Remove Anxiety
❌ "Subscribe now"  
✅ "7-day free trial • 14-day money-back guarantee • Cancel anytime"

---

## 🎬 Next Steps

1. **This week**: Implement debt optimizer + update Pro screen copy
2. **Next week**: Enhance rebalancing with trade list + add dashboard CTAs
3. **Week 3**: Ship custom alerts + update pricing
4. **Week 4**: Build scenario engine + launch trial flow
5. **Month 2**: Monitor conversions, iterate on copy, build tax features

**The goal**: Transform from "nice features" to "this pays for itself."
