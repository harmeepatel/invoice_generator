package validate

import (
	"ae_invoice/src/logger"
	model "ae_invoice/src/models"
	"ae_invoice/src/util"
	"errors"
	"fmt"
	"net/http"
	"net/mail"
	"path"
	"regexp"
	"strings"
	"unicode"

	"github.com/starfederation/datastar-go/datastar"
	"github.com/uptrace/bunrouter"
)

var (
	panFirstFivePattern  = regexp.MustCompile(`^[A-Z]{5}$`)
	panHolderTypePattern = regexp.MustCompile(`^[PCFHATGLJ]$`)
	panDigitsPattern     = regexp.MustCompile(`^\d{4}$`)
	panLastCharPattern   = regexp.MustCompile(`^[A-Z]$`)
)

func patchSignal(w http.ResponseWriter, req bunrouter.Request, signals any) error {
	sse := datastar.NewSSE(w, req.Request)
	if err := sse.MarshalAndPatchSignals(signals); err != nil {
		logger.Logger.Error(fmt.Sprintf("Failed to Marshal %+v with error: %+v", signals, err.Error()))
		return err
	}
	return nil
}

func AllCustomerValid() bool { return allCustomerValid() }

func allCustomerValid() bool {
	c := model.Customer
	if validateName(strings.ToUpper(strings.TrimSpace(c.Name))) != nil {
		return false
	}
	if validateGstin(strings.ToUpper(strings.TrimSpace(c.GSTIN))) != nil {
		return false
	}
	if validateGst(c.GST) != nil {
		return false
	}
	if validateEmail(c.Email) != nil {
		return false
	}
	if validatePhone(c.Phone) != nil {
		return false
	}
	if validateRemark(c.Remark) != nil {
		return false
	}
	if validateShopNo(strings.ToUpper(strings.TrimSpace(c.ShopNo))) != nil {
		return false
	}
	if validateLine(c.Line1, true) != nil {
		return false
	}
	if validateLine(c.Line2, false) != nil {
		return false
	}
	if validateLine(c.Line3, false) != nil {
		return false
	}
	if validateCity(c.City) != nil {
		return false
	}
	if validatePostalCode(c.State, c.PostalCode) != nil {
		return false
	}
	return true
}

// Customer {

func validateName(name string) error {
	switch {
	case len(name) == 0:
		return errors.New("Required")
	case len(name) < 3:
		return errors.New("Too short")
	case len(name) > 100:
		return errors.New("Name must be 100 characters or fewer")
	}
	return util.ContainsInvalidChar(name)
}

func Name(w http.ResponseWriter, req bunrouter.Request) error {
	if err := datastar.ReadSignals(req.Request, model.Customer); err != nil {
		logger.Logger.Error(fmt.Sprintf("Failed to ReadSignals %+v with error: %+v", model.Customer, err.Error()))
		return err
	}

	type Signals struct {
		HasError  bool   `json:"hasError"`
		NameError string `json:"nameError"`
	}
	signals := &Signals{}

	name := strings.ToUpper(strings.TrimSpace(model.Customer.Name))
	if err := validateName(name); err != nil {
		signals.NameError = err.Error()
	}
	signals.HasError = allCustomerValid()

	return patchSignal(w, req, signals)
}

