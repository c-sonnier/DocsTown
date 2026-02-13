class DraftGenerationJob < ApplicationJob
  queue_as :default

  PROVIDERS = {
    "claude" => ClaudeClient,
    "openai" => OpenaiClient,
    "kimi" => KimiClient
  }.freeze

  def perform(documentation_task_id)
    task = DocumentationTask.find(documentation_task_id)
    return unless task.drafting?
    return if task.draft_versions.any?

    prompt = task.build_prompt
    labels = %i[a b c].shuffle
    provider_names = PROVIDERS.keys.shuffle

    mapping = provider_names.zip(labels)
    drafts_created = 0

    mapping.each do |provider_name, label|
      content = generate_draft(provider_name, prompt)
      next unless content

      task.draft_versions.create!(
        label: label,
        provider: provider_name,
        content: content,
        prompt_used: prompt
      )
      drafts_created += 1
    rescue => e
      Rails.logger.error("DraftGenerationJob: #{provider_name} failed for task #{task.id}: #{e.message}")
    end

    if drafts_created >= 2
      task.start_voting!
      Rails.logger.info("DraftGenerationJob: task #{task.id} moved to voting with #{drafts_created} drafts")
    else
      Rails.logger.error("DraftGenerationJob: task #{task.id} only got #{drafts_created} drafts, staying in drafting")
    end
  end

  private

  def generate_draft(provider_name, prompt)
    client = PROVIDERS.fetch(provider_name).new
    client.generate(prompt: prompt)
  end
end
