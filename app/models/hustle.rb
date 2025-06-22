class Hustle < ApplicationRecord
  validates :job_title, presence: true
  validates :job_url, presence: true
  validates :resume, presence: true
end