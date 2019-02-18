@First
Feature: Environment variable-baesd authN/authZ
    To validate a deployed environment,
    as a robot, I need to authenticate and be authorized

    Scenario:
        Given the environment variable "GOOGLE_APPLICATION_CREDENTIALS"
        When I examine the "GOOGLE_APPLICATION_CREDENTIALS" contents
        Then I find the "GOOGLE_APPLICATION_CREDENTIALS" contents "are the path to a readable file"

    # Ref: https://cloud.google.com/resource-manager/reference/rest/v1/projects
    Scenario:
        Given the environment variable "GOOGLE_PROJECT_ID"
        When I examine the "GOOGLE_PROJECT_ID" contents
        Then I find the "GOOGLE_PROJECT_ID" contents "are 6 to 30 lowercase letters, digits, or hyphens"
        And I find the "GOOGLE_PROJECT_ID" contents "begin with a letter"
        And I find the "GOOGLE_PROJECT_ID" contents "do not end with a hyphen"

    # Ref: https://godoc.org/golang.org/x/oauth2/google#DefaultClient
    Scenario:
        Given the environment variable "GOOGLE_APPLICATION_CREDENTIALS"
        And the environment variable "GOOGLE_PROJECT_ID"
        And I find the "GOOGLE_APPLICATION_CREDENTIALS" contents "are the path to a readable file"
        And I find the "GOOGLE_PROJECT_ID" contents "are 6 to 30 lowercase letters, digits, or hyphens"
        And I find the "GOOGLE_PROJECT_ID" contents "begin with a letter"
        And I find the "GOOGLE_PROJECT_ID" contents "do not end with a hyphen"
        When I call the google.CredentialsFromJSON method
        And I call the oauth2.NewClient
        And I can call the compute.New method
        Then I am able to retrieve a list of instances from all zones
        And the list of instances is not empty
