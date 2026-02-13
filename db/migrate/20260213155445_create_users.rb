class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :github_uid, null: false, index: { unique: true }
      t.string :github_username, null: false
      t.string :avatar_url
      t.string :email
      t.integer :role, default: 0, null: false
      t.boolean :digest_opted_in, default: true, null: false

      t.timestamps
    end
  end
end
