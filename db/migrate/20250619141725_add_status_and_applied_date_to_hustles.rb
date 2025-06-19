class AddStatusAndAppliedDateToHustles < ActiveRecord::Migration[7.1]
  def change
    add_column :hustles, :status, :string
    add_column :hustles, :applied_on, :datetime
  end
end
