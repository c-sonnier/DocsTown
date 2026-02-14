import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["area"]

  toggle() {
    const area = this.areaTarget
    if (area.style.display === "none") {
      area.style.display = "block"
    } else {
      area.style.display = "none"
    }
  }
}
