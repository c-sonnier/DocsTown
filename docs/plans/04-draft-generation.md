# Plan 04: Draft Generation Pipeline

## Goal
Build the system that sends method context to three LLM providers and stores the resulting documentation drafts.

## Prerequisites
- Plan 00 (Project Setup)
- Plan 01 (Data Model — DraftVersion)
- Plan 03 (Discovery Pipeline — creates tasks that trigger draft generation)

## Tasks

### 1. Prompt Builder
Create `DraftGeneration::PromptBuilder`:
- Build a standardized prompt from DocumentationTask attributes:
  - Method signature
  - Method source code
  - Class/module context
  - Rails RDoc style guide conventions
- Include instructions for:
  - Writing in RDoc format
  - Matching Rails documentation tone and conventions
  - Including parameter descriptions, return values, examples
  - Appropriate length (concise but complete)
- Store the Rails documentation style guide as a reference document in the app

### 2. LLM Client Adapters
Create a common interface with three implementations:

**`DraftGeneration::Clients::Claude`**
- HTTP client to Anthropic Messages API
- Handle rate limiting and retries
- Parse response and extract documentation text

**`DraftGeneration::Clients::OpenAI`**
- HTTP client to OpenAI Chat Completions API
- Handle rate limiting and retries
- Parse response and extract documentation text

**`DraftGeneration::Clients::Gemini`**
- HTTP client to Google Gemini API
- Handle rate limiting and retries
- Parse response and extract documentation text

Common interface:
```ruby
class BaseClient
  def generate(prompt:) -> String  # returns generated documentation
end
```

### 3. Label Randomization
- For each task, randomly assign which provider gets which label (A, B, C)
- Store the mapping so we know which provider wrote which draft (for internal analytics)
- Ensure voters never see provider names

### 4. Draft Generation Job
Create `DraftGenerationJob`:
- Takes a `documentation_task_id`
- Builds the prompt
- Generates a random provider → label mapping
- Calls all three LLM providers (can be parallel or sequential)
- Creates three `DraftVersion` records
- Updates task status from `drafting` → `voting`
- Handle partial failures: if one provider fails, retry that provider, don't regenerate all three

### 5. Error Handling & Retries
- Retry failed LLM calls up to 3 times with exponential backoff
- If a provider consistently fails, log the error and create the task with available drafts (degrade gracefully)
- Track API costs/tokens used per generation (store in DraftVersion or separate log)

### 6. Rate Limiting & Cost Control
- Implement a rate limiter to avoid overwhelming LLM APIs
- Consider a daily/weekly cap on draft generations
- Process draft generation jobs with concurrency limits on the `drafts` queue

### 7. Tests
- Unit tests for PromptBuilder with various method types
- Mock LLM responses for client adapter tests
- Integration test for full draft generation flow
- Test label randomization distribution
- Test partial failure handling

## Output
Background job system that generates three LLM-powered documentation drafts per task and stores them for voting.

## Estimated Complexity
Medium — API integrations are straightforward, but error handling and rate limiting add complexity.

## Notes
- Consider using `ActiveSupport::Notifications` to instrument LLM API calls for monitoring
- The prompt is the most important thing to get right — plan for iteration
- Store `prompt_used` on each DraftVersion for auditing and prompt improvement
