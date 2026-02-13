class CreateDocumentationTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :documentation_tasks do |t|
      t.references :project, null: false, foreign_key: true
      t.integer :status, default: 0, null: false
      t.string :method_signature, null: false
      t.string :source_file_path, null: false
      t.text :source_code, null: false
      t.text :class_context
      t.string :pr_url
      t.integer :pr_status
      t.text :reviewer_note

      t.timestamps
    end

    add_index :documentation_tasks, [ :project_id, :method_signature ], unique: true
    add_index :documentation_tasks, :status
    add_index :documentation_tasks, :pr_status
  end
end
