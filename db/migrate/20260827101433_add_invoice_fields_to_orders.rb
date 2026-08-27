class AddInvoiceFieldsToOrders < ActiveRecord::Migration[7.1]
  def change
    add_column :orders, :invoice_number, :string
    add_column :orders, :invoiced_at, :datetime

    add_index :orders,
              :invoice_number,
              unique: true
  end
end
