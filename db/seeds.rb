# Seed pour créer des produits fictifs avec des images locales

# Supprimer tous les produits existants avant d'ajouter de nouveaux
Product.destroy_all

# Réinitialiser l'ID des produits (facultatif, pour recommencer à 1)
ActiveRecord::Base.connection.reset_pk_sequence!('products')

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

# Dossier où les images sont censées être stockées
image_folder = Rails.root.join('app', 'assets', 'images', 'products')

# Créer ou mettre à jour les produits
products.each do |product|
  image_path = image_folder.join(product[:image_file])

  # Vérification que l'image existe dans le dossier
  if File.exist?(image_path)
    Product.create!(
      name: product[:name],
      description: product[:description],
      price: product[:price],
      stock: product[:stock],
      image_url: product[:image_file] # Stocke simplement le nom de fichier si l'image existe
    )
  else
    puts "Image non trouvée pour #{product[:name]}: #{image_path}"
  end
end
