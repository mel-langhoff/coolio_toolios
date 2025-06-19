class CreateHustles < ActiveRecord::Migration[7.1]
  def change
    create_table :hustles do |t|
      t.string :job_title
      t.string :company
      t.string :job_description
      t.jsonb :resume

      t.timestamps
    end
  end
end
