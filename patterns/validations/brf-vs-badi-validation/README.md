# Choosing between BRF+ and BAdI for validations

> Every validation rule should have exactly one home. This pattern helps you decide whether that home is configuration, BRF+, or ABAP in a BAdI — and how to structure the BAdI so it stays testable.

| | |
|---|---|
| **Area** | Validations |
| **Status** | Illustrative — code not executed |
| **Applies to** | SAP MDG on S/4HANA, central governance — concepts apply across recent releases |
| **Domains** | Material in the examples; the decision applies to any domain |

> Items marked **[VERIFY]** depend on your release — check them in your system before relying on them.

---

## 1. Problem

The business hands over a list of data rules: *"Finished goods must have a material group." "Trading goods need the old material number for traceability." "A supplier's bank country must match the payment method."*

SAP MDG gives you several places to put each rule. On most projects, rules end up scattered across all of them: some in BRF+, some in a BAdI, some as mandatory-field settings, a few duplicated in two places. Six months later nobody can say where a rule lives, the same check fires twice with different wording, and mass processing slows down because one rule does a database read for every record.

The technical question — *BRF+ or BAdI?* — is really a design question: **who should own the rule, how often will it change, and how expensive is it to run?**

## 2. When to use / when not to

**Use this pattern when**
- You're designing validations for a new MDG implementation or a new domain
- A design review needs a consistent rule for where checks belong
- An existing project has rules scattered and duplicated, and you're cleaning up

**Don't use it for**
- *Derivations* (filling values automatically) — related but different trade-offs; see the derivation pattern
- Checks that standard MDG or the backend already performs — don't re-implement them (see option 1 below)

## 3. Options compared

| # | Option | Good for | Watch out for |
|---|---|---|---|
| 1 | **Standard checks** — data model and domain checks, check tables, and the backend checks the reuse area already runs **[VERIFY: which backend checks run for your domain]** | Formats, allowed values, existence of keys | Re-implementing them in BRF+ or ABAP "to be safe" — you get duplicate messages and double maintenance |
| 2 | **Field properties** — mandatory / read-only / hidden per change request type and step | "This field is required *at this step*" | Using a validation to make a field mandatory. Field properties show the requirement in the UI before the user submits |
| 3 | **BRF+ rules** — decision tables and expressions on the entity's trigger function **[VERIFY: trigger function naming in your release]** | Simple, single-entity conditions; rules the business wants to read or change; values that change often | Complex logic, loops, reading other entity types, heavy lookups. BRF+ becomes hard to read and test once logic branches |
| 4 | **BAdI** — ABAP implementation of the rule service BAdI (`USMD_RULE_SERVICE`) **[VERIFY: BAdI and interface names in SE18]** | Cross-entity checks, logic that reads other tables, performance-critical rules, anything that needs unit tests | Hard-coded values, logic buried in one huge method, no test coverage, developer needed for every change |

### Quick decision guide

```
Is it already checked by the data model, a check table, or the backend?
 └─ Yes → Option 1. Don't add another check.
 └─ No
     Is it really "field X is required at step Y"?
      └─ Yes → Option 2 (field properties).
      └─ No
          Does it only look at fields of ONE entity, with simple conditions,
          and should the business be able to read or adjust it?
           └─ Yes → Option 3 (BRF+, ideally a decision table).
           └─ No → Option 4 (BAdI), using the structure in section 5.
```

## 4. Recommended design

### 4.1 One home per rule, written down

Keep a **rule catalogue** — a simple table, owned by the functional lead, reviewed in design sessions:

| Rule ID | Description | Domain / entity | Where implemented | Severity | Owner |
|---|---|---|---|---|---|
| MAT-001 | Listed material types require a material group | Material / MATERIAL | BAdI (`ZCL_..._VALIDATOR`) | Error | Product data team |
| MAT-002 | Trading goods should have an old material number | Material / MATERIAL | BAdI | Warning | Product data team |
| MAT-003 | Net weight must not exceed gross weight | Material / MATERIAL | BRF+ decision table | Error | Logistics |

Put the rule ID in the message text. When a user or tester reports a message, anyone can find the rule in seconds.

### 4.2 BRF+: keep it readable

