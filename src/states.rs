use std::collections::HashMap;

#[derive(Debug, Clone)]
pub struct StateInfo {
    pub min_code: u32,
    pub max_code: u32,
    pub cities: Vec<&'static str>,
}

/// Returns the full states map. Equivalent to util.States in Go.
pub fn states() -> HashMap<&'static str, StateInfo> {
    let mut m = HashMap::new();
    m.insert("Andaman and Nicobar Islands", StateInfo { min_code: 744101, max_code: 744304, cities: vec!["Port Blair", "Car Nicobar", "Diglipur", "Rangat", "Mayabunder"] });
    m.insert("Andhra Pradesh", StateInfo { min_code: 507130, max_code: 535594, cities: vec!["Visakhapatnam", "Vijayawada", "Guntur", "Tirupati", "Kurnool", "Kakinada", "Nellore", "Rajahmundry"] });
    m.insert("Arunachal Pradesh", StateInfo { min_code: 790001, max_code: 792131, cities: vec!["Itanagar", "Naharlagun", "Pasighat", "Tezpur", "Bomdila", "Ziro"] });
    m.insert("Assam", StateInfo { min_code: 781001, max_code: 788931, cities: vec!["Guwahati", "Silchar", "Dibrugarh", "Jorhat", "Nagaon", "Tinsukia", "Tezpur", "Bongaigaon"] });
    m.insert("Bihar", StateInfo { min_code: 800001, max_code: 855117, cities: vec!["Patna", "Gaya", "Muzaffarpur", "Bhagalpur", "Darbhanga", "Purnia", "Arrah", "Begusarai"] });
    m.insert("Chandigarh", StateInfo { min_code: 140119, max_code: 160102, cities: vec!["Chandigarh"] });
    m.insert("Chhattisgarh", StateInfo { min_code: 490001, max_code: 497778, cities: vec!["Raipur", "Bhilai", "Bilaspur", "Korba", "Durg", "Rajnandgaon", "Jagdalpur"] });
    m.insert("Dadra and Nagar Haveli and Daman and Diu", StateInfo { min_code: 362520, max_code: 396240, cities: vec!["Daman", "Diu", "Silvassa"] });
    m.insert("Delhi", StateInfo { min_code: 110001, max_code: 110097, cities: vec!["New Delhi", "Delhi", "Dwarka", "Rohini", "Shahdara", "Janakpuri", "Pitampura"] });
    m.insert("Goa", StateInfo { min_code: 403001, max_code: 403806, cities: vec!["Panaji", "Margao", "Vasco da Gama", "Mapusa", "Ponda", "Calangute"] });
    m.insert("Gujarat", StateInfo { min_code: 360001, max_code: 396590, cities: vec!["Ahmedabad", "Surat", "Vadodara", "Rajkot", "Bhavnagar", "Jamnagar", "Gandhinagar", "Anand"] });
    m.insert("Haryana", StateInfo { min_code: 121001, max_code: 136156, cities: vec!["Faridabad", "Gurugram", "Panipat", "Ambala", "Yamunanagar", "Rohtak", "Hisar", "Karnal"] });
    m.insert("Himachal Pradesh", StateInfo { min_code: 171001, max_code: 177601, cities: vec!["Shimla", "Dharamshala", "Solan", "Mandi", "Kullu", "Hamirpur", "Una"] });
    m.insert("Jammu and Kashmir (including Ladakh)", StateInfo { min_code: 180001, max_code: 194404, cities: vec!["Srinagar", "Jammu", "Leh", "Anantnag", "Baramulla", "Kargil", "Sopore"] });
    m.insert("Jharkhand", StateInfo { min_code: 813208, max_code: 835325, cities: vec!["Ranchi", "Jamshedpur", "Dhanbad", "Bokaro", "Hazaribagh", "Deoghar", "Giridih"] });
    m.insert("Karnataka", StateInfo { min_code: 560001, max_code: 591346, cities: vec!["Bengaluru", "Mysuru", "Hubli", "Mangaluru", "Belagavi", "Davanagere", "Ballari", "Tumkur"] });
    m.insert("Kerala", StateInfo { min_code: 670001, max_code: 695615, cities: vec!["Thiruvananthapuram", "Kochi", "Kozhikode", "Thrissur", "Kollam", "Palakkad", "Alappuzha", "Kannur"] });
    m.insert("Lakshadweep", StateInfo { min_code: 682551, max_code: 682559, cities: vec!["Kavaratti", "Agatti", "Minicoy", "Amini"] });
    m.insert("Madhya Pradesh", StateInfo { min_code: 450001, max_code: 488448, cities: vec!["Bhopal", "Indore", "Gwalior", "Jabalpur", "Ujjain", "Sagar", "Dewas", "Satna"] });
    m.insert("Maharashtra", StateInfo { min_code: 400001, max_code: 445402, cities: vec!["Mumbai", "Pune", "Nagpur", "Nashik", "Aurangabad", "Solapur", "Thane", "Kolhapur", "Amravati"] });
    m.insert("Manipur", StateInfo { min_code: 795001, max_code: 795159, cities: vec!["Imphal", "Thoubal", "Bishnupur", "Churachandpur", "Senapati"] });
    m.insert("Meghalaya", StateInfo { min_code: 783123, max_code: 794115, cities: vec!["Shillong", "Tura", "Jowai", "Nongpoh", "Baghmara"] });
    m.insert("Mizoram", StateInfo { min_code: 796001, max_code: 796901, cities: vec!["Aizawl", "Lunglei", "Champhai", "Serchhip", "Kolasib"] });
    m.insert("Nagaland", StateInfo { min_code: 797001, max_code: 798627, cities: vec!["Kohima", "Dimapur", "Mokokchung", "Tuensang", "Wokha", "Zunheboto"] });
    m.insert("Odisha", StateInfo { min_code: 751001, max_code: 770076, cities: vec!["Bhubaneswar", "Cuttack", "Rourkela", "Berhampur", "Sambalpur", "Puri", "Balasore"] });
    m.insert("Puducherry", StateInfo { min_code: 533464, max_code: 673310, cities: vec!["Puducherry", "Karaikal", "Mahe", "Yanam"] });
    m.insert("Punjab", StateInfo { min_code: 140001, max_code: 160104, cities: vec!["Ludhiana", "Amritsar", "Jalandhar", "Patiala", "Bathinda", "Mohali", "Pathankot", "Hoshiarpur"] });
    m.insert("Rajasthan", StateInfo { min_code: 301001, max_code: 345034, cities: vec!["Jaipur", "Jodhpur", "Kota", "Bikaner", "Ajmer", "Udaipur", "Bhilwara", "Alwar"] });
    m.insert("Sikkim", StateInfo { min_code: 737101, max_code: 737139, cities: vec!["Gangtok", "Namchi", "Geyzing", "Mangan"] });
    m.insert("Tamil Nadu", StateInfo { min_code: 600001, max_code: 643253, cities: vec!["Chennai", "Coimbatore", "Madurai", "Tiruchirappalli", "Salem", "Tirunelveli", "Vellore", "Erode"] });
    m.insert("Telangana", StateInfo { min_code: 500001, max_code: 509412, cities: vec!["Hyderabad", "Warangal", "Nizamabad", "Karimnagar", "Khammam", "Ramagundam", "Mahbubnagar"] });
    m.insert("Tripura", StateInfo { min_code: 799001, max_code: 799290, cities: vec!["Agartala", "Dharmanagar", "Udaipur", "Kailashahar", "Belonia"] });
    m.insert("Uttar Pradesh", StateInfo { min_code: 201001, max_code: 285223, cities: vec!["Lucknow", "Kanpur", "Varanasi", "Agra", "Prayagraj", "Meerut", "Ghaziabad", "Noida", "Bareilly"] });
    m.insert("Uttarakhand", StateInfo { min_code: 244712, max_code: 263680, cities: vec!["Dehradun", "Haridwar", "Roorkee", "Haldwani", "Rudrapur", "Rishikesh", "Kashipur"] });
    m.insert("West Bengal", StateInfo { min_code: 700001, max_code: 743711, cities: vec!["Kolkata", "Howrah", "Durgapur", "Asansol", "Siliguri", "Bardhaman", "Malda", "Kharagpur"] });

    debug_assert_eq!(m.len(), 35, "States map has {} entries, expected 35", m.len());
    m
}

/// Sorted state names for dropdowns — equivalent to util.StateNames in Go.
pub fn state_names() -> Vec<&'static str> {
    let mut names: Vec<&'static str> = states().into_keys().collect();
    names.sort_unstable();
    names
}
