class AddAwesomeToUser < ActiveRecord::Migration
  def change
    add_column :users, :awesome, :boolean
  end
end
