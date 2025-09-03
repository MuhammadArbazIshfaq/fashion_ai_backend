class ProductSerializer < ActiveModel::Serializer
  attributes :id, :name, :category, :size, :color, :price, :image_url, :tags
end
