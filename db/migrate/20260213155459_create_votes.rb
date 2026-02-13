class CreateVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :documentation_task, null: false, foreign_key: true
      t.references :draft_version, null: false, foreign_key: true

      t.timestamps
    end

    add_index :votes, [ :user_id, :documentation_task_id ], unique: true
  end
end
