// DESC: retain form info on refresh

const inputs = document.querySelectorAll(`[data-type="input"]`)

for (let input of inputs) {
    input.value = localStorage.getItem(input.name) || input.value

    input.addEventListener("input", () => {
        localStorage.setItem(input.name, input.value)
    })
}
console.log(localStorage)


for (let input of inputs) {
    switch (input.id) {
        case "gst":
            input.value = 5.0
            break
        case "gstin":
            input.value = "24ABCPM1234L1Z5"
            break
        case "phone":
            input.value = "9834567890"
            break
        case "email":
            input.value = "asdf@asdf.com"
            break
        case "postalCode":
            input.value = 382424
            break
        case "hsn":
            input.value = 1222
            break
        case "quantity":
            input.value = 1
            break
        case "rate":
            input.value = 1
            break
        case "phoneExt":
            console.log(input.id, input.value)
            break
        case "state":
            input.value="Gujarat"
            console.log(input.id, input.value)
            break
        default:
            input.value = "asdf"
            break
    }
}