func validateGstin(gstin string) error {
	var validatePan = func(panInput string) error {
		pan := strings.ToUpper(strings.TrimSpace(panInput))

		switch {
		case len(pan) == 0:
			return errors.New("Required")
		case len(pan) != 10:
			return errors.New("PAN must be exactly 10 characters")
		default:
			switch {
			case !panFirstFivePattern.MatchString(pan[:5]):
				return errors.New("First 5 characters of PAN must be alphabetic")
			case !panHolderTypePattern.MatchString(string(pan[3])):
				return errors.New("Invalid 6th characters [P, C, F, H, A, T, G, L, J]")
			case !panDigitsPattern.MatchString(pan[5:9]):
				return errors.New("Characters 7–11 must be numeric")
			case pan[5:9] == "0000":
				return errors.New("Numeric portion must be between 0001 and 9999")
			case !panLastCharPattern.MatchString(string(pan[9])):
				return errors.New("Last character must be alphabetic")
			}
		}

		return nil
	}

	switch {
	case len(gstin) == 0:
		return errors.New("Required")
	case len(gstin) != 15:
		return errors.New("GSTIN must be 15 characters")
	case !unicode.IsDigit(rune(gstin[0])) && !unicode.IsDigit(rune(gstin[1])):
		return errors.New("GSTIN has an invalid state code")
	case validatePan(gstin[2:12]) != nil:
		return validatePan(gstin[2:12])
	case !unicode.IsDigit(rune(gstin[12])) && !unicode.IsUpper(rune(gstin[12])):
		return errors.New("GSTIN has an invalid registration number")
	case gstin[13] != 'Z':
		return errors.New("GSTIN has an invalid format")
	case !unicode.IsDigit(rune(gstin[14])) && !unicode.IsLetter(rune(gstin[14])):
		return errors.New("GSTIN has an invalid last character")
	}

	return nil
}

// ae: 24AAZPP2696Q1ZE
func Gstin(w http.ResponseWriter, req bunrouter.Request) error {
	if err := datastar.ReadSignals(req.Request, model.Customer); err != nil {
		logger.Logger.Error(fmt.Sprintf("Failed to ReadSignals %+v with error: %+v", model.Customer, err.Error()))
		return err
	}

	type Signals struct {
		HasError   bool   `json:"hasError"`
		GstinError string `json:"gstinError"`
	}
	signals := &Signals{}

	gstin := strings.ToUpper(strings.TrimSpace(model.Customer.GSTIN))
	if err := validateGstin(gstin); err != nil {
		signals.GstinError = err.Error()
	}
	signals.HasError = allCustomerValid()

	return patchSignal(w, req, signals)
}

func validateGst(gst float32) error {
	if gst < 0 || gst > 40 {
		return errors.New("GST must be 0% - 40%")
	}
	return nil
}

func Gst(w http.ResponseWriter, req bunrouter.Request) error {
	if err := datastar.ReadSignals(req.Request, model.Customer); err != nil {
		logger.Logger.Error(fmt.Sprintf("Failed to ReadSignals %+v with error: %+v", model.Customer, err.Error()))
		return err
	}

	type Signals = struct {
		HasError bool   `json:"hasError"`
		GstError string `json:"gstError"`
	}
	signals := &Signals{}

	if err := validateGst(model.Customer.GST); err != nil {
		signals.GstError = err.Error()
	}
	signals.HasError = allCustomerValid()

	return patchSignal(w, req, signals)
}

func validateEmail(email string) error {
	_, err := mail.ParseAddress(email)
	if len(email) > 0 && err != nil {
		return errors.New("Invalid Email")
	}
	return nil
}

func Email(w http.ResponseWriter, req bunrouter.Request) error {
	if err := datastar.ReadSignals(req.Request, model.Customer); err != nil {
		logger.Logger.Error(fmt.Sprintf("Failed to ReadSignals %+v with error: %+v", model.Customer, err.Error()))
		return err
	}

	type Signals = struct {
		HasError   bool   `json:"hasError"`
		EmailError string `json:"emailError"`
	}
	signals := &Signals{}

	if err := validateEmail(model.Customer.Email); err != nil {
		signals.EmailError = err.Error()
	}
	signals.HasError = allCustomerValid()

	return patchSignal(w, req, signals)
}

func validatePhone(phone string) error {
	switch {
	case len(phone) == 0:
		return errors.New("Required")
	case !util.IsAllDigits(phone):
		return errors.New("Letters not allowed")
	case len(phone) > 10:
		return errors.New("Must be exactly 10 digits")
	case phone[0] < '6' || phone[0] > '9':
		return errors.New("Should start with 6 - 9")
	}
	return nil
}

