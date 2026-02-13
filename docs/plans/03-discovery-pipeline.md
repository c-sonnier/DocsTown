# Plan 03: Discovery Pipeline

## Goal
Build the automated system that clones the Rails repo, parses Ruby source files, identifies undocumented public methods, and creates DocumentationTask records.

## Prerequisites
- Plan 00 (Project Setup)
- Plan 01 (Data Model — Project, DocumentationTask)

## Tasks

### 1. Repository Manager
Create `Discovery::RepoManager` in `app/services/discovery/`:
- Clone `rails/rails` to a persistent working directory
- If already cloned, `git pull` to update to latest main
- Track the current HEAD commit SHA for reference
- Handle clone/pull failures gracefully

**Storage strategy:**
- Development: `tmp/repos/rails-rails/`
- Production: persistent volume mount at `/data/repos/` (Fly.io volumes or Render persistent disks)
- The clone directory MUST survive deploys. Ephemeral filesystems (default on most PaaS) will force a full re-clone on every deploy. Configure a persistent disk in the deployment plan.
- If persistent storage is unavailable, fall back to GitHub API content fetching (slower per-file but no disk dependency)

### 2. Method Parser
Create `Discovery::MethodParser` in `app/services/discovery/`:
- Walk all `.rb` files in the Rails source tree
- For each file, parse and extract:
  - Public method definitions (instance and class methods)
  - Method signature (class/module path + method name)
  - Method source code
  - Surrounding class/module context
- Use **Prism** (Ruby 3.3+ default parser) for AST parsing
- Filter out:
  - Methods in `private` or `protected` sections
  - Methods with `# :nodoc:` directive
  - DSL-generated methods (`has_many`, `scope`, `delegate`, etc.) — use heuristics to detect framework-generated definitions vs hand-written ones

### 3. Gap Detection (private method on MethodParser or inline in DiscoveryJob)
Gap detection is a simple filter predicate — does this method have a comment block preceding it? This does not need its own class:
- Check for RDoc comment block immediately preceding the method definition
- Skip methods that already have documentation
- Output: list of undocumented method signatures with metadata

### 4. Task Creation (inline in DiscoveryJob)
Creating tasks from discovered methods is a straightforward database operation:
- Use `insert_all` with `on_duplicate: :skip` for bulk creation (far more efficient than individual `find_or_create_by` for thousands of methods)
- Set initial status to `drafting`
- Use `method_signature` + `project_id` uniqueness to avoid duplicates

Note: Task creation does NOT enqueue draft generation jobs. Tasks are created in `drafting` status. A separate process (Plan 04's `DraftGenerationJob`) picks up `drafting` tasks. This avoids a hard dependency between the Discovery and Draft Generation pipelines.

### 5. Discovery Job
Create `DiscoveryJob`:
- Orchestrates the full pipeline: clone/pull → parse → detect gaps → bulk create tasks
- Runs as a Solid Queue job on the `default` queue
- Update `project.last_scanned_at` on completion
- Log statistics: methods scanned, gaps found, tasks created

### 6. Scheduled Execution
- Configure Solid Queue recurring schedule for weekly discovery runs
- Allow manual triggering from admin interface (future)

### 7. Tests
- Unit tests for MethodParser with sample Ruby files
- Unit tests for gap detection with documented and undocumented methods
- Integration test for full discovery pipeline with a small fixture repo
- Test idempotency — running discovery twice doesn't create duplicates
- Test `insert_all` bulk creation behavior

## Output
A scheduled job that scans Rails source code and populates the database with DocumentationTask records for undocumented public methods.

## Estimated Complexity
High — Ruby parsing is the most technically complex part of the MVP. Needs careful handling of Ruby's method visibility semantics.

## Key Risks
- **Parser accuracy:** Ruby's method visibility is complex (reopened classes, `module_function`, `public`/`private` blocks vs inline). May need iterative refinement.
- **Scale:** Rails has thousands of public methods. Initial scan will create a large batch of tasks. `insert_all` handles this efficiently.
- **Edge cases:** DSL-generated methods (e.g., `has_many`, `scope`) may appear as undocumented. Need heuristics to filter framework-generated methods vs hand-written ones.
- **Production storage:** Must have persistent disk for the repo clone. See storage strategy in Task 1.
