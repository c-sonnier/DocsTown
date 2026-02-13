class CreateDraftVersions < ActiveRecord::Migration[8.1]
  def change
    create_table :draft_versions do |t|
      t.references :documentation_task, null: false, foreign_key: true
      t.integer :label, null: false
      t.string :provider, null: false
      t.text :content, null: false
      t.text :prompt_used
      t.integer :votes_count, default: 0, null: false
      t.boolean :winner, default: false, null: false

      t.timestamps
    end

    add_index :draft_versions, [ :documentation_task_id, :label ], unique: true
    add_index :draft_versions, :documentation_task_id, unique: true, where: "winner = true",
              name: "index_draft_versions_on_task_id_winner"
  end
end