func Phone(w http.ResponseWriter, req bunrouter.Request) error {
	if err := datastar.ReadSignals(req.Request, model.Customer); err != nil {
		logger.Logger.Error(fmt.Sprintf("Failed to ReadSignals %+v with error: %+v", model.Customer, err.Error()))
		return err
	}

	type Signals = struct {
		HasError   bool   `json:"hasError"`
		PhoneError string `json:"phoneError"`
	}
	signals := &Signals{}

	if err := validatePhone(model.Customer.Phone); err != nil {
		signals.PhoneError = err.Error()
	}
	signals.HasError = allCustomerValid()

	return patchSignal(w, req, signals)
}

func validateRemark(remark string) error {
	if len(remark) > 0 {
		switch {
		case len(remark) < 3:
			return errors.New("Too short")
		case len(remark) > 100:
			return errors.New("Remark must be 100 characters or fewer")
		}
	}
	return util.ContainsInvalidChar(remark)
}

func Remark(w http.ResponseWriter, req bunrouter.Request) error {
	if err := datastar.ReadSignals(req.Request, model.Customer); err != nil {
		logger.Logger.Error(fmt.Sprintf("Failed to ReadSignals %+v with error: %+v", model.Customer, err.Error()))
		return err
	}

	type Signals = struct {
		HasError    bool   `json:"hasError"`
		RemarkError string `json:"remarkError"`
	}
	signals := &Signals{}

	if err := validateRemark(model.Customer.Remark); err != nil {
		signals.RemarkError = err.Error()
	}
	signals.HasError = allCustomerValid()

	return patchSignal(w, req, signals)
}

func validateShopNo(shopNo string) error {
	switch {
	case len(shopNo) == 0:
		return errors.New("Required")
	case len(shopNo) < 3:
		return errors.New("Too short")
	case len(shopNo) > 8:
		return errors.New("ShopNo must be 8 characters or fewer")
	}

	return util.ContainsInvalidChar(shopNo)
}

func ShopNo(w http.ResponseWriter, req bunrouter.Request) error {
	if err := datastar.ReadSignals(req.Request, model.Customer); err != nil {
		logger.Logger.Error(fmt.Sprintf("Failed to ReadSignals %+v with error: %+v", model.Customer, err.Error()))
		return err
	}

	type Signals = struct {
		HasError    bool   `json:"hasError"`
		ShopNoError string `json:"shopNoError"`
	}
	signals := &Signals{}

	shopNo := strings.ToUpper(strings.TrimSpace(model.Customer.ShopNo))
	if err := validateShopNo(shopNo); err != nil {
		signals.ShopNoError = err.Error()
	}
	signals.HasError = allCustomerValid()

	return patchSignal(w, req, signals)
}

func validateLine(value string, isRequired bool) error {
	switch {
	case isRequired && len(value) == 0:
		return errors.New("Required")
	case len(value) < 3 && !(len(value) == 0):
		return errors.New("Too short")
	case len(value) > 100:
		return errors.New("Must be 100 characters or fewer")
	}
	if err := util.ContainsInvalidChar(value); err != nil && len(value) > 0 {
		return err
	}
	return nil
}

func Line(w http.ResponseWriter, req bunrouter.Request) error {
	if err := datastar.ReadSignals(req.Request, model.Customer); err != nil {
		logger.Logger.Error(fmt.Sprintf("Failed to ReadSignals %+v with error: %+v", model.Customer, err.Error()))
		return err
	}

	lines := map[string]struct {
		value      string
		isRequired bool
	}{
		"line1": {model.Customer.Line1, true},
		"line2": {model.Customer.Line2, false},
		"line3": {model.Customer.Line3, false},
	}

	endpoint := path.Base(req.URL.Path)
	if line, ok := lines[endpoint]; ok {
		errMsg := ""
		if err := validateLine(line.value, line.isRequired); err != nil {
			errMsg = err.Error()
		}
		signals := map[string]any{
			endpoint + "Error": errMsg,
			"hasError":         allCustomerValid(),
		}
		return patchSignal(w, req, signals)
	}

	return nil
}

