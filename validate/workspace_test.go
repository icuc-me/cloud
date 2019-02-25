package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/DATA-DOG/godog"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/imdario/mergo"
)

var workspaceInfo struct {
	cfgDirNames      []string
	cfgNphasePath    string
	cfgNphaseContent string
	cfgNphase        int
	wsRfrshExt       []int
	tfOpts           terraform.Options
	tfOutputs        map[string]interface{}
}

func init() {
	workspaceInfo.cfgNphase = -1
	workspaceInfo.cfgNphasePath = ""
	workspaceInfo.tfOpts = terraform.Options{
		TerraformDir: "",
		NoColor:      true,
	}
}

func iListTheContentsOfTheDirectory() error {
	var cfgDir *os.File
	var err error
	var cfgDirNames []string
	cfgDir, err = os.Open(envVars[tfCfgDir])
	if err == nil {
		if cfgDirNames, err = cfgDir.Readdirnames(-1); err == nil {
			logger.Logf(goDogGoT, "terraform dir containts %d entries", len(cfgDirNames))
			workspaceInfo.cfgDirNames = cfgDirNames
			return nil
		}
	}
	return err
}

func iFindAFileNamedN_phases() error {
	for _, name := range workspaceInfo.cfgDirNames {
		if name == phaseFname {
			workspaceInfo.cfgNphasePath = filepath.Join(envVars[tfCfgDir], name)
			logger.Logf(goDogGoT, "\tfound %s", workspaceInfo.cfgNphasePath)
			return nil
		}
	}
	return fmt.Errorf("file %s not found in directory %s", phaseFname, envVars[tfCfgDir])
}

func iLoadAndParseTheFileN_phases() error {
	var err error
	var np *os.File
	var contents []byte

	if workspaceInfo.cfgNphasePath == "" {
		workspaceInfo.cfgNphasePath = filepath.Join(envVars[tfCfgDir], phaseFname)
	}

	if np, err = os.Open(workspaceInfo.cfgNphasePath); err == nil {
		if contents, err = ioutil.ReadAll(np); err == nil {
			workspaceInfo.cfgNphaseContent = strings.TrimSpace(string(contents))
			logger.Logf(goDogGoT, "\t\tread %s", workspaceInfo.cfgNphaseContent)
		}
	}
	return err
}

func iFindN_phasesContainsANumberGreaterThanAndSmallerThan(arg1, arg2 int) error {
	var err error
	var cfgNphase int

	if workspaceInfo.cfgNphaseContent == "" {
		_ = iLoadAndParseTheFileN_phases()
	}

	if cfgNphase, err = strconv.Atoi(workspaceInfo.cfgNphaseContent); err != nil {
		return err
	}

	workspaceInfo.cfgNphase = cfgNphase
	if workspaceInfo.cfgNphase > arg1 && workspaceInfo.cfgNphase < arg1 {
		return fmt.Errorf("number of phases (%d) not between %d - %d",
			workspaceInfo.cfgNphase, arg1, arg2)
	}
	return nil
}

func theContentsOfN_phasesAreValid() error {
	return iFindN_phasesContainsANumberGreaterThanAndSmallerThan(1, 99)
}

func iKnowHowManyPhasesAndWorkspacesToExpect() error {
	logger.Logf(goDogGoT, "working with %d phases", workspaceInfo.cfgNphase)
	workspaceInfo.tfOpts.TerraformDir = envVars[tfCfgDir]
	return nil
}

func iSwitchToEachWorkspaceAndRefresh() error {
	var err error
	var exit int
	var outMap map[string]interface{}

	err = os.Chdir(workspaceInfo.tfOpts.TerraformDir)
	workspaceInfo.wsRfrshExt = make([]int, workspaceInfo.cfgNphase)
	for phaseN := 1; phaseN <= workspaceInfo.cfgNphase; phaseN++ {
		phaseS := fmt.Sprintf("phase_%d", phaseN)
		phaseP := fmt.Sprintf("./.%s", phaseS)

		exit, err = terraform.GetExitCodeForTerraformCommandE(goDogGoT, &workspaceInfo.tfOpts,
			"workspace", "select", phaseS, phaseP)
		if err != nil {
			err = fmt.Errorf("%s: exit %d", err, exit)
			break
		}
		workspaceInfo.wsRfrshExt[phaseN-1] = exit

		outMap, err = terraform.OutputAllE(goDogGoT, &workspaceInfo.tfOpts)
		if err != nil {
			break
		}

		err = mergo.Merge(&workspaceInfo.tfOutputs, outMap, mergo.WithOverride)
		if err != nil {
			break
		}
	}
	return err
}

func iFindAZeroExitCodeForEachRefresh() error {
	for phaseN := 1; phaseN < workspaceInfo.cfgNphase; phaseN++ {
		if workspaceInfo.wsRfrshExt[phaseN-1] != 0 {
			return fmt.Errorf("Refresh of workspace/phase %d failed with code %d",
				phaseN, workspaceInfo.wsRfrshExt[phaseN-1])
		}
	}
	return nil
}

func theDeploymentOutputsAreAllAvailable() error {
	logger.Logf(goDogGoT, "Terraform Outputs:\n")
	prettyJSON, _ := json.MarshalIndent(workspaceInfo.tfOutputs, "", "  ")
	for _, s := range strings.Split(string(prettyJSON), `\n`) {
		logger.Logf(goDogGoT, "%s\n", s)
	}
	for _, key := range requiredOutputKeys {
		if value, present := workspaceInfo.tfOutputs[key]; present {
			logger.Logf(goDogGoT, "Found required key '%s': '%v'", key, value)
			continue
		} else {
			return fmt.Errorf("Missing required output key %s", key)
		}
	}
	return nil
}

func WorkspaceFeatureContext(s *godog.Suite) {
	s.Step(`^I list the contents of the directory$`, iListTheContentsOfTheDirectory)
	s.Step(`^I find a file named n_phases$`, iFindAFileNamedN_phases)
	s.Step(`^I load and parse the file n_phases$`, iLoadAndParseTheFileN_phases)
	s.Step(`^I find n_phases contains a number greater than (\d+) and smaller than (\d+)$`,
		iFindN_phasesContainsANumberGreaterThanAndSmallerThan)
	s.Step(`^the contents of n_phases are valid$`, theContentsOfN_phasesAreValid)
	s.Step(`^I know how many phases and workspaces to expect$`, iKnowHowManyPhasesAndWorkspacesToExpect)
	s.Step(`^I switch to each workspace and refresh$`, iSwitchToEachWorkspaceAndRefresh)
	s.Step(`^I find a zero exit code for each refresh$`, iFindAZeroExitCodeForEachRefresh)
	s.Step(`^the deployment outputs are all available$`, theDeploymentOutputsAreAllAvailable)
}
