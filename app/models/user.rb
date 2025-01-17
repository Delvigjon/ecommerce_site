class User < ApplicationRecord
  # Relations
  has_one :cart, dependent: :destroy
  has_many :orders, dependent: :destroy

  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
end
