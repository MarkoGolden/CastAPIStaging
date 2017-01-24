class Addstatetopushcondition < ActiveRecord::Migration
  def change
    add_column :push_conditions, :state, :text

  end
end
