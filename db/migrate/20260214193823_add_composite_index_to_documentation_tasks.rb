class AddCompositeIndexToDocumentationTasks < ActiveRecord::Migration[8.1]
  def change
    add_index :documentation_tasks, [:status, :created_at], order: { created_at: :desc }, name: "index_documentation_tasks_on_status_and_created_at"
  end
end
