# B2BAllowDenyList-to-XTAP
Sample script to migrate Azure AD domains from the External Collaboration Settings (allow/deny list) to Cross Tenant Access Settings.

## Prerequisites
- [Microsoft.graph PowerShell SDK](https://docs.microsoft.com/en-us/graph/powershell/installation)

```
Install-Module Microsoft.Graph -Scope CurrentUser
```
- [AzureAD PowerShell Module](https://docs.microsoft.com/en-us/powershell/azure/active-directory/install-adv2?view=azureadps-2.0)

```
Install-Module AzureADPreview
```

## Backup Current Configuration
You should backup the existing policies before running this script.

Backup the Allow/Deny List:
```
$path = "TODO" #Enter the file path where you want the txt file exported
connect-azuread
$b2b = get-azureadpolicy | Where-Object {$_.type -eq "B2BManagementPolicy"}
$dmn = $b2b.Definition | convertfrom-json 
$domains = $dmn.b2bmanagementpolicy.InvitationsAllowedAndBlockedDomainsPolicy.AllowedDomains
$domains | out-file $path
```
Backup Cross Tenant Access Settings Partner Configurations:


## Steps
1. Determine if your current configuration is an allow list or a deny list. This can be found at Azure AD > External Identities > External Collaboration Settings. 
- If "Collaboration Restrictions" is set to "Deny invitations to the specified domains" run the Deny-List-Migration script.
- If "Collaboration Restrictions" is set to "Allow invitations only to the specified domains" run the Allow-List-Migration script.
2. Run the script in Windows PowerShell. When prompted, authenticate with a Global Admin.
3. Once the script is complete, verify the policies have been updated correctly.

## Restore Original Configuration

Restore Allow List:
```
$path = "TODO" #Enter the file path of your backup txt file
connect-azuread
$b2b = get-azureadpolicy | Where-Object {$_.type -eq "B2BManagementPolicy"}
[string[]]$BackUpAllowList = Get-Content -Path $path
$policyValue = @{
"B2BManagementPolicy" =  @{
    "InvitationsAllowedAndBlockedDomainsPolicy" = @{
        "AllowedDomains" = @($BackUpAllowList)}
    }
} | ConvertTo-Json -Depth 5
Set-AzureADPolicy -Definition $policyValue -Id $B2B.Id
```

Restore Deny List:
```
$path = "TODO" #Enter the file path of your backup txt file
connect-azuread
$b2b = get-azureadpolicy | Where-Object {$_.type -eq "B2BManagementPolicy"}
[string[]]$BackUpAllowList = Get-Content -Path $path
$policyValue = @{
"B2BManagementPolicy" =  @{
    "InvitationsAllowedAndBlockedDomainsPolicy" = @{
        "BlockedDomains" = @($BackUpAllowList)}
    }
} | ConvertTo-Json -Depth 5
Set-AzureADPolicy -Definition $policyValue -Id $B2B.Id
```

Restore Cross Tenant Access Settings Partner Configurations:
