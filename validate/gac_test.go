package main

import (
	"container/list"
	"context"
	"fmt"
	"io/ioutil"
	"net/http"
	"strings"

	"github.com/DATA-DOG/godog"
	"github.com/gruntwork-io/terratest/modules/logger"
	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
	compute "google.golang.org/api/compute/v1"
)

var gac struct {
	googleCreds          *google.Credentials
	googleComputeClient  *http.Client
	googleComputeService *compute.Service
	accessScopes         []string
	instNames            *list.List
	gacIsGood            bool
}

func init() {
	gac.accessScopes = []string{compute.ComputeReadonlyScope}
	envVars = map[string]string{
		gacEnvVarName: "",
		pidEnvVarName: "",
	}
	gac.gacIsGood = false
}

func theEnvironmentVariable(arg1 string) error {
	return knownEnvVar(arg1)
}

func theEnvVarContents(arg1, arg2 string) error {
	var err error
	arg1 = strings.TrimSpace(arg1)
	arg2 = strings.TrimSpace(arg2)
	if envVars[arg1], err = fullEnvVar(arg1); err != nil {
		return validateEnvVar(envVars[arg1], arg2)
	}
	return err
}

// Ref: https://godoc.org/golang.org/x/oauth2/google#DefaultClient
func iCallTheGoogleCredentialsFromJSONMethod() error {
	var err error
	var data []byte
	var creds *google.Credentials

	data, err = ioutil.ReadFile(envVars[gacEnvVarName])
	if err != nil {
		return err
	}
	logger.Logf(goDogGoT, "Loaded JSON credentials")
	creds, err = google.CredentialsFromJSON(context.Background(), data, gac.accessScopes...)
	if err != nil {
		return err
	}
	creds.ProjectID = envVars[pidEnvVarName]
	gac.googleCreds = creds
	return nil
}

func iCallTheOauthNewClient(arg1 int) error {
	gac.googleComputeClient = oauth2.NewClient(context.Background(), gac.googleCreds.TokenSource)
	return nil
}

func iCanCallTheComputeNewMethod() error {
	svc, err := compute.New(gac.googleComputeClient)
	if err != nil {
		return err
	}
	gac.googleComputeService = svc
	gac.googleComputeService.UserAgent = fmt.Sprintf("%s %s %s",
		"go",
		"github.com/icuc-me/cloud.git/validate",
		clientVersion)
	return nil
}

func iAmAbleToRetrieveAListOfInstancesFromAllZones() error {
	if err := theListOfInstancesIsNotEmpty(); err == nil {
		return nil
	}
	gac.instNames = list.New()
	if gac.googleCreds == nil {
		return fmt.Errorf("Google API Credientials are undefined")
	}
	if gac.googleCreds.ProjectID == "" {
		return fmt.Errorf("project ID is undefined")
	}
	call := gac.googleComputeService.Instances.AggregatedList(gac.googleCreds.ProjectID)
	logger.Logf(goDogGoT, "Obtained search handle")
	err := call.Pages(context.Background(), func(page *compute.InstanceAggregatedList) error {
		for scopeName, scopes := range page.Items {
			for _, instance := range scopes.Instances {
				gac.instNames.PushBack(instance.Name)
				logger.Logf(goDogGoT, "\tChecking %s", scopeName)
				logger.Logf(goDogGoT, "\t\tFound %s", instance.Name)
			}
		}
		gac.gacIsGood = true
		return nil
	})
	if err != nil {
		return err
	}
	return nil
}

func theListOfInstancesIsNotEmpty() error {
	if gac.instNames != nil {
		if gac.instNames.Len() < 1 {
			return fmt.Errorf("did not find any compute instances")
		}
		return nil
	}
	return fmt.Errorf("list of instance names unexpectedly empty")
}

func iKnowICanInteractWithTheGoogleAPIs() error {
	if gac.gacIsGood {
		return nil
	}
	return fmt.Errorf("no working oauth client or api service defined")
}

func GacFeatureContext(s *godog.Suite) {
	s.Step(`^the environment variable "([^"]*)"$`, theEnvironmentVariable)
	s.Step(`^the env\. var\. "([^"]*)" contents "([^"]*)"$`, theEnvVarContents)
	s.Step(`^I call the google\.CredentialsFromJSON method$`, iCallTheGoogleCredentialsFromJSONMethod)
	s.Step(`^I call the oauth(\d+)\.NewClient$`, iCallTheOauthNewClient)
	s.Step(`^I can call the compute\.New method$`, iCanCallTheComputeNewMethod)
	s.Step(`^I am able to retrieve a list of instances from all zones$`, iAmAbleToRetrieveAListOfInstancesFromAllZones)
	s.Step(`^the list of instances is not empty$`, theListOfInstancesIsNotEmpty)
	s.Step(`^I know I can interact with the google APIs$`, iKnowICanInteractWithTheGoogleAPIs)
}
