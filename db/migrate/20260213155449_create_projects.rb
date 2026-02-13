class CreateProjects < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.string :name, null: false
      t.string :github_repo, null: false, index: { unique: true }
      t.string :default_branch, default: "main", null: false
      t.datetime :last_scanned_at

      t.timestamps
    end
  end
end
