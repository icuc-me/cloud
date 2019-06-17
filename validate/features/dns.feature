Feature: A tree of DNS zones and records should match a specific general structure
    To validate a deployed environment, as a robot, I can confirm DNS records
    and structure match my expectations.

    Background:
        Given I find a zero exit code for each refresh
          And the deployment outputs are all available
          And the env. var. "ENV_NAME" contents "names a valid environment"
          And the following <required> output keys exist
              | required       | expected_type |
              | domain_fqdn    | string        |
              | legacy_fqdns   | list          |
              | services_fqdns | map           |
              | shortsub_fqdns | map           |

    Scenario:
         When I retrieve the <required> output key's value
         Then I can cache the <required> value as <expected_type>

    Scenario:
        Given I can cache the <required> value as <expected_type>
         When I perform a DNS lookup of "domain_fqdn" for a "NS record"
          And I perform a DNS lookup of "domain_fqdn" for a "MX record"
         Then I find the "domain_fqdn" "NS record" query was successful within "300" seconds
          And I find the "domain_fqdn" "MX record" query was successful within "30" seconds

    Scenario:
        Given I find the "domain_fqdn" "MX record" query was successful within "30" seconds
         When I perform a DNS lookup of "TSP subdomains" for a "A records"
         Then I find the "TSP subdomains" "A records" query was successful within "30" seconds

    Scenario:
        Given I find the "domain_fqdn" "NS query" was successful within "300" seconds
          And I retrieve the list of keys from the "services_fqdns" output
         When I combine the "services_fqdns" keys with the "domain_fqdn" value
          And I perform a DNS lookup of "services plus domain" for a "CNAME records"
         Then I find the "services plus domain" "CNAME queries" was successful within "30" seconds

    Scenario:
        Given I find the "services plus domain" "CNAME queries" was successful within "30" seconds
         When I perform a DNS lookup of "service CNAMES" for a "A records"
         Then I find the "service CNAMES" "A queries" was successful within "30" seconds
