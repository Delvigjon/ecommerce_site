// app/javascript/controllers/back_to_top_controller.js

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    offset: {
      type: Number,
      default: 350
    }
  }

  connect() {
    this.handleScroll = this.handleScroll.bind(this)

    window.addEventListener("scroll", this.handleScroll, {
      passive: true
    })

    this.handleScroll()
  }

  disconnect() {
    window.removeEventListener("scroll", this.handleScroll)
  }

  handleScroll() {
    const shouldShow = window.scrollY > this.offsetValue

    this.element.classList.toggle(
      "back-to-top--visible",
      shouldShow
    )
  }

  scrollToTop() {
    window.scrollTo({
      top: 0,
      behavior: "smooth"
    })
  }
}
