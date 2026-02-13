rails_project = Project.find_or_create_by!(github_repo: "rails/rails") do |p|
  p.name = "Ruby on Rails"
  p.default_branch = "main"
end

maintainer = User.find_or_create_by!(github_uid: "1") do |u|
  u.github_username = "dhh"
  u.avatar_url = "https://avatars.githubusercontent.com/u/2741"
  u.email = "dhh@hey.com"
  u.role = :maintainer
end

voter = User.find_or_create_by!(github_uid: "2") do |u|
  u.github_username = "contributor1"
  u.avatar_url = "https://avatars.githubusercontent.com/u/1"
  u.email = "contributor@example.com"
  u.role = :voter
end

task = DocumentationTask.find_or_create_by!(
  project: rails_project,
  method_signature: "ActiveRecord::Base.find"
) do |t|
  t.source_file_path = "activerecord/lib/active_record/core.rb"
  t.source_code = <<~RUBY
    def find(*ids)
      return super if block_given?
      find_by_ids(*ids)
    end
  RUBY
  t.status = :voting
end

%w[claude openai kimi].each_with_index do |provider, i|
  label = %i[a b c][i]
  DraftVersion.find_or_create_by!(documentation_task: task, label: label) do |d|
    d.provider = provider
    d.content = "# ActiveRecord::Base.find\n\nFinds a record by its primary key.\n\n(Draft #{label.upcase} by #{provider})"
  end
end

puts "Seeded: #{Project.count} project, #{User.count} users, #{DocumentationTask.count} task, #{DraftVersion.count} drafts"
