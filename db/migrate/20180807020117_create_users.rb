class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :line_user_id
      t.boolean :is_blocked, default: false
      t.timestamps
    end
  end
end
