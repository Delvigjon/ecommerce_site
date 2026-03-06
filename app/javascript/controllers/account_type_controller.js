import { Controller } from "@hotwired/stimulus"

// data-controller="account-type"
export default class extends Controller {
  static targets = ["proBlock", "accountType", "subtitle", "b2bRequired", "b2cRequired"]
  static values = { default: String }

  connect() {
    const initial = this.defaultValue || "b2c"
    this.apply(initial)
  }

  pick(event) {
    this.apply(event.target.value)
  }

  apply(type) {
    // set hidden field that will be saved in DB
    if (this.hasAccountTypeTarget) this.accountTypeTarget.value = type

    // show/hide pro block
    if (this.hasProBlockTarget) {
      this.proBlockTarget.hidden = (type !== "b2b")
    }

    // toggle required fields
    this.toggleRequired(this.b2bRequiredTargets, type === "b2b")
    this.toggleRequired(this.b2cRequiredTargets, type === "b2c")

    // update subtitle
    if (this.hasSubtitleTarget) {
      this.subtitleTarget.textContent =
        (type === "b2b")
          ? "Créez un compte professionnel pour commander au nom de votre société."
          : "Créez votre compte particulier pour accéder au panier et suivre vos commandes."
    }
  }

  toggleRequired(elements, isRequired) {
    elements.forEach((el) => {
      if (isRequired) {
        el.setAttribute("required", "required")
      } else {
        el.removeAttribute("required")
      }
    })
  }
}
