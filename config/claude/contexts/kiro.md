## Spec-Driven Development (cc-sdd)

Kiro-style Spec Driven Development.

### Paths

- Working directory: `~/ghq/github.com/fohte/specs/`
- Steering: `steering/<repo>/`
- Features: `features/<feature>/`
- Settings: `.shared/settings/`
- Implementation repos: `~/ghq/github.com/fohte/<repo>`

### Steering vs Specification

- **Steering** (`steering/<repo>/`): Repository-wide rules and context
- **Features** (`features/<feature>/`): Formalize the development process for individual features

### Minimal Workflow

1. Phase 0 (optional): `/kiro:steering <repo>`, `/kiro:steering-custom <repo> <name>`
2. Phase 1 (Specification):
    - `/kiro:spec-init <target-repo> "description"`
    - `/kiro:spec-requirements {feature}`
    - `/kiro:spec-design {feature} [-y]`
    - `/kiro:spec-tasks {feature} [-y]`
3. Phase 2 (Implementation): `/kiro:spec-impl {feature} [tasks]`
4. Progress check: `/kiro:spec-status {feature}`

### Development Rules

- 3-phase approval workflow: Requirements -> Design -> Tasks -> Implementation
- Human review required each phase; use `-y` only for intentional fast-track
- Always work in `~/ghq/github.com/fohte/specs/` directory
- Implementation code is accessed at `~/ghq/github.com/fohte/<repo>`
