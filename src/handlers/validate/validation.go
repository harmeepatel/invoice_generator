package validate

import (
	"ae_invoice/src/logger"
	model "ae_invoice/src/models"
	"ae_invoice/src/shared"
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

var isAllDigits = func(str string) bool {
	for _, d := range str {
		if !unicode.IsDigit(d) {
			return false
		}
	}
	return true
}
var isAllLetters = func(str string) bool {
	for _, d := range str {
		if !unicode.IsLetter(d) {
			return false
		}
	}
	return true
}

func patch(w http.ResponseWriter, req bunrouter.Request, signals any) error {
	sse := datastar.NewSSE(w, req.Request)
	if err := sse.MarshalAndPatchSignals(signals); err != nil {
		logger.Logger.Error(fmt.Sprintf("Failed to Marshal %+v with error: %+v", signals, err.Error()))
		return err
	}
	return nil
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
	name := strings.TrimSpace(model.Customer.Name)
	switch {
	case len(name) == 0:
		signals.HasError, signals.NameError = true, "Required"
	case len(name) < 3:
		signals.HasError, signals.NameError = true, "Too short"
	case len(name) > 100:
		signals.HasError, signals.NameError = true, "Name must be 100 characters or fewer"
	default:
		var specialCharPattern = regexp.MustCompile(`[^\w]`)
		if specialCharPattern.FindStringIndex(name) != nil {
			signals.HasError, signals.NameError = true, "Contains invalid characters"
		}
	}
	return patch(w, req, signals)
}

func Gstin(w http.ResponseWriter, req bunrouter.Request) error {
	if err := datastar.ReadSignals(req.Request, model.Customer); err != nil {
		logger.Logger.Error(fmt.Sprintf("Failed to ReadSignals %+v with error: %+v", model.Customer, err.Error()))
		return err
	}

	var validatePan = func(panInput string) error {
		pan := strings.TrimSpace(strings.ToUpper(panInput))
		switch {
		case len(pan) == 0:
			return errors.New("Required")
		case len(pan) != 10:
			return errors.New("PAN must be exactly 10 characters")
		default:
			var panPattern = regexp.MustCompile(`^[A-Z]{3}[PCFHATGLJ][A-Z]\d{4}[A-Z]$`)
			switch {
			case !regexp.MustCompile(`^[A-Z]{5}`).MatchString(pan[:5]):
				return errors.New("First 5 characters of PAN must be alphabetic")
			case !regexp.MustCompile(`^[PCFHATGLJ]$`).MatchString(string(pan[3])):
				return errors.New("6th character must be a valid holder type (P, C, F, H, A, T, G, L, or J)")
			case !regexp.MustCompile(`^\d{4}$`).MatchString(pan[5:9]):
				return errors.New("Characters 7–11 must be numeric")
			case pan[5:9] == "0000":
				return errors.New("Numeric portion must be between 0001 and 9999")
			case !regexp.MustCompile(`^[A-Z]$`).MatchString(string(pan[9])):
				return errors.New("Last character must be alphabetic")
			case !panPattern.MatchString(pan):
				return errors.New("Invalid PAN format")
			}
		}
		return nil
	}

	type Signals struct {
		HasError   bool   `json:"hasError"`
		GstinError string `json:"gstinError"`
	}
	signals := &Signals{}
	gstin := strings.TrimSpace(model.Customer.GSTIN)

	switch {
	case len(gstin) == 0:
		signals.HasError, signals.GstinError = true, "Required"
	case len(gstin) != 15:
		signals.HasError, signals.GstinError = true, "GSTIN must be 15 characters"
	default:
		switch {
		case !unicode.IsDigit(rune(gstin[0])) || !unicode.IsDigit(rune(gstin[1])):
			signals.HasError, signals.GstinError = true, "GSTIN has an invalid state code"
		case validatePan(gstin[2:12]) != nil:
			err := validatePan(gstin[2:12])
			signals.HasError, signals.GstinError = true, err.Error()
		case !unicode.IsDigit(rune(gstin[12])) && !unicode.IsUpper(rune(gstin[12])):
			signals.HasError, signals.GstinError = true, "GSTIN has an invalid registration number"
		case gstin[13] != 'Z':
			signals.HasError, signals.GstinError = true, "GSTIN has an invalid format"
		case !unicode.IsDigit(rune(gstin[14])) || !unicode.IsLetter(rune(gstin[14])):
			signals.HasError, signals.GstinError = true, "GSTIN has an invalid checksum"
		}
	}
	return patch(w, req, signals)
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

	gst := model.Customer.GST
	switch {
	case gst < 0 || gst > 40:
		signals.HasError, signals.GstError = true, "GST must be 0% - 40%"
	}

	return patch(w, req, signals)
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

	_, err := mail.ParseAddress(model.Customer.Email)
	if len(model.Customer.Email) > 0 && err != nil {
		signals.HasError, signals.EmailError = true, "Invalid Email"
	}

	return patch(w, req, signals)
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

	phone := model.Customer.Phone

	switch {
	case len(phone) == 0:
		signals.HasError, signals.PhoneError = true, "Required"
	case phone[0] < '6' || phone[0] > '9':
		signals.HasError, signals.PhoneError = true, "Should start with 6 - 9"
	case !isAllDigits(phone):
		signals.HasError, signals.PhoneError = true, "Must be all digits"
	case len(phone) > 10:
		signals.HasError, signals.PhoneError = true, "Must be only 10 digits"
	}
	return patch(w, req, signals)
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
	remark := model.Customer.Remark

	if len(remark) > 0 {
		switch {
		case len(remark) < 3:
			signals.HasError, signals.RemarkError = true, "Too short"
		case len(remark) > 100:
			signals.HasError, signals.RemarkError = true, "Remark must be 100 characters or fewer"
		default:
			var specialCharPattern = regexp.MustCompile(`[^\w]`)
			if specialCharPattern.FindStringIndex(remark) != nil {
				signals.HasError, signals.RemarkError = true, "Contains invalid characters"
			}
		}
	}

	return patch(w, req, signals)
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

	shopNo := strings.TrimSpace(model.Customer.ShopNo)
	switch {
	case len(shopNo) == 0:
		signals.HasError, signals.ShopNoError = true, "Required"
	case len(shopNo) < 3:
		signals.HasError, signals.ShopNoError = true, "Too short"
	case len(shopNo) > 8:
		signals.HasError, signals.ShopNoError = true, "ShopNo must be 8 characters or fewer"
	default:
		var specialCharPattern = regexp.MustCompile(`[^\w]`)
		if specialCharPattern.FindStringIndex(shopNo) != nil {
			signals.HasError, signals.ShopNoError = true, "Contains invalid characters"
		}
	}
	return patch(w, req, signals)
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

	var specialCharPattern = regexp.MustCompile(`[^\w]`)
	var validateLine = func(value string, required bool) string {
		if required && len(value) == 0 {
			return "Required"
		}
		if len(value) == 0 {
			return ""
		}
		switch {
		case len(value) < 3:
			return "Too short"
		case len(value) > 100:
			return "Must be 100 characters or fewer"
		case specialCharPattern.MatchString(value):
			return "Contains invalid characters"
		}
		return ""
	}

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

	if l, ok := lines[endpoint]; ok {
		if errMsg := validateLine(l.value, l.required); errMsg != "" {
			signals.HasError = true
			l.setError(errMsg)
		}
	}

	return patch(w, req, signals)
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

	city := model.Customer.City

	switch {
	case len(city) == 0:
		signals.HasError, signals.CityError = true, "Required"
	case len(city) < 3:
		signals.HasError, signals.CityError = true, "Too Short"
	case len(city) > 32:
		signals.HasError, signals.CityError = true, "Too Long"
	case !isAllLetters(city):
		signals.HasError, signals.CityError = true, "Digits not allowed"
	default:
		var specialCharPattern = regexp.MustCompile(`[^\w]`)
		if specialCharPattern.FindStringIndex(city) != nil {
			signals.HasError, signals.CityError = true, "Contains invalid characters"
		}

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

	state := model.Customer.State
	stateMinPc, stateMaxPc := shared.States[state].MinCode, shared.States[state].MaxCode
	pc := model.Customer.PostalCode

	if pc < uint(stateMinPc) || pc > uint(stateMaxPc) {
		signals.HasError, signals.PostalCodeError = true, fmt.Sprintf("Out of range (%v - %v)", stateMinPc, stateMaxPc)
	}

	return patch(w, req, signals)
}
