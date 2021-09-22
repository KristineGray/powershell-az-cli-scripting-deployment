# TODO: set variables
$studentName = "Kristine"
$rgName = "$studentName-lc0821-ps-rg"
$vmName = "$studentName-lc0821-ps-vm"
$vmSize = "Standard_B2s"
$vmImage = "$(az vm image list --query "[? contains(urn, 'Ubuntu')] | [0].urn" -o tsv)"
$vmAdminUsername = "student"
$kvName = "$studentName-lc0821-ps-kv"
$kvSecretName = "ConnectionStrings--Default"
$kvSecretValue = "server=localhost;port=3306;database=coding_events;user=coding_events;password=launchcode"

# TODO: provision RG
az group create -n $rgName

# TODO: provision VM
vmData = $(az vm create -n $vmName -g $rgName --size $vmSize --image $vmImage --admin-username $vmAdminUsername --admin-password "LaunchCode-@zure1)

# TODO: capture the VM systemAssignedIdentity
vmId = $vmData --query "identity.systemAssignedIdentity"

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
