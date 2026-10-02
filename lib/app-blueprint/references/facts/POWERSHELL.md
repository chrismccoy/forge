# POWERSHELL facts
Covers: PowerShell 7 and Windows PowerShell 5.1, scheduled tasks, ActiveDirectory, Microsoft.Graph, ExchangeOnlineManagement, ImportExcel
Verified: 2026-09-29 against official documentation. Re-verify facts older than 12 months.

## Modules and auth

### PS-01 AzureAD and MSOnline are dead ends
- Trap: New scripts use `Connect-MsolService`, `Get-MsolUser`, `Connect-AzureAD` or `Get-AzureADUser`.
- Reality: AzureAD, AzureADPreview and MSOnline were deprecated on 2024-03-30. MSOnline was retired on 2025-05-30. Microsoft points to Microsoft Graph PowerShell or Microsoft Entra PowerShell.
- Detect: `*-Msol*` or `*-AzureAD*` cmdlets.
- Fix: Use Microsoft.Graph cmdlets, migrating with Microsoft's cmdlet map.
- Source: Azure AD PowerShell migration FAQ - https://learn.microsoft.com/en-us/powershell/azure/active-directory/migration-faq

### PS-02 Unattended Exchange Online needs a certificate app, not a stored password
- Trap: A scheduled script uses `Connect-ExchangeOnline -Credential` with a saved password, or `New-PSSession` remote PowerShell.
- Reality: Unattended access is app-only certificate auth: an Entra app with the `Exchange.ManageAsApp` application permission (admin-consented) plus an Entra role or custom role group. `-Organization` must be the `.onmicrosoft.com` domain; `-CertificateThumbprint` is Windows-only and reads the user store; CNG certificates are unsupported. REST connections replaced remote PowerShell in 2023, and `Invoke-Command` does not work over them.
- Detect: stored EXO credentials, `New-PSSession` to Exchange, a thumbprint on Linux, no role for the app.
- Fix: Grant `Exchange.ManageAsApp` and a least-privilege role; install a CSP-key certificate for the running account (or pass `-Certificate`).
- Source: App-only authentication in Exchange Online PowerShell - https://learn.microsoft.com/en-us/powershell/exchange/app-only-auth-powershell-v2

### PS-03 Graph and AD cmdlets return partial data
- Trap: `Connect-MgGraph -Scopes User.Read.All` in a scheduled job, then `Get-MgUser` returns every user with every field.
- Reality: `-Scopes` requests delegated permissions only. App-only (`-ClientId -TenantId -CertificateThumbprint`) uses admin-consented application permissions and reads the current user's certificate store. `Get-MgUser` returns only a default subset of properties (`-Property` selects more) and one page unless `-All` is used. `Invoke-RestMethod -FollowRelLink` follows RFC 5988 `Link` headers, not `@odata.nextLink`. `Get-ADUser` likewise returns a default property set unless `-Properties` names more.
- Detect: `-Scopes` in unattended scripts; non-default attributes read without `-Property`/`-Properties`; no `-All`.
- Fix: Use certificate app-only auth, `-All`, and explicit property lists. Install only the needed Graph submodules.
- Source: Connect-MgGraph - https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.authentication/connect-mggraph ; Get-MgUser - https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.users/get-mguser ; Get-ADUser - https://learn.microsoft.com/en-us/powershell/module/activedirectory/get-aduser

### PS-04 5.1 and 7 are separate installs with different module behavior
- Trap: "PowerShell 7" and "the 5.1 management server" are used interchangeably, or every 5.1 module is assumed to work in 7.
- Reality: `powershell.exe` (5.1) and `pwsh.exe` (7) coexist with separate PSModulePath and profiles. ActiveDirectory and ScheduledTasks load natively in 7 on Windows; GroupPolicy is untested and loads via the compatibility layer, a hidden 5.1 session returning deserialized objects. ExchangeOnlineManagement 3.10+ needs PowerShell 7.6+. PowerShell 7.4 LTS support ends 2026-11-10; 7.6 is the current LTS.
- Detect: "PowerShell" with no version, modules installed for only one host, methods called on GroupPolicy objects in 7, 7.4 as a target.
- Fix: Pin one host (`#Requires -Version`) and install modules for it; target 7.6 LTS for new work.
- Source: about_Windows_PowerShell_Compatibility - https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_windows_powershell_compatibility ; Module compatibility - https://learn.microsoft.com/en-us/powershell/windows/module-compatibility ; Support lifecycle - https://learn.microsoft.com/en-us/powershell/scripting/install/powershell-support-lifecycle

