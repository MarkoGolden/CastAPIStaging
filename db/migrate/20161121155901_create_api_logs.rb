class CreateApiLogs < ActiveRecord::Migration
  def change
    create_table :api_logs do |t|
      t.string :api_name, limit: 50
      t.string :request
      t.string :response
      t.datetime :created_at

      t.timestamps null: false
    end
  end
end
