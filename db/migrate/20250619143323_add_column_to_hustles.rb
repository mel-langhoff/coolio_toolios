class AddColumnToHustles < ActiveRecord::Migration[7.1]
  def change
    add_column :hustles, :job_url, :string
  end
end
