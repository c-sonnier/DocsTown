class AddIndexToDocumentationTasksCreatedAt < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :documentation_tasks, :created_at, algorithm: :concurrently
  end
end
