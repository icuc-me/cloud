package main

import (
	"container/list"
	"context"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"

	"github.com/DATA-DOG/godog"
	"golang.org/x/oauth2"
	"golang.org/x/oauth2/google"
	"google.golang.org/api/compute/v1"
)

const (
	clientVersion = "1.0"
	gacEnvVarName = "GOOGLE_APPLICATION_CREDENTIALS"
	pidEnvVarName = "GOOGLE_PROJECT_ID"
)

type gacT struct {
	gEnvVars             map[string]string
	googleCreds          *google.Credentials
	googleComputeClient  *http.Client
	googleComputeService *compute.Service
	accessScopes         []string
	instNames            *list.List
}

var gac gacT

func init() {
	gac.accessScopes = []string{compute.ComputeReadonlyScope}
	gac.gEnvVars = map[string]string{
		gacEnvVarName: "",
		pidEnvVarName: "",
	}
}

func theEnvironmentVariable(arg1 string) error {
	value, err := fullEnvVar(arg1)
	if err != nil {
		return err
	}
	gac.gEnvVars[arg1] = value
	return nil
}

func iExamineTheContents(arg1 string) error {
	value, present := gac.gEnvVars[arg1]
	if !present {
		return fmt.Errorf("unknown environment variable '%s': '%s'", arg1, value)
	}
	if len(value) < 1 {
		return fmt.Errorf("'%s' contains empty string", arg1)
	}
	return nil
}

func iFindTheContents(arg1, arg2 string) error {
	var eDetail string
	var matched bool
	value := "undefined value"

	switch arg1 {
	case pidEnvVarName:
		matched = true
		value = gac.gEnvVars[pidEnvVarName]
		eDetail = validatePIDEnvVar(value, arg2)
	case gacEnvVarName:
		matched = true
		value = gac.gEnvVars[gacEnvVarName]
		eDetail = validateGACEnvVarName(value, arg2)
	}
	if !matched {
		eDetail = "unknown value"
	}
	if eDetail != "" {
		return fmt.Errorf("%s: %s", eDetail, value)
	}
	return nil
}

// Ref: https://godoc.org/golang.org/x/oauth2/google#DefaultClient
func iCallTheGoogleCredentialsFromJSONMethod() error {
	data, err := ioutil.ReadFile(gac.gEnvVars[gacEnvVarName])
	if err != nil {
		return err
	}
	goDogGoT.Logf("Loaded JSON credentials")
	creds, err := google.CredentialsFromJSON(context.Background(), data, gac.accessScopes...)
	if err != nil {
		log.Fatal(err)
	}
	creds.ProjectID = gac.gEnvVars[pidEnvVarName]
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
	gac.instNames = list.New()
	call := gac.googleComputeService.Instances.AggregatedList(gac.googleCreds.ProjectID)
	goDogGoT.Logf("Obtained search handle")
	err := call.Pages(context.Background(), func(page *compute.InstanceAggregatedList) error {
		for scopeName, scopes := range page.Items {
			goDogGoT.Logf("\tChecking %s", scopeName)
			for _, instance := range scopes.Instances {
				gac.instNames.PushBack(instance.Name)
				goDogGoT.Logf("\t\tFound %s", instance.Name)
			}
		}
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

func FeatureContext(s *godog.Suite) {
	s.Step(`^the environment variable "([^"]*)"$`, theEnvironmentVariable)
	s.Step(`^I examine the "([^"]*)" contents$`, iExamineTheContents)
	s.Step(`^I find the "([^"]*)" contents "([^"]*)"$`, iFindTheContents)
	s.Step(`^I call the google\.CredentialsFromJSON method$`, iCallTheGoogleCredentialsFromJSONMethod)
	s.Step(`^I call the oauth(\d+)\.NewClient$`, iCallTheOauthNewClient)
	s.Step(`^I can call the compute\.New method$`, iCanCallTheComputeNewMethod)
	s.Step(`^I am able to retrieve a list of instances from all zones$`, iAmAbleToRetrieveAListOfInstancesFromAllZones)
	s.Step(`^the list of instances is not empty$`, theListOfInstancesIsNotEmpty)

}
