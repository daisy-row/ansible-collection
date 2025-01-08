# Fabproxy Removal

This is a support project for removing Fabproxy from migrated instances from IBM Blockchain Platform Software as a Service.  Instances that migrated from IBM Blockchain Platform Software as a Service (SaaS) to HLF Support instance are still using fabproxy.  The ports used by fabproxy are non-standard ports and should be migrated to the standard port (443) and host names used by HLF Support.

Fabproxy removal is included as an open source example and will work with the open source operator and console.  It can be used a a reference sample for automating common maintenance tasks.   Some examples include:
- Renewing TLS certificates for CAs.
- Reenrolling enrollment and TLS certificates for peers and ordering nodes
- Updating metadata for CAs, peers and ordering nodes
- Listing and iterating on CAs
- Listing and iterating on peers and ordering nodes by associated CAs

Fabproxy removal will remove fabproxy from migrated instances. Ansible scripts are used for removing fabproxy from the HLF Support instances.

The fabproxy removal process will use the following high level steps:

- Migrate the All CA address.
- Update associated nodes.
- Migrate the self hosted and imported Peer address.
- Migrate the orderering node address.
- Update anchor peer in the channel.

**Note:**
 This script is not compatible with Single Ordering node setups.

## Step 1: Install Prerequisites for the Hyperledger Fabric Ansible Collection

There are two methods for running the ansible playbooks.  Ansible and its prerequisites can be installed locally, or the Hyperledger Fabric ansible collection image can be used.

### Option 1 - Use the Ansible collection image (recommended)


The ansible collection docker image is available for automatic download.  This method provides a simpler setup and does not require any local installation with the exception of docker.

Create a directory on the local machine before beginning.

Execute the following docker command to create a container based on the ansible collection:

```
docker run -it --rm -u $(id -u) -v "local fully qualified path to fabproxy removal playbooks":/playbooks ghcr.io/hyperledger-labs/fabric-ansible:sha-c9330b9 bash

```

Example:

```
docker run -it --rm -u $(id -u) -v ./examples/fabproxy-removal:/playbooks ghcr.io/hyperledger-labs/fabric-ansible:sha-c7cd5e4 bash
```

At the command prompt, change directory to '/playbooks' and copy the fabproxy removal playbooks.

```
[hlf-user@f401182e9510 /]$ cd playbooks/

[hlf-user@f401182e9510 playbooks]$ cp -R /opt/fabproxy-removal/* .
```

Execute an ls and you should see the fabproxy-removal playbooks:

```
[hlf-user@f401182e9510 playbooks]$ ls
01-migrate-all-ca-addresses.yml  03-migrate-peer-and-imported-addresses.yml  05-update_anchor_peers.yml  channels.yml	  tasks
02-update-associated-nodes.yml	 04-migrate-ordering-node-addresses.yml      README.md			 common-vars.yml

```

### Option 2 - Install the ansible playbook prerequisites locally


The fabproxy-removal playbooks can be executed locally.  This requires a more detailed setup on the local machine.  Installation requirements can be found here:

