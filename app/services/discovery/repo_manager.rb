module Discovery
  class RepoManager
    attr_reader :project, :repo_path, :head_sha

    def initialize(project)
      @project = project
    end

    def sync!
      if cloned?
        pull!
      else
        clone!
      end

      @head_sha = read_head_sha
      @repo_path = local_path
      self
    end

    def cloned?
      File.directory?(File.join(local_path, ".git"))
    end

    private

    def clone!
      FileUtils.mkdir_p(File.dirname(local_path))
      result = system("git", "clone", "--depth", "1", "--branch", project.default_branch,
        "https://github.com/#{project.github_repo}.git", local_path)
      raise "Clone failed for #{project.github_repo}" unless result
    end

    def pull!
      Dir.chdir(local_path) do
        system("git", "fetch", "--depth", "1", "origin", project.default_branch)
        system("git", "reset", "--hard", "origin/#{project.default_branch}")
      end
    end

    def read_head_sha
      Dir.chdir(local_path) { `git rev-parse HEAD`.strip }
    end

    def local_path
      base = Rails.env.production? ? "/data/repos" : Rails.root.join("tmp", "repos")
      File.join(base.to_s, project.github_repo.tr("/", "-"))
    end
  end
end
