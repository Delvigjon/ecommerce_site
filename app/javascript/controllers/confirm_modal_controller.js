import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    title: String,
    message: String,
    confirm: String
  }

  connect() {
    this.confirmed = false
  }

  open(event) {
    if (this.confirmed) return

    event.preventDefault()

    this.createModal()
  }

  createModal() {
    this.close()

    const modal = document.createElement("div")

    modal.className = "confirm-modal"
    modal.dataset.confirmModalOverlay = "true"

    modal.innerHTML = `
      <div class="confirm-modal__backdrop"></div>

      <div
        class="confirm-modal__dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="confirm-modal-title"
      >
        <div class="confirm-modal__icon">
          <i class="fa-solid fa-arrow-right-from-bracket"></i>
        </div>

        <p class="confirm-modal__kicker">
          Maison Lumière
        </p>

        <h2
          class="confirm-modal__title"
          id="confirm-modal-title"
        >
          ${this.escapeHtml(this.titleValue || "Confirmation")}
        </h2>

        <p class="confirm-modal__message">
          ${this.escapeHtml(this.messageValue || "Voulez-vous continuer ?")}
        </p>

        <div class="confirm-modal__actions">
          <button
            type="button"
            class="confirm-modal__button confirm-modal__button--cancel"
            data-confirm-modal-cancel
          >
            Annuler
          </button>

          <button
            type="button"
            class="confirm-modal__button confirm-modal__button--confirm"
            data-confirm-modal-confirm
          >
            ${this.escapeHtml(this.confirmValue || "Confirmer")}
          </button>
        </div>
      </div>
    `

    document.body.appendChild(modal)

    this.modal = modal

    modal
      .querySelector("[data-confirm-modal-cancel]")
      .addEventListener("click", () => this.close())

    modal
      .querySelector("[data-confirm-modal-confirm]")
      .addEventListener("click", () => this.confirm())

    modal
      .querySelector(".confirm-modal__backdrop")
      .addEventListener("click", () => this.close())

    this.keydownHandler = (event) => {
      if (event.key === "Escape") {
        this.close()
      }
    }

    document.addEventListener("keydown", this.keydownHandler)

    requestAnimationFrame(() => {
      modal.classList.add("confirm-modal--visible")
    })
  }

  confirm() {
    this.confirmed = true

    const form = this.element.closest("form")

    this.close()

    if (form) {
      form.requestSubmit()
    }
  }

  close() {
    const modal =
      this.modal ||
      document.querySelector("[data-confirm-modal-overlay]")

    if (!modal) return

    modal.classList.remove("confirm-modal--visible")

    if (this.keydownHandler) {
      document.removeEventListener(
        "keydown",
        this.keydownHandler
      )
    }

    setTimeout(() => {
      modal.remove()
    }, 220)

    this.modal = null
  }

  escapeHtml(value) {
    const div = document.createElement("div")
    div.textContent = value
    return div.innerHTML
  }
}
