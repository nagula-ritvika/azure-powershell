﻿# ----------------------------------------------------------------------------------
#
# Copyright Microsoft Corporation
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# ----------------------------------------------------------------------------------

<#
.SYNOPSIS
Tests deployment template validation.
#>
function Test-ValidateDeployment
{
	# Setup
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$location = "West US 2"

	# Test
	New-AzResourceGroup -Name $rgname -Location $location

	$list = Test-AzResourceGroupDeployment -ResourceGroupName $rgname -TemplateFile Build2014_Website_App.json -siteName $rname -hostingPlanName $rname -siteLocation $location -sku Free -workerSize 0

	# Assert
	Assert-AreEqual 0 @($list).Count
}

<#
.SYNOPSIS
Tests deployment via template file and parameter object.
#>
function Test-NewDeploymentFromTemplateFile
{
	# Setup
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = "West US 2"

	try
	{
		# Test
		New-AzResourceGroup -Name $rgname -Location $rglocation

		$deployment = New-AzResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile sampleDeploymentTemplate.json -TemplateParameterFile sampleDeploymentTemplateParams.json

		# Assert
		Assert-AreEqual Succeeded $deployment.ProvisioningState

		$subId = (Get-AzContext).Subscription.SubscriptionId
		$deploymentId = "/subscriptions/$subId/resourcegroups/$rgname/providers/Microsoft.Resources/deployments/$rname"
		$getById = Get-AzResourceGroupDeployment -Id $deploymentId
		Assert-AreEqual $getById.DeploymentName $deployment.DeploymentName
	}

	finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}

