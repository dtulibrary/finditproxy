class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users, :id=>false do |t|
      t.string :api_key, :primary=>true
      t.string :ln
      t.string :sn

      t.timestamps
    end
  end
end