## Error handling

### PS-05 try/catch misses non-terminating errors and exit codes
- Trap: Wrapping cmdlets or `robocopy` in `try { } catch { }` detects every failure.
- Reality: Non-terminating errors (e.g. `Get-ChildItem` on a missing path) do not trigger `catch` unless `-ErrorAction Stop` or `$ErrorActionPreference = 'Stop'`. Native commands only set `$LASTEXITCODE`; in 7.4+ `$PSNativeCommandUseErrorActionPreference = $true` turns non-zero exits into errors (default `$false`).
- Detect: try/catch without `-ErrorAction Stop`; no `$LASTEXITCODE` checks.
- Fix: Set `$ErrorActionPreference = 'Stop'` at the top and check `$LASTEXITCODE` (robocopy uses non-zero codes for success; treat 8+ as failure).
- Source: about_Error_Handling - https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_error_handling ; about_Preference_Variables - https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables

## Scheduled tasks

### PS-06 A scheduled task's account decides what the script can reach
- Trap: A task running without a stored password can still write to `\\server\share` and use the admin's certificates.
- Reality: S4U logon stores no password and has no access to the network or encrypted files. Password and S4U tasks need the "Log on as a batch job" right. Thumbprint-based auth (PS-02, PS-03) reads that account's own certificate store. Tasks stop after 72 hours by default.
- Detect: network output paths with S4U, a certificate installed only for the admin, jobs that may run longer than 3 days.
- Fix: Run as a gMSA (supported by Task Scheduler) or a service account with batch rights, install the certificate for that account, and set `ExecutionTimeLimit` deliberately.
- Source: TASK_LOGON_TYPE - https://learn.microsoft.com/en-us/windows/win32/api/taskschd/ne-taskschd-task_logon_type ; ExecutionTimeLimit - https://learn.microsoft.com/en-us/windows/win32/taskschd/tasksettings-executiontimelimit

### PS-07 Execution policy is not a security control
- Trap: "Set the policy to AllSigned/RemoteSigned so nobody can run unapproved scripts."
- Reality: Execution policy is not a security boundary: it is easily bypassed (for example by pasting script contents). On non-Windows it is always Unrestricted and cannot be changed.
- Detect: execution policy listed as an access or tamper control.
- Fix: Protect scripts with file ACLs, signing in the release pipeline and least-privilege accounts.
- Source: about_Execution_Policies - https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies

## Data and output

### PS-08 File encodings differ between 5.1 and 7
- Trap: The same `Export-Csv`/`Out-File` code produces the same file under 5.1 and 7.
- Reality: 7 writes `utf8NoBOM` by default. In 5.1, `Out-File` and `>` write UTF-16LE, `Set-Content` writes ANSI, `Export-Csv` writes ASCII (non-ASCII names are lost) and adds a `#TYPE` line unless `-NoTypeInformation`. 5.1 reads BOM-less UTF-8 scripts as ANSI.
- Detect: file output with no `-Encoding`, especially names with accents.
- Fix: Always pass `-Encoding utf8` (plus `-NoTypeInformation` on 5.1), and save 5.1 scripts with non-ASCII text as UTF-8 with BOM.
- Source: about_Character_Encoding - https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_character_encoding ; Export-Csv - https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/export-csv

### PS-09 `ConvertTo-Json` truncates at depth 2
- Trap: `$report | ConvertTo-Json | Set-Content state.json` saves the whole object.
- Reality: The default `-Depth` is 2; deeper levels become type-name strings. 7.1+ warns; 5.1 truncates silently.
- Detect: nested objects serialized with no `-Depth`.
- Fix: Pass an explicit `-Depth` (up to 100) and round-trip test the output.
- Source: ConvertTo-Json - https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/convertto-json

### PS-10 Excel and mail need neither Excel nor Send-MailMessage
- Trap: The report server needs Office for `.xlsx`, and mail goes out with `Send-MailMessage`.
- Reality: ImportExcel creates workbooks without Excel, on Windows, Linux and macOS. `Send-MailMessage` is obsolete and does not guarantee secure SMTP; Microsoft suggests `Send-MgUserMail` for Exchange Online.
- Detect: `-ComObject Excel.Application` on servers, `Send-MailMessage`.
- Fix: Use `Export-Excel`, and send mail with `Send-MgUserMail` or a maintained library.
- Source: ImportExcel README - https://github.com/dfinke/ImportExcel ; Send-MailMessage - https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/send-mailmessage