function Test-NewDeploymentFromTemplateObject
{
    # Setup
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $rglocation = "West US 2"

    try
    {
        # Test
        New-AzResourceGroup -Name $rgname -Location $rglocation

        $path = (Get-Item ".\").FullName
        $file = Join-Path $path "sampleDeploymentTemplate.json"
        $json = ConvertFrom-Json ([System.IO.File]::ReadAllText($file))
        $templateObject = @{}
        $json.PSObject.Properties | % { $templateObject[$_.Name] = $_.Value }
        $deployment = New-AzResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateObject $templateObject -TemplateParameterFile sampleDeploymentTemplateParams.json

        # Assert
        Assert-AreEqual Succeeded $deployment.ProvisioningState

		$subId = (Get-AzContext).Subscription.SubscriptionId
		$deploymentId = "/subscriptions/$subId/resourcegroups/$rgname/providers/Microsoft.Resources/deployments/$rname"
		$getById = Get-AzResourceGroupDeployment -Id $deploymentId
		Assert-AreEqual $getById.DeploymentName $deployment.DeploymentName
	}

	finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}

function Test-TestResourceGroupDeploymentErrors
{
    # Catch exception when resource group doesn't exist
    $rgname = "unknownresourcegroup"
    $deploymentName = Get-ResourceName
    $result = Test-AzResourceGroupDeploymentWithName -DeploymentName $deploymentName -ResourceGroupName $rgname -TemplateFile sampleDeploymentTemplate.json -TemplateParameterFile sampleDeploymentTemplateParams.json
    Write-Debug "$result"
    Assert-NotNull $result
    Assert-AreEqual "ResourceGroupNotFound" $result.Code
    Assert-AreEqual "Resource group '$rgname' could not be found." $result.Message

    # Setup
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $rglocation = "West US 2"

    try
    {
        # Test
        # Catch exception when parameter template is missing
        New-AzResourceGroup -Name $rgname -Location $rglocation
        $result = Test-AzResourceGroupDeploymentWithName -DeploymentName $deploymentName -ResourceGroupName $rgname -TemplateFile sampleDeploymentTemplate.json -SkipTemplateParameterPrompt
        Assert-NotNull $result
        Assert-AreEqual "InvalidTemplate" $result.Code
        Assert-StartsWith "Deployment template validation failed" $result.Message
    }
    finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}

<#
.SYNOPSIS
Tests cross resource group deployment via template file.
.DESCRIPTION
Smoke[Broken]Test
#>
function Test-CrossResourceGroupDeploymentFromTemplateFile
{
	# Setup
	$rgname = Get-ResourceGroupName
	$rgname2 = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = "West US 2"

	try
	{
		# Test
		New-AzResourceGroup -Name $rgname -Location $rglocation
		New-AzResourceGroup -Name $rgname2 -Location $rglocation

		$parameters = @{ "NestedDeploymentResourceGroup" = $rgname2 }
		$deployment = New-AzResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile sampleTemplateWithCrossResourceGroupDeployment.json -TemplateParameterObject $parameters

		# Assert
		Assert-AreEqual Succeeded $deployment.ProvisioningState

		$subId = (Get-AzContext).Subscription.SubscriptionId
		$deploymentId = "/subscriptions/$subId/resourcegroups/$rgname/providers/Microsoft.Resources/deployments/$rname"
		$getById = Get-AzResourceGroupDeployment -Id $deploymentId
		Assert-AreEqual $getById.DeploymentName $deployment.DeploymentName

		$nestedDeploymentId = "/subscriptions/$subId/resourcegroups/$rgname2/providers/Microsoft.Resources/deployments/nestedTemplate"
		$nestedDeployment = Get-AzResourceGroupDeployment -Id $nestedDeploymentId
		Assert-AreEqual Succeeded $nestedDeployment.ProvisioningState
	}

	finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}

<#
.SYNOPSIS
Tests nested errors displayed when temployment put fails.
#>
function Test-NestedErrorsDisplayed
{
	# Setup
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = "CentralUSEUAP"

	try
	{
		# Test
		$ErrorActionPreference = "SilentlyContinue"
		$Error.Clear()
		New-AzResourceGroup -Name $rgname -Location $rglocation
		New-AzResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile sampleTemplateThrowsNestedErrors.json
	}
	catch
	{
		Assert-True { $Error[1].Contains("Storage account name must be between 3 and 24 characters in length") }
	}
	finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}

<#
.SYNOPSIS
Tests nested deployment.
.DESCRIPTION
Smoke[Broken]Test
#>
function Test-NestedDeploymentFromTemplateFile
{
	# Setup
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = "West US 2"

	try
	{
		# Test
		New-AzResourceGroup -Name $rgname -Location $rglocation

		$deployment = New-AzResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile sampleNestedTemplate.json -TemplateParameterFile sampleNestedTemplateParams.json

		# Assert
		Assert-AreEqual Succeeded $deployment.ProvisioningState

		$subId = (Get-AzContext).Subscription.SubscriptionId
		$deploymentId = "/subscriptions/$subId/resourcegroups/$rgname/providers/Microsoft.Resources/deployments/$rname"
		$getById = Get-AzResourceGroupDeployment -Id $deploymentId
		Assert-AreEqual $getById.DeploymentName $deployment.DeploymentName
	}

	finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}

<#
.SYNOPSIS
Tests save deployment template file.
.DESCRIPTION
Smoke[Broken]Test
#>
function Test-SaveDeploymentTemplateFile
{
	# Setup
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = "West US 2"

	try
	{
		# Test
		New-AzResourceGroup -Name $rgname -Location $rglocation

		$deployment = New-AzResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile sampleDeploymentTemplate.json -TemplateParameterFile sampleDeploymentTemplateParams.json

		# Assert
		Assert-AreEqual Succeeded $deployment.ProvisioningState

		$saveOutput = Save-AzResourceGroupDeploymentTemplate -ResourceGroupName $rgname -DeploymentName $rname -Force
		Assert-NotNull $saveOutput
		Assert-True { $saveOutput.Path.Contains($rname + ".json") }
	}

	finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}

<#
.SYNOPSIS
Tests deployment via template file and parameter file with KeyVault reference.
#>
function Test-NewDeploymentWithKeyVaultReference
{
	# Setup
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$keyVaultname = Get-ResourceName
	$secretName = Get-ResourceName
	$rglocation = "CentralUSEUAP"
	$location = Get-ProviderLocation "Microsoft.Web/sites"
	$hostplanName = "xDeploymentTestHost26668"

	try
	{
		# Test
		New-AzResourceGroup -Name $rgname -Location $rglocation

		$context = Get-AzContext
		$subscriptionId = $context.Subscription.SubscriptionId
		$tenantId = $context.Tenant.TenantId
		$adUser = Get-AzADUser -UserPrincipalName $context.Account.Id
		$objectId = $adUser.Id
		$KeyVaultResourceId = "/subscriptions/" + $subscriptionId + "/resourcegroups/" + $rgname + "/providers/Microsoft.KeyVault/vaults/" + $keyVaultname

		$parameters = @{ "keyVaultName" = $keyVaultname; "secretName" = $secretName; "secretValue" = $hostplanName; "tenantId" = $tenantId; "objectId" = $objectId }
		$deployment = New-AzResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile keyVaultSetupTemplate.json -TemplateParameterObject $parameters

		# Assert
		Assert-AreEqual Succeeded $deployment.ProvisioningState

		$content = (Get-Content keyVaultTemplateParams.json) -join '' | ConvertFrom-Json
		$content.hostingPlanName.reference.KeyVault.id = $KeyVaultResourceId
		$content.hostingPlanName.reference.SecretName = $secretName
		$content | ConvertTo-Json -depth 999 | Out-File keyVaultTemplateParams.json

		$deployment = New-AzResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile sampleTemplate.json -TemplateParameterFile keyVaultTemplateParams.json

		# Assert
		Assert-AreEqual Succeeded $deployment.ProvisioningState

		$subId = (Get-AzContext).Subscription.SubscriptionId
		$deploymentId = "/subscriptions/$subId/resourcegroups/$rgname/providers/Microsoft.Resources/deployments/$rname"
		$getById = Get-AzResourceGroupDeployment -Id $deploymentId
		Assert-AreEqual $getById.DeploymentName $deployment.DeploymentName
	}

	finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}

<#
.SYNOPSIS
Tests deployment with template file with complex parameters.
#>
function Test-NewDeploymentWithComplexPramaters
{
	# Setup
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = "CentralUSEUAP"

	try
	{
		# Test
		New-AzResourceGroup -Name $rgname -Location $rglocation

		$deployment = New-AzResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile complexParametersTemplate.json -TemplateParameterFile complexParameters.json

		# Assert
		Assert-AreEqual Succeeded $deployment.ProvisioningState

		$subId = (Get-AzContext).Subscription.SubscriptionId
		$deploymentId = "/subscriptions/$subId/resourcegroups/$rgname/providers/Microsoft.Resources/deployments/$rname"
		$getById = Get-AzResourceGroupDeployment -Id $deploymentId
		Assert-AreEqual $getById.DeploymentName $deployment.DeploymentName
	}

	finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}

<#
.SYNOPSIS
Tests deployment with template file with parameter object.
#>
function Test-NewDeploymentWithParameterObject
{
	# Setup
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = "CentralUSEUAP"

	try
	{
		# Test
		New-AzResourceGroup -Name $rgname -Location $rglocation

		$deployment = New-AzResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile complexParametersTemplate.json -TemplateParameterObject @{appSku=@{code="f1"; name="Free"}; servicePlan="plan1"; ranks=@("c", "d")}

		# Assert
		Assert-AreEqual Succeeded $deployment.ProvisioningState

		$subId = (Get-AzContext).Subscription.SubscriptionId
		$deploymentId = "/subscriptions/$subId/resourcegroups/$rgname/providers/Microsoft.Resources/deployments/$rname"
		$getById = Get-AzResourceGroupDeployment -Id $deploymentId
		Assert-AreEqual $getById.DeploymentName $deployment.DeploymentName
	}

	finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}

<#
.SYNOPSIS
Tests deployment with template file with dynamic parameters.
#>
function Test-NewDeploymentWithDynamicParameters
{
	# Setup
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = "West US 2"

	try
	{
		# Test
		New-AzResourceGroup -Name $rgname -Location $rglocation

		$deployment = New-AzResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile complexParametersTemplate.json -appSku @{code="f3"; name=@{major="Official"; minor="1.0"}} -servicePlan "plan1" -ranks @("c", "d")

		# Assert
		Assert-AreEqual Succeeded $deployment.ProvisioningState

		$subId = (Get-AzContext).Subscription.SubscriptionId
		$deploymentId = "/subscriptions/$subId/resourcegroups/$rgname/providers/Microsoft.Resources/deployments/$rname"
		$getById = Get-AzResourceGroupDeployment -Id $deploymentId
		Assert-AreEqual $getById.DeploymentName $deployment.DeploymentName
	}

	finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}

<#
.SYNOPSIS
Tests error displayed for invalid parameters.
#>
function Test-NewDeploymentWithInvalidParameters
{
	# Setup
	$rgname = Get-ResourceGroupName
	$rname = Get-ResourceName
	$rglocation = "CentralUSEUAP"

	try
	{
		# Test
		$ErrorActionPreference = "SilentlyContinue"
		$Error.Clear()
		New-AzResourceGroup -Name $rgname -Location $rglocation
		$deployment = New-AzResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile complexParametersTemplate.json -appSku @{code="f4"; name="Free"} -servicePlan "plan1"
	}
	catch
	{
		Assert-True { $Error[1].Contains("The parameter value is not part of the allowed value(s)") }
	}
	finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}

<#
.SYNOPSIS
Tests deployment via template file with KeyVault reference in TemplateParameterObject.
#>
function Test-NewDeploymentWithKeyVaultReferenceInParameterObject
{
	# Setup
	$location = "West US"

	$vaultId = "/subscriptions/fb3a3d6b-44c8-44f5-88c9-b20917c9b96b/resourceGroups/powershelltest-keyvaultrg/providers/Microsoft.KeyVault/vaults/saname"
	$secretName = "examplesecret"

	try
	{
		$deploymentRG = Get-ResourceGroupName
		$deploymentName = Get-ResourceName

		New-AzResourceGroup -Name $deploymentRG -Location $location

		# Test
		$parameters = @{"storageAccountName"= @{"reference"= @{"keyVault"= @{"id"= $vaultId};"secretName"= $secretName}}}
		$deployment = New-AzResourceGroupDeployment -Name $deploymentName -ResourceGroupName $deploymentRG -TemplateFile StorageAccountTemplate.json -TemplateParameterObject $parameters

		# Assert
		Assert-AreEqual Succeeded $deployment.ProvisioningState
	}

	finally
    {
        # Cleanup
        Clean-ResourceGroup $deploymentRG
    }
}

<#
.SYNOPSIS
Tests deployment exception thrown with nonexistent template file.
#>
function Test-NewDeploymentFromNonexistentTemplateFile
{
    # Setup
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $rglocation = "West US 2"
    try
    {
        # Test
        New-AzResourceGroup -Name $rgname -Location $rglocation

        # Assert exception is thrown
        $path = (Get-Item ".\").FullName
        $file = Join-Path $path "nonexistentFile.json"
        $exceptionMessage = "Cannot retrieve the dynamic parameters for the cmdlet. Cannot find path '$file' because it does not exist."
        Assert-Throws { New-AzResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile $file -TemplateParameterFile sampleTemplateParams.json } $exceptionMessage
    }
    finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}

<#
.SYNOPSIS
Tests deployment exception thrown with nonexistent template parameter file.
#>
function Test-NewDeploymentFromNonexistentTemplateParameterFile
{
    # Setup
    $rgname = Get-ResourceGroupName
    $rname = Get-ResourceName
    $rglocation = "West US 2"
    try
    {
        # Test
        New-AzResourceGroup -Name $rgname -Location $rglocation

        # Assert exception is thrown
        $path = (Get-Item ".\").FullName
        $file = Join-Path $path "nonexistentFile.json"
        $exceptionMessage = "Cannot retrieve the dynamic parameters for the cmdlet. Cannot find path '$file' because it does not exist."
        Assert-Throws { New-AzResourceGroupDeployment -Name $rname -ResourceGroupName $rgname -TemplateFile sampleTemplateParams.json -TemplateParameterFile $file } $exceptionMessage
    }
    finally
    {
        # Cleanup
        Clean-ResourceGroup $rgname
    }
}