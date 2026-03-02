// DESC: retain form info on refresh

const fieldset = document.getElementsByClassName("fieldset")

for (let elem of fieldset) {
    const input = elem.querySelector(`[data-type="input"]`)
    input.value = localStorage.getItem(input.name) || input.value

    input.addEventListener("input", () => {
        localStorage.setItem(input.name, input.value)
    })
}
console.log(localStorage)
