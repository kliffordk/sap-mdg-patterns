# SAP MDG Patterns

Practical design patterns for SAP Master Data Governance (MDG) — validations, derivations, workflow, field properties, mass processing and consolidation — explained the way I'd explain them to a developer joining an MDG project.

SAP documentation tells you *what* each framework and BAdI does. These patterns focus on the part that's harder to find written down: **which approach to choose, why, and what tends to go wrong.**

> **Independent project.** Not affiliated with, endorsed by, or representing SAP or any employer or client. All examples are written from scratch against SAP's standard data models. Always verify object names, method signatures and behaviour against your own release.

---

## Patterns

| # | Pattern | Area | Status |
|---|---|---|---|
| 1 | [Choosing between BRF+ and BAdI for validations](patterns/validations/brf-vs-badi-validation/README.md) | Validations | Illustrative |
| 2 | Cross-entity checks without hurting performance | Validations | Planned |
| 3 | A reusable derivation pattern | Derivations | Planned |
| 4 | Creating a successor change request from a system method | Workflow | Planned |
| 5 | Email notifications and SLA tracking in rule-based workflow | Workflow | Planned |
| 6 | Dynamic agent determination without hard-coding users | Workflow | Planned |
| 7 | Field properties by change request type and step | Field properties | Planned |
| 8 | Designing a custom mass-change application | Mass processing | Planned |
| 9 | Adding custom fields to the data model — a checklist | Data model | Planned |
| 10 | Onboarding a developer new to MDG: the first two weeks | Leadership | Planned |

**Status meanings**
- **Tested** — code was executed on the release named in the pattern.
- **Illustrative** — the design is the point; code shows the structure and has not been executed. Expect to adjust signatures for your release.
- **Planned** — not written yet.

## How each pattern is organized

Every pattern follows the same [template](templates/PATTERN_TEMPLATE.md):

1. Problem
2. When to use / when not to
3. Options compared
4. Recommended design
5. Implementation sketch
6. Testing
7. Pitfalls
8. Release notes
9. Related patterns

## Who this is for

- Developers new to SAP MDG who know ABAP but not the MDG frameworks
- Functional consultants who want to understand the technical trade-offs behind a design
- Technical leads looking for a shared vocabulary for design reviews

## Contributing

Corrections, release-specific notes and new pattern ideas are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

## Author

**Klifford Kurt Kho** — Senior SAP MDG Consultant & Technical Lead
[kliffordkho.vercel.app](https://kliffordkho.vercel.app) · [LinkedIn](https://www.linkedin.com/in/kliffordk/)

## Licence

- Code (`*.abap` and other source files): [MIT](LICENSE)
- Written content (`*.md`): [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) — reuse it with attribution.

SAP, SAP MDG, S/4HANA, BRF+ and other SAP product names are trademarks of SAP SE.
