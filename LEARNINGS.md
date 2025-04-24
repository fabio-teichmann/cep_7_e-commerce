

## GitHub Actions

### Infra-backend
The goal is to have 2 separate actions, 1 to generate the state-lock infrastructure and 1 to destroy it. Both actions will be triggered manually by the user.

| :o: Issue | :mag_right: Source | :white_check_mark: Solution |
| :---- | :----- | :------- |
| Data / outputs from 1 job not available in other (separate) jobs | GitHub Action jobs are ephemeral | Use `uses: actions/upload-artifact` in job 1 and `uses: actions/download-artifact` in job 2 |
| `terraform destroy` in separate job unable to see state from previous job | Trying to pass on `.tfstate` as artifact in GitHub Actions | :x: realized that artifact are tied to 1 job and cannot be passed between 2 separate jobs.<br>Will try to upload state file into S3 bucket instead. |
| Destroy action doesn't know dynamic bucket name at job runtime. | Can't pass the bucket name between jobs if not through a bucket. But the bucket name is only known to the first job. | :white_check_mark: create **static bucket** to host such information. This trade-off is necessary to automate the state-lock portion. |