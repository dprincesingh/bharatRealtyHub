# Bharat Realty Hub

A demo Salesforce Sales Cloud org built for learning — a real estate CRM where visitors on a public website can browse properties and enquire, enquiries land as Salesforce Leads, and (next up) get worked through a full sales pipeline to a closed deal.

This README doubles as the **product backlog** for the org. Stories are written the way a PM would hand them to a developer — read the story, build it yourself in the org, and come back for help wherever you get stuck.

- **Live website:** https://calm-fudge-9ed4cc.netlify.app/
- **Salesforce org:** `bharatRealtyHub` alias, Enterprise Edition trial
- **Guest site (public API + enquiry form):** https://site-velocity-6162.my.site.com/

## How to use this backlog

- **Status**: `Done` / `To Do` / `Backlog` (not yet prioritized)
- **Priority**: `P1` (do next) / `P2` / `P3`
- Each story has a **description**, **acceptance criteria**, and **notes** (hints, gotchas, or what's already in place to build on)

---

## Epic 1 — Website Lead Capture ✅ Done

Public visitors can browse published properties and submit an enquiry that becomes a Salesforce Lead.

### BRH-1 — Property data model
**Status:** Done
As an admin, I want Properties modeled as a distinct Account Record Type with all listing details, so the business has one place to manage inventory.
- Account Record Type `Property` with fields: Property Type, Listing Type (Sale/Rent), Price, Bedrooms, Bathrooms, Area, Status, Description, Image URL, Image Preview (formula), Is Published
- Dedicated `Property Layout` separate from the standard Account layout

### BRH-2 — Public property listing feed
**Status:** Done
As a website visitor, I want to see all currently available properties, so I can browse before enquiring.
- `PropertyListingService` (Apex REST, `/services/apexrest/properties`) returns published properties as JSON, callable anonymously
- Website fetches this live on every page load (no hardcoded data)
- CORS explicitly allowlisted for the Netlify domain

### BRH-3 — Guest enquiry form → Lead
**Status:** Done
As a website visitor, I want to submit my details against a specific property, so the agency can follow up with me.
- Guest-accessible LWC (`propertyEnquiryFlowLauncher`) on the Experience Cloud site, styled (warm luxury theme)
- `PropertyEnquiryController` creates a Lead: First/Last Name, Email, Phone, Message, `LeadSource = Website`, linked via `Property_Interest__c`, `Enquiry_Type__c` (Buy/Rent) derived from the property's Listing Type
- **Note:** Guest Users cannot run Screen Flows on this org (platform restriction, confirmed) — this had to be Apex + LWC, not declarative Flow. Keep that in mind before reaching for a Screen Flow for anything guest-facing.

### BRH-4 — Duplicate enquiry handling
**Status:** Done
As the business, I don't want 5 Leads created because someone clicked submit 5 times, so my pipeline stays clean.
- Before insert, checks for an existing **open** Lead with the same Email + Property within the last 30 days
- If found: appends the new message onto the existing Lead instead of creating a duplicate; no duplicate Slack ping (Slack alert only fires on Create)

### BRH-5 — Publish validation
**Status:** Done
As an admin, I don't want an incomplete listing to go live by accident.
- Record-triggered Flow (`Property_Publish_Validation`) on Account: when `Is_Published__c = true`, checks all required fields are filled
- Missing fields → auto-unpublish + log to `Error_Log__c`
- All complete → sends a Custom Notification confirming it's live

### BRH-6 — Slack alert on new Lead
**Status:** Done
As a sales rep, I want to know immediately when a website enquiry comes in.
- Flow (`New_Lead_Slack_Alert`) posts to `#new-leads` when a Lead is created with `LeadSource = Website`
- Fault path logs to `Error_Log__c` if the Slack post fails

### BRH-7 — Centralized error logging
**Status:** Done
As an admin, I want failures from anywhere in this app (Apex or Flow) captured in one place instead of vanishing silently.
- `Error_Log__c` object + `ErrorLogger` Apex class, usable from both Flow (`@InvocableMethod`) and Apex (static methods)
- Wired into every Apex entry point (`PropertyEnquiryController`, `PropertyListingService`) and the Slack alert Flow's fault path

---

## Epic 2 — Lead → Account/Contact/Opportunity 🔧 Next up (this is yours to build)

This is the natural next step: a website enquiry shouldn't just sit as a Lead forever. Once it's a real prospect, it needs to become an actual sales record — an Account (the buyer/renter), a Contact (the person), and an Opportunity (the deal being worked), linked back to the Property they're interested in.

### BRH-8 — Manual Lead conversion with mapped fields
**Status:** Done | **Priority:** P1

**As a** sales rep,
**I want** to convert a qualified Lead into a Contact and Opportunity with one click,
**so that** I can start actively working the deal instead of managing it as a raw Lead.

**Decision (made):** Conversion does **not** create a new Account. The Lead converts onto the **existing Property Account** it already points to (`Lead.Property_Interest__c`) — no buyer-company Account gets created. `Opportunity.AccountId` *is* the Property, so no separate "linked property" field was needed.

**What got built:**
- A **custom Apex conversion action** (`LeadConversionService.convertLead`) — the standard "Convert" button was ruled out because it either creates a new Account or requires the rep to manually search/select the right one (error-prone). This uses `Database.LeadConvert` with `setAccountId(lead.Property_Interest__c)` forced explicitly, so it's always correct, never a manual choice.
- A **Quick Action LWC** (`convertLeadAction`, exposed via `lightning__RecordAction`) added to the Lead's Highlights Panel (required enabling **Dynamic Actions** on the Highlights Panel — LWC actions won't appear in the picker without it) — shows a confirm dialog, calls the Apex, then navigates straight to the new Opportunity
- On conversion, the Opportunity gets: `AccountId` = the Property, `Amount` = the Property's `Price__c`, `CloseDate` = today + 30 days, `Purchase_Type__c` (new field, Buy/Rent) carried over from the Lead's `Enquiry_Type__c`
- `Term_In_Months__c` — a new Opportunity field (picklist 3–12, default 3) for rental deals, made conditionally visible via **Dynamic Forms** field visibility rules (`Purchase Type Equals Rent`) so it only shows for rentals
- Errors during conversion log to `Error_Log__c` via the existing `ErrorLogger`

