# db/seeds.rb

require "net/http"
require "uri"
require "json"

# =========================================================
# Helpers : HTTP / URL
# =========================================================
def http_client_for(uri)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = (uri.scheme == "https")
  http.open_timeout = 4
  http.read_timeout = 4
  http
end

def url_reachable?(url)
  return false if url.to_s.strip.empty?

  uri = URI.parse(url)
  http = http_client_for(uri)

  begin
    head = Net::HTTP::Head.new(uri.request_uri)
    res = http.request(head)

    return true if res.is_a?(Net::HTTPSuccess) || res.is_a?(Net::HTTPRedirection)
  rescue
  end

  begin
    get = Net::HTTP::Get.new(uri.request_uri)
    get["Range"] = "bytes=0-0"

    res = http.request(get)

    return true if res.is_a?(Net::HTTPSuccess) ||
                   res.is_a?(Net::HTTPPartialContent) ||
                   res.is_a?(Net::HTTPRedirection)
  rescue
    false
  end

  false
rescue
  false
end

def safe_image_url(url, fallback_url:)
  return fallback_url if url.to_s.strip.empty?

  if url_reachable?(url)
    url
  else
    puts "⚠ Image HS → #{url}"
    fallback_url
  end
end

def sanitize_pexels_url(url, width: 1600)
  return url if url.to_s.strip.empty?
  return url unless url.include?("images.pexels.com/")

  uri = URI.parse(url)
  params = URI.decode_www_form(uri.query.to_s)

  params_hash = params.to_h
  params_hash["auto"] = "compress"
  params_hash["cs"]   = "tinysrgb"
  params_hash["w"]    = width.to_s

  uri.query = URI.encode_www_form(params_hash.to_a)
  uri.to_s
rescue
  url
end

# =========================================================
# PEXELS
# =========================================================
PEXELS_API_URL = "https://api.pexels.com/v1/search"
PEXELS_KEY = ENV["PEXELS_API_KEY"]

def pexels_search(query:, per_page: 40, orientation: "landscape")
  raise "PEXELS_API_KEY manquante." if PEXELS_KEY.to_s.strip.empty?

  uri = URI.parse(PEXELS_API_URL)

  uri.query = URI.encode_www_form(
    query: query,
    per_page: per_page,
    orientation: orientation
  )

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 6
  http.read_timeout = 6

  req = Net::HTTP::Get.new(uri.request_uri)
  req["Authorization"] = PEXELS_KEY

  res = http.request(req)

  return [] unless res.is_a?(Net::HTTPSuccess)

  data = JSON.parse(res.body)

  Array(data["photos"])
rescue => e
  puts "⚠ Pexels error → #{e.message}"
  []
end

def extract_best_src(photo)
  photo.dig("src", "large2x") ||
    photo.dig("src", "large") ||
    photo.dig("src", "original")
end

def fetch_pexels_urls_validated(
  queries:,
  total_needed: 24,
  orientation: "landscape"
)
  good_keywords = %w[
    light
    lighting
    lamp
    lamps
    chandelier
    pendant
    ceiling
    wall
    led
    bulb
    interior
    home
    design
    outdoor
  ]

  bad_keywords = %w[
    beach
    sea
    ocean
    mountain
    car
    knife
    blade
    food
    animal
    fashion
    laptop
    phone
  ]

  collected = []
  attempts = 0
  max_attempts = 8

  while collected.size < total_needed && attempts < max_attempts
    attempts += 1

    queries.each do |q|
      break if collected.size >= total_needed

      photos = pexels_search(
        query: q,
        per_page: 40,
        orientation: orientation
      )

      photos.each do |ph|
        break if collected.size >= total_needed

        alt = ph["alt"].to_s.downcase

        next if alt.empty?
        next if bad_keywords.any? { |w| alt.include?(w) }
        next unless good_keywords.any? { |w| alt.include?(w) }

        src = extract_best_src(ph)

        next if src.to_s.strip.empty?

        src = sanitize_pexels_url(src, width: 1600)

        next unless url_reachable?(src)

        collected << src
      end
    end

    collected = collected.uniq
  end

  collected.take(total_needed)
end

# =========================================================
# RESET
# =========================================================
puts "🧹 Cleaning database..."

Offer.destroy_all
CartItem.destroy_all
Cart.destroy_all
OrderItem.destroy_all
Order.destroy_all
User.destroy_all
Product.destroy_all

ActiveRecord::Base.connection.reset_pk_sequence!("products")
ActiveRecord::Base.connection.reset_pk_sequence!("offers")
ActiveRecord::Base.connection.reset_pk_sequence!("users")
ActiveRecord::Base.connection.reset_pk_sequence!("carts")
ActiveRecord::Base.connection.reset_pk_sequence!("orders")
ActiveRecord::Base.connection.reset_pk_sequence!("cart_items")
ActiveRecord::Base.connection.reset_pk_sequence!("order_items")

