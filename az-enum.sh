# Start with a DNS domain as seed, and do some recon to check if domain is M365 / Azure tenant hosted
# Insert your domain environment variable below
DOMAIN="microsoft.com"

# Check the getuserrealm.srf endpoint for domain information

# Check autodiscover.$DOMAIN DNS entry
host autodiscover.$DOMAIN
# Note:  Checks autodiscover forward lookup ~ you should see a CNAME record for autodiscover.$DOMAIN pointing to autodiscover.otulook.com

# Test if domain is managed or not.  Check if it's a Azure/M365 tenant.  Returns 'Unknown', 'Federated', or 'Managed'
 curl -s https:///login.microsoftonline.com/getuserrealm.srf\?login\=$DOMAIN\&\json\=1
# Note:  Look for NameSpaceType

# Return NameSpaceType - either "Unknown", "Managed", or "Federated"
curl -s https:///login.microsoftonline.com/getuserrealm.srf\?login\=$DOMAIN\&\json\=1 | jq -r '.NameSpaceType'

# Check for federation on the domain
curl -s https:///login.microsoftonline.com/getuserrealm.srf\?login\=$DOMAIN\&\xml\=1
# Note:  Look at <NameSpaceType> and <IsFederated>

# Get the TenantID for a managed domain
curl -s https:///login.microsoftonline.com/$DOMAIN/v2.0/.well-known/openid-configuration
# Note:  Look for the token endpoint.  Example response:
# "token_endpoint":"https://login.microsoftonline.com/9d9817d9-f209-4430-8f4f-cc03332848cb/oauth2/v2.0/token
# '9d9817d9-f209-4430-8f4f-cc03332848cb' is the TenantId

# Check GetCredentialType endpoint for username enumeration
# Once on a managed domain, check individual users
# Credit and props to Brian Thomas for helping to validate this.  Thanks Brian!
# Verify that the getuserrealm.srf returns a "Managed" value for NameSpaceType
# If it does, the 0 or 1 below is correct.  IF it doesn't, unmanaged domains can return 0, leading to false positives
curl -s -X POST https:///login.microsoftonline.com/common/GetCredentialType --data '{"Username":"user1@example.com"}' | jq '.IfExistsResult'
# Note:  Checking the user:  user1@example.com
# Response Codes
# 1 - User Does Not Exist on Azure as Identity Provider
# 0 - Account exists for domain using Azure as Identity Provider
# 5 - Account exists but uses different IdP other than Microsoft
# 6 - Account exists and is setup to use the domain and an IdP other than Microsoft


# ADFS Recon Google Dorks
inurl://adfs/ls/idpinitiatedsignon

inurl://adfs/oauth2/authorize
