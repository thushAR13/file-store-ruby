class StoredFile < ApplicationRecord
  has_one_attached :file

  validates :name, presence: true, uniqueness: true
  validates :file_hash, presence: true
end
