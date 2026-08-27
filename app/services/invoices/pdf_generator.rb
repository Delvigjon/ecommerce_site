# app/services/invoices/pdf_generator.rb

module Invoices
  class PdfGenerator
    include ActionView::Helpers::NumberHelper

    TVA_RATE = 0.20

    BRAND_GOLD  = "B49A72"
    BRAND_DARK  = "15130F"
    TEXT_DARK   = "222222"
    TEXT_MUTED  = "777777"
    BORDER      = "E5E0D7"
    PAPER_LIGHT = "EEE9DF"

    # =========================================================
    # INITIALIZE
    # =========================================================

    def initialize(order)
      @order = order
      @user  = order.user
    end


    # =========================================================
    # CALL
    # =========================================================

    def call
      @order.ensure_invoice!

      Prawn::Document.new(
        page_size: "A4",
        margin: 42
      ) do |pdf|

        header(pdf)

        pdf.move_down 28

        invoice_information(pdf)

        pdf.move_down 30

        customer_information(pdf)

        pdf.move_down 34

        items_table(pdf)

        pdf.move_down 26

        totals(pdf)

        pdf.move_down 34

        payment_information(pdf)

        footer(pdf)

      end.render
    end


    private


    # =========================================================
    # HEADER
    # =========================================================

    def header(pdf)
      pdf.fill_color BRAND_GOLD

      pdf.text(
        "MAISON LUMIÈRE",
        size: 20,
        style: :bold,
        character_spacing: 1.4
      )

      pdf.move_down 5

      pdf.fill_color TEXT_MUTED

      pdf.text(
        "Luminaires & éclairage",
        size: 8
      )

      pdf.move_down 20

      pdf.stroke_color BORDER
      pdf.stroke_horizontal_rule

      pdf.fill_color TEXT_DARK
    end


    # =========================================================
    # FACTURE
    # =========================================================

    def invoice_information(pdf)
      pdf.fill_color TEXT_DARK

      pdf.text(
        "FACTURE",
        size: 24,
        style: :bold
      )

      pdf.move_down 14

      invoice_date =
        (@order.invoiced_at || @order.created_at)
          .strftime("%d/%m/%Y")

      info = [
        ["Numéro", @order.invoice_number],
        ["Date", invoice_date],
        ["Commande", "##{@order.id}"],
        ["Statut", @order.human_status]
      ]

      info.each do |label, value|

        pdf.formatted_text(
          [
            {
              text: "#{label} : ",
              styles: [:bold]
            },
            {
              text: value.to_s
            }
          ],
          size: 9
        )

        pdf.move_down 4
      end
    end


    # =========================================================
    # CLIENT
    # =========================================================

    def customer_information(pdf)
      section_title(
        pdf,
        "FACTURÉ À"
      )

      pdf.move_down 10

      customer_name = [
        @user.first_name,
        @user.last_name
      ]
        .compact
        .reject(&:blank?)
        .join(" ")

      pdf.fill_color TEXT_DARK

      pdf.text(
        customer_name.presence || @user.email,
        size: 10,
        style: :bold
      )

      pdf.move_down 5


      # -------------------------------------------------------
      # Société B2B
      # -------------------------------------------------------

      if @user.company_name.present?

        pdf.text(
          @user.company_name,
          size: 9
        )

        pdf.move_down 3
      end


      # -------------------------------------------------------
      # SIRET
      # -------------------------------------------------------

      if @user.siret.present?

        pdf.text(
          "SIRET : #{@user.siret}",
          size: 8
        )

        pdf.move_down 3
      end


      # -------------------------------------------------------
      # Adresse
      # -------------------------------------------------------

      pdf.text(
        @order.address.presence || "Adresse non renseignée",
        size: 9
      )

      pdf.move_down 3


      # -------------------------------------------------------
      # Email
      # -------------------------------------------------------

      pdf.text(
        @user.email,
        size: 9
      )


      # -------------------------------------------------------
      # Téléphone
      # -------------------------------------------------------

      if @user.phone.present?

        pdf.move_down 3

        pdf.text(
          @user.phone,
          size: 9
        )

      end
    end


    # =========================================================
    # ARTICLES
    # =========================================================

    def items_table(pdf)
      section_title(
        pdf,
        "DÉTAIL DE LA COMMANDE"
      )

      pdf.move_down 12


      # -------------------------------------------------------
      # Données
      # -------------------------------------------------------

      data = [
        [
          "Produit",
          "Qté",
          "PU HT",
          "TVA",
          "Total TTC"
        ]
      ]


      @order.order_items.each do |item|

        unit_ttc =
          item.price.to_f

        unit_ht =
          unit_ttc /
          (1 + TVA_RATE)

        total_ttc =
          unit_ttc *
          item.quantity

        product_name =
          item.product&.name.presence ||
          "Produit"


        data << [
          product_name,
          item.quantity.to_s,
          money(unit_ht),
          "20 %",
          money(total_ttc)
        ]
      end


      # -------------------------------------------------------
      # Largeur disponible
      #
      # On utilise toute la largeur réellement disponible
      # dans le document.
      # -------------------------------------------------------

      available_width =
        pdf.bounds.width


      column_widths = [
        available_width * 0.48,
        available_width * 0.08,
        available_width * 0.16,
        available_width * 0.10,
        available_width * 0.18
      ]


      # -------------------------------------------------------
      # Table
      # -------------------------------------------------------

      pdf.table(
        data,
        header: true,
        column_widths: column_widths
      ) do |table|


        # =====================================================
        # GLOBAL
        # =====================================================

        table.cells.padding =
          7

        table.cells.size =
          8

        table.cells.border_color =
          BORDER

        table.cells.border_width =
          0.5


        # =====================================================
        # HEADER
        # =====================================================

        table.row(0).background_color =
          BRAND_DARK

        table.row(0).text_color =
          PAPER_LIGHT

        table.row(0).font_style =
          :bold


        # =====================================================
        # ALIGNEMENTS
        # =====================================================

        table.column(0).align =
          :left

        table.columns(1..4).align =
          :right


        # =====================================================
        # PRODUIT
        # =====================================================

        table.column(0).text_color =
          "333333"


        # =====================================================
        # TOTAL TTC
        # =====================================================

        table.column(4).font_style =
          :bold

      end
    end


    # =========================================================
    # TOTALS
    # =========================================================

    def totals(pdf)
      total_ttc =
        @order.order_items.sum do |item|

          item.price.to_f *
            item.quantity

        end


      total_ht =
        total_ttc /
        (1 + TVA_RATE)


      vat_total =
        total_ttc -
        total_ht


      # -------------------------------------------------------
      # Bloc aligné à droite
      # -------------------------------------------------------

      box_width =
        230

      x =
        pdf.bounds.right -
        box_width


      pdf.bounding_box(
        [x, pdf.cursor],
        width: box_width
      ) do

        total_line(
          pdf,
          "Sous-total HT",
          money(total_ht)
        )


        total_line(
          pdf,
          "TVA 20 %",
          money(vat_total)
        )


        pdf.move_down 8


        pdf.stroke_color BRAND_GOLD
        pdf.stroke_horizontal_rule


        pdf.move_down 10


        pdf.formatted_text(
          [
            {
              text: "TOTAL TTC",
              styles: [:bold],
              size: 11
            },
            {
              text: "   #{money(total_ttc)}",
              styles: [:bold],
              size: 14,
              color: BRAND_GOLD
            }
          ],
          align: :right
        )

      end
    end


    # =========================================================
    # PAIEMENT
    # =========================================================

    def payment_information(pdf)
      section_title(
        pdf,
        "PAIEMENT"
      )

      pdf.move_down 10

      pdf.fill_color "555555"

      pdf.text(
        "Commande réglée par paiement sécurisé Stripe.",
        size: 8
      )

      pdf.move_down 4

      pdf.text(
        "Statut du paiement : payé",
        size: 8
      )


      if @order.stripe_payment_intent_id.present?

        pdf.move_down 4

        pdf.fill_color TEXT_MUTED

        pdf.text(
          "Référence de paiement : #{@order.stripe_payment_intent_id}",
          size: 7
        )

      end


      pdf.fill_color TEXT_DARK
    end


    # =========================================================
    # FOOTER
    # =========================================================

    def footer(pdf)
      pdf.repeat(:all) do

        pdf.bounding_box(
          [
            pdf.bounds.left,
            pdf.bounds.bottom + 22
          ],
          width: pdf.bounds.width,
          height: 20
        ) do

          pdf.stroke_color BORDER

          pdf.stroke_horizontal_rule

          pdf.move_down 7

          pdf.fill_color TEXT_MUTED

          pdf.text(
            "Maison Lumière — Facture #{@order.invoice_number}",
            size: 7,
            align: :center
          )

        end
      end
    end


    # =========================================================
    # SECTION TITLE
    # =========================================================

    def section_title(pdf, title)
      pdf.fill_color BRAND_GOLD

      pdf.text(
        title,
        size: 9,
        style: :bold,
        character_spacing: 1
      )

      pdf.fill_color TEXT_DARK
    end


    # =========================================================
    # TOTAL LINE
    # =========================================================

    def total_line(pdf, label, value)
      pdf.formatted_text(
        [
          {
            text: label,
            color: "666666"
          },
          {
            text: "    #{value}",
            styles: [:bold],
            color: TEXT_DARK
          }
        ],
        size: 9,
        align: :right
      )

      pdf.move_down 7
    end


    # =========================================================
    # MONEY
    # =========================================================

    def money(value)
      format(
        "%.2f EUR",
        value.to_f
      ).tr(".", ",")
    end

  end
end
