class CreateFrames < ActiveRecord::Migration[5.1]
  def change
    create_table :frames do |t|
      t.string :type # typed
      t.string :data # generic
			t.string :locator
			t.integer :frame_id # recursive
			t.boolean :active, default: false

      t.timestamps
    end
		add_index :frames, :locator, unique: true
  end
end
