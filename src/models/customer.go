package model

// CustomerInfo holds all form signals
type CustomerInfo struct {
	Name       string  `json:"name"`
	GSTIN      string  `json:"gstin"`
	GST        float32 `json:"gst"`
	Email      string  `json:"email"`
	Phone      string  `json:"phone"`
	PhoneExt   string  `json:"phoneExt"`
	Remark     string  `json:"remark"`
	ShopNo     string  `json:"shopNo"`
	Line1      string  `json:"line1"`
	Line2      string  `json:"line2"`
	Line3      string  `json:"line3"`
	City       string  `json:"city"`
	State      string  `json:"state"`
	PostalCode uint    `json:"postalCode"`
}

type ShippingAddr struct{
}
type BillingAddr struct{
}

var Customer = &CustomerInfo{}
