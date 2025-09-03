class RecommendationSerializer < ActiveModel::Serializer
  attributes :id, :score, :reason, :selfie_url, :preview_url, :analysis_json
  belongs_to :product, serializer: ProductSerializer
end
