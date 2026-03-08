package util

import (
	"errors"
	"math"
	"regexp"
	"strings"
	"unicode"
)

func IsAllDigits(str string) bool {
	for _, d := range str {
		if !unicode.IsDigit(d) {
			return false
		}
	}
	return true
}

func IsAllLetters(str string) bool {
	for _, d := range str {
		if !unicode.IsLetter(d) {
			return false
		}
	}
	return true
}

var invalidCharPattern = regexp.MustCompile(`^\w+$`)

func ContainsInvalidChar(str string) error {
	words := strings.SplitSeq(strings.TrimSpace(str), " ")
	for word := range words {
		if invalidCharPattern.FindStringIndex(word) == nil {
			return errors.New("Contains invalid characters")
		}
	}
	return nil
}

func CamelToKebab(s string) string {
	var b strings.Builder
	var prevLower bool

	for i, r := range s {
		if unicode.IsUpper(r) {
			if i > 0 && prevLower {
				b.WriteRune('-')
			}
			b.WriteRune(unicode.ToLower(r))
			prevLower = false
		} else {
			b.WriteRune(r)
			prevLower = true
		}
	}

	return b.String()
}

func RoundFloat(val float64) float64 {
	ratio := math.Pow(10, float64(2))
	return math.Round(val*ratio) / ratio
}
