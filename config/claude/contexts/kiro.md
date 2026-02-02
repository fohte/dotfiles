## Spec-Driven Development (cc-sdd)

Kiro-style Spec Driven Development.

### Paths

- Steering: `.kiro/steering/`
- Specs: `.kiro/specs/`

Actual files are in `~/ghq/github.com/fohte/specs/<project>/.kiro/`, and each repository's `.kiro` is a symlink to it.

### Steering vs Specification

- **Steering** (`.kiro/steering/`): Project-wide rules and context
- **Specs** (`.kiro/specs/`): Formalize the development process for individual features

### Minimal Workflow

1. Phase 0 (optional): `/kiro:steering`, `/kiro:steering-custom`
2. Phase 1 (Specification):
    - `/kiro:spec-init "description"`
    - `/kiro:spec-requirements {feature}`
    - `/kiro:spec-design {feature} [-y]`
    - `/kiro:spec-tasks {feature} [-y]`
3. Phase 2 (Implementation): `/kiro:spec-impl {feature} [tasks]`
4. Progress check: `/kiro:spec-status {feature}`

### Development Rules

- 3-phase approval workflow: Requirements → Design → Tasks → Implementation
- Human review required each phase; use `-y` only for intentional fast-track
