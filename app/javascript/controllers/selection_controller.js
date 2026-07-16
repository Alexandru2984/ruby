import { Controller } from "@hotwired/stimulus"

// Tracks checked bookmark checkboxes and reveals the bulk-action bar.
export default class extends Controller {
  static targets = ["checkbox", "bar", "count"]

  refresh() {
    const selected = this.checkboxTargets.filter((checkbox) => checkbox.checked).length
    this.barTarget.hidden = selected === 0
    this.countTarget.textContent = selected
  }

  clear() {
    this.checkboxTargets.forEach((checkbox) => { checkbox.checked = false })
    this.refresh()
  }
}
