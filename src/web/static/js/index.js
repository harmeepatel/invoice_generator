// DESC: retain form info on refresh

const inputs = document.querySelectorAll(`[data-type="input"]`)

for (let input of inputs) {
    input.value = localStorage.getItem(input.name) || input.value

    input.addEventListener("input", () => {
        localStorage.setItem(input.name, input.value)
    })
}
console.log(localStorage)
