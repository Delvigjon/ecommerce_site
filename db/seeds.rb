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
    knife
    knives
    blade
    blacksmith
    forged
    damascus
    steel
    chef
    hunting
    artisan
  ]

  bad_keywords = %w[
    beach
    sea
    ocean
    mountain
    lamp
    lighting
    chandelier
    sofa
    bedroom
    apartment
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
  "https://picsum.photos/seed/couteau-artisanal/1600/1000"

puts "🌱 Seeding couteaux artisanaux..."

pexels_urls =
  begin
    fetch_pexels_urls_validated(
      queries: [
        "handmade knife",
        "chef knife",
        "hunting knife",
        "forged knife",
        "damascus knife",
        "blacksmith knife",
        "artisan knife",
        "wood handle knife",
        "steel knife"
      ],
      total_needed: 24,
      orientation: "landscape"
    )
  rescue => e
    puts "⚠ Pexels indisponible → #{e.message}"
    []
  end

while pexels_urls.size < 24
  pexels_urls << "https://picsum.photos/seed/couteau-#{pexels_urls.size + 1}/1600/1000"
end

# =========================================================
# PRODUITS
# =========================================================
names = [
  "Couteau de chasse",
  "Couteau d’office",
  "Couteau de chef",
  "Pièce unique — Forge brute",
  "Couteau damas — Manche érable",
  "Couteau artisanal — Noyer",
  "Lame forgée — Série noire",
  "Couteau outdoor",
  "Couteau de cuisine — Carbone",
  "Couteau utilitaire",
  "Couteau pleine soie",
  "Couteau forgé main",
  "Lame artisanale",
  "Couteau signature",
  "Couteau bushcraft",
  "Couteau d’atelier",
  "Couteau japonais revisité",
  "Couteau à découper",
  "Couteau rustique",
  "Couteau collection",
  "Lame damassée",
  "Couteau manche bois de cerf",
  "Couteau de précision",
  "Création unique"
]

descs = [
  "Pièce forgée à la main dans un esprit artisanal et durable.",
  "Lame équilibrée, manche travaillé et finition soignée.",
  "Création unique mêlant tradition, acier premium et savoir-faire.",
  "Couteau artisanal pensé pour durer et traverser le temps.",
  "Une pièce unique fabriquée dans un atelier traditionnel."
]

prices = [
  180,
  220,
  250,
  280,
  320,
  350,
  390,
  450,
  520,
  590,
  690
]

stocks = [
  1,
  1,
  2,
  2,
  3,
  4,
  5,
  7,
  10
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
    name: "Sélection — Couteau de chasse",
    description: "Une pièce robuste idéale pour les amateurs de belles lames.",
    price: 320.00,
    product_name: "Couteau de chasse"
  },
  {
    name: "Pièce signature — Couteau de chef",
    description: "Une lame élégante pensée pour une précision parfaite.",
    price: 450.00,
    product_name: "Couteau de chef"
  },
  {
    name: "Création unique — Forge brute",
    description: "Une pièce originale au caractère brut et authentique.",
    price: 280.00,
    product_name: "Pièce unique — Forge brute"
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
