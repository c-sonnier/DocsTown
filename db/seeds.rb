# frozen_string_literal: true

ActiveRecord::Base.transaction do
  # ---------- Project ----------
  project = Project.find_or_create_by!(github_repo: "rails/rails") do |p|
    p.name = "Ruby on Rails"
    p.default_branch = "main"
  end
  project.update!(last_scanned_at: 1.day.ago)

  # ---------- Users ----------
  User.where(github_username: "c-sonnier").update_all(role: :admin)
  csonnier = User.find_by(github_username: "c-sonnier") || User.create!(
    github_username: "c-sonnier",
    github_uid: "100000",
    avatar_url: "https://avatars.githubusercontent.com/u/100000",
    email: "c-sonnier@example.com",
    role: :admin
  )

  user_data = [
    { github_uid: "100001", github_username: "rails-fan42",  avatar_url: "https://avatars.githubusercontent.com/u/234501" },
    { github_uid: "100002", github_username: "docsmith",     avatar_url: "https://avatars.githubusercontent.com/u/234502" },
    { github_uid: "100003", github_username: "rubyista",     avatar_url: "https://avatars.githubusercontent.com/u/234503" },
    { github_uid: "100004", github_username: "pr-machine",   avatar_url: "https://avatars.githubusercontent.com/u/234504" },
    { github_uid: "100005", github_username: "syntax-sage",  avatar_url: "https://avatars.githubusercontent.com/u/234505" },
    { github_uid: "100006", github_username: "test-ninja",   avatar_url: "https://avatars.githubusercontent.com/u/234506" },
    { github_uid: "100007", github_username: "gem-hunter",   avatar_url: "https://avatars.githubusercontent.com/u/234507" }
  ]

  voters = user_data.map do |data|
    User.find_or_create_by!(github_uid: data[:github_uid]) do |u|
      u.github_username = data[:github_username]
      u.avatar_url = data[:avatar_url]
      u.email = "#{data[:github_username]}@example.com"
      u.role = :voter
    end
  end

  all_users = [csonnier] + voters

  # ---------- Task definitions ----------
  tasks_config = [
    # 5 voting tasks
    {
      method_signature: "ActiveRecord::Base.connection_pool",
      source_file_path: "activerecord/lib/active_record/connection_adapters/pool.rb",
      source_code: <<~RUBY,
        def connection_pool
          connection_handler.retrieve_connection_pool(name, role: current_role, shard: current_shard)
        end
      RUBY
      class_context: "class ActiveRecord::Base\n  # Connection pool management for database connections\nend",
      status: :voting
    },
    {
      method_signature: "ActionController::Metal#process_action",
      source_file_path: "actionpack/lib/action_controller/metal.rb",
      source_code: <<~RUBY,
        def process_action(method_name, *args)
          run_callbacks(:process_action) do
            super
          end
        end
      RUBY
      class_context: "class ActionController::Metal < AbstractController::Base\n  # Core action processing pipeline\nend",
      status: :voting
    },
    {
      method_signature: "ActiveSupport::Notifications.subscribe",
      source_file_path: "activesupport/lib/active_support/notifications.rb",
      source_code: <<~RUBY,
        def subscribe(pattern = nil, callback = nil, &block)
          notifier.subscribe(pattern, callback, monotonic: false, &block)
        end
      RUBY
      class_context: nil,
      status: :voting
    },
    {
      method_signature: "ActionMailer::Base#deliver_now",
      source_file_path: "actionmailer/lib/action_mailer/message_delivery.rb",
      source_code: <<~RUBY,
        def deliver_now
          processed_mailer.handle_exceptions do
            message.deliver
          end
        end
      RUBY
      class_context: "class ActionMailer::MessageDelivery < Delegator\n  # Wraps mail delivery with error handling\nend",
      status: :voting
    },
    {
      method_signature: "ActiveRecord::Relation#load",
      source_file_path: "activerecord/lib/active_record/relation.rb",
      source_code: <<~RUBY,
        def load(&block)
          if !loaded? || scheduled?
            @records = exec_queries(&block)
            @loaded = true
          end
          self
        end
      RUBY
      class_context: nil,
      status: :voting
    },

    # 3 pending_review tasks
    {
      method_signature: "ActionView::Helpers::FormHelper#form_with",
      source_file_path: "actionview/lib/action_view/helpers/form_helper.rb",
      source_code: <<~RUBY,
        def form_with(model: nil, scope: nil, url: nil, format: nil, **options, &block)
          options[:allow_method_names_outside_object] = true
          options[:skip_default_ids] = !form_with_generates_ids
          if model
            url ||= polymorphic_path(model, format: format)
            model = model.last if model.is_a?(Array)
            scope ||= model_name_from_record_or_class(model).param_key
          end
          builder = instantiate_builder(scope, model, options)
          output = capture(builder, &block)
          builder.multipart? ? html_options_for_form_with(url, model, **options) : output
        end
      RUBY
      class_context: "module ActionView::Helpers::FormHelper\n  # Provides form building helpers\nend",
      status: :pending_review
    },
    {
      method_signature: "ActiveJob::Base.perform_later",
      source_file_path: "activejob/lib/active_job/enqueuing.rb",
      source_code: <<~RUBY,
        def perform_later(*args)
          job = job_or_instantiate(*args)
          enqueue_result = job.enqueue
          yield job if block_given?
          enqueue_result
        end
      RUBY
      class_context: "module ActiveJob::Enqueuing::ClassMethods\n  # Handles job enqueue logic\nend",
      status: :pending_review
    },
    {
      method_signature: "ActionCable::Channel::Base#stream_from",
      source_file_path: "actioncable/lib/action_cable/channel/streams.rb",
      source_code: <<~RUBY,
        def stream_from(broadcasting, callback = nil, coder: nil, &block)
          broadcasting = String(broadcasting)
          coder ||= ActiveSupport::JSON
          streams << [ broadcasting, callback || block, coder ]
          connection.server.event_loop.post do
            pubsub.subscribe(broadcasting, handler, proc { transmit_subscription_confirmation })
          end
        end
      RUBY
      class_context: nil,
      status: :pending_review
    },

    # 2 submitted tasks
    {
      method_signature: "ActiveStorage::Blob#download",
      source_file_path: "activestorage/lib/active_storage/blob.rb",
      source_code: <<~RUBY,
        def download(&block)
          if block_given?
            service.download(key, &block)
          else
            service.download(key)
          end
        end
      RUBY
      class_context: "class ActiveStorage::Blob < ActiveStorage::Record\n  # Represents an uploaded file in the storage service\nend",
      status: :submitted,
      pr_url: "https://github.com/rails/rails/pull/54321",
      pr_status: :open
    },
    {
      method_signature: "ActiveModel::Validations#validate",
      source_file_path: "activemodel/lib/active_model/validations.rb",
      source_code: <<~RUBY,
        def validate(*args, &block)
          if args.empty? && block_given?
            validates_with(BlockValidator, _validates_default_keys.merge(block: block))
          else
            set_callback(:validate, *args, &block)
          end
        end
      RUBY
      class_context: "module ActiveModel::Validations::ClassMethods\n  # Adds validation support to any object\nend",
      status: :submitted,
      pr_url: "https://github.com/rails/rails/pull/54287",
      pr_status: :open
    },

    # 2 merged tasks
    {
      method_signature: "ActiveRecord::Migration#change",
      source_file_path: "activerecord/lib/active_record/migration.rb",
      source_code: <<~RUBY,
        def change
          raise IrreversibleMigration unless defined?(@change)
          @change
        end
      RUBY
      class_context: "class ActiveRecord::Migration\n  # Abstract base for database migrations\nend",
      status: :merged,
      pr_url: "https://github.com/rails/rails/pull/53998",
      pr_status: :merged
    },
    {
      method_signature: "ActionDispatch::Routing::Mapper#resources",
      source_file_path: "actionpack/lib/action_dispatch/routing/mapper.rb",
      source_code: <<~RUBY,
        def resources(*resources, &block)
          options = resources.extract_options!.dup
          if apply_common_behavior_for(:resources, resources, options, &block)
            return self
          end
          with_scope_level(:resources) do
            options = apply_action_options(options)
            resource_scope(Resource.new(resources.pop, api_only?, @scope[:shallow], options)) do
              yield if block_given?
              concerns(options[:concerns]) if options[:concerns]
              collection { post :create } if parent_resource.actions.include?(:create)
              new { get :new } if parent_resource.actions.include?(:new)
            end
          end
        end
      RUBY
      class_context: nil,
      status: :merged,
      pr_url: "https://github.com/rails/rails/pull/53876",
      pr_status: :merged
    }
  ]

  # ---------- Draft content templates ----------
  drafts_for = {
    "ActiveRecord::Base.connection_pool" => [
      { label: :a, provider: "claude", content: <<~RDOC },
        # Returns the connection pool associated with this class.
        #
        # Retrieves the connection pool from the connection handler for the current
        # role and shard configuration. The connection pool manages a set of reusable
        # database connections, reducing the overhead of establishing new connections
        # for each database operation.
        #
        # Returns an instance of +ActiveRecord::ConnectionAdapters::ConnectionPool+.
      RDOC
      { label: :b, provider: "openai", content: <<~RDOC },
        # Grabs the connection pool for this model's database.
        #
        # Think of it as a shared bucket of database connections that your app
        # reuses instead of opening a new one every time. It respects whatever
        # role (reading/writing) and shard you're currently using.
        #
        #   pool = ActiveRecord::Base.connection_pool
        #   pool.size  # => 5 (default)
      RDOC
      { label: :c, provider: "kimi", content: <<~RDOC }
        # Returns the connection pool for this class.
        #
        # Params: none
        # Returns: +ConnectionPool+ — the pool for the current role and shard.
        # Raises: +ConnectionNotEstablished+ if no pool is configured.
      RDOC
    ],
    "ActionController::Metal#process_action" => [
      { label: :a, provider: "openai", content: <<~RDOC },
        # Executes the specified controller action within the process_action callback chain.
        #
        # This method wraps the action execution in +run_callbacks(:process_action)+,
        # ensuring that all registered before, around, and after filters are invoked
        # in the correct order. It delegates to the superclass implementation for the
        # actual method dispatch.
        #
        # +method_name+:: Symbol or String — the action name to process.
      RDOC
      { label: :b, provider: "kimi", content: <<~RDOC },
        # Runs a controller action with all its callbacks.
        #
        # When a request comes in and hits your controller, this is the method
        # that actually fires it. It wraps everything in callbacks so your
        # before_action and after_action filters all run in the right order.
        #
        #   # Typically called by the router, not directly:
        #   controller.process_action(:index)
      RDOC
      { label: :c, provider: "claude", content: <<~RDOC }
        # Processes the named action with callbacks.
        #
        # Params:
        # - +method_name+ — Symbol or String, the action to invoke.
        # - +*args+ — additional arguments forwarded to the action.
        # Returns: the result of the action.
      RDOC
    ],
    "ActiveSupport::Notifications.subscribe" => [
      { label: :a, provider: "kimi", content: <<~RDOC },
        # Subscribes to an instrumentation event by name or pattern.
        #
        # Registers a callback that will be invoked whenever an event matching the
        # given +pattern+ is published via +ActiveSupport::Notifications.instrument+.
        # The subscriber receives the event name, start time, end time, a unique ID,
        # and a payload hash containing event-specific data.
        #
        # +pattern+:: String, Regexp, or nil — the event name to subscribe to. Pass +nil+ to subscribe to all events.
      RDOC
      { label: :b, provider: "claude", content: <<~RDOC },
        # Listen for instrumentation events in your Rails app.
        #
        # Use this to hook into things like SQL queries, cache hits, or your own
        # custom events. Pass a name (or regex) and a block:
        #
        #   ActiveSupport::Notifications.subscribe("sql.active_record") do |event|
        #     Rails.logger.debug event.duration
        #   end
        #
        # Pass +nil+ to catch everything (careful, it's noisy!).
      RDOC
      { label: :c, provider: "openai", content: <<~RDOC }
        # Subscribes to instrumentation events.
        #
        # Params:
        # - +pattern+ — String, Regexp, or nil. Event name/pattern to match.
        # - +callback+ — callable, or provide a block.
        # Returns: a subscriber object (use with +unsubscribe+).
      RDOC
    ],
    "ActionMailer::Base#deliver_now" => [
      { label: :a, provider: "claude", content: <<~RDOC },
        # Delivers the email message synchronously.
        #
        # Processes the mailer action and delivers the resulting email immediately,
        # blocking until delivery is complete. Any exceptions raised during delivery
        # are handled by the mailer's exception handling mechanism, which by default
        # will re-raise the exception.
        #
        # Returns the +Mail::Message+ that was delivered.
      RDOC
      { label: :b, provider: "openai", content: <<~RDOC },
        # Sends the email right now, without queuing.
        #
        # Unlike +deliver_later+, this sends the email inline and blocks until
        # it's done. Great for transactional emails where you need confirmation:
        #
        #   UserMailer.welcome(user).deliver_now
        #
        # If something goes wrong, the mailer's error handling kicks in.
      RDOC
      { label: :c, provider: "kimi", content: <<~RDOC }
        # Delivers the email synchronously.
        #
        # Params: none
        # Returns: +Mail::Message+
        # Raises: delivery errors unless rescued by handle_exceptions.
        # See also: +deliver_later+ for async delivery.
      RDOC
    ],
    "ActiveRecord::Relation#load" => [
      { label: :a, provider: "openai", content: <<~RDOC },
        # Executes the query and loads the resulting records into memory.
        #
        # If the relation has not yet been loaded (or was previously scheduled for
        # lazy evaluation), this method triggers the SQL query execution and caches
        # the result set. Subsequent calls return the cached records without hitting
        # the database. Returns +self+ to allow method chaining.
        #
        # Accepts an optional block that is passed to +exec_queries+.
      RDOC
      { label: :b, provider: "kimi", content: <<~RDOC },
        # Forces the query to run and loads all records into memory.
        #
        # Normally, ActiveRecord is lazy — it won't touch the database until
        # you actually need the records. Call +load+ when you want to force
        # that query to run right now:
        #
        #   posts = Post.where(published: true).load
        #   posts.each { |p| ... }  # no additional query
      RDOC
      { label: :c, provider: "claude", content: <<~RDOC }
        # Eagerly loads the relation's records.
        #
        # Params:
        # - +&block+ — optional block forwarded to exec_queries.
        # Returns: +self+ (the relation, now loaded).
        # Note: no-op if already loaded and not scheduled.
      RDOC
    ],
    "ActionView::Helpers::FormHelper#form_with" => [
      { label: :a, provider: "claude", content: <<~RDOC },
        # Creates a form tag based on mixing URLs, scopes, or models.
        #
        # This is the primary form helper in Rails, superseding +form_for+ and
        # +form_tag+. It generates an HTML form element and yields a form builder
        # to the given block. When a +model+ is provided, the form action URL and
        # field scoping are automatically inferred via +polymorphic_path+.
        #
        # +model+:: an ActiveRecord object or array for nested resources.
        # +url+:: explicit form action URL. Inferred from model if not given.
        # +scope+:: the scope to prefix field names with.
      RDOC
      { label: :b, provider: "openai", content: <<~RDOC },
        # The go-to helper for building forms in Rails.
        #
        # Pass a model and it figures out the URL and method for you:
        #
        #   <%= form_with(model: @post) do |f| %>
        #     <%= f.text_field :title %>
        #     <%= f.submit %>
        #   <% end %>
        #
        # Works great with Turbo — remote by default since Rails 7.
      RDOC
      { label: :c, provider: "kimi", content: <<~RDOC }
        # Generates an HTML form element.
        #
        # Params:
        # - +model+ — ActiveRecord object (optional).
        # - +scope+ — String, field name prefix (optional).
        # - +url+ — String, form action URL (optional, inferred from model).
        # - +format+ — Symbol, URL format suffix (optional).
        # Returns: HTML-safe form string.
      RDOC
    ],
    "ActiveJob::Base.perform_later" => [
      { label: :a, provider: "openai", content: <<~RDOC },
        # Enqueues the job for asynchronous execution by the configured queue adapter.
        #
        # Instantiates the job with the provided arguments (if not already instantiated)
        # and places it on the queue for background processing. The queue adapter
        # (Sidekiq, Resque, etc.) determines when and how the job is executed.
        #
        # +*args+:: the arguments to pass to the job's +perform+ method.
        # Returns the enqueued job instance.
      RDOC
      { label: :b, provider: "kimi", content: <<~RDOC },
        # Queue this job to run in the background.
        #
        # Instead of running right now, the job gets handed off to your queue
        # backend (Sidekiq, etc.) to process later:
        #
        #   NotificationJob.perform_later(user, message)
        #
        # Want it now instead? Use +perform_now+.
      RDOC
      { label: :c, provider: "claude", content: <<~RDOC }
        # Enqueues the job for background execution.
        #
        # Params:
        # - +*args+ — arguments forwarded to +perform+.
        # Returns: the enqueued +ActiveJob::Base+ instance.
        # Raises: +EnqueueError+ if enqueueing fails.
      RDOC
    ],
    "ActionCable::Channel::Base#stream_from" => [
      { label: :a, provider: "kimi", content: <<~RDOC },
        # Subscribes this channel to a named broadcasting stream.
        #
        # Establishes a pub/sub subscription so that messages published to the
        # specified +broadcasting+ are automatically relayed to the connected
        # WebSocket client. An optional callback or coder can customize how
        # incoming messages are processed before transmission.
        #
        # +broadcasting+:: String — the name of the broadcasting to subscribe to.
        # +callback+:: Proc (optional) — custom handler for incoming messages.
      RDOC
      { label: :b, provider: "claude", content: <<~RDOC },
        # Start streaming messages from a broadcast channel to the client.
        #
        # This is how you wire up real-time updates. Call it in your +subscribed+
        # callback to push messages to the browser over WebSockets:
        #
        #   class ChatChannel < ApplicationCable::Channel
        #     def subscribed
        #       stream_from "chat_\#{params[:room_id]}"
        #     end
        #   end
      RDOC
      { label: :c, provider: "openai", content: <<~RDOC }
        # Subscribes the channel to a broadcasting.
        #
        # Params:
        # - +broadcasting+ — String, the broadcast name.
        # - +callback+ — Proc, optional message handler.
        # - +coder:+ — coder for message serialization (default: JSON).
        # Returns: void.
      RDOC
    ],
    "ActiveStorage::Blob#download" => [
      { label: :a, provider: "claude", content: <<~RDOC },
        # Downloads the file associated with this blob from the storage service.
        #
        # When called without a block, returns the entire file contents as a binary
        # string. When called with a block, streams the file in chunks, yielding
        # each chunk to the block — useful for large files to avoid loading the
        # entire contents into memory.
        #
        # Returns the binary contents of the file (without block), or nil (with block).
      RDOC
      { label: :b, provider: "openai", content: <<~RDOC },
        # Downloads the blob's file from storage.
        #
        # Two ways to use it — grab everything at once, or stream it:
        #
        #   # All at once
        #   data = blob.download
        #
        #   # Streaming (better for large files)
        #   blob.download do |chunk|
        #     file.write(chunk)
        #   end
      RDOC
      { label: :c, provider: "kimi", content: <<~RDOC }
        # Downloads the blob's file content.
        #
        # Params:
        # - +&block+ — optional, yields chunks for streaming.
        # Returns: String (binary) without block, nil with block.
        # Raises: +ActiveStorage::FileNotFoundError+ if missing.
      RDOC
    ],
    "ActiveModel::Validations#validate" => [
      { label: :a, provider: "openai", content: <<~RDOC },
        # Adds a validation method, symbol, or block to the model's validation chain.
        #
        # When called with a block and no arguments, creates a +BlockValidator+ that
        # executes the block in the context of the record during validation. When called
        # with symbols or strings, registers those methods as validation callbacks that
        # will be invoked during the validate phase of the lifecycle.
        #
        # This is the foundation of custom validations in Active Model.
      RDOC
      { label: :b, provider: "kimi", content: <<~RDOC },
        # Add a custom validation to your model.
        #
        # The most flexible way to validate — just pass a block or method name:
        #
        #   validate :check_email_domain
        #   validate { errors.add(:base, "nope") if suspicious? }
        #
        # Runs every time you call +valid?+ or +save+.
      RDOC
      { label: :c, provider: "claude", content: <<~RDOC }
        # Registers a custom validation callback.
        #
        # Params:
        # - +*args+ — Symbol method names or validation options.
        # - +&block+ — optional validation block.
        # Returns: void.
        # See also: +validates+, +validates_with+.
      RDOC
    ],
    "ActiveRecord::Migration#change" => [
      { label: :a, provider: "kimi", content: <<~RDOC },
        # Defines the primary transformation for a reversible migration.
        #
        # Implement this method in your migration subclass to describe schema changes
        # using reversible methods (e.g., +create_table+, +add_column+). Rails will
        # automatically determine how to reverse the migration when rolling back.
        # For non-reversible operations, use +up+ and +down+ instead.
        #
        # This is the recommended approach for writing migrations in Rails.
      RDOC
      { label: :b, provider: "claude", content: <<~RDOC },
        # The main method you override when writing a migration.
        #
        # Put your schema changes here and Rails figures out how to undo them:
        #
        #   def change
        #     create_table :posts do |t|
        #       t.string :title
        #       t.timestamps
        #     end
        #   end
        #
        # If Rails can't reverse it, use +up+/+down+ instead.
      RDOC
      { label: :c, provider: "openai", content: <<~RDOC }
        # Defines reversible migration transformations.
        #
        # Override in subclass. Use reversible DDL methods.
        # Returns: void.
        # Raises: +IrreversibleMigration+ if called without being overridden.
        # See: +up+, +down+ for non-reversible changes.
      RDOC
    ],
    "ActionDispatch::Routing::Mapper#resources" => [
      { label: :a, provider: "claude", content: <<~RDOC },
        # Defines RESTful routes for a resource, mapping HTTP verbs to controller actions.
        #
        # Generates the standard set of seven routes (index, show, new, create, edit,
        # update, destroy) for the given resource name. Accepts options to customize
        # which actions are generated, add nested resources via a block, and configure
        # path prefixes, constraints, and concerns.
        #
        # +*resources+:: Symbol(s) — the resource name(s) to route.
      RDOC
      { label: :b, provider: "openai", content: <<~RDOC },
        # Sets up all the standard CRUD routes for a resource.
        #
        # One line in your routes file gives you 7 routes:
        #
        #   resources :posts
        #   # => GET /posts, GET /posts/:id, POST /posts, etc.
        #
        # Nest them, limit them, go wild:
        #
        #   resources :posts, only: [:index, :show] do
        #     resources :comments
        #   end
      RDOC
      { label: :c, provider: "kimi", content: <<~RDOC }
        # Generates RESTful routes for a resource.
        #
        # Params:
        # - +*resources+ — Symbol(s), resource names.
        # - +only:+ / +except:+ — Array, limit generated actions.
        # - +&block+ — nested resources or member/collection routes.
        # Returns: +self+.
      RDOC
    ]
  }

  # ---------- Create tasks and drafts ----------
  tasks = tasks_config.map do |config|
    pr_url = config.delete(:pr_url)
    pr_status = config.delete(:pr_status)

    task = DocumentationTask.find_or_create_by!(project: project, method_signature: config[:method_signature]) do |t|
      t.source_file_path = config[:source_file_path]
      t.source_code = config[:source_code]
      t.class_context = config[:class_context]
    end

    # Set status directly to avoid state machine transitions
    attrs = { status: config[:status] }
    attrs[:pr_url] = pr_url if pr_url
    attrs[:pr_status] = pr_status if pr_status
    task.update_columns(**attrs)

    # Create draft versions
    draft_configs = drafts_for[config[:method_signature]]
    drafts = draft_configs.map do |dc|
      DraftVersion.find_or_create_by!(documentation_task: task, label: dc[:label]) do |d|
        d.provider = dc[:provider]
        d.content = dc[:content].strip
      end
    end

    { task: task.reload, drafts: drafts.map(&:reload) }
  end

  # ---------- Votes ----------
  vote_count = 0

  tasks.each_with_index do |entry, task_index|
    task = entry[:task]
    drafts = entry[:drafts]

    case task.status
    when "voting"
      # Spread votes somewhat evenly with a slight leader
      leader_index = task_index % 3
      all_users.shuffle(random: Random.new(task_index)).first(rand(6..8)).each do |user|
        # Give the leader draft a higher chance
        if rand < 0.45
          draft = drafts[leader_index]
        else
          draft = drafts.sample(random: Random.new(user.id + task_index))
        end

        Vote.find_or_create_by!(user: user, documentation_task: task) do |v|
          v.draft_version = draft
        end
        vote_count += 1
      end

    when "pending_review", "submitted", "merged"
      # One version should clearly dominate
      winner_draft = drafts.first # Version A wins for these
      all_users.each do |user|
        # ~75% vote for winner, ~25% split among others
        if rand(100) < 75
          draft = winner_draft
        else
          draft = drafts[1..2].sample(random: Random.new(user.id + task_index))
        end

        Vote.find_or_create_by!(user: user, documentation_task: task) do |v|
          v.draft_version = draft
        end
        vote_count += 1
      end

      # Ensure winner flag is set
      winner_draft.update_columns(winner: true)
    end
  end

  # Make sure c-sonnier has voted on at least 8 tasks, including some winners
  tasks.each_with_index do |entry, i|
    break if i >= 10
    task = entry[:task]
    drafts = entry[:drafts]

    next if Vote.exists?(user: csonnier, documentation_task: task)

    # Pick winning draft for non-voting tasks so "Winning Picks" stat works
    draft = if task.voting?
              drafts.sample(random: Random.new(i))
            else
              drafts.find { |d| d.winner? } || drafts.first
            end

    Vote.create!(user: csonnier, documentation_task: task, draft_version: draft)
    vote_count += 1
  end

  # ---------- Reset counter caches ----------
  DraftVersion.find_each { |dv| DraftVersion.reset_counters(dv.id, :votes) }

  puts "Seeded: #{Project.count} project, #{User.count} users, #{DocumentationTask.count} tasks, #{DraftVersion.count} drafts, #{Vote.count} votes"
end
