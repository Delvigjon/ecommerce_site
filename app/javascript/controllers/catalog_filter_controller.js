import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["product"]

  filter(event) {
    const selectedCategory = event.currentTarget.dataset.category
    const buttons = this.element.querySelectorAll(".catalog-filter-btn")

    buttons.forEach((button) => {
      button.classList.remove("is-active")
    })

    event.currentTarget.classList.add("is-active")

    this.productTargets.forEach((product) => {
      const productCategory = product.dataset.category

      if (selectedCategory === "all" || productCategory === selectedCategory) {
        product.style.display = ""
      } else {
        product.style.display = "none"
      }
    })
  }
}
