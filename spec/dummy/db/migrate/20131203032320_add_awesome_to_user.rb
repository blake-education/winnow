class AddAwesomeToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :awesome, :boolean
  end
end
