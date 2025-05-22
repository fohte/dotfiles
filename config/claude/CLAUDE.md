# Custom Instructions for AI Model

## ConPort Memory Strategy

**MUST** follow these instructions:

### 1. SETUP PHASE

- **Workspace ID Source**: Obtain the absolute path to current workspace for all ConPort tool calls

#### Initialization
Step 1: Initial check for ConPort database
- **Agent Action Plan**:
  1. Determine workspace path (ACTUAL_WORKSPACE_ID)
  2. Check for existing ConPort database in context_portal/
  3. Branch based on database existence
     - If context.db exists → load_existing_conport_context
     - Else context.db missing → handle_new_conport_setup

### 2. EXISTING DATABASE HANDLING

#### Load Existing ConPort Context
- **Agent Action Plan**:
  1. Load initial contexts from ConPort
     - Load product_context, active_context, decisions, progress, patterns, critical_settings, glossary
     - Get recent activity summary for quick catch-up
  2. Analyze loaded content and set status
     - If data exists → Set [CONPORT_ACTIVE], inform user
     - Else minimal data → Set [CONPORT_ACTIVE], suggest initialization
  3. Handle any load failures by falling back to inactive mode

### 3. NEW DATABASE SETUP

#### Handle New ConPort Setup
- **Agent Action Plan**:
  1. Inform user no database exists
  2. Ask if user wants to initialize new database
  3. Process user response
     - If user wants new database:
       - Check for projectBrief.md to bootstrap initial content
       - If found, offer to import content into Product Context
       - If not found, offer manual definition
       - Proceed to load_existing_conport_context
     - If user declines:
       - Set inactive mode

### 4. INACTIVE FALLBACK

- **If ConPort unavailable or init failed**: Set [CONPORT_INACTIVE], continue without ConPort

### 5. GENERAL BEHAVIOR

- **Status prefix**: Begin EVERY response with [CONPORT_ACTIVE] or [CONPORT_INACTIVE]
- **Proactive logging**: Identify opportunities to log decisions/progress, confirm with user

### 6. SYNC COMMAND SEQUENCE

#### ConPort Sync Routine
- **Trigger**: ^(Sync ConPort|ConPort Sync)$
- **User acknowledgement text**: [CONPORT_SYNCING]
- **Instructions**:
  1. Stop current activity
  2. Send [CONPORT_SYNCING] to user
  3. Analyze chat history for new information
- **Core update process**:
  - Log new decisions, progress, patterns
  - Update contexts if changed
  - Log new custom data
  - Create relationships between items
  - Summarize changes made
- **Post-sync actions**:
  - Inform user: ConPort synchronized
  - Resume previous task or await instructions

### 7. DYNAMIC RETRIEVAL PROCESS

#### Dynamic Context Retrieval for RAG
- **Steps**:
  1. Analyze user query to identify needed information
  2. Select retrieval strategy based on query type
  3. Retrieve initial set of relevant items
  4. Expand context with related items if needed
  5. Filter and synthesize into concise summary
  6. Structure response with attribution to sources
- **General principles**:
  - Prefer targeted retrieval over broad context dumps
  - Iterate if initial results are insufficient
  - Balance detail with brevity

### 8. KNOWLEDGE GRAPH BUILDING

#### Proactive Knowledge Graph Linking
- **Steps**:
  1. Monitor conversation for potential item relationships
  2. Identify specific items that could be linked
  3. Suggest creating appropriate relationship link
  4. If user confirms, create link with proper relationship type
  5. Confirm successful linking
- **General principles**:
  - Focus on meaningful relationships
  - Be helpful but not intrusive
  - Use standard relationship types when possible

### 9. PROMPT CACHING STRATEGY

- **Enabled**: true
- **Core approach**:
  - Identify stable, cacheable content (>750 tokens)
  - Place at beginning of prompt
  - Append variable content after cached sections
  - Handle updates by refreshing cached content
- **Priority content**:
  1. Product context (high stability)
  2. Complex system patterns
  3. Large custom data items with cache_hint:true
  4. Stable portions of active context
- **Provider handling**:
  - Gemini: Use implicit caching with stable prefix
  - Anthropic: Use explicit cache_control breakpoints
  - OpenAI: Leverage automatic caching for large prompts
