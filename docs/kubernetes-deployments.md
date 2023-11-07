# Kubernetes Deployments

These are some examples of how to deploy applications to Kubernetes using different tools and approaches.

 - Deploy with Helm manually encrypting/decrypting secret files with SOPS
 - Helm-secrets plugin
 - Helm-secrets plugin in Skaffold
 - Kustomize with `--enable-helm` and Secret Generator
 - Skaffold with `helm-secrets` plugin
 - helmfile.yaml with `helm secrets` plugin
  
 ## **Deploy with Helm manually encrypting/decrypting secret files with SOPS**

 SOPS ( Secret OPerationS ) is an editor of encrypted files that supports YAML, JSON, ENV, INI and BINARY formats and encrypts with AWS KMS, GCP KMS, Azure Key Vault, AGE and PGP. It's a great tool to encrypt files and store them safely in the repository, following **GitOps** best practices to keep all the configuration versioned in Git repositories.

 Follow the steps below to encrypt the [/kubernetes/mysql/secrets.yaml](/kubernetes/mysql/secrets.yaml) file with SOPS:

  1. **Install SOPS**: Install [SOPS](https://github.com/getsops/sops/releases)
  2. **Configure SOPS**: Install SOPS with the [/scripts/configure-sops.sh](/scripts/configure-sops.sh) script in the `scripts` folder.
  3. **Replace secret.yaml**: Replace the encrypted `secrets.yaml` with your unencrypted secret file, according to the Kubernetes official documentation.
  4. **Encrypt the file with SOPS**: Encrypt the [/kubernetes/mysql/secrets.yaml](/kubernetes/mysql/secrets.yaml) and then safely commit the file to your repository.

    sops -e -i kubernetes/mysql/secrets.yaml
  
  5. **Decrypt the file with SOPS**: Before deploying the Helm Chart, you need to decrypt the file with SOPS, so that Helm can read the file. You can do that with the following command:

    sops -d -i kubernetes/mysql/secrets.yaml

  6. **Deploy the MySQL Helm Chart**: Now, you can deploy the MySQL Helm Chart with the decrypted secrets file with the following command:
    
    helm upgrade --install mysql oci://registry-1.docker.io/bitnamicharts/mysql -v ./mysql-values.yaml -v ./mysql/secrets.yaml --create-namespaces -n mysql
  
  Now you can freely commit the encrypted file to the repository. Always double-check if the file is encrypted before committing it. There are tools that can help you with that, or you can create a pre-commit hook to check if there are unencrypted secret files before committing it.

  If you change the AGE key, you will have to [update the encrypted files](https://github.com/getsops/sops#adding-and-removing-keys) with:

    sops updatekeys /path/to/secret.enc.yaml
    
## Helm-secrets plugin

`helm-secrets` is a Helm plugin that enables on-the-fly decryption of encrypted Helm value files.

- Utilize `sops` to encrypt your value files and securely store them in your git repository.
- Leverage cloud-native secret managers such as AWS SecretManager, Azure KeyVault, or HashiCorp Vault to store your secrets and inject them directly into your value files or templates.
- Integrate `helm-secrets` with your preferred deployment tool or GitOps Operator, such as FluxCD, for a seamless deployment experience.

By convention, files containing secrets are named secrets.yaml, or anything beginning with "secrets" and ending with ".yaml". E.g. secrets.test.yaml, secrets.prod.yaml secretsCOOL.yaml.

Read the [official documentation](https://github.com/jkroepke/helm-secrets/wiki/Usage) for more detailed information

1. **Install the plugin**: 
    ```bash
    helm plugin install https://github.com/jkroepke/helm-secrets --version v4.5.1
    ```
1. Now, instead of running `helm` commands, you will run `helm secrets`. For example, to install the MySQL Helm Chart, you will run:
   
    ```bash
    # Change directory to the helm folder
    cd $(git rev-parse --show-toplevel)/kubernetes/mysql/helm

    helm secrets upgrade --install mysql oci://registry-1.docker.io/bitnamicharts/mysql --version 9.14.1 -f ./values.yaml -f ./secrets.yaml --create-namespace -n mysql
    ```

You can also use [KSOPS](https://github.com/viaduct-ai/kustomize-sops) to run `kustomize build` with SOPS automatic decryption, declaring a [secret-generator.yaml](https://github.com/viaduct-ai/kustomize-sops#generate-secret-directly-from-encrypted-files) file.

Notice from the logs that it detects the secret file automatically and then temporarily decrypts the secrets.yaml file to finally use it as input for the Helm release, reencrypting it at the end.

## Helm-secrets plugin in Skaffold

In this repository, the `helm-secrets` plugin is used to encrypt the [/kubernetes/mysql/secrets.yaml](/kubernetes/mysql/secrets.yaml) file with SOPS and store it safely in the repository, following GitOps best practices to keep all the configuration versioned in Git repositories. Then, for the Helm charts deployment we use Skaffold, which leverages the helm-secrets plugin via the `useHelmSecrets: true` attribute in the [skaffold.yaml](/skaffold.yaml) file to decrypt the secrets file before deploying the Helm Chart.

## Kustomize with `--enable-helm` and Secret Generator

Another common option is to use Helm to get the Helm chart templates and patch them with Kustomize to generate the Secrets and ConfigMaps from local files, in order to avoid storing sensitive information in the repository. To do this, use the `--enable-helm` flag in the `kustomize build` command.

 It joins the best of both worlds, using Helm to deploy the MySQL Server and Kustomize to generate the Secrets and ConfigMaps, in order to avoid storing sensitive information in the repository.

   1. Deploying with Helm and Kustomize

    The kustomization.yaml file contains a reference to the Helm chart to be pulled and the values file.

   2. Deploy the manifests with `kubectl kustomize --eanble-helm` running:
      
    ```bash
    kubectl apply -k mysql --enable-helm
    ```

The OCI registries dispenses the need of adding the helm repository to your local machine and instead downloads the chart directly from the registry. 

The `mysql-values.yaml` file contains the values that will be used to configure the MySQL Server.

## helmfile with `secrets-plugin`

Helmfile is analogous to a docker-compose, but for Helm releases, allowing you to declare the desired state of your Helm releases in a declarative way. It's a great tool to deploy complex Helm releases at once, with different values for each environment, and it's also a great tool to deploy Helm Charts with `helm-secrets` plugin.

Run the following commands to deploy all the Helm charts:

    helmfile repos
    helmfile sync
    kubectl -n stack-io port-forward svc/stack-io 8086:8080

The application should now be accessible at http://localhost:8086.

> * Notice that helmfile project is still in its 0.x.x versions, so it's not designated for production use-cases.
> * The releases defined in helmfile.yaml will only be installed after the releases defined in defaults.yaml are installed.

## GitOps with FluxCD

For production use-cases, I recommend using a GitOps approach to continuously deploy the Helm releases upon new image versions. 

A [gitops-fluxcd](github.com/guirgouveia/gitops-fluxcd) project can be found in my GitHub, which continuously deploys a whole DevOps stack in a Kubernetes Cluster including a sample application you can use as a reference to deploy the stack-io Go app. The project is still under developmet and may not yethave been publicly released yet.