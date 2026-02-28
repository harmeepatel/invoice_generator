package model

type ProductInfo struct {
	Quantity     int    `json:"quantity"`
	Price        float32 `json:"sellPrice"`
	Discount     float32 `json:"discount"`
	SerialNumber string  `json:"serialNumber"`
	Name         string  `json:"productName"`
	Hsn          string  `json:"hsn"`
}

type CustomerInfo struct {
	Name       string        `json:"name"`
	GSTIN      string        `json:"gstin"`
	GST        float32       `json:"gst"`
	Email      string        `json:"email"`
	Phone      string        `json:"phone"`
	PhoneExt   string        `json:"phoneExt"`
	Remark     string        `json:"remark"`
	ShopNo     string        `json:"shopNo"`
	Line1      string        `json:"line1"`
	Line2      string        `json:"line2"`
	Line3      string        `json:"line3"`
	City       string        `json:"city"`
	State      string        `json:"state"`
	PostalCode uint          `json:"postalCode"`
	Products   []ProductInfo `json:"productList"`
}

type ShippingAddr struct {
}
type BillingAddr struct {
}

var Customer = &CustomerInfo{}
var Product = &ProductInfo{}
