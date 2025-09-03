# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🧹 Cleaning up old data..."

# Destroy all existing products and recommendations
Recommendation.destroy_all
Product.destroy_all

puts "✅ Old products and recommendations destroyed"

puts "👥 Seeding users..."

# Clear old data
# User.destroy_all (commented out to preserve users)

# Create some demo users if they don't exist
admin_user = User.find_or_create_by!(email: "admin@example.com") do |user|
  user.name = "Admin User"
end

test_user = User.find_or_create_by!(email: "test@example.com") do |user|
  user.name = "Test User"
end

puts "✅ Done! Seeded #{User.count} users."

puts "👔 Seeding products with local images..."

# Base path for your local images
image_base_path = "C:/Users/MuhammadArbaz3/Pictures/Screenshots/Images"

# Fashion products with your local image paths
products_data = [
  {
    name: "Classic White Shirt",
    category: "shirts",
    size: "M",
    color: "white",
    price: 59.99,
    image_url: "#{image_base_path}/c1.jpg",
    tags: ["formal", "classic", "professional", "minimal"]
  },
  {
    name: "Navy Blue Blazer",
    category: "blazers",
    size: "L",
    color: "navy",
    price: 129.99,
    image_url: "#{image_base_path}/c2.jpg", 
    tags: ["formal", "professional", "classic", "navy"]
  },
  {
    name: "Casual Denim Jeans",
    category: "jeans",
    size: "M",
    color: "blue",
    price: 79.99,
    image_url: "#{image_base_path}/c3.jpg",
    tags: ["casual", "denim", "versatile", "blue"]
  },
  {
    name: "Black Dress Pants",
    category: "pants", 
    size: "M",
    color: "black",
    price: 89.99,
    image_url: "#{image_base_path}/c4.jpg",
    tags: ["formal", "professional", "black", "classic"]
  },
  {
    name: "Grey Wool Sweater",
    category: "sweaters",
    size: "L", 
    color: "gray",
    price: 95.99,
    image_url: "#{image_base_path}/c5.jpg",
    tags: ["cozy", "comfortable", "gray", "warm"]
  },
  {
    name: "Beige Trench Coat",
    category: "coats",
    size: "M",
    color: "beige",
    price: 189.99,
    image_url: "#{image_base_path}/c6.jpg",
    tags: ["professional", "sophisticated", "beige", "classic"]
  },
  {
    name: "Red Polo Shirt",
    category: "shirts",
    size: "S",
    color: "red", 
    price: 45.99,
    image_url: "#{image_base_path}/c7.jpg",
    tags: ["casual", "vibrant", "red", "sporty"]
  },
  {
    name: "Brown Leather Jacket",
    category: "jackets",
    size: "L",
    color: "brown",
    price: 225.99,
    image_url: "#{image_base_path}/c8.jpg",
    tags: ["edgy", "bold", "brown", "leather"]
  },
  {
    name: "Pink Summer Dress",
    category: "dresses",
    size: "M",
    color: "pink",
    price: 65.99,
    image_url: "#{image_base_path}/c9.jpg",
    tags: ["vibrant", "casual", "pink", "summer"]
  },
  {
    name: "Charcoal Suit Jacket",
    category: "blazers",
    size: "L",
    color: "charcoal",
    price: 159.99,
    image_url: "#{image_base_path}/c10.jpg",
    tags: ["formal", "professional", "charcoal", "sophisticated"]
  },
  {
    name: "Light Blue Oxford Shirt",
    category: "shirts", 
    size: "M",
    color: "light_blue",
    price: 52.99,
    image_url: "#{image_base_path}/c11.jpg",
    tags: ["professional", "minimal", "light_blue", "classic"]
  },
  {
    name: "Forest Green Cardigan",
    category: "sweaters",
    size: "S",
    color: "forest_green",
    price: 72.99,
    image_url: "#{image_base_path}/c12.jpg",
    tags: ["cozy", "comfortable", "forest_green", "casual"]
  },
  {
    name: "Orange Casual T-Shirt",
    category: "shirts",
    size: "M",
    color: "orange",
    price: 29.99,
    image_url: "#{image_base_path}/c13.jpg",
    tags: ["vibrant", "casual", "orange", "trendy"]
  },
  {
    name: "Dark Blue Jeans",
    category: "jeans",
    size: "L", 
    color: "dark_blue",
    price: 85.99,
    image_url: "#{image_base_path}/c14.jpg",
    tags: ["casual", "versatile", "dark_blue", "denim"]
  },
  {
    name: "Burgundy Wine Blazer",
    category: "blazers",
    size: "M",
    color: "burgundy",
    price: 145.99,
    image_url: "#{image_base_path}/c15.jpg",
    tags: ["bold", "statement", "burgundy", "formal"]
  },
  {
    name: "Yellow Summer Top",
    category: "shirts",
    size: "S",
    color: "yellow",
    price: 38.99,
    image_url: "#{image_base_path}/c16.jpg", 
    tags: ["bright", "vibrant", "yellow", "summer"]
  },
  {
    name: "White Sneakers",
    category: "shoes",
    size: "10",
    color: "white",
    price: 95.99,
    image_url: "#{image_base_path}/c17.jpg",
    tags: ["casual", "versatile", "white", "sporty"]
  },
  {
    name: "Black Leather Boots",
    category: "shoes", 
    size: "9",
    color: "black",
    price: 145.99,
    image_url: "#{image_base_path}/c18.jpg",
    tags: ["edgy", "bold", "black", "professional"]
  },
  {
    name: "Lavender Blouse",
    category: "shirts",
    size: "M",
    color: "lavender",
    price: 48.99,
    image_url: "#{image_base_path}/c19.jpg",
    tags: ["minimal", "professional", "lavender", "soft"]
  },
  {
    name: "Khaki Chinos",
    category: "pants",
    size: "M", 
    color: "khaki",
    price: 69.99,
    image_url: "#{image_base_path}/c20.jpg",
    tags: ["casual", "versatile", "khaki", "comfortable"]
  }
]

# Create products
created_count = 0
products_data.each do |product_data|
  begin
    Product.create!(product_data)
    created_count += 1
    print "."
  rescue => e
    puts "\n❌ Error creating product '#{product_data[:name]}': #{e.message}"
  end
end

puts "\n✅ Done! Created #{created_count} products with local images."
puts "📊 Total products in database: #{Product.count}"
puts "📊 Total users in database: #{User.count}"

# Display sample products
puts "\n📋 Sample products created:"
Product.limit(5).each do |product|
  puts "  • #{product.name} (#{product.category}) - $#{product.price} - #{product.color}"
end

puts "\n🎉 Database seeding completed successfully!"
