class User < ApplicationRecord
  # =========================================================
  # RELATIONS
  # =========================================================

  has_one :cart, dependent: :destroy
  has_many :orders, dependent: :destroy


  # =========================================================
  # DEVISE
  # =========================================================

  devise :database_authenticatable,
         :registerable,
         :recoverable,
         :rememberable,
         :validatable


  # =========================================================
  # ROLES
  # =========================================================

  ROLES = %w[customer admin].freeze

  validates :role,
            presence: true,
            inclusion: { in: ROLES }


  # =========================================================
  # ACCOUNT TYPES
  # =========================================================

  ACCOUNT_TYPES = %w[individual business].freeze

  validates :account_type,
            inclusion: { in: ACCOUNT_TYPES },
            allow_nil: true


  # =========================================================
  # B2B VALIDATIONS
  # =========================================================

  validates :company_name,
            presence: true,
            if: :business?

  validates :siret,
            presence: true,
            if: :business?


  # =========================================================
  # ROLE HELPERS
  # =========================================================

  def admin?
    role == "admin"
  end

  def customer?
    role == "customer"
  end


  # =========================================================
  # ACCOUNT TYPE HELPERS
  # =========================================================

  def individual?
    account_type == "individual"
  end

  def business?
    account_type == "business"
  end
end
