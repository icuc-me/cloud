package main

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"regexp"
	"strings"
)

func fullEnvVar(name string) (value string, err error) {
	var present bool
	var fullValue string

	if fullValue, present = os.LookupEnv(name); !present {
		err = fmt.Errorf("expected env. var %s to exist", name)
	} else {
		value = strings.TrimSpace(fullValue)
		if value == "" {
			err = fmt.Errorf("expected env. var %s contents to not be empty", name)
		}
	}
	return value, err
}

func validatePIDEnvVar(value, test string) string {
	switch test {
	case "are 6 to 30 lowercase letters, digits, or hyphens":
		if len(value) < 6 || len(value) > 30 {
			return "shorter than 6 or longer than 30"
		}
		if strings.ToLower(value) != value {
			return "not lowercase"
		}
		validPID := regexp.MustCompile(`^[a-z0-9\-]+$`)
		if !validPID.Match([]byte(value)) {
			return "not lowercase letters, digits or hyphens"
		}
		return ""
	case "begin with a letter":
		validPID := regexp.MustCompile(`^[a-z]`)
		if !validPID.Match([]byte(value)) {
			return "not lowercase letter"
		}
		return ""
	case "do not end with a hyphen":
		validPID := regexp.MustCompile(`-$`)
		if validPID.Match([]byte(value)) {
			return "ends in hyphen"
		}
		return ""
	}
	return fmt.Sprintf("undefined test '%s'", test)
}

func validateGACEnvVarName(value, test string) string {
	if test == "are the path to a readable file" {
		gacFile, err := os.Open(value)
		if err == nil {
			gacJSON := json.NewDecoder(gacFile)
			for complexity := 0; true; complexity++ {
				var i interface{}
				jerr := gacJSON.Decode(&i)
				if jerr == io.EOF && complexity > 0 {
					return ""
				} else if jerr == io.EOF {
					return fmt.Sprintf("expected non-empty json in %s", value)
				}
			}
		}
		return fmt.Sprintf("%s: %s", err, value)
	}
	return fmt.Sprintf("undefined test '%s'", test)
}
