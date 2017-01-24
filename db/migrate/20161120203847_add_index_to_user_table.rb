class AddIndexToUserTable < ActiveRecord::Migration
  def change
    add_index "users", ["first_name","last_name"], name: "index_users_on_first_and_last_name",  using: :btree
  end
end
