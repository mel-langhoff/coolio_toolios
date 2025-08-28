class AddColumnNameToDifferentAreaCodeHoes < ActiveRecord::Migration[7.1]
  def change
    add_column :different_area_code_hoes, :status, :string
  end
end

