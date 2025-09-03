class Recommendation < ApplicationRecord
  belongs_to :user
  belongs_to :product
  
  # analysis_json is already a JSON column type in PostgreSQL
  # No need for serialize since it handles JSON natively
end
