@First
Feature: Environment variable-baesd authN/authZ
    To validate a deployed test environment,
    as a robot, I need to authenticate and be authorized

    Background:
        Given the environment variable "GOOGLE_APPLICATION_CREDENTIALS"
        And the environment variable "GOOGLE_PROJECT_ID"
        And the env. var. "GOOGLE_APPLICATION_CREDENTIALS" contents "are the path to a readable file"
        And the env. var. "GOOGLE_PROJECT_ID" contents "conform to a naming standard"

    # Ref: https://godoc.org/golang.org/x/oauth2/google#DefaultClient
    Scenario:
        When I call the google.CredentialsFromJSON method
        And I call the oauth2.NewClient
        And I can call the compute.New method
        Then I am able to retrieve a list of instances from all zones
        And the list of instances is not empty
        And I know I can interact with the google APIs
