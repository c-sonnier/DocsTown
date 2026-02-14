class Github::PrSubmitter
    MAX_RETRIES = 3

    def initialize(task)
      @task = task
    end

    def call
      ensure_fork_exists
      sync_fork
      branch_name = create_branch
      modified_content = insert_documentation
      commit_to_branch(branch_name, modified_content)
      pr_url = open_pull_request(branch_name)

      @task.update!(pr_url: pr_url, pr_status: :open)
      pr_url
    end

    private

    def ensure_fork_exists
      client.repository(fork_repo)
    rescue Octokit::NotFound
      client.fork(upstream_repo)
    end

    def sync_fork
      upstream_ref = client.ref(upstream_repo, "heads/main")
      upstream_sha = upstream_ref.object.sha

      begin
        client.update_ref(fork_repo, "heads/main", upstream_sha, true)
      rescue Octokit::UnprocessableEntity
        client.create_ref(fork_repo, "heads/main", upstream_sha)
      end
    end

    def create_branch
      name = branch_name
      main_sha = client.ref(fork_repo, "heads/main").object.sha
      client.create_ref(fork_repo, "heads/#{name}", main_sha)
      name
    end

    def insert_documentation
      file_response = client.contents(upstream_repo, path: @task.source_file_path)
      file_content = Base64.decode64(file_response.content)

      winning_doc = @task.winning_version&.content
      raise "No winning version found for task #{@task.id}" unless winning_doc

      Github::DocInserter.new(file_content, @task.method_signature, winning_doc).call
    end

    def commit_to_branch(branch_name, content)
      ref = client.ref(fork_repo, "heads/#{branch_name}")
      base_commit_sha = ref.object.sha
      base_commit = client.commit(fork_repo, base_commit_sha)
      base_tree_sha = base_commit.commit.tree.sha

      blob_sha = client.create_blob(fork_repo, content, "utf-8")

      tree = client.create_tree(fork_repo, [
        {
          path: @task.source_file_path,
          mode: "100644",
          type: "blob",
          sha: blob_sha
        }
      ], base_tree: base_tree_sha)

      new_commit = client.create_commit(
        fork_repo,
        commit_message,
        tree.sha,
        base_commit_sha
      )

      client.update_ref(fork_repo, "heads/#{branch_name}", new_commit.sha)
    end

    def open_pull_request(branch_name)
      pr = client.create_pull_request(
        upstream_repo,
        "main",
        "#{fork_owner}:#{branch_name}",
        pr_title,
        pr_body
      )
      pr.html_url
    end

    def branch_name
      method_slug = @task.method_signature.gsub(/[^a-zA-Z0-9]/, "-").gsub(/-+/, "-").downcase
      "docstown/add-docs-#{method_slug}-#{@task.id}"
    end

    def commit_message
      "Add documentation for `#{@task.method_signature}`"
    end

    def pr_title
      "Add documentation for `#{@task.method_signature}`"
    end

    def pr_body
      <<~BODY
        ## Documentation added by [DocsTown](https://docstown.org)

        This PR adds RDoc documentation for `#{@task.method_signature}` in `#{@task.source_file_path}`.

        **Community-reviewed:** #{@task.votes.count} community members voted on three AI-generated versions.
        The winning version received #{@task.winning_version&.votes_count || 0} votes.

        ---
        *Submitted automatically by DocsTown — community-driven Rails documentation.*
      BODY
    end

    def upstream_repo
      @task.project.github_repo
    end

    def fork_repo
      "#{fork_owner}/#{upstream_repo.split('/').last}"
    end

    def fork_owner
      Rails.application.credentials.dig(:github, :username) || raise("Missing github username in credentials")
    end

    def client
      @client ||= Github.client
    end
end
