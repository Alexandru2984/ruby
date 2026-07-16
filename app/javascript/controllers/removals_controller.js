import { Controller } from "@hotwired/stimulus"

// Removes its element from the page, e.g. dismissing a flash message.
export default class extends Controller {
  remove() {
    this.element.remove()
  }
}
