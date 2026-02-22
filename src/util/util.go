package util

import (
	"errors"
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
