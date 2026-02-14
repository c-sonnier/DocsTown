class AddLastDigestSentAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :last_digest_sent_at, :datetime
  end
end