**Notes / gotchas hit along the way:**
- The Converted Lead Status in this org is `Qualified`, not the usual default `Closed - Converted` — always check `Setup → Lead Statuses` rather than assuming
- `lightning__RecordAction` LWCs do **not** support per-object scoping via `<objects>` in the meta.xml (unlike other LWC targets) — including it silently breaks the action's registration
- `Database.LeadConvert` has no way to set `Amount`/`CloseDate`/custom fields directly — those need a follow-up `update` on the new Opportunity after conversion succeeds
- Lead conversion touches/re-saves the target Account even when reusing an existing one (not just on create) — this caused `Property_Publish_Validation` to re-fire its "Property Published" notification on every conversion. Fixed by gating that notification on `ISCHANGED({!$Record.Is_Published__c})` so it only fires on a genuine transition, not an incidental touch

**Not done (deliberately out of scope for BRH-8):** `Message__c` isn't currently mapped onto the Contact/Opportunity — still living only on the original (now converted) Lead.

### BRH-9 — Opportunity Negotiation → Property "Under Offer"
**Status:** Done | **Priority:** P2

As a sales rep, when an Opportunity reaches Negotiation, the Property should reflect that it's under offer (not just "Available"), so anyone looking at the Property record knows there's an active deal being worked.

**What got built:**
- Record-Triggered Flow **`Opportunity_Under_Offer`** on Opportunity — After Save, entry condition `StageName = 'Negotiation'`, guarded with a `ISCHANGED(StageName)` formula (same lesson as `Property_Publish_Validation`: without this, any unrelated touch to an Opportunity already sitting in Negotiation would re-fire the update every time)
- On match: updates the related Property Account (`Opportunity.AccountId`) → `Status__c = 'Under Offer'`
- Fault path logs to `Error_Log__c` via `ErrorLogger`, same pattern as every other Flow in this org

