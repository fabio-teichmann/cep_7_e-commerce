## AWS

### Kinesis
- Kinesis Firehose (KFH) can read directly from Kinesis Streams (KDS)
- KFH can write directly to Iceberg tables, however, this makes the setup static, but controls the resource creation (e.g., AWS Glue Tables) through TerraForm
- KDA needs consumers only for the enhanced fan-out option and if more throughput is required. This setup will incur more costs (!)

> [!IMPORTANT]
> writing directly to Iceberg tables with KFH should be considered only for structured data inputs (e.g., CSV, JSON). Else, the preferred way is to create the catalog tables dynamically with Spark instead

## GitHub Actions

- to chain jobs (run one after the other), use keyword `needs: [job-name-1, job-name-2]` to create job dependencies

### Infra-backend
The goal is to have 2 separate actions, 1 to generate the state-lock infrastructure and 1 to destroy it. Both actions will be triggered manually by the user.

| :o: Issue | :mag_right: Source | :white_check_mark: Solution |
| :---- | :----- | :------- |
| Data / outputs from 1 job not available in other (separate) jobs | GitHub Action jobs are ephemeral | Use `uses: actions/upload-artifact` in job 1 and `uses: actions/download-artifact` in job 2 |
| `terraform destroy` in separate job unable to see state from previous job | Trying to pass on `.tfstate` as artifact in GitHub Actions | :x: realized that artifact are tied to 1 job and cannot be passed between 2 separate jobs.<br>Will try to upload state file into S3 bucket instead. |
| Destroy action doesn't know dynamic bucket name at job runtime. | Can't pass the bucket name between jobs if not through a bucket. But the bucket name is only known to the first job. | :white_check_mark: create **static bucket** to host such information. This trade-off is necessary to automate the state-lock portion. |
| Parameters don't carry over between jobs | Runners are launched in their own environment. Maybe that's the cause? | :x: write params to `>> $GITHUB_OUTPUT` |
| Flow doesn't appear correctly in GitHub UI and can't be triggered | One/some of the `uses:` statements incorrect. | |


### App deployment
| :o: Issue | :mag_right: Investigation | :white_check_mark: Outcome |
| :---- | :----- | :------- |
| Inject TerraForm outputs (e.g., Kinesis stream name) into app | Pass TF outputs from job 1 into image build in job 2 | Use `upload-artifact`/`download-artifact` actions to pass arguments within the same deployment flow |
| The infrastructure deployment will provide all from EKS to Kinesis in one go. How can I feed the Kinesis stream name into the app after the fact? | 1. Do I need a multi-step infra deployment?<br>2. Can I deploy the app code into the EKS cluster after the cluster was created? | |


## Automation

### EKS-Cluster
- a pod can only assume ONE service account role

| :o: Issue | :mag_right: Investigation | :white_check_mark: Outcome |
| :---- | :----- | :------- |
| Application needs access to several environmental variables. Some of which are created dynamically (e.g., Kinesis stream name) others are tokens and need to passed in securely | (1) How to inject TerraForm outputs into the app | - for **Kinesis**, only the stream name is required (partition key calculated in app); this could be a hard-coded parameter inside the container but I'd like to automate this further to minimize maintenance across different components<br>- TF outputs can be ingested through CI/CD flow (GitHub Actions job) into the image build as a .env file |
 | (2) Inject secrets into Docker image through GitHub Actions? | |
| Nodes unable to write to Kinesis Data Streams | Probably missing access rights. | EKS pods need OIDC (Open ID Connect) Federation to assume IAM roles to interact with services. Will put IRSA in place for the EKS cluster to allow access to Kinesis. |


## TerraForm

## Iceberg

### Data ingestion from S3 using Spark
- use `s3a://` for paths to benefit from parallelism

| :o: Issue | :mag_right: Investigation | :white_check_mark: Outcome |
| :---- | :----- | :------- |
| Spark will automatically read all data at the specified location. This includes potential re-reads of the same data. | How can this be streamlined to reduce I/O overhead? | - Pre-order data coming in by partitioning (e.g., by timestamp)<br>- Use checkpoints (separate file) to keep track of already read files. |
| | | |

### Schema evolution
| :o: Issue | :mag_right: Investigation | :white_check_mark: Outcome |
| :---- | :----- | :------- |
| Neither Spark nor Iceberg automatically update schema changes. Iceberg provides flexibility to do so but not automatically. | What are best practices around handling schema evolution? | 1. Specify schemas explicitly when reading data<br>2. When schema changes are detected, **manually trigger** the schema change to record it in Iceberg<br>3. reprocess any data that may have fallen off before the schema evolution. |