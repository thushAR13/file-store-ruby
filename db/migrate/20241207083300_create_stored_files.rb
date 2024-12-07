class CreateStoredFiles < ActiveRecord::Migration[7.1]
  def change
    create_table :stored_files do |t|
      t.string :name
      t.string :file_hash

      t.timestamps
    end
  end
end
