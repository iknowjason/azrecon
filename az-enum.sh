#!/bin/bash

# Function to print in color
print_color() {
    local color=$1
    shift
    printf "\e[${color}m$@\e[0m\n"
}

# Input: Enter the domain to perform reconnaissance on
echo -e "\033[1;32mEnter the domain to perform reconnaissance on:\033[0m"
read DOMAIN

# Input: Enter a username for credential type check
echo -e "\033[1;32mEnter a username for credential type check:\033[0m"
read USERNAME

# Check the getuserrealm.srf endpoint for domain information
print_color "1;34" "\nChecking getuserrealm.srf endpoint for domain information..."
curl_result=$(curl -s "https://login.microsoftonline.com/getuserrealm.srf?login=$DOMAIN&json=1" | jq .)
echo "User Realm Information:"
echo "$curl_result"

# Check autodiscover.$DOMAIN DNS entry
print_color "1;34" "\nChecking autodiscover.$DOMAIN DNS entry..."
autodiscover_result=$(host "autodiscover.$DOMAIN")
echo "Autodiscover DNS Entry:"
echo "$autodiscover_result"

# Test if the domain is managed or not. Check if it's an Azure/M365 tenant. Returns 'Unknown', 'Federated', or 'Managed'
print_color "1;34" "\nTesting if the domain is managed or not..."
managed_result=$(curl -s "https://login.microsoftonline.com/getuserrealm.srf?login=$DOMAIN&json=1" | jq .)
echo "Managed Status:"
echo "$managed_result"

# Return NameSpaceType - either "Unknown", "Managed", or "Federated"
print_color "1;34" "\nGetting NameSpaceType for the domain..."
namespace_type=$(curl -s "https://login.microsoftonline.com/getuserrealm.srf?login=$DOMAIN&json=1" | jq -r '.NameSpaceType')
echo "NameSpaceType: $namespace_type"

# Check for federation on the domain
print_color "1;34" "\nChecking for federation on the domain..."
federation_output=$(curl -s "https://login.microsoftonline.com/getuserrealm.srf?login=$DOMAIN&xml=1")
namespace_type=$(echo "$federation_output" | xmllint --xpath '//NameSpaceType/text()' - 2>/dev/null)
is_federated_ns=$(echo "$federation_output" | xmllint --xpath '//IsFederatedNS/text()' - 2>/dev/null)
echo "NameSpaceType: $namespace_type"
echo "IsFederatedNS: $is_federated_ns"
# Note: Look at NameSpaceType and IsFederated

# Get the TenantID for a managed domain
print_color "1;34" "\nGetting the TenantID for a managed domain..."
tenant_id=$(curl -s "https://login.microsoftonline.com/$DOMAIN/v2.0/.well-known/openid-configuration" | jq -r '.token_endpoint' | cut -d'/' -f4)
echo "TenantID: $tenant_id"
# Note: Look for the token endpoint.

# Check GetCredentialType endpoint for username enumeration
print_color "1;34" "\nChecking GetCredentialType endpoint for username enumeration..."
credential_result=$(curl -s -X POST "https://login.microsoftonline.com/common/GetCredentialType" --data "{\"Username\":\"$USERNAME@$DOMAIN\"}" | jq '.IfExistsResult')
echo "Credential Type Result for $USERNAME@$DOMAIN:"
echo "$credential_result"
# Note: Checking the user: $USERNAME@$DOMAIN
# Response Codes
# 1 - User Does Not Exist on Azure as Identity Provider
# 0 - Account exists for the domain using Azure as Identity Provider
# 5 - Account exists but uses a different IdP other than Microsoft
# 6 - Account exists and is set up to use the domain and an IdP other than Microsoft

# Check SPF record for domain
print_color "1;34" "\nChecking SPF record for the domain..."
spf_record=$(nslookup -type=txt $DOMAIN)
echo "SPF Record:"
echo "$spf_record"

# Run an Nmap scan with -Pn option
TARGET=$DOMAIN
if [ -n "$TARGET" ]; then
    print_color "1;34" "\nRunning Nmap scan with -Pn option on $TARGET..."
    nmap_result=$(nmap -Pn $TARGET)
    echo "Nmap Scan Result:"
    echo "$nmap_result"
else
    print_color "1;31" "Error: No target specified."
fi

# ADFS Recon Google Dorks
echo -e "\033[1;34m\nADFS Recon Google Dorks:\033[0m"
echo "inurl://adfs/ls/idpinitiatedsignon"
echo "inurl://adfs/oauth2/authorize"
echo "intitle:ADFS Discovery document"
echo "intitle:ADFS Home Realm Discovery"
echo "inurl:/adfs/services/trust/mex"
echo "inurl:/adfs/services/trust/x509"
echo "intitle:ADFS WS-Federation"
echo "inurl:/adfs/services/policystore/wsdl"
echo "inurl:/adfs/services/trust/2005/windowstransport"
echo "intitle:ADFS SAML"


# Check for SMB (NetBIOS) information
print_color "1;34" "\nChecking for NetBIOS information..."
enum4linux_result=$(enum4linux $DOMAIN)
echo "NetBIOS Information:"
echo "$enum4linux_result"

# Enumerate Active Directory users using LDAP
print_color "1;34" "\nEnumerating Active Directory users using LDAP..."
ldap_users=$(ldapsearch -LLL -x -H ldap://$DOMAIN -b "dc=$DOMAIN" "(objectClass=user)" sAMAccountName | grep "sAMAccountName:" | cut -d" " -f2)
echo "LDAP Users:"
echo "$ldap_users"

# Enumerate Active Directory groups using LDAP
print_color "1;34" "\nEnumerating Active Directory groups using LDAP..."
ldap_groups=$(ldapsearch -LLL -x -H ldap://$DOMAIN -b "dc=$DOMAIN" "(objectClass=group)" sAMAccountName | grep "sAMAccountName:" | cut -d" " -f2)
echo "LDAP Groups:"
echo "$ldap_groups"

# Enumerate Active Directory computers using LDAP
print_color "1;34" "\nEnumerating Active Directory computers using LDAP..."
ldap_computers=$(ldapsearch -LLL -x -H ldap://$DOMAIN -b "dc=$DOMAIN" "(objectClass=computer)" sAMAccountName | grep "sAMAccountName:" | cut -d" " -f2)
echo "LDAP Computers:"
echo "$ldap_computers"
