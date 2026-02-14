import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["body", "label", "arrow"]

  toggle() {
    const body = this.bodyTarget
    const isCollapsed = body.style.maxHeight === "0px"

    if (isCollapsed) {
      body.style.maxHeight = "600px"
      body.style.opacity = "1"
      this.labelTarget.textContent = "Hide context"
      this.arrowTarget.style.transform = "rotate(180deg)"
    } else {
      body.style.maxHeight = "0px"
      body.style.opacity = "0"
      this.labelTarget.textContent = "Show context"
      this.arrowTarget.style.transform = "rotate(0deg)"
    }
  }
}
