# SQL Server Job Monitor & Reporter 📊

![PowerShell](https://img.shields.io/badge/PowerShell-%235391FE.svg?style=for-the-badge&logo=powershell&logoColor=white)
![SQL Server](https://img.shields.io/badge/Microsoft%20SQL%20Server-CC2927?style=for-the-badge&logo=microsoft%20sql%20server&logoColor=white)

A PowerShell script that monitors SQL Server Agent jobs (filtered for backup jobs) and sends HTML-formatted email reports with execution status.

## 🌟 Features

- **Automated Monitoring**: Checks status of all jobs matching `'Bk Up DB%'` pattern
- **Professional Reporting**: Generates HTML-formatted tables with color-coded status
- **Email Alerts**: Sends results via Gmail SMTP
- **CSV Export**: Locally saves job history for audit purposes
- **Easy Configuration**: Simple variable setup at script header

## 🛠 Prerequisites

1. **PowerShell 5.1+**
2. **SQL Server Management Objects (SMO)**
   ```powershell
   Install-Module -Name SqlServer -Force -AllowClobber
   ```
3. **Gmail Account** (for SMTP) with:
   - [Less Secure Apps enabled](https://myaccount.google.com/lesssecureapps) **OR**
   - [App Password](https://support.google.com/accounts/answer/185833) if using 2FA

## ⚙️ Configuration

Edit these variables in the script:

```powershell
# SQL Server Connection
$serverInstance = "localhost"  # Replace with your SQL instance
$databaseName = "msdb"

# Output Configuration
$outputFilePath = "C:\DB Job\JobStatus.csv"

# Email Configuration
$recipients = @("test@gmail.com")  # Add all recipients
$smtpSenderMailAdd = "dba@gmail.com"
$smtpPassword = "your_app_password"  # Gmail app password
$smtpIp = "smtp.gmail.com"
$smtpPortNo = 587
```

## 🚀 Usage

1. **Save the script** as `SQLJobMonitor.ps1`
2. **Run manually**:
   ```powershell
   .\SQLJobMonitor.ps1
   ```
3. **Schedule with Task Scheduler** (recommended):
   ```powershell
   # Create daily scheduled task
   $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"C:\path\to\SQLJobMonitor.ps1`""
   $trigger = New-ScheduledTaskTrigger -Daily -At 9am
   Register-ScheduledTask -TaskName "SQL Job Monitor" -Action $action -Trigger $trigger -RunLevel Highest
   ```

## ✉️ Email Report Preview

![image](https://github.com/user-attachments/assets/f4c1e552-747e-4ed7-a39c-1cc416fd439e)

*(Example of the HTML table report sent via email)*

## 🔍 Customizing Job Filters

Modify the SQL query to monitor different jobs:

```sql
-- Current filter (backup jobs):
WHERE j.name LIKE 'Bk Up DB%'

-- Alternative examples:
WHERE j.name LIKE '%Maintenance%'  -- Maintenance jobs
WHERE j.enabled = 1                -- All enabled jobs
```

## 🔒 Security Notes

1. **Credential Security**:
   - Consider using [Windows Credential Manager](https://github.com/davotronic5000/PowerShell_Credential_Manager) for SMTP passwords
   - Or encrypt credentials with:
     ```powershell
     Read-Host "Enter password" -AsSecureString | ConvertFrom-SecureString | Out-File "mailpass.txt"
     ```

2. **SQL Permissions**:
   - The script requires `SELECT` access to:
     - `msdb.dbo.sysjobs`
     - `msdb.dbo.sysjobhistory`

## 🐛 Troubleshooting

**Common Issues**:
- **SQL Connection Failed**: Verify SQL instance name and firewall rules
- **Email Not Sending**:
  - Check Gmail's "Less secure apps" setting
  - Verify app password if using 2FA
- **Permission Denied**: Run PowerShell as administrator

**Debug Mode**:
Add `-Verbose` parameter when testing:
```powershell
.\SQLJobMonitor.ps1 -Verbose
```

---

### 📌 Recommended Improvements (Future)
- [ ] Add failure threshold alerts
- [ ] Support multiple SQL instances
- [ ] Option for SMS notifications
- [ ] Historical trend analysis

---
