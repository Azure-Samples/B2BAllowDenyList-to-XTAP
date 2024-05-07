connect-azuread
$b2b = get-azureadpolicy | Where-Object {$_.type -eq "B2BManagementPolicy"}
$dmn = $b2b.Definition | convertfrom-json 
$domains = $dmn.b2bmanagementpolicy.InvitationsAllowedAndBlockedDomainsPolicy.AllowedDomains
$B2BArray = @()

Connect-Graph -scopes "policy.read.all", "CrossTenantInformation.ReadBasic.All", "Policy.ReadWrite.CrossTenantAccess"
#Get Tenant ID's from domains
foreach($domain in $domains){
Write-Output "-----------------------"
$dmn = ""
try {
$dmn = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/tenantRelationships/findTenantInformationByDomainName(domainName='$domain')"
$tenantid = $dmn.tenantId
}
catch
{
Write-Output "$domain doesn't exist in Azure AD"
}

#If domain resolves to tenant ID, add Organization as organization in XTAP.
If($dmn -ne ""){

#Prevent adding Consumer Microsoft Tenants. Instead, add domain to B2B Array (gmail.com, outlook.com, etc.).
If(($tenantid -eq "f8cdef31-a31e-4b4a-93e4-5f571e91255a") -or ($tenantid -eq "9cd80435-793b-4f48-844b-6b3f37d1c1f3")){
Write-Output "$domain resolved to Azure AD tenant, but it is a consumer domain. $domain will not be added to XTAP."
$B2BArray = $B2BArray + $domain
}

#Add Azure AD domain as tenant in XTAP
Else{
$body = @{
  "tenantId" = "$tenantId"
  "b2bCollaborationInbound" = @{
                "usersAndGroups" = @{
                    "accessType" = "allowed"
                    "targets" = @(
                        @{
                            "target" = "AllUsers"
                            "targetType" = "user"
                        }
                    )
                }
}
} | ConvertTo-Json -Depth 6
Write-Output "Adding $domain to XTAP"

Try{
Invoke-MgGraphRequest -Method POST -Uri https://graph.microsoft.com/beta/policies/crossTenantAccessPolicy/partners -Body $body
}
Catch{
Write-Output "Unable to add $domain to XTAP. Verify if $domain already is present in XTAP." 
}
}
}

#If domain doesn't resolve to tenant ID, add to array.
Else{
$B2BArray = $B2BArray + $domain
}
}

#Update B2B policy with new, reduced list of domains.
$policyValue = @{
"B2BManagementPolicy" =  @{
    "InvitationsAllowedAndBlockedDomainsPolicy" = @{
        "AllowedDomains" = @($B2BArray)}
    }
} | ConvertTo-Json -Depth 5
Write-Output "-----------------------"
Write-Output "The following domains could not be migrated to XTAP and will remain on the Allow List:"
$B2BArray
Set-AzureADPolicy -Definition $policyValue -Id $B2B.Id