func validateCity(city string) error {
	switch {
	case len(city) == 0:
		return errors.New("Required")
	case len(city) < 3:
		return errors.New("Too Short")
	case len(city) > 32:
		return errors.New("Too Long")
	case !util.IsAllLetters(city):
		return errors.New("Digits not allowed")
	}
	return util.ContainsInvalidChar(city)
}

func City(w http.ResponseWriter, req bunrouter.Request) error {
	if err := datastar.ReadSignals(req.Request, model.Customer); err != nil {
		logger.Logger.Error(fmt.Sprintf("Failed to ReadSignals %+v with error: %+v", model.Customer, err.Error()))
		return err
	}

	type Signals = struct {
		HasError  bool   `json:"hasError"`
		CityError string `json:"cityError"`
	}
	signals := &Signals{}

	if err := validateCity(model.Customer.City); err != nil {
		signals.CityError = "Required"
	}
	signals.HasError = allCustomerValid()

	return patchSignal(w, req, signals)
}

func State(w http.ResponseWriter, req bunrouter.Request) error {
	if err := datastar.ReadSignals(req.Request, model.Customer); err != nil {
		logger.Logger.Error(fmt.Sprintf("Failed to ReadSignals %+v with error: %+v", model.Customer, err.Error()))
		return err
	}

	return nil
}

func validatePostalCode(state string, pc uint) error {
	stateMinPc, stateMaxPc := util.States[state].MinCode, util.States[state].MaxCode
	if pc < uint(stateMinPc) || pc > uint(stateMaxPc) {
		return fmt.Errorf("Out of range [%v - %v]", stateMinPc, stateMaxPc)
	}
	return nil
}

func PostalCode(w http.ResponseWriter, req bunrouter.Request) error {
	if err := datastar.ReadSignals(req.Request, model.Customer); err != nil {
		logger.Logger.Error(fmt.Sprintf("Failed to ReadSignals %+v with error: %+v", model.Customer, err.Error()))
		return err
	}

	type Signals = struct {
		HasError        bool   `json:"hasError"`
		PostalCodeError string `json:"postalCodeError"`
	}
	signals := &Signals{}

	if err := validatePostalCode(model.Customer.State, model.Customer.PostalCode); err != nil {
		signals.PostalCodeError = err.Error()
	}
	signals.HasError = allCustomerValid()

	return patchSignal(w, req, signals)
}

// }

// Product {
func AllProductValid() bool { return allProductValid() }

func allProductValid() bool {
	p := model.Product
	if validatePsn(p.SerialNumber) != nil {
		return false
	}
	if validatePname(p.Name) != nil {
		return false
	}
	if validatePhsn(p.Hsn) != nil {
		return false
	}
	if validatePquan(p.Quantity) != nil {
		return false
	}
	if validatePsp(p.SellPrice) != nil {
		return false
	}
	if validatePdisc(p.Discount) != nil {
		return false
	}
	return true
}

func validatePsn(sn string) error {
	switch {
	case len(sn) == 0:
		return errors.New("Required")
	}
	return nil
}

func SerialNumber(w http.ResponseWriter, req bunrouter.Request) error {
	if err := datastar.ReadSignals(req.Request, model.Product); err != nil {
		logger.Logger.Error(fmt.Sprintf("Failed to ReadSignals %+v with error: %+v", model.Customer, err.Error()))
		return err
	}

	type Signals = struct {
		ProductHasError bool   `json:"productHasError"`
		SerialNumber    string `json:"serialNumberError"`
	}
	signals := &Signals{}

	if err := validatePsn(model.Product.SerialNumber); err != nil {
		signals.SerialNumber = err.Error()
	}
	signals.ProductHasError = allProductValid()

	return patchSignal(w, req, signals)
}

func validatePname(name string) error {
	switch {
	case len(name) == 0:
		return errors.New("Required")
	}
	return nil
}

