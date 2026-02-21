package shared

import (
	"ae_invoice/src/logger"
	"sort"
)

type StateInfo struct {
	MinCode uint32
	MaxCode uint32
	Cities  []string
}

var States = map[string]StateInfo{
	"Andaman and Nicobar Islands": {
		MinCode: 744101, MaxCode: 744304,
		Cities: []string{"Port Blair", "Car Nicobar", "Diglipur", "Rangat", "Mayabunder"},
	},
	"Andhra Pradesh": {
		MinCode: 507130, MaxCode: 535594,
		Cities: []string{"Visakhapatnam", "Vijayawada", "Guntur", "Tirupati", "Kurnool", "Kakinada", "Nellore", "Rajahmundry"},
	},
	"Arunachal Pradesh": {
		MinCode: 790001, MaxCode: 792131,
		Cities: []string{"Itanagar", "Naharlagun", "Pasighat", "Tezpur", "Bomdila", "Ziro"},
	},
	"Assam": {
		MinCode: 781001, MaxCode: 788931,
		Cities: []string{"Guwahati", "Silchar", "Dibrugarh", "Jorhat", "Nagaon", "Tinsukia", "Tezpur", "Bongaigaon"},
	},
	"Bihar": {
		MinCode: 800001, MaxCode: 855117,
		Cities: []string{"Patna", "Gaya", "Muzaffarpur", "Bhagalpur", "Darbhanga", "Purnia", "Arrah", "Begusarai"},
	},
	"Chandigarh": {
		MinCode: 140119, MaxCode: 160102,
		Cities: []string{"Chandigarh"},
	},
	"Chhattisgarh": {
		MinCode: 490001, MaxCode: 497778,
		Cities: []string{"Raipur", "Bhilai", "Bilaspur", "Korba", "Durg", "Rajnandgaon", "Jagdalpur"},
	},
	"Dadra and Nagar Haveli and Daman and Diu": {
		MinCode: 362520, MaxCode: 396240,
		Cities: []string{"Daman", "Diu", "Silvassa"},
	},
	"Delhi": {
		MinCode: 110001, MaxCode: 110097,
		Cities: []string{"New Delhi", "Delhi", "Dwarka", "Rohini", "Shahdara", "Janakpuri", "Pitampura"},
	},
	"Goa": {
		MinCode: 403001, MaxCode: 403806,
		Cities: []string{"Panaji", "Margao", "Vasco da Gama", "Mapusa", "Ponda", "Calangute"},
	},
	"Gujarat": {
		MinCode: 360001, MaxCode: 396590,
		Cities: []string{"Ahmedabad", "Surat", "Vadodara", "Rajkot", "Bhavnagar", "Jamnagar", "Gandhinagar", "Anand"},
	},
	"Haryana": {
		MinCode: 121001, MaxCode: 136156,
		Cities: []string{"Faridabad", "Gurugram", "Panipat", "Ambala", "Yamunanagar", "Rohtak", "Hisar", "Karnal"},
	},
	"Himachal Pradesh": {
		MinCode: 171001, MaxCode: 177601,
		Cities: []string{"Shimla", "Dharamshala", "Solan", "Mandi", "Kullu", "Hamirpur", "Una"},
	},
	"Jammu and Kashmir (including Ladakh)": {
		MinCode: 180001, MaxCode: 194404,
		Cities: []string{"Srinagar", "Jammu", "Leh", "Anantnag", "Baramulla", "Kargil", "Sopore"},
	},
	"Jharkhand": {
		MinCode: 813208, MaxCode: 835325,
		Cities: []string{"Ranchi", "Jamshedpur", "Dhanbad", "Bokaro", "Hazaribagh", "Deoghar", "Giridih"},
	},
	"Karnataka": {
		MinCode: 560001, MaxCode: 591346,
		Cities: []string{"Bengaluru", "Mysuru", "Hubli", "Mangaluru", "Belagavi", "Davanagere", "Ballari", "Tumkur"},
	},
	"Kerala": {
		MinCode: 670001, MaxCode: 695615,
		Cities: []string{"Thiruvananthapuram", "Kochi", "Kozhikode", "Thrissur", "Kollam", "Palakkad", "Alappuzha", "Kannur"},
	},
	"Lakshadweep": {
		MinCode: 682551, MaxCode: 682559,
		Cities: []string{"Kavaratti", "Agatti", "Minicoy", "Amini"},
	},
	"Madhya Pradesh": {
		MinCode: 450001, MaxCode: 488448,
		Cities: []string{"Bhopal", "Indore", "Gwalior", "Jabalpur", "Ujjain", "Sagar", "Dewas", "Satna"},
	},
	"Maharashtra": {
		MinCode: 400001, MaxCode: 445402,
		Cities: []string{"Mumbai", "Pune", "Nagpur", "Nashik", "Aurangabad", "Solapur", "Thane", "Kolhapur", "Amravati"},
	},
	"Manipur": {
		MinCode: 795001, MaxCode: 795159,
		Cities: []string{"Imphal", "Thoubal", "Bishnupur", "Churachandpur", "Senapati"},
	},
	"Meghalaya": {
		MinCode: 783123, MaxCode: 794115,
		Cities: []string{"Shillong", "Tura", "Jowai", "Nongpoh", "Baghmara"},
	},
	"Mizoram": {
		MinCode: 796001, MaxCode: 796901,
		Cities: []string{"Aizawl", "Lunglei", "Champhai", "Serchhip", "Kolasib"},
	},
	"Nagaland": {
		MinCode: 797001, MaxCode: 798627,
		Cities: []string{"Kohima", "Dimapur", "Mokokchung", "Tuensang", "Wokha", "Zunheboto"},
	},
	"Odisha": {
		MinCode: 751001, MaxCode: 770076,
		Cities: []string{"Bhubaneswar", "Cuttack", "Rourkela", "Berhampur", "Sambalpur", "Puri", "Balasore"},
	},
	"Puducherry": {
		MinCode: 533464, MaxCode: 673310,
		Cities: []string{"Puducherry", "Karaikal", "Mahe", "Yanam"},
	},
	"Punjab": {
		MinCode: 140001, MaxCode: 160104,
		Cities: []string{"Ludhiana", "Amritsar", "Jalandhar", "Patiala", "Bathinda", "Mohali", "Pathankot", "Hoshiarpur"},
	},
	"Rajasthan": {
		MinCode: 301001, MaxCode: 345034,
		Cities: []string{"Jaipur", "Jodhpur", "Kota", "Bikaner", "Ajmer", "Udaipur", "Bhilwara", "Alwar"},
	},
	"Sikkim": {
		MinCode: 737101, MaxCode: 737139,
		Cities: []string{"Gangtok", "Namchi", "Geyzing", "Mangan"},
	},
	"Tamil Nadu": {
		MinCode: 600001, MaxCode: 643253,
		Cities: []string{"Chennai", "Coimbatore", "Madurai", "Tiruchirappalli", "Salem", "Tirunelveli", "Vellore", "Erode"},
	},
	"Telangana": {
		MinCode: 500001, MaxCode: 509412,
		Cities: []string{"Hyderabad", "Warangal", "Nizamabad", "Karimnagar", "Khammam", "Ramagundam", "Mahbubnagar"},
	},
	"Tripura": {
		MinCode: 799001, MaxCode: 799290,
		Cities: []string{"Agartala", "Dharmanagar", "Udaipur", "Kailashahar", "Belonia"},
	},
	"Uttar Pradesh": {
		MinCode: 201001, MaxCode: 285223,
		Cities: []string{"Lucknow", "Kanpur", "Varanasi", "Agra", "Prayagraj", "Meerut", "Ghaziabad", "Noida", "Bareilly"},
	},
	"Uttarakhand": {
		MinCode: 244712, MaxCode: 263680,
		Cities: []string{"Dehradun", "Haridwar", "Roorkee", "Haldwani", "Rudrapur", "Rishikesh", "Kashipur"},
	},
	"West Bengal": {
		MinCode: 700001, MaxCode: 743711,
		Cities: []string{"Kolkata", "Howrah", "Durgapur", "Asansol", "Siliguri", "Bardhaman", "Malda", "Kharagpur"},
	},
}

// StateNames is a sorted slice for use in dropdowns
var StateNames []string

func init() {
	// comptime-equivalent length check
	if len(States) != 35 {
		logger.Logger.Fatalf("IndianStates map has %d entries, expected 35", len(States))
	}
	for name := range States {
		StateNames = append(StateNames, name)
	}
	sort.Strings(StateNames)
}
