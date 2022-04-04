connect-azuread
$b2b = get-azureadpolicy | Where-Object {$_.type -eq "B2BManagementPolicy"}
$dmn = $b2b.Definition | convertfrom-json 
$domains = $dmn.b2bmanagementpolicy.InvitationsAllowedAndBlockedDomainsPolicy.AllowedDomains
$B2BArray = @()

Connect-Graph -scopes policy.read.all
#Get Tenant ID's from domains
foreach($domain in $domains){
$dmn = ""
$dmn = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/beta/tenantRelationships/findTenantInformationByDomainName(domainName='$domain')"
$tenantid = $dmn.tenantId

#If domain resolves to tenant ID, add Organization as organization in XTAP.
If($dmn -ne ""){

#Prevent adding Consumer Microsoft Tenants. Instead, add domain to B2B Array (gmail.com, outlook.com, etc.).
If(($tenantid -eq "f8cdef31-a31e-4b4a-93e4-5f571e91255a") -or ($tenantid -eq "9cd80435-793b-4f48-844b-6b3f37d1c1f3")){
$B2BArray = $B2BArray + $domain
}

#Add Azure AD domain as tenant in XTAP
Else{
$body = @{
  "tenantId" = "$tenantId"
  "b2bCollaborationInbound" = @{
                "usersAndGroups" = @{
                    "accessType" = "blocked"
                    "targets" = @(
                        @{
                            "target" = "AllUsers"
                            "targetType" = "user"
                        }
                    )
                }
}
} | ConvertTo-Json -Depth 6
Invoke-MgGraphRequest -Method POST -Uri https://graph.microsoft.com/beta/policies/crossTenantAccessPolicy/partners -Body $body
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
        "BlockedDomains" = @($B2BArray)}
    }
} | ConvertTo-Json -Depth 5
Set-AzureADPolicy -Definition $policyValue -Id $B2B.Id
