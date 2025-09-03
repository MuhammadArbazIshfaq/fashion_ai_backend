class Product < ApplicationRecord
   has_many :recommendations
  validates :name, :price, presence: true
  # tags stored as comma separated values (e.g. "streetwear,minimal")
  def tag_list
    (tags || "").split(",").map(&:strip)
  end
end