- Prefer **decision tables** over nested expressions — they're the part the business can actually read.
- One rule per decision table row or expression; name them with the rule ID.
- Keep values that change (material types, thresholds) in the table, not in formulas.

### 4.3 BAdI: thin shell, testable core

The most useful structural decision for BAdI validations is to **keep the BAdI method thin**:

```
BAdI implementation (framework-facing)
  1. Is this an entity type I handle?  If not, return.
  2. Map framework data → simple structure
  3. Read configuration (customizing table, not hard-coded values)
  4. Call the validator
  5. Map validator messages → framework message table
          │
          ▼
Validator class (plain ABAP, no MDG dependencies)
  - one method per rule, named by rule ID
  - takes simple structures, returns messages
  - fully covered by ABAP Unit tests
```

Why this matters:
- **Testable.** The validator has no dependency on the MDG framework, so ABAP Unit tests run in seconds without creating change requests.
- **Readable.** Each rule is one short method you can review on its own.
- **Reusable.** The same validator can be called from a mass-change program or a data migration check.
- **Configurable.** Values the business may change live in a customizing table, passed in through the constructor.

## 5. Implementation sketch

Files in this folder (abapGit naming):

| File | What it is |
|---|---|
| [`zcl_mdgp_material_validator.clas.abap`](zcl_mdgp_material_validator.clas.abap) | The validator — plain ABAP, one method per rule |
| [`zcl_mdgp_material_validator.clas.testclasses.abap`](zcl_mdgp_material_validator.clas.testclasses.abap) | ABAP Unit tests for every rule |
| [`zcl_mdgp_rule_service.clas.abap`](zcl_mdgp_rule_service.clas.abap) | The thin BAdI shell — structure only; **[VERIFY]** interface and method signatures in SE18/SE19 |

Example rules used in the code:
- **MAT-001 (error):** material types listed in configuration must have a material group.
- **MAT-002 (warning):** trading goods (`HAWA`) should carry an old material number for traceability.

These rules are invented for illustration. Replace them with your own.

## 6. Testing

| # | Scenario | Expected result |
|---|---|---|
| 1 | Material type in the configured list, material group empty | Error MAT-001 on field MATKL |
| 2 | Same material type, material group filled | No message |
| 3 | Material type *not* in the list, material group empty | No message |
| 4 | Configuration list is empty | No MAT-001 messages at all (see pitfall on empty ranges) |
| 5 | Trading good without old material number | Warning MAT-002 on field BISMT |
| 6 | Change request with 500 materials (mass processing) | Validation time stays acceptable; no database reads per record |
| 7 | Same rule also exists in BRF+ | Should never happen — check the rule catalogue |

Cases 1–5 are covered by the ABAP Unit tests. Cases 6–7 are integration and design-review checks.

## 7. Pitfalls

- **Same rule in two places.** A BRF+ rule and a BAdI check with slightly different wording. Users see two messages and testers raise two defects. The rule catalogue prevents this.
- **Validations used as mandatory-field settings.** Field properties show the requirement in the UI before the user submits; a validation only complains afterwards.
- **Empty ranges in ABAP.** `value IN range` is *true* when the range is empty. If configuration is missing, a rule meant for "these types" suddenly applies to *every* type. Always guard: `IF range IS NOT INITIAL AND value IN range`.
- **Database reads inside the loop.** Fine for one record, painful for a 5,000-record mass change. Read lookup data once, before the loop.
- **Hard-coded values.** Material types, plants and thresholds belong in a customizing table, not in the code.
- **Messages without context.** "Field is invalid" helps nobody. Include the rule ID, the field and the value.
- **Errors where warnings would do.** An error blocks the change request. Agree severity with the business per rule — and record it in the catalogue.
- **Re-implementing backend checks.** Check what already runs when data is activated before writing your own.

## 8. Release notes

- Written against: SAP MDG on S/4HANA (central governance) concepts
- Tested on: **not executed** — illustrative
- Verify for your release: rule service BAdI and interface names, method signatures, BRF+ trigger function naming, and which backend checks run for your domain

## 9. Related patterns

- Cross-entity checks without hurting performance *(planned)*
- A reusable derivation pattern *(planned)*
- Field properties by change request type and step *(planned)*
