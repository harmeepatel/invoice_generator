package route

import (
	"ae_invoice/src/logger"
	model "ae_invoice/src/models"
	"ae_invoice/src/validate"
	"fmt"
	"net/http"
	"strconv"

	"github.com/starfederation/datastar-go/datastar"
	"github.com/uptrace/bunrouter"
)

// base: /validate
func Validate(vg *bunrouter.Group) {
			vg.POST("/city", validate.City)
			vg.POST("/companyName", validate.CompanyName)
			vg.POST("/email", validate.Email)
			vg.POST("/igst", validate.Igst)
			vg.POST("/gstin", validate.Gstin)
			vg.POST("/line1", validate.Line)
			vg.POST("/line2", validate.Line)
			vg.POST("/line3", validate.Line)
			vg.POST("/name", validate.Name)
			vg.POST("/phone", validate.Phone)
			vg.POST("/postalCode", validate.PostalCode)
			vg.POST("/remark", validate.Remark)
			vg.POST("/shopNo", validate.ShopNo)
			vg.POST("/state", validate.State)

			vg.POST("/discount", validate.Discount)
			vg.POST("/gst", validate.Gst)
			vg.POST("/hsn", validate.Hsn)
			vg.POST("/productName", validate.ProductName)
			vg.POST("/quantity", validate.Quantity)
			vg.POST("/rate", validate.Rate)
			vg.POST("/serialNumber", validate.SerialNumber)

			vg.GET("/all", func(w http.ResponseWriter, req bunrouter.Request) error {
				err := req.ParseForm()
				if err != nil {
					logger.Logger.Error("Failed to parse form on /invoice/validate/all")
					return err
				}

				postalCode, _ := strconv.ParseUint(req.Form.Get("postalCode"), 10, 64)
				model.Customer = &model.CustomerInfo{
					Name:        req.Form.Get("name"),
					CompanyName: req.Form.Get("companyName"),
					Gstin:       req.Form.Get("gstin"),
					Email:       req.Form.Get("email"),
					Phone:       req.Form.Get("phone"),
					PhoneExt:    req.Form.Get("phoneExt"),
					Remark:      req.Form.Get("remark"),
					ShopNo:      req.Form.Get("shopNo"),
					Line1:       req.Form.Get("line1"),
					Line2:       req.Form.Get("line2"),
					Line3:       req.Form.Get("line3"),
					City:        req.Form.Get("city"),
					State:       req.Form.Get("state"),
					PostalCode:  uint(postalCode),
				}

				gst, _ := strconv.ParseFloat(req.Form.Get("gst"), 32)
				qty, _ := strconv.Atoi(req.Form.Get("quantity"))
				rate, _ := strconv.ParseFloat(req.Form.Get("rate"), 32)
				discount, _ := strconv.ParseFloat(req.Form.Get("discount"), 32)
				model.Product = &model.ProductInfo{
					Quantity:     qty,
					Rate:         rate,
					Discount:     discount,
					Gst:          gst,
					SerialNumber: req.Form.Get("serialNumber"),
					Name:         req.Form.Get("productName"),
					Hsn:          req.Form.Get("hsn"),
				}

				type Signals struct {
					HasError        bool `json:"hasError"`
					ProductHasError bool `json:"productHasError"`
				}
				signals := &Signals{}

				signals.HasError = !validate.AllCustomerValid()
				signals.ProductHasError = !validate.AllProductValid()

				sse := datastar.NewSSE(w, req.Request)
				if err := sse.MarshalAndPatchSignals(signals); err != nil {
					logger.Logger.Error(fmt.Sprintf("Failed to Marshal %+v with error: %+v", signals, err.Error()))
					return err
				}
				return nil

			})
		}