**Decision (deliberate):** forward-only, no auto-revert. If the Opportunity later leaves Negotiation (lost, or pushed back a stage), the Property does **not** automatically revert to "Available" — an admin does that manually. Reasoning: a Property can have more than one Opportunity against it (e.g. two interested parties), so auto-reverting on one Opportunity leaving Negotiation isn't safe — it could incorrectly reopen a Property still being negotiated with someone else. Handling that properly would mean querying sibling Opportunities, which wasn't worth the added complexity for this story.

**Verified:** moved a test Opportunity to Negotiation → linked Property (`Golden Acres Farmhouse`) flipped to `Under Offer` within ~20 seconds, no errors logged.

### BRH-10 — Opportunity close → Property status update
**Status:** Done | **Priority:** P2

When an Opportunity is Closed Won, the Property's `Status__c` should move to Sold/Rented, and `Is_Published__c` should be automatically unchecked so it stops showing as available on the live website.

**What got built:** Record-Triggered Flow **`Opportunity_Closed_Won_Property_Update`** on Opportunity — After Save, entry condition `StageName = 'Closed Won'`, same `ISCHANGED` guard pattern. Updates the related Property: `Status__c = 'Sold'` if `Purchase_Type__c = 'Buy'`, or `'Rented'` if `'Rent'`; `Is_Published__c = false` either way. Fault path logs to `Error_Log__c`.

This was originally built as part of the BRH-11 DocuSign exploration (see below) but is independent of *how* an Opportunity reaches Closed Won — it was kept when that feature's other parts were reverted, and will work unchanged once DocuSign (or anything else) sets the stage.

### BRH-11 — Contract Generation & E-Signature
**Status:** Parked | **Priority:** —

Explored two paths: a DIY in-house signing page (guest LWC + Apex, same pattern as the enquiry form) and DocuSign. Built and fully tested the DIY version end-to-end (send → view → sign → Closed Won cascade all worked), then reverted it entirely — decided real e-signature via DocuSign was the better fit going forward, not a custom-built signer.

**DocuSign findings so far:**
- The "DocuSign for Salesforce" AppExchange managed package is **paid** ($30/user/month) — not viable for a learning project, so that path is out
- Pivoted to the free path instead: DocuSign's own Developer/sandbox account (free) + custom Apex calling the DocuSign eSignature REST API directly (JWT Bearer auth via a Salesforce Named Credential, no AppExchange purchase needed)
- A contract Word template with merge-field placeholders (buyer, property details, price, term, and a property-photo link) was drafted and saved locally at `docusign/Property_Agreement_Template.docx` (not committed to this repo), ready to upload into DocuSign once the API integration is connected
- Setup was paused before completing DocuSign's Integration Key / RSA keypair / consent steps — pick back up there when ready

---

## Backlog — Ideas not yet started

Pulled from an earlier review of the whole system. Not prioritized — pick whatever's interesting to learn next.

- **Duplicate Rule on Lead** (native Salesforce feature) as a second layer on top of the Apex dedupe already in place
- **Spam/bot protection** on the public guest endpoints (honeypot field or rate limiting)
- **Lead assignment** — auto-assign new Leads to a rep or queue instead of defaulting to the running user
- **Reporting dashboard** — properties by status, leads by source, enquiry-to-close conversion funnel
- **Website filters** — by city, price range, bedrooms, property type (currently just a flat grid)
- **Property detail page** on the website before the enquiry form (currently goes straight from card to form)
- **Extend the luxury redesign** to the main website — only the enquiry form got restyled so far, there's a visual mismatch with the plain listing grid
- **Apex test classes** — none exist yet; not required for a trial org, but required (75% coverage) before this could ever move to a real production org

---

## Setup reference

- `force-app/` — all Salesforce metadata (source of truth, deploy with `sf project deploy start`)
- `website/` — the property listing site (deployed to Netlify, also mirrored at `~/Downloads/bharat-realty-hub-site/`)
- Org alias: `bharatRealtyHub` — `sf org display --target-org bharatRealtyHub`
