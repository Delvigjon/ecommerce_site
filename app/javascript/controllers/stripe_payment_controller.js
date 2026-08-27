import { Controller } from "@hotwired/stimulus"

export default class extends Controller {

  static targets = [
    "element",
    "error",
    "submit",
    "address",
    "postalCode",
    "city"
  ]

  static values = {
    intentUrl: String,
    addressUrl: String,
    successUrl: String
  }


  // =========================================================
  // CONNECT
  // =========================================================

  async connect() {
    await this.initializeStripe()
  }


  // =========================================================
  // INITIALIZE STRIPE
  // =========================================================

  async initializeStripe() {

    try {

      this.hideError()

      const response = await fetch(
        this.intentUrlValue,
        {
          method: "POST",

          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-CSRF-Token": this.csrfToken
          },

          credentials: "same-origin"
        }
      )


      const data =
        await this.parseJsonResponse(
          response,
          "initialisation du paiement"
        )


      if (!response.ok) {

        throw new Error(
          data.error ||
          "Impossible d'initialiser le paiement."
        )

      }


      // =====================================================
      // STRIPE PUBLIC KEY
      // =====================================================

      const stripeMeta =
        document.querySelector(
          'meta[name="stripe-key"]'
        )


      if (!stripeMeta) {

        throw new Error(
          "La clé publique Stripe est introuvable."
        )

      }


      if (typeof Stripe === "undefined") {

        throw new Error(
          "Stripe.js n'est pas chargé."
        )

      }


      this.stripe =
        Stripe(
          stripeMeta.content
        )


      // =====================================================
      // ELEMENTS
      // =====================================================

      this.elements =
        this.stripe.elements({

          clientSecret:
            data.client_secret,

          appearance: {

            theme: "night",

            variables: {

              colorPrimary:
                "#b49a72",

              colorBackground:
                "#0a0907",

              colorText:
                "#eee9df",

              colorDanger:
                "#a16659",

              borderRadius:
                "0px"

            }

          }

        })


      // =====================================================
      // PAYMENT ELEMENT
      // =====================================================

      this.paymentElement =
        this.elements.create(
          "payment",
          {
            layout: "tabs"
          }
        )


      this.paymentElement.mount(
        this.elementTarget
      )

    } catch (error) {

      console.error(
        "Stripe initialization error:",
        error
      )

      this.showError(
        error.message
      )

    }

  }


  // =========================================================
  // SUBMIT
  // =========================================================

  async submit(event) {

    event.preventDefault()

    this.hideError()


    // =====================================================
    // STRIPE READY?
    // =====================================================

    if (
      !this.stripe ||
      !this.elements
    ) {

      this.showError(
        "Le module de paiement n'est pas encore prêt."
      )

      return

    }


    // =====================================================
    // ADDRESS
    // =====================================================

    const address =
      this.addressTarget.value.trim()

    const postalCode =
      this.postalCodeTarget.value.trim()

    const city =
      this.cityTarget.value.trim()


    if (
      address === "" ||
      postalCode === "" ||
      city === ""
    ) {

      this.showError(
        "Veuillez renseigner votre adresse de livraison complète."
      )

      return

    }


    // =====================================================
    // DISABLE BUTTON
    // =====================================================

    this.submitTarget.disabled = true


    try {

      // ===================================================
      // SAVE ADDRESS
      // ===================================================

      await this.saveAddress({
        address: address,
        postal_code: postalCode,
        city: city
      })


      // ===================================================
      // VALIDATE STRIPE ELEMENTS
      // ===================================================

      const {
        error: submitError
      } =
        await this.elements.submit()


      if (submitError) {

        throw new Error(
          submitError.message
        )

      }


      // ===================================================
      // CONFIRM PAYMENT
      // ===================================================

      const {
        error,
        paymentIntent
      } =
        await this.stripe.confirmPayment({

          elements:
            this.elements,

          confirmParams: {

            return_url:
              this.successUrlValue

          },

          redirect:
            "if_required"

        })


      // ===================================================
      // STRIPE ERROR
      // ===================================================

      if (error) {

        throw new Error(
          error.message
        )

      }


      // ===================================================
      // PAYMENT SUCCEEDED WITHOUT REDIRECT
      // ===================================================

      if (
        paymentIntent &&
        paymentIntent.status === "succeeded"
      ) {

        this.redirectToSuccess(
          paymentIntent.id
        )

        return

      }


      // ===================================================
      // OTHER STATUS
      // ===================================================

      if (paymentIntent) {

        switch (paymentIntent.status) {

          case "processing":

            this.showError(
              "Votre paiement est en cours de traitement."
            )

            break


          case "requires_payment_method":

            this.showError(
              "Le paiement n'a pas pu être effectué. Veuillez utiliser un autre moyen de paiement."
            )

            break


          default:

            this.showError(
              "Le paiement n'a pas encore été confirmé."
            )

        }

      }

    } catch (error) {

      console.error(
        "Payment error:",
        error
      )

      this.showError(
        error.message
      )

    } finally {

      this.submitTarget.disabled = false

    }

  }


  // =========================================================
  // SAVE ADDRESS
  // =========================================================

  async saveAddress(addressData) {

    if (!this.hasAddressUrlValue) {

      throw new Error(
        "L'URL d'enregistrement de l'adresse est manquante."
      )

    }


    const response =
      await fetch(
        this.addressUrlValue,
        {
          method: "PATCH",

          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-CSRF-Token": this.csrfToken
          },

          credentials: "same-origin",

          body:
            JSON.stringify(
              addressData
            )
        }
      )


    const data =
      await this.parseJsonResponse(
        response,
        "enregistrement de l'adresse"
      )


    if (!response.ok) {

      throw new Error(
        data.error ||
        "Impossible d'enregistrer l'adresse de livraison."
      )

    }


    return data

  }


  // =========================================================
  // PARSE JSON RESPONSE
  // =========================================================

  async parseJsonResponse(
    response,
    context
  ) {

    const contentType =
      response.headers.get(
        "content-type"
      ) || ""


    // Rails nous a renvoyé autre chose que du JSON

    if (
      !contentType.includes(
        "application/json"
      )
    ) {

      const responseText =
        await response.text()


      console.error(
        `Réponse non JSON pendant ${context}:`,
        {
          status:
            response.status,

          url:
            response.url,

          body:
            responseText
        }
      )


      throw new Error(
        `Erreur serveur pendant ${context} (${response.status}). Consultez la console Rails.`
      )

    }


    try {

      return await response.json()

    } catch (error) {

      console.error(
        `JSON invalide pendant ${context}:`,
        error
      )


      throw new Error(
        `Réponse serveur invalide pendant ${context}.`
      )

    }

  }


  // =========================================================
  // SUCCESS REDIRECT
  // =========================================================

  redirectToSuccess(
    paymentIntentId
  ) {

    const url =
      new URL(
        this.successUrlValue,
        window.location.origin
      )


    url.searchParams.set(
      "payment_intent",
      paymentIntentId
    )


    window.location.href =
      url.toString()

  }


  // =========================================================
  // ERROR
  // =========================================================

  showError(message) {

    if (!this.hasErrorTarget) {
      return
    }


    this.errorTarget.hidden =
      false

    this.errorTarget.textContent =
      message

  }


  hideError() {

    if (!this.hasErrorTarget) {
      return
    }


    this.errorTarget.hidden =
      true

    this.errorTarget.textContent =
      ""

  }


  // =========================================================
  // CSRF
  // =========================================================

  get csrfToken() {

    const meta =
      document.querySelector(
        'meta[name="csrf-token"]'
      )


    return meta
      ? meta.content
      : ""

  }

}
