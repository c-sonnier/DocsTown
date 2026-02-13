# Plan 04: Draft Generation Pipeline

## Goal
Build the system that sends method context to three LLM providers and stores the resulting documentation drafts.

## Prerequisites
- Plan 00 (Project Setup)
- Plan 01 (Data Model — DraftVersion, DocumentationTask#build_prompt)
- Plan 03 (Discovery Pipeline — creates tasks in `drafting` status)

## Tasks

### 1. LLM Clients
Create three client classes in `app/clients/`:

**`ClaudeClient`** (`app/clients/claude_client.rb`)
- HTTP client to Anthropic Messages API
- Handle rate limiting and retries (3 retries, exponential backoff per README error handling strategy)
- Parse response and extract documentation text

**`OpenaiClient`** (`app/clients/openai_client.rb`)
- HTTP client to OpenAI Chat Completions API
- Handle rate limiting and retries
- Parse response and extract documentation text

**`KimiClient`** (`app/clients/kimi_client.rb`)
- HTTP client to Moonshot AI Kimi API
- Handle rate limiting and retries
- Parse response and extract documentation text

All three clients share the same public method signature:
```ruby
# @param prompt [String]
# @return [String] generated documentation
def generate(prompt:)
```

No `BaseClient` abstract class — duck typing is the interface. If all three respond to `#generate(prompt:)`, that is the contract. Verify with a shared test module:

```ruby
module ClientInterfaceTest
  def test_responds_to_generate
    assert_respond_to @client, :generate
  end
end
```

Include in each client's test class.

### 2. Label Randomization
- For each task, randomly assign which provider gets which label (A, B, C)
- Store the mapping via `provider` column on DraftVersion (for internal analytics)
- Voters never see provider names

### 3. Draft Generation Job
Create `DraftGenerationJob`:
- Picks up DocumentationTasks in `drafting` status that have no DraftVersions yet
- Calls `task.build_prompt` (defined on the model in Plan 01)
- Generates a random provider → label mapping
- Calls all three LLM clients sequentially
- Creates three `DraftVersion` records
- Calls `task.start_voting!` to transition `drafting` → `voting`
- Handle partial failures: if one provider fails after retries, create the task with available drafts (2 of 3 is acceptable for MVP). Log the failure.

### 4. Picking Up New Tasks
- A recurring Solid Queue job scans for tasks in `drafting` status without DraftVersions and enqueues `DraftGenerationJob` for each
- This decouples discovery from draft generation — no direct dependency between the two jobs

### 5. Rate Limiting
- Process draft generation jobs with concurrency limits (Solid Queue `limit` option on the recurring job or throttle in the job itself)
- Keep it simple for MVP: process one task at a time, no parallelism across providers

### 6. Tests
- Unit tests for each client with mocked HTTP responses
- Shared interface test module included in all three client test classes
- Integration test for full draft generation flow
- Test label randomization distribution
- Test partial failure handling (one provider down)
- Test task state transition from `drafting` to `voting`

## Output
Background job system that generates three LLM-powered documentation drafts per task and stores them for voting.

## Estimated Complexity
Medium — API integrations are straightforward, but error handling adds complexity.

## Notes
- The prompt is the most important thing to get right — plan for iteration
- `prompt_used` stored on each DraftVersion for auditing and prompt improvement
- Cost tracking deferred from MVP. Add `tokens_used` and `cost_cents` columns to DraftVersion when needed.
