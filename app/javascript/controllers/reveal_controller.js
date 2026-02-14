import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          const parent = entry.target.parentElement
          const siblings = [...parent.querySelectorAll(".reveal")]
          const idx = siblings.indexOf(entry.target)
          entry.target.style.transitionDelay = `${idx * 0.1}s`
          entry.target.classList.add("visible")
        }
      })
    }, { threshold: 0.15 })

    this.element.querySelectorAll(".reveal").forEach(el => this.observer.observe(el))
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
  }
}