func ProductName(w http.ResponseWriter, req bunrouter.Request) error {
	if err := datastar.ReadSignals(req.Request, model.Product); err != nil {
		logger.Logger.Error(fmt.Sprintf("Failed to ReadSignals %+v with error: %+v", model.Customer, err.Error()))
		return err
	}

	type Signals = struct {
		ProductHasError   bool   `json:"productHasError"`
		ProductNameNumber string `json:"productNameError"`
	}
	signals := &Signals{}

	if err := validatePname(model.Product.Name); err != nil {
		signals.ProductNameNumber = err.Error()
	}
	signals.ProductHasError = allProductValid()

	return patchSignal(w, req, signals)
}

func validatePhsn(hsn string) error {
	switch {
	case len(hsn) == 0:
		return errors.New("Required")
	case len(hsn) != 2 && len(hsn) != 4 && len(hsn) != 6 && len(hsn) != 8:
		return errors.New("Must be 2, 4, 6, or 8 digits")
	case !util.IsAllDigits(hsn):
		return errors.New("Letters not allowed")
	}
	return nil
}

func Hsn(w http.ResponseWriter, req bunrouter.Request) error {
	if err := datastar.ReadSignals(req.Request, model.Product); err != nil {
		logger.Logger.Error(fmt.Sprintf("Failed to ReadSignals %+v with error: %+v", model.Customer, err.Error()))
		return err
	}

	type Signals = struct {
		ProductHasError bool   `json:"productHasError"`
		HsnNumber       string `json:"hsnError"`
	}
	signals := &Signals{}

	if err := validatePhsn(model.Product.Hsn); err != nil {
		signals.HsnNumber = err.Error()
	}
	signals.ProductHasError = allProductValid()

	return patchSignal(w, req, signals)
}

func validatePquan(quantity int) error {
	switch {
	case quantity <= 0:
		return errors.New("Atleast 1 Required")
	}
	return nil
}

func Quantity(w http.ResponseWriter, req bunrouter.Request) error {
	if err := datastar.ReadSignals(req.Request, model.Product); err != nil {
		logger.Logger.Error(fmt.Sprintf("Failed to ReadSignals %+v with error: %+v", model.Customer, err.Error()))
		return err
	}

	type Signals = struct {
		ProductHasError bool   `json:"productHasError"`
		QuantityNumber  string `json:"quantityError"`
	}
	signals := &Signals{}

	if err := validatePquan(model.Product.Quantity); err != nil {
		signals.QuantityNumber = err.Error()
	}
	signals.ProductHasError = allProductValid()

	return patchSignal(w, req, signals)
}

func validatePsp(price float32) error {
	switch {
	case price <= 0:
		return errors.New("Invalid")
	}
	return nil
}

func SellPrice(w http.ResponseWriter, req bunrouter.Request) error {
	if err := datastar.ReadSignals(req.Request, model.Product); err != nil {
		logger.Logger.Error(fmt.Sprintf("Failed to ReadSignals %+v with error: %+v", model.Customer, err.Error()))
		return err
	}

	type Signals = struct {
		ProductHasError bool   `json:"productHasError"`
		SellPriceNumber string `json:"sellPriceError"`
	}
	signals := &Signals{}

	if err := validatePsp(model.Product.SellPrice); err != nil {
		signals.SellPriceNumber = err.Error()
	}
	signals.ProductHasError = allProductValid()

	return patchSignal(w, req, signals)
}

func validatePdisc(discount float32) error {
	switch {
	case discount < -0.1 || discount > 100.0:
		return errors.New("Invalid")
	}
	return nil
}

func Discount(w http.ResponseWriter, req bunrouter.Request) error {
	if err := datastar.ReadSignals(req.Request, model.Product); err != nil {
		logger.Logger.Error(fmt.Sprintf("Failed to ReadSignals %+v with error: %+v", model.Customer, err.Error()))
		return err
	}

	type Signals = struct {
		ProductHasError bool   `json:"productHasError"`
		DiscountNumber  string `json:"discountError"`
	}
	signals := &Signals{}

	if err := validatePdisc(model.Product.Discount); err != nil {
		signals.DiscountNumber = err.Error()
	}
	signals.ProductHasError = allProductValid()

	return patchSignal(w, req, signals)
}

// }
