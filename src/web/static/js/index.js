// retain form info on refresh
// TODO: errorSpan contains the error but datastar `data-text` attr messes with it.
let fieldset = document.getElementsByClassName("fieldset")

for (let elem of fieldset) {
    let input = elem.querySelector(`[data-type="input"]`)
    let errorSpan = elem.querySelector("span")

    const existingInputValue = input.value
    const existingSpanText = errorSpan.textContent

    input.value = localStorage.getItem(input.name) || existingInputValue
    errorSpan.textContent = localStorage.getItem(errorSpan.id) || existingSpanText


    input.addEventListener("input", () => {
        localStorage.setItem(input.name, input.value)
        localStorage.setItem(errorSpan.id, errorSpan.textContent)
    });

    console.log(`id: ${errorSpan.id} textContent: ${errorSpan.textContent}`)
}

console.log(localStorage);
