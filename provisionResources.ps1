# TODO: set variables
$studentName = "kg"
$rgName = "$studentName-lc0921-ps-rg"
$vmName = "$studentName-lc0921-ps-vm"
$vmSize = "Standard_B2s"
$vmImage = "$(az vm image list --query "[? contains(urn, 'Windows')] | [0].urn" -o tsv)"
$vmAdminUsername = "student"
$kvName = "$studentName-lc0921-ps-kv"
$kvSecretName = "ConnectionStrings--Default"
$kvSecretValue = "server=localhost;port=3306;database=coding_events;user=coding_events;password=launchcode"

# TODO: provision RG
az group create -n $rgName
az configure --defaults group=$rgName

# TODO: provision VM
$vmData = $(az vm create -n $vmName --size $vmSize --image $vmImage --admin-username $vmAdminUsername --admin-password "LaunchCode-@zure1" --authentication-type password --assign-identity --query "[ identity.systemAssignedIdentity, publicIpAddress ]" -o tsv)
az configure --defaults vm=$vmName

# TODO: capture the VM systemAssignedIdentity
$vmId = $vmData | head -n 1
$vmIp = $vmData | tail -n +2

# TODO: open vm port 443
az vm open-port --port 443

# provision KV
az keyvault create -n $kvName --enable-soft-delete false --enabled-for-deployment true

# TODO: create KV secret (database connection string)
az keyvault secret set --vault-name $kvName --description "Connection string" --name $kvSecretName --value $kvSecretValue

# TODO: set KV access-policy (using the vm ``systemAssignedIdentity``)
az keyvault set-policy --name $kvName --object-id $vmId --secret-permissions list get

az vm run-command invoke --command-id RunShellScript --scripts @vm-configuration-scripts/1configure-vm.sh

az vm run-command invoke --command-id RunShellScript --scripts @vm-configuration-scripts/2configure-ssl.sh

az vm run-command invoke --command-id RunShellScript --scripts @deliver-deploy.sh

# TODO: print VM public IP address to STDOUT or save it as a file
echo "$vmName available at $vmIp"