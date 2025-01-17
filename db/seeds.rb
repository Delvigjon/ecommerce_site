# Supprimer toutes les données existantes
Offer.destroy_all
CartItem.destroy_all
Cart.destroy_all
OrderItem.destroy_all
Order.destroy_all
User.destroy_all
Product.destroy_all

# Réinitialiser les ID (facultatif)
ActiveRecord::Base.connection.reset_pk_sequence!('products')
ActiveRecord::Base.connection.reset_pk_sequence!('offers')
ActiveRecord::Base.connection.reset_pk_sequence!('users')
ActiveRecord::Base.connection.reset_pk_sequence!('carts')
ActiveRecord::Base.connection.reset_pk_sequence!('orders')
ActiveRecord::Base.connection.reset_pk_sequence!('cart_items')
ActiveRecord::Base.connection.reset_pk_sequence!('order_items')

# Créer un utilisateur par défaut
default_user = User.create!(
  email: "test@example.com",
  password: "password123",
  password_confirmation: "password123"
)

# Créer un panier pour l'utilisateur (via la relation `has_one`)
default_cart = default_user.create_cart


# Produits
products = [
  { name: "Cafetière à filtre", description: "Cafetière simple pour préparer du café filtre.", price: 29.99, stock: 50, image_file: "Cafetière à filtre.webp" },
  { name: "Grille-pain", description: "Grille-pain 2 fentes avec contrôle de brunissage.", price: 19.99, stock: 30, image_file: "Grille-pain.webp" },
  { name: "Machine à espresso", description: "Machine à espresso avec buse vapeur pour cappuccino.", price: 149.99, stock: 20, image_file: "Machine à espresso.webp" },
  { name: "Bouilloire électrique", description: "Bouilloire électrique en acier inoxydable de 1,7 litre.", price: 39.99, stock: 40, image_file: "Bouilloire électrique.webp" },
  { name: "Mixeur plongeant", description: "Mixeur plongeant multifonction avec accessoires.", price: 24.99, stock: 25, image_file: "Mixeur plongeant.webp" },
  { name: "Friteuse sans huile", description: "Friteuse sans huile pour une cuisson saine et rapide.", price: 89.99, stock: 15, image_file: "Friteuse sans huile.webp" },
  { name: "Plancha électrique", description: "Plancha électrique pour griller viandes et légumes.", price: 49.99, stock: 20, image_file: "Plancha électrique.webp" },
  { name: "Robot pâtissier", description: "Robot pâtissier avec bol en acier inoxydable.", price: 199.99, stock: 10, image_file: "Robot pâtissier.webp" },
  { name: "Blender", description: "Blender avec fonction pulse et lames en acier inoxydable.", price: 59.99, stock: 35, image_file: "Blender.webp" },
  { name: "Cuiseur à riz", description: "Cuiseur à riz avec panier vapeur et cuve anti-adhésive.", price: 29.99, stock: 45, image_file: "Cuiseur à riz.webp" }
]

# Dossier où les images des produits sont censées être stockées
image_folder = Rails.root.join('app', 'assets', 'images', 'products')

# Créer les produits
products.each do |product|
  image_path = image_folder.join(product[:image_file])

  # Vérification de la présence de l'image
  if File.exist?(image_path)
    Product.create!(
      name: product[:name],
      description: product[:description],
      price: product[:price],
      stock: product[:stock],
      image_url: product[:image_file]
    )
  else
    puts "Image non trouvée pour #{product[:name]}: #{image_path}"
  end
end

# Offres
offers = [
  { name: "Offre spéciale Cafetière", description: "Obtenez 10% de réduction sur notre cafetière à filtre.", price: 26.99, product_name: "Cafetière à filtre", image_file: nil },
  { name: "Offre Grille-pain", description: "Grille-pain à seulement 15.99€ pour une durée limitée.", price: 15.99, product_name: "Grille-pain", image_file: nil },
  { name: "Promotion Espresso", description: "Profitez d'une réduction de 20% sur la machine à espresso.", price: 119.99, product_name: "Machine à espresso", image_file: nil },
  { name: "Bouilloire Économique", description: "Remise de 5€ sur la bouilloire électrique.", price: 34.99, product_name: "Bouilloire électrique", image_file: nil }
]

# Créer les offres
offers.each do |offer|
  product = Product.find_by(name: offer[:product_name])

  if product
    Offer.create!(
      name: offer[:name],
      description: offer[:description],
      price: offer[:price],
      product: product,
      image_url: offer[:image_file].presence || product.image_url,
      user: default_user
    )
  else
    puts "Produit manquant pour l'offre #{offer[:name]}"
  end
end

# Ajouter des articles au panier pour tester
CartItem.create!(
  cart: default_cart,
  product: Product.first,
  quantity: 2
)

# Simuler une commande
order = default_user.orders.create!(
  status: 'completed',
  total_price: 59.98 # Exemple : 2x Cafetière à filtre
)

order.order_items.create!(
  product: Product.first,
  quantity: 2,
  price: Product.first.price
)

puts "Seed terminé avec succès ! Un utilisateur par défaut, des produits, des offres, un panier et une commande ont été créés."
