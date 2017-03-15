workflow loadtest-cleandb
{
	# Inputs
    param (
        [Object] $WebhookData
    )
	# If runbook was called from Webhook, WebhookData will not be null.
    if ($WebhookData -ne $null) {   	
		# Collect properties of WebhookData
     	$WebhookName    =   $WebhookData.WebhookName
     	$WebhookHeaders =   $WebhookData.RequestHeader
     	$WebhookBody    =   $WebhookData.RequestBody

     	# Collect who start WebHook
     	$From = $WebhookHeaders.From
	
	 	# Collect DB info
	 	$DbInfo = ConvertFrom-Json -InputObject $WebhookBody
	 	$CollDatabase2Copy = $DbInfo.CollDatabase2Copy
     	$TestDatabase2Snap = $DbInfo.TestDatabase2Snap
        $TestSnapName = $DbInfo.TestSnapName
     	$CollDatabaseServer = $DbInfo.CollDatabaseServer
        $TestDatabaseServer = $DbInfo.TestDatabaseServer
        $TestDBEdition = $DbInfo.TestDBEdition
        $CollDBEdition = $DbInfo.CollDBEdition
        $TestNewPricingTier = $DbInfo.TestNewPricingTier
        $CollNewPricingTier = $DbInfo.CollNewPricingTier
        $TestRG = $DbInfo.TestRG
        $CollRG = $DbInfo.CollRG
	 	Write-Output "Runbook started from webhook $WebhookName by $From."
	 	Write-Output "Request value Gold image: $CollDatabase2Copy - Copy: $DatabaseCopy - Sql Server: $DatabaseServer"
	
		# Check Input
		if (!$CollDatabase2Copy) { 
			Write-Output "variable Coll database to copy Name is null" 
			Exit	
		}
		if (!$TestDatabase2Snap) { 
			Write-Output "variable Test database to Snap is null" 
			Exit	
		}
		if (!$TestSnapName) { 
			Write-Output "variable Test snapshot name is null" 
			Exit	
		}
        if (!$CollDatabaseServer) { 
			Write-Output "variable Coll database server is null" 
			Exit	
		}
		if (!$TestDatabaseServer) { 
			Write-Output "variable Test database server is null" 
			Exit	
		}
		if (!$TestNewPricingTier) { 
			Write-Output "variable Test database tier is null" 
			Exit	
		}
		if (!$CollNewPricingTier) { 
			Write-Output "variable coll database tier is null" 
			Exit	
		}
        if (!$CollDBEdition) { 
			Write-Output "variable Coll database edition is null" 
			Exit	
		}
		if (!$TestDBEdition) { 
			Write-Output "variable Test database edition is null" 
			Exit	
		}
        if (!$TestRG) { 
			Write-Output "variable Test resource group is null" 
			Exit	
		}
		if (!$CollRG) { 
			Write-Output "variable Coll resource group is null" 
			Exit	
		}

		# Login Azure RM
        $RmCred = Get-AutomationPSCredential -Name "mondora"
		$RmLogin = Add-AzureRmAccount -Credential $RmCred -ErrorAction Stop  
        $RmLogin = Login-AzureRmAccount -Credential $RmCred -ErrorAction Stop
        $RmSub =  Select-AzureRmSubscription -SubscriptionName "HubFePa"
	 	Write-Output "Runbook RM logged in. Ready to execute"
        
        # Create Test SnapShot 
        New-AzureRmSqlDatabaseCopy -ResourceGroupName $TestRG -ServerName $TestDatabaseServer -DatabaseName $TestDatabase2Snap -CopyServerName $TestDatabaseServer -CopyDatabaseName $TestSnapName  -ErrorAction Stop
		Write-Output "DB Snapshot Completed"

     	# Delete Test db
     	$delete = Remove-AzureRmSqlDatabase -ResourceGroupName $TestRG -ServerName $TestDatabaseServer -DatabaseName $TestDatabase2Snap -ErrorAction Stop
        Write-Output "DB: $TestDatabase2Snap deleted"
        
        # Sobstitute Coll DB To Test
        New-AzureRmSqlDatabaseCopy -ResourceGroupName $TestRG -ServerName $CollDatabaseServer -DatabaseName $CollDatabase2Copy -CopyServerName $TestDatabaseServer -CopyDatabaseName $TestDatabase2Snap  -ErrorAction Stop
        Write-Output "Coll DB ready"

        $RGList = @("b2bhub-test","b2b-test")
		# Restart WebApp
		foreach ($group in $RGList) {
		    $appList = Get-AzureRmWebApp -ResourceGroupName $group
		    foreach ($app in $appList) {
    			    Restart-AzureRmWebApp -ResourceGroupName $group -Name $app.Name
		    }
        } 

         Write-Output "Execution Completed"
	 }
    else {
        Write-Error "Runbook mean to be started only from webhook." 
    } 
}