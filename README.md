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

## Steps
Determine if your current configuration is an allow list or a deny list. Choose the appropriate script.
