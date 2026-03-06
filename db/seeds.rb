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

# HEAD peut être bloqué par certains CDN.
# => On tente HEAD, puis fallback GET (range 0-0) si besoin.
def url_reachable?(url)
  return false if url.to_s.strip.empty?

  uri = URI.parse(url)
  http = http_client_for(uri)

  # 1) HEAD
  begin
    head = Net::HTTP::Head.new(uri.request_uri)
    res = http.request(head)

    return true if res.is_a?(Net::HTTPSuccess) || res.is_a?(Net::HTTPRedirection)

    # si HEAD renvoie 403/405/etc, on tente GET
  rescue
    # ignore, fallback GET
  end

  # 2) GET light (Range)
  begin
    get = Net::HTTP::Get.new(uri.request_uri)
    get["Range"] = "bytes=0-0"
    res = http.request(get)

    # 206 Partial Content = OK (range)
    return true if res.is_a?(Net::HTTPSuccess) || res.is_a?(Net::HTTPPartialContent) || res.is_a?(Net::HTTPRedirection)
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

# Force des paramètres stables sur les URLs Pexels (quand c'est une url images.pexels.com)
def sanitize_pexels_url(url, width: 1600)
  return url if url.to_s.strip.empty?
  return url unless url.include?("images.pexels.com/")

  uri = URI.parse(url)
  params = URI.decode_www_form(uri.query.to_s)

  # Remplace/ajoute des params connus Pexels/CDN
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
# Pexels API
# =========================================================
PEXELS_API_URL = "https://api.pexels.com/v1/search"
PEXELS_KEY = ENV["PEXELS_API_KEY"]

def pexels_search(query:, per_page: 40, orientation: "landscape")
  raise "PEXELS_API_KEY manquante. Ajoute-la en ENV pour récupérer des vraies images de luminaires." if PEXELS_KEY.to_s.strip.empty?

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
  puts "⚠ Pexels search error (#{query}) → #{e.message}"
  []
end

def extract_best_src(photo)
  photo.dig("src", "large2x") || photo.dig("src", "large") || photo.dig("src", "original")
end

# Récupère DES URLS VALIDES (anti 404) + filtre par alt
def fetch_pexels_urls_validated(queries:, total_needed: 24, orientation: "landscape")
  good_keywords = %w[lamp lamps lighting light chandelier pendant sconce fixture luminaire ceiling]
  bad_keywords  = %w[beach sea ocean landscape mountain food kitchen living room bedroom sofa hotel apartment]

  collected = []
  attempts = 0
  max_attempts = 8 # limite globale (évite boucle infinie)

  while collected.size < total_needed && attempts < max_attempts
    attempts += 1

    queries.each do |q|
      break if collected.size >= total_needed

      photos = pexels_search(query: q, per_page: 40, orientation: orientation)

      photos.each do |ph|
        break if collected.size >= total_needed

        alt = ph["alt"].to_s.downcase
        next if alt.empty?
        next if bad_keywords.any? { |w| alt.include?(w) }
        next unless good_keywords.any? { |w| alt.include?(w) }

        src = extract_best_src(ph)
        next if src.to_s.strip.empty?

        src = sanitize_pexels_url(src, width: 1600)

        # 🔥 la partie qui manquait : on valide AVANT de garder
        next unless url_reachable?(src)

        collected << src
      end
    end

    collected = collected.uniq
  end

  collected.take(total_needed)
end

# =========================================================
# Reset
# =========================================================
puts "🧹 Cleaning database…"

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
# Default user + cart
# =========================================================
default_user = User.create!(
  email: "test@example.com",
  password: "password123",
  password_confirmation: "password123"
)
default_cart = default_user.create_cart

# =========================================================
# Fallback
# =========================================================
FALLBACK_PRODUCT_IMAGE = "https://picsum.photos/seed/fallback-luminaire/1600/1000"

puts "🌱 Seeding luminaires (Pexels + validation anti-404)…"

pexels_urls =
  begin
    fetch_pexels_urls_validated(
      queries: [
        "pendant lamp",
        "chandelier",
        "wall lamp",
        "sconce lamp",
        "floor lamp",
        "table lamp",
        "ceiling light",
        "modern lamp",
        "designer lamp"
      ],
      total_needed: 24,
      orientation: "landscape"
    )
  rescue => e
    puts "⚠ Pexels indisponible → #{e.message}"
    []
  end

# Si Pexels renvoie trop peu (rare), on complète picsum
while pexels_urls.size < 24
  pexels_urls << "https://picsum.photos/seed/luminaire-#{pexels_urls.size + 1}/1600/1000"
end

# =========================================================
# Produits (24)
# =========================================================
names = [
  "Suspension — Halo laiton",
  "Applique — Lueur murale",
  "Lampadaire — Arc noir mat",
  "Lampe de table — Verre fumé",
  "Suspension — Cylindre opalin",
  "Applique — Liseré doré",
  "Suspension — Globe ambré",
  "Plafonnier — Disque graphite",
  "Lampadaire — Duo LED",
  "Lampe de chevet — Céramique sable",
  "Suspension — Ligne horizontale",
  "Applique — Tube minimal",
  "Plafonnier — Opale soft",
  "Lampe — Dôme noir",
  "Suspension — Trio sphères",
  "Applique — Clair-obscur",
  "Lampadaire — Laiton brossé",
  "Lampe de bureau — Focus",
  "Suspension — Métal perforé",
  "Plafonnier — Carré compact",
  "Ruban LED — Ambiance",
  "Spot — Direction réglable",
  "Suspension — Verre clair",
  "Applique — Graphite"
]

descs = [
  "Design sobre, diffusion chaleureuse. Parfait pour une ambiance premium.",
  "Finition soignée, rendu élégant. Pensé pour une expérience visuelle haut de gamme.",
  "Lumière douce et homogène. Idéal pour salon, chambre ou entrée.",
  "Style contemporain, détails premium. Met en valeur la pièce sans surcharge."
]

prices = [49, 59, 69, 79, 89, 99, 109, 119, 129, 149, 159, 179, 189, 219, 249, 279, 329]
stocks = [0, 7, 9, 10, 12, 16, 18, 22, 26, 28, 30, 33, 36, 40, 44, 48, 52, 60, 70, 120, 200]

puts "🌱 Creating products…"

names.first(24).each_with_index do |name, idx|
  url = pexels_urls[idx]
  img = safe_image_url(url, fallback_url: FALLBACK_PRODUCT_IMAGE)

  product = Product.create!(
    name: name,
    description: descs.sample,
    price: prices.sample.to_f,
    stock: stocks.sample,
    image_url: img
  )

  puts "✅ [#{idx + 1}/24] #{product.name}"
end

puts "🌱 Seeding offers…"

offers = [
  {
    name: "Offre — Pack ambiance salon",
    description: "Une sélection pensée pour une ambiance chaleureuse et premium.",
    price: 299.00,
    product_name: "Lampadaire — Arc noir mat"
  },
  {
    name: "Sélection — Suspension star",
    description: "Notre best-seller en version mise en avant.",
    price: 169.00,
    product_name: "Suspension — Globe ambré"
  },
  {
    name: "Bundle — Bureau & Focus",
    description: "Deux indispensables pour un coin travail propre et efficace.",
    price: 99.00,
    product_name: "Lampe de bureau — Focus"
  }
]

offers.each_with_index do |o, idx|
  product = Product.find_by(name: o[:product_name])
  if product.nil?
    puts "⚠ Offre ignorée (produit manquant) → #{o[:name]}"
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
# Cart + Order test
# =========================================================
first_product = Product.first

CartItem.create!(cart: default_cart, product: first_product, quantity: 2)

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
