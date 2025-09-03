class User < ApplicationRecord
   has_many :recommendations, dependent: :destroy
  validates :email, presence: true, uniqueness: true
end
