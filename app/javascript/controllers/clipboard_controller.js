import { Controller } from "@hotwired/stimulus"

// Copies a value to the clipboard and briefly confirms it on the trigger.
export default class extends Controller {
  static values = { text: String }

  async copy(event) {
    const button = event.currentTarget

    try {
      await navigator.clipboard.writeText(this.textValue)
    } catch {
      return
    }

    const original = button.innerHTML
    button.innerHTML = "Copied!"
    setTimeout(() => { button.innerHTML = original }, 1200)
  }
}
