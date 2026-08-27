// app/javascript/controllers/cookie_banner_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["banner"]

  connect() {
    this.showIfNeeded()
  }

  showIfNeeded() {
    const choice = sessionStorage.getItem("cookie_consent")

    if (!choice) {
      this.show()
    } else {
      this.hide()
    }
  }

  accept() {
    sessionStorage.setItem("cookie_consent", "accepted")

    this.hide()

    // Ici, plus tard, on pourra déclencher
    // les scripts nécessitant le consentement.
    window.dispatchEvent(
      new CustomEvent("cookie-consent:accepted")
    )
  }

  refuse() {
    sessionStorage.setItem("cookie_consent", "refused")

    this.hide()

    window.dispatchEvent(
      new CustomEvent("cookie-consent:refused")
    )
  }

  show() {
    this.bannerTarget.hidden = false

    requestAnimationFrame(() => {
      this.bannerTarget.classList.add(
        "cookie-banner--visible"
      )
    })
  }

  hide() {
    if (!this.hasBannerTarget) return

    this.bannerTarget.classList.remove(
      "cookie-banner--visible"
    )

    window.setTimeout(() => {
      this.bannerTarget.hidden = true
    }, 300)
  }
}