# =========================================================
# USER
# =========================================================
default_user = User.create!(
  email: "test@example.com",
  password: "password123",
  password_confirmation: "password123"
)

default_cart = default_user.create_cart

# =========================================================
# FALLBACK
# =========================================================
FALLBACK_PRODUCT_IMAGE =
  "https://picsum.photos/seed/luminaire-template/1600/1000"

puts "🌱 Seeding luminaires..."

pexels_urls =
  begin
    fetch_pexels_urls_validated(
      queries: [
        "modern lighting",
        "led lamp",
        "ceiling light",
        "wall light",
        "pendant light",
        "outdoor lighting",
        "interior lighting",
        "designer lamp",
        "home lighting"
      ],
      total_needed: 24,
      orientation: "landscape"
    )
  rescue => e
    puts "⚠ Pexels indisponible → #{e.message}"
    []
  end

while pexels_urls.size < 24
  pexels_urls << "https://picsum.photos/seed/luminaire-#{pexels_urls.size + 1}/1600/1000"
end

# =========================================================
# PRODUITS
# =========================================================
names = [
  "Suspension design noire",
  "Applique murale LED",
  "Plafonnier LED rond",
  "Lampe de table scandinave",
  "Spot encastrable orientable",
  "Ruban LED blanc chaud",
  "Suspension en rotin naturel",
  "Projecteur extérieur LED",
  "Borne lumineuse extérieure",
  "Lampe baladeuse rechargeable",
  "Réglette LED cuisine",
  "Ampoule LED connectée",
  "Suspension industrielle",
  "Applique salle de bain IP44",
  "Lampe de bureau LED",
  "Guirlande lumineuse extérieure",
  "Spot sur rail",
  "Panneau LED carré",
  "Lampadaire arc moderne",
  "Hublot LED extérieur",
  "Suspension verre fumé",
  "Applique liseuse",
  "Éclairage miroir LED",
  "Pack spots LED"
]

descs = [
  "Luminaire moderne conçu pour sublimer vos espaces intérieurs.",
  "Une solution d’éclairage performante et élégante.",
  "Design contemporain et matériaux de qualité.",
  "Parfait pour créer une ambiance chaleureuse et accueillante.",
  "Un éclairage pensé pour allier esthétique et efficacité."
]

prices = [
  18.90,
  24.90,
  29.90,
  34.90,
  39.90,
  44.90,
  49.90,
  54.90,
  59.90,
  69.90,
  79.90,
  89.90,
  99.90,
  109.90,
  129.90
]

stocks = [
  5,
  8,
  10,
  12,
  15,
  18,
  20,
  24,
  30,
  35,
  40,
  50
]

puts "🌱 Creating products..."

names.each_with_index do |name, idx|
  url = pexels_urls[idx]

  img = safe_image_url(
    url,
    fallback_url: FALLBACK_PRODUCT_IMAGE
  )

  product = Product.create!(
    name: name,
    description: descs.sample,
    price: prices.sample.to_f,
    stock: stocks.sample,
    image_url: img
  )

  puts "✅ [#{idx + 1}/#{names.size}] #{product.name}"
end

# =========================================================
# OFFERS
# =========================================================
puts "🌱 Seeding offers..."

offers = [
  {
    name: "Offre spéciale — Suspension design noire",
    description: "Une suspension moderne idéale pour donner du style à une pièce.",
    price: 79.90,
    product_name: "Suspension design noire"
  },
  {
    name: "Sélection LED — Plafonnier rond",
    description: "Un éclairage sobre, efficace et facile à intégrer.",
    price: 59.90,
    product_name: "Plafonnier LED rond"
  },
  {
    name: "Pack ambiance — Ruban LED blanc chaud",
    description: "Une solution simple pour créer une ambiance lumineuse chaleureuse.",
    price: 29.90,
    product_name: "Ruban LED blanc chaud"
  }
]

offers.each_with_index do |o, idx|
  product = Product.find_by(name: o[:product_name])

  if product.nil?
    puts "⚠ Offre ignorée → #{o[:name]}"
    next
  end

  Offer.create!(
    name: o[:name],
    description: o[:description],
    price: o[:price],
    product: product,
    image_url: product.image_url,
    user: default_user
  )

  puts "✅ [#{idx + 1}/#{offers.size}] #{o[:name]}"
end

# =========================================================
# CART + ORDER TEST
# =========================================================
first_product = Product.first

CartItem.create!(
  cart: default_cart,
  product: first_product,
  quantity: 2
)

order = default_user.orders.create!(
  status: "completed",
  total_price: (first_product.price * 2).round(2)
)

order.order_items.create!(
  product: first_product,
  quantity: 2,
  price: first_product.price
)

puts "✅ Seed terminé avec succès !"
puts "   - Products: #{Product.count}"
puts "   - Offers:   #{Offer.count}"
puts "   - Users:    #{User.count}"
