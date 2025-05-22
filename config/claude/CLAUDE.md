# Custom Instructions for AI Model

## ConPort Memory Strategy

**MUST** follow these instructions:

```yaml
conport_memory_strategy:
  # 1. SETUP PHASE
  workspace_id_source: "Obtain the absolute path to current workspace for all ConPort tool calls"
  
  initialization:
    # Step 1: Initial check for ConPort database
    agent_action_plan:
      - step: 1
        action: "Determine workspace path (ACTUAL_WORKSPACE_ID)"
      - step: 2
        action: "Check for existing ConPort database in context_portal/"
      - step: 3
        action: "Branch based on database existence"
        conditions:
          - if: "context.db exists → load_existing_conport_context"
          - else: "context.db missing → handle_new_conport_setup"
  
  # 2. EXISTING DATABASE HANDLING
  load_existing_conport_context:
    agent_action_plan:
      - step: 1
        description: "Load initial contexts from ConPort"
        actions:
          - "Load product_context, active_context, decisions, progress, patterns, critical_settings, glossary"
          - "Get recent activity summary for quick catch-up"
      - step: 2
        description: "Analyze loaded content and set status"
        conditions:
          - if: "Data exists → Set [CONPORT_ACTIVE], inform user"
          - else: "Minimal data → Set [CONPORT_ACTIVE], suggest initialization"
      - step: 3
        description: "Handle any load failures by falling back to inactive mode"
  
  # 3. NEW DATABASE SETUP
  handle_new_conport_setup:
    agent_action_plan:
      - step: 1
        action: "Inform user no database exists"
      - step: 2
        action: "Ask if user wants to initialize new database"
      - step: 3
        description: "Process user response"
        conditions:
          - if_user_wants_new_database:
            actions:
              - "Check for projectBrief.md to bootstrap initial content"
              - "If found, offer to import content into Product Context"
              - "If not found, offer manual definition"
              - "Proceed to load_existing_conport_context"
          - if_user_declines:
            action: "Set inactive mode"
  
  # 4. INACTIVE FALLBACK
  if_conport_unavailable_or_init_failed:
    agent_action: "Set [CONPORT_INACTIVE], continue without ConPort"
  
  # 5. GENERAL BEHAVIOR
  general:
    status_prefix: "Begin EVERY response with [CONPORT_ACTIVE] or [CONPORT_INACTIVE]"
    proactive_logging: "Identify opportunities to log decisions/progress, confirm with user"
  
  # 6. SYNC COMMAND SEQUENCE
  conport_sync_routine:
    trigger: "^(Sync ConPort|ConPort Sync)$"
    user_acknowledgement_text: "[CONPORT_SYNCING]"
    instructions:
      - "1. Stop current activity"
      - "2. Send [CONPORT_SYNCING] to user"
      - "3. Analyze chat history for new information"
    core_update_process:
      agent_action_plan:
        - "Log new decisions, progress, patterns"
        - "Update contexts if changed"
        - "Log new custom data"
        - "Create relationships between items"
        - "Summarize changes made"
    post_sync_actions:
      - "Inform user: ConPort synchronized"
      - "Resume previous task or await instructions"
  
  # 7. DYNAMIC RETRIEVAL PROCESS
  dynamic_context_retrieval_for_rag:
    steps:
      - step: 1
        action: "Analyze user query to identify needed information"
      - step: 2
        action: "Select retrieval strategy based on query type"
      - step: 3
        action: "Retrieve initial set of relevant items"
      - step: 4
        action: "Expand context with related items if needed"
      - step: 5
        action: "Filter and synthesize into concise summary"
      - step: 6
        action: "Structure response with attribution to sources"
    general_principles:
      - "Prefer targeted retrieval over broad context dumps"
      - "Iterate if initial results are insufficient"
      - "Balance detail with brevity"
  
  # 8. KNOWLEDGE GRAPH BUILDING
  proactive_knowledge_graph_linking:
    steps:
      - step: 1
        action: "Monitor conversation for potential item relationships"
      - step: 2
        action: "Identify specific items that could be linked"
      - step: 3
        action: "Suggest creating appropriate relationship link"
      - step: 4
        action: "If user confirms, create link with proper relationship type"
      - step: 5
        action: "Confirm successful linking"
    general_principles:
      - "Focus on meaningful relationships"
      - "Be helpful but not intrusive"
      - "Use standard relationship types when possible"

# 9. PROMPT CACHING STRATEGY
prompt_caching_strategies:
  enabled: true
  core_approach:
    - "Identify stable, cacheable content (>750 tokens)"
    - "Place at beginning of prompt"
    - "Append variable content after cached sections"
    - "Handle updates by refreshing cached content"
  
  priority_content:
    - "1. Product context (high stability)"
    - "2. Complex system patterns"
    - "3. Large custom data items with cache_hint:true"
    - "4. Stable portions of active context"
  
  provider_handling:
    - "Gemini: Use implicit caching with stable prefix"
    - "Anthropic: Use explicit cache_control breakpoints"
    - "OpenAI: Leverage automatic caching for large prompts"
```