# Define the SQL query
$sqlQuery = @"
SELECT 
    j.name AS JobName, 
    h.run_status AS LastRunStatus, 
    h.run_date AS LastRunDate, 
    FORMAT(
        CAST(
            CONVERT(VARCHAR, h.run_date) + ' ' + 
            RIGHT('0' + CAST(h.run_time / 10000 AS VARCHAR(2)), 2) + ':' + 
            RIGHT('0' + CAST((h.run_time % 10000) / 100 AS VARCHAR(2)), 2) + ':' + 
            RIGHT('0' + CAST(h.run_time % 100 AS VARCHAR(2)), 2) 
            AS DATETIME
        ), 
        'MM/dd/yyyy hh:mm:ss tt'
    ) AS LastRunTime,
    CASE 
        WHEN h.run_status = 0 THEN 'Failed' 
        WHEN h.run_status = 1 THEN 'Succeeded' 
        WHEN h.run_status = 2 THEN 'Retry' 
        WHEN h.run_status = 3 THEN 'Canceled' 
        ELSE 'Unknown' 
    END AS JobOutcome 
FROM 
    msdb.dbo.sysjobs AS j 
INNER JOIN 
    msdb.dbo.sysjobhistory AS h ON j.job_id = h.job_id 
WHERE 
    h.instance_id = (
        SELECT MAX(h2.instance_id) 
        FROM msdb.dbo.sysjobhistory h2 
        WHERE h2.job_id = j.job_id
    ) 
    AND j.name LIKE 'Bk Up DB%' 
ORDER BY 
    h.run_date DESC, h.run_time DESC;
"@

# Define the SQL Server and database details
$serverInstance = "localhost"  # Replace with your SQL Server instance name
$databaseName = "msdb"
$outputFilePath = "C:\DB Job\JobStatus.csv"  # Define where you want to save the CSV file

# Define email parameters
$recipients = @("test@gmail.com")
$smtpSenderMailAdd = "dba@gmail.com"  # Replace with your Gmail email address
$smtpPassword = ""  # Replace with your Gmail password or Token
$smtpIp = "smtp.gmail.com"
$smtpPortNo = 587
$hostname = (Get-ComputerInfo).CsName  # Retrieves the computer name
$hostnameFolder = "Job Status Report"
$csvFilePath = $outputFilePath  # Path to your CSV file

# Execute the query and export results to CSV
try {
    # Run the SQL query
    $result = Invoke-Sqlcmd -ServerInstance $serverInstance -Database $databaseName -Query $sqlQuery

    # Export result to CSV
    $result | Export-Csv -Path $outputFilePath -NoTypeInformation

    Write-Host "Data exported successfully to $outputFilePath"

# Read the CSV file content without headers since you're manually adding them in the HTML
$csvContent = Import-Csv -Path $csvFilePath

# Initialize the mail body with HTML formatting
$mailBody = @"
<html>
<head>
    <style>
        table {
            width: 100%;
            border-collapse: collapse;
        }
        table, th, td {
            border: 1px solid black;
        }
        th, td {
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
    </style>
</head>
<body>
<h2>Server: $hostname</h2>
<table>
    <tr>
        <th>JobName</th>
        <th>LastRunStatus</th>
        <th>LastRunTime</th>
        <th>JobOutcome</th>
    </tr>
"@

# Loop through each row in the CSV and append it to the HTML table
foreach ($row in $csvContent) {
    $mailBody += "<tr>"
    $mailBody += "<td>$($row.JobName)</td>"
    $mailBody += "<td>$($row.LastRunStatus)</td>"
    $mailBody += "<td>$($row.LastRunTime)</td>"
    $mailBody += "<td>$($row.JobOutcome)</td>"
    $mailBody += "</tr>"
}

# Close the HTML tags
$mailBody += "</table></body></html>"

    # Create the email message parameters
    $mailParams = @{
        From         = $smtpSenderMailAdd
        To           = $recipients
        Subject      = "Backup Completed for $hostnameFolder"
        Body         = $mailBody
        SmtpServer   = $smtpIp
        Port         = $smtpPortNo
        Credential   = New-Object System.Management.Automation.PSCredential($smtpSenderMailAdd, (ConvertTo-SecureString $smtpPassword -AsPlainText -Force))
        UseSsl       = $true
        BodyAsHtml   = $true  # This enables sending the email as HTML
    }

    # Send the email
    Send-MailMessage @mailParams

    # Output success message
    Write-Host "Email sent successfully with job status in table format."

} catch {
    Write-Host "Error: $($_.Exception.Message)"
}