- [Fabric Ansible Collection Pre-requisites](https://labs.hyperledger.org/fabric-ansible-collection/installation.html#requirements)

Once all prerequisites have been installed, clone the ansible collection to a local directory.

```
git clone git@github.com:hyperledger-labs/fabric-ansible-collection.git
```

Once the collection has been successfully clone, change directory to the "examples/fabproxy-removal" directory.

Execute and "ls" and you should see the fabproxy-removal playbooks:

```
[fabric-ansible-collection] $ cd examples/fabproxy-removal/

[fabproxy-removal] $ ls
01-migrate-all-ca-addresses.yml			04-migrate-ordering-node-addresses.yml		channels.yml
02-update-associated-nodes.yml			05-update_anchor_peers.yml			common-vars.yml
03-migrate-peer-and-imported-addresses.yml	README.md					tasks

```


The customer should carry out the script under the supervision of an IBM HLF SRE team member. If the client is confident  in the Ansible script's execution process they can execute the script therself. They must gather logs and communicate them via support tickets in the event that there are failures in the sequential execution flow. It is necessary to complete each step in order.
{: important}


## Step 2: Download Identies from the HLF Support Console.

The fabproxy-removal playbooks require admin identities in order to complete changes to the channels.

First create a "wallet" directory in the same directory as the fabproxy removal playbooks:

```
[playbooks]$ mkdir wallet
[playbooks]$ ls
01-migrate-all-ca-addresses.yml  03-migrate-peer-and-imported-addresses.yml  05-update_anchor_peers.yml  channels.yml	  tasks        wallet
02-update-associated-nodes.yml	 04-migrate-ordering-node-addresses.yml      README.md			 common-vars.yml  testing.txt
```

On the Fabric Operations console, go to the wallet tab and export each wallet entry into the wallet directory.

Optionally, export the data in bulk:

Navigate to the Settings tab in the left hand navigation. You will see a section called Bulk data management followed by two buttons. The Export button will open a panel on the right, where you have several options of what to export.

- By default, the Identities box in the export panel is left deselected. Download the peer, CA, and orderer identities by selecting the identities box.

- Unzip the bulk export file and copy all of the identities in the 'Wallet' directory to the 'wallet' directory in the fabroxy removal directory.

## Step 3: Editing the variable files.

 Variable files are used to store variables that are used across multiple Ansible playbooks. Each organization has their own variable file, and you must edit these files to specify the connection details for the instance for that organization.The playbook repository has two ansible variable files such as` channels.yml` and `common-vars.yml`.

 This is how the `channels.yml` definition appears. It has the System channel name and the Application channel name by default. if the client's orderer node with system channel. Since `testchainid` is the default system channel name, they don't need to modify it. The customer must alter the name of the appropriate application channel. They have entered each name individually if they have more than one application channel name. If the customer has the orderer node without system channel, they don't need mention the system channel name `testchainid`.

 ***Note:***

If you exclude any channel in the configuration below, those channels will be unused after the FabProxy migration, and there will be no way to recover them. Ensure that you include all the channels you wish to migrate.


 ```
 channel_names:
   - testchainid
   - channel1

 ```
An alternate method for determining the channel list. Please execute the below command to find the list of channel associated with the network and update channel variable files.

```
kubectl exec -it [Ordrer Node Name] -c orderer -n [namespace] -- ls /ordererdata/ledger/ibporderer/chains | xargs printf ' - %s \n'
```

This is how the `common-vars.yml` definition appears. Edit the variable file.

- Determine the URL of your instance’s console.

- Determine the API key and secret you use to access your console. You can also use a username and password instead of an API key and secret.

- Set `api_endpoint` to the URL of your console.

- Set `api_authtype` to basic.

- Set `api_key` to your API key or username.

- Set `api_secret` to your API secret or password.

- Set `ordering_service_name`. its the name of your orderering service.

- Set `ordering_service_node_name`. its the name of your orderering service node name. If you have multiple Orderering Service node. The execution mode will one by one. Each time change respective  orderering service node name and execute script.

- Set `ordering_service_admin_identity` the OS identity name.

- Set `ordering_service_msp_id` th OS MSP name. We can get the name from Orderering Service MSP definition.

  ```
  api_endpoint: <Console URL>
  api_authtype: basic
  api_key: <Console UserName>
  api_secret: <Console Password>
  preferred_url_os: "os"
  preferred_url_legacy: "legacy"
  ordering_service_name: <Orderering Service Name>
  ordering_service_node_name: <Orderering Service Node Name>
  ordering_service_admin_identity: <Orderering Service Admin Identity>
  ordering_service_msp_id: <Orderering Service MSP Name>
  dry_run: false
  wait_timeout: 600

  ```

## Step 4: Migrate the All CA address.

 1. This script will renew the CA TLS certificates.

 2. Execute the following script. if we want to see the logs trace. We can add `-vvv` as a suffix in the end of the command

  ```
  ansible-playbook 01-migrate-all-ca-addresses.yml
  ```
 3. Once the script executed.  Check the CA pods are restarted. If its restarted navigate to the console and click the CA node. In the CA `info and usage` page the `Operations url` and `API url`  port has been changed into `443`.

***Note:***

After migrating all CA addresses. Before proceeding to the next step. If the customer has multi-console setup/using imported CA, then export all of the CAs and replace the imported CAs in all consoles.

## Step 5: Update Associated Nodes.

 1. The steps associate nodes the respective to the CA nodes.

 2. Execute the following command.

   ```
   ansible-playbook 02-update-associated-nodes.yml
  ```
 3. Once the script executed.  Check the respective nodes to the CA are restarted. For example Peer and Orderer nodes getting restarted.

## Step 6: Migrate the self hosted and imported Peer address.

 1. The steps migrate Peer and imported Orderer node address and also Re-enroll the peer TLS certificates.

 2. Execute the following command.

   ```
   ansible-playbook 03-migrate-peer-and-imported-addresses.yml
  ```
 3. Once the aforementioned command has been executed, confirm that the respective peer nodes are restarting. If its restarted navigate to the console and click the Peer node. In the Peer `info and usage` page the `Operations url` and `API url`  port has been changed into `443`.

 ## Step 7: Migrate the orderering node address.

 ***Note:***
  In the `common-vars.yml`, set the `dry-run` variable to true for the first run. This will ensure all channels are reachable and all actions can be completeted with making changes to the channels.


  1. The steps migrate renew the Orderer TLS certificate and migrate the Orderer address.

  2. Verify that everything is configured appropriately by reviewing your variable configuration files before running the script. If a customer uses the RAFT ordering service, we must update the name of the ordering service node in the `common-vars.yml` file after each execution.

 3. The ordering node logs for the ordering nodes should be reviewed before proceeding. The script needs to be applied for the subsequent ordering service if everything is operating as it should.

 4. Execute the following command.

   ```
   ansible-playbook 04-migrate-ordering-node-addresses.yml
  ```
 5. Once the aforementioned command has been executed, confirm that the respective Orderer nodes are restarting. If its restarted navigate to the console and click the Orderer node. In the Orderer `info and usage` page the `Operations url` and `API url`  port has been changed into `443`.

## Step 8: Update anchor peer in the channel.

 1. The steps migrate the anchor peer address in the application channel config.

 2. Execute the following command.

   ```
   ansible-playbook 05-update_anchor_peers.yml
  ```
 3. Once the above steps executed check the application channel config. The peer address are migrated.

# Verify the IBM Support for Hyperledger Fabric instance after the FabProxy migration:

**Step 1:** Remove the Peer and Orderer external addresses from their respective CRSpec using the following commands.

```
kubectl get ibppeer -n [namespace]  --no-headers=true -o custom-columns=":metadata.name" | xargs kubectl patch ibppeer [Peer Name] -n [namespace]   --type merge --patch '{"spec":{"peerExternalEndpoint":""}}'

kubectl get ibporderer -n [namespace]  --no-headers=true -o custom-columns=":metadata.name" | xargs kubectl patch ibporderer [Orderer Name] -n [namespace]  --type merge --patch '{"spec":{"externalAddress":""}}'
```

**Step 2:** Remove the deployments of Peer, Orderer, and CA. Once removed, the operator will restart the deployments. Ensure the deployments are up.

```
kubectl delete deployment [peer/orderer/ca] -n [namespace]
```
Note: When deleting deployments, delete them one by one and ensure that the corresponding pods are up and running.

**Step 3** Recommend deleting all ingresses in the namespace where the blockchain components are hosted. Delete each component's ingress using the commands below.

```
kubectl get ingress -n [namespace]

kubectl delete ingress [component-ingress-name] -n [namespace]
```

**Step 4** Restart the operator by deleting the operator pods.

```
kubectl delete pod [operator-pod-name] -n [namespace]
```
**Step 5:** Verify that the ports for the HLF components(Peer/CA/Orderer) have been updated to 443.

**Step 6:** Scale down the fabproxy deployments in `ibpinfra` namespace  using the below command.
```
kubectl scale deployment --replicas=0 proxy-fabproxy -n ibpinfra
```
**Step 7:** Once the fabproxy pods are scale down to zero. Check the console all the compoents are in green state.

**Step 8:**  Download the latest connection profile from your console and configure it in your client application. Execute the transaction and verify that the console is functioning as it did previously.

**Step 9:**  If eveything working as expected. User can remove `ibpinfra` namespace.
