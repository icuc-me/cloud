Feature: Multiple terraform environment phases and workspaces each have specific outputs
    To validate a deployed environment, as a robot, I need to know specific output values
    from deployed phases and workspaces

    Background:
        Given the environment variable "TF_CFG_DIR"
        And the environment variable "ENV_NAME"
        And the env. var. "TF_CFG_DIR" contents "referrs to a directory"
        And the env. var. "ENV_NAME" contents "names a valid environment"

    Scenario:
        Given I list the contents of the directory
        And I find a file named n_phases
        When I load and parse the file n_phases
        Then I find n_phases contains a number greater than 1 and smaller than 99
        And the contents of n_phases are valid

    Scenario:
        Given the contents of n_phases are valid
        And I know how many phases and workspaces to expect
        And I know I can interact with the google APIs
        When I switch to each workspace and refresh
        Then I find a zero exit code for each refresh
        And the deployment outputs are all available
