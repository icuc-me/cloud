package main

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"regexp"
	"strings"
)

const (
	clientVersion  = "1.0"
	gacEnvVarName  = "GOOGLE_APPLICATION_CREDENTIALS"
	pidEnvVarName  = "GOOGLE_PROJECT_ID"
	envNameVarName = "ENV_NAME"
	tfCfgDir       = "TF_CFG_DIR"
	phaseFname     = "n_phases"
)

var envVars map[string]string
var requiredOutputKeys = [...]string{
	"gateway_external_ip",
	"gateway_private_ip",
	"private_network",
	"public_network",
	"strongbox_uris",
	"uuid",
}

func knownEnvVar(name string) error {
	if name == gacEnvVarName || name == pidEnvVarName || name == tfCfgDir || name == envNameVarName {
		return nil
	}
	return fmt.Errorf("unknown environment variable '%s'", name)
}

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

func validateEnvVar(value, test string) error {
	switch test {
	case "are 6 to 30 lowercase letters, digits, or hyphens":
		if len(value) < 6 || len(value) > 30 {
			return fmt.Errorf("shorter than 6 or longer than 30")
		}
		if strings.ToLower(value) != value {
			return fmt.Errorf("not lowercase")
		}
		validPID := regexp.MustCompile(`^[a-z0-9\-]+$`)
		if !validPID.Match([]byte(value)) {
			return fmt.Errorf("not lowercase letters, digits or hyphens")
		}
		return nil
	case "begin with a letter":
		validPID := regexp.MustCompile(`^[a-z]`)
		if !validPID.Match([]byte(value)) {
			return fmt.Errorf("not lowercase letter")
		}
		return nil
	case "do not end with a hyphen":
		validPID := regexp.MustCompile(`-$`)
		if validPID.Match([]byte(value)) {
			return fmt.Errorf("ends in hyphen")
		}
		return nil
	case "are the path to a readable file":
		gacFile, err := os.Open(value)
		if err != nil {
			return fmt.Errorf("%s: %s", err, value)
		}
		gacJSON := json.NewDecoder(gacFile)
		for nDecodes := 0; true; nDecodes++ {
			var i interface{}
			jerr := gacJSON.Decode(&i)
			if jerr == io.EOF && nDecodes > 0 {
				return nil
			} else if jerr == io.EOF {
				return fmt.Errorf("expected non-empty json in %s", value)
			}
		}
		return fmt.Errorf("%s: %s", err, value)
	case "referrs to a directory":
		if info, err := os.Stat(value); os.IsNotExist(err) {
			return err
		} else if info.IsDir() {
			return nil
		}
		return fmt.Errorf("not a directory: %s", value)
	case "names a valid environment":
		switch value {
		case "test",
			"stage",
			"prod":
			return nil
		}
		return fmt.Errorf("not 'test', 'stage', or 'prod'")
	}
	return fmt.Errorf("undefined test '%s'", test)
}
