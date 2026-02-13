# Plan 03: Discovery Pipeline

## Goal
Build the automated system that clones the Rails repo, parses Ruby source files, identifies undocumented public methods, and creates DocumentationTask records.

## Prerequisites
- Plan 00 (Project Setup)
- Plan 01 (Data Model — Project, DocumentationTask)

## Tasks

### 1. Repository Management Service
Create `DiscoveryService::RepoManager`:
- Clone `rails/rails` to a local working directory (e.g., `tmp/repos/rails-rails/`)
- If already cloned, `git pull` to update to latest main
- Track the current HEAD commit SHA for reference
- Handle clone/pull failures gracefully

### 2. Ruby Method Parser
Create `DiscoveryService::MethodParser`:
- Walk all `.rb` files in the Rails source tree
- For each file, parse and extract:
  - Public method definitions (instance and class methods)
  - Method signature (class/module path + method name)
  - Method source code
  - Surrounding class/module context
- Use one of:
  - **Ripper** (Ruby's built-in parser) — lightweight but lower-level
  - **Prism** (Ruby 3.3+ default parser) — modern, better AST
  - **parser** gem — mature, well-documented AST
- Recommended: **Prism** since we're on Ruby 3.3+ and it's the standard

### 3. Documentation Gap Detector
Create `DiscoveryService::GapDetector`:
- For each parsed public method, determine if it has RDoc documentation
- Check for:
  - Comment block immediately preceding the method definition
  - `# :nodoc:` directive (skip these — intentionally undocumented)
  - Methods in `private` or `protected` sections (skip)
- Output a list of undocumented method signatures with their metadata

### 4. Task Creator
Create `DiscoveryService::TaskCreator`:
- For each undocumented method, find or create a `DocumentationTask`
- Use `method_signature` + `project_id` uniqueness to avoid duplicates
- Only create tasks for methods not already tracked
- Set initial status to `drafting`
- Enqueue draft generation jobs for new tasks

### 5. Discovery Job
Create `DiscoveryJob`:
- Orchestrates the full pipeline: clone/pull → parse → detect gaps → create tasks
- Runs as a Solid Queue job on the `discovery` queue
- Update `project.last_scanned_at` on completion
- Log statistics: methods scanned, gaps found, tasks created

### 6. Scheduled Execution
- Configure Solid Queue recurring schedule for weekly discovery runs
- Allow manual triggering from admin interface (future)

### 7. Tests
- Unit tests for MethodParser with sample Ruby files
- Unit tests for GapDetector with documented and undocumented methods
- Integration test for full discovery pipeline with a small fixture repo
- Test idempotency — running discovery twice doesn't create duplicates

## Output
A scheduled job that scans Rails source code and populates the database with DocumentationTask records for undocumented public methods.

## Estimated Complexity
High — Ruby parsing is the most technically complex part of the MVP. Needs careful handling of Ruby's method visibility semantics.

## Key Risks
- **Parser accuracy:** Ruby's method visibility is complex (reopened classes, `module_function`, `public`/`private` blocks vs inline). May need iterative refinement.
- **Scale:** Rails has thousands of public methods. Initial scan will create a large batch of tasks. Consider batching or rate-limiting draft generation.
- **Edge cases:** DSL-generated methods (e.g., `has_many`, `scope`) may appear as undocumented. Need heuristics to filter framework-generated methods vs hand-written ones.

## Open Decisions
- Which Ruby parser to use (Prism recommended)
- Whether to store the commit SHA on each task for version tracking
- How to handle methods that become documented between discovery and voting (staleness check)
