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

func patch(w http.ResponseWriter, req bunrouter.Request, signals any) error {
	sse := datastar.NewSSE(w, req.Request)
	if err := sse.MarshalAndPatchSignals(signals); err != nil {
		logger.Logger.Error(fmt.Sprintf("Failed to Marshal %+v with error: %+v", signals, err.Error()))
		return err
	}
	return nil
}

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
		signals.HasError, signals.NameError = true, err.Error()
	}

	return patch(w, req, signals)
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
		signals.HasError, signals.GstinError = true, err.Error()
	}

	return patch(w, req, signals)
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
		signals.HasError, signals.GstError = true, err.Error()
	}

	return patch(w, req, signals)
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
		signals.HasError, signals.EmailError = true, err.Error()
	}

	return patch(w, req, signals)
}

func validatePhone(phone string) error {
	switch {
	case len(phone) == 0:
		return errors.New("Required")
	case !util.IsAllDigits(phone):
		return errors.New("Must be all digits")
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
		signals.HasError, signals.PhoneError = true, err.Error()
	}

	return patch(w, req, signals)
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
		signals.HasError, signals.RemarkError = true, err.Error()
	}

	return patch(w, req, signals)
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
		signals.HasError, signals.ShopNoError = true, err.Error()
	}

	return patch(w, req, signals)
}

func validateLine(value string) error {
	required := false
	if value == "line1" {
		required = true
	}

	switch {
	case required && len(value) == 0:
		return errors.New("Required")
	case len(value) < 3 && !(len(value) == 0):
		return errors.New("Too short")
	case len(value) > 100:
		return errors.New("Must be 100 characters or fewer")
	}
	return util.ContainsInvalidChar(value)
}

func Line(w http.ResponseWriter, req bunrouter.Request) error {
	if err := datastar.ReadSignals(req.Request, model.Customer); err != nil {
		logger.Logger.Error(fmt.Sprintf("Failed to ReadSignals %+v with error: %+v", model.Customer, err.Error()))
		return err
	}

	type Signals = struct {
		HasError   bool   `json:"hasError"`
		Line1Error string `json:"line1Error"`
		Line2Error string `json:"line2Error"`
		Line3Error string `json:"line3Error"`
	}
	signals := &Signals{}

	endpoint := path.Base(req.URL.Path)
	lines := map[string]struct {
		value    string
		required bool
		setError func(string)
	}{
		"line1": {model.Customer.Line1, true, func(e string) { signals.Line1Error = e }},
		"line2": {model.Customer.Line2, false, func(e string) { signals.Line2Error = e }},
		"line3": {model.Customer.Line3, false, func(e string) { signals.Line3Error = e }},
	}

	if line, ok := lines[endpoint]; ok {
		if err := validateLine(line.value); err != nil {
			signals.HasError = true
			line.setError(err.Error())
		}
	}

	return patch(w, req, signals)
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
		signals.HasError, signals.CityError = true, "Required"
	}

	return patch(w, req, signals)
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
		signals.HasError, signals.PostalCodeError = true, err.Error()
	}

	return patch(w, req, signals)
}
