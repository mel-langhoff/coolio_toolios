class CreateDifferentAreaCodeHoes < ActiveRecord::Migration[7.1]
  def change
    create_table :different_area_code_hoes do |t|
      t.string :title
      t.string :url
      t.string :description
      t.date :date_accessed

      t.timestamps
    end
  end
end
