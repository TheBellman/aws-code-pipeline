# aws-code-pipeline

This is an example of using Code Commit and Code Pipeline to build and deploy a Go based Lambda function. At the time of writing it only deploys into an S3 bucket, the rest of the deployment is a problem for tomorrow.

I suggest you use the [go-lambda-example](https://github.com/TheBellman/go-lambda-example) Lambda code, since it's very simple and has no side effects.

## Prerequisites
This project does make use of Terraform version constraints (see `versions.tf`) but can be summarised as:

 - Terraform 0.13.4 or above
 - Terraform AWS provider 3.7.0 or above

## Usage
Start by creating `terraform.tfvars` to hold the necessary overload values (the bucket and account ID below are fake, by the way)

```
aws_region     = "eu-west-2"
aws_profile    = "adm_rhook_cli"
aws_account_id = "881999133503"
bucket_name    = "rahookbuild20211114111717192400000002"
```

The profile you use for applying the script will need pretty broad permissions, probably close to a full admin. The bucket is used to hold assets for the Code Pipeline build, and is where the Lambda ZIP file will be deployed as well. This bucket needs to pre-exist, should be private, and needs to be readable and writeable by the account.

Running up the infrastructure is simple. Note this creates the target Code Commit repository - you will need to manually push the lambda code into it in order to any testing.

```
$ terraform init
$ terraform apply
.
.
.
badge_url = https://codebuild.eu-west-2.amazonaws.com/badges?uuid=eyJlbmNyeXB0ZWREYXRhIjoiZnJ2ZVY2NUMyWmhIVjdmdHdUVHdwdEF2SXMrb1VQQW9YTmdEMis0aHIzVUhuUDRVOVdzaFlNUWFnR1B0VFBObEpLSVBTWCtNWVh2MGdQUm9NWkxFeG93PSIsIml2UGFyYW1ldGVyU3BlYyI6ImNJUHFwang3ZmJMZHdweXciLCJtYXRlcmlhbFNldFNlcmlhbCI6MX0%3D&branch=master
project_arn = arn:aws:codebuild:eu-west-2:889199313043:project/go-lambda-example
src_url = ssh://git-codecommit.eu-west-2.amazonaws.com/v1/repos/go-lambda-example
```

If you have the lambda code checked out, you can add an additional remote, and push it up (yes, it could have been done in different ways)

```
$ git remote add aws ssh://git-codecommit.eu-west-2.amazonaws.com/v1/repos/go-lambda-example
$ git remote -v
aws	ssh://git-codecommit.eu-west-2.amazonaws.com/v1/repos/go-lambda-example (fetch)
aws	ssh://git-codecommit.eu-west-2.amazonaws.com/v1/repos/go-lambda-example (push)
origin	git@github.com:TheBellman/go-lambda-example.git (fetch)
origin	git@github.com:TheBellman/go-lambda-example.git (push)
$ git push aws HEAD
```

In order to test the pipeline, make a change to the Go code (don't forget to update the test) and push it into Code Commit:

```
$ go test
PASS
ok    parttimepolymath.net/lambda    0.523s

$ git commit -a -m"Make a change to trigger the pipeline"
[main bc3bd21] Make a change to trigger the pipeline
 2 files changed, 2 insertions(+), 2 deletions(-)

$ git push aws
Enumerating objects: 7, done.
Counting objects: 100% (7/7), done.
Delta compression using up to 8 threads
Compressing objects: 100% (4/4), done.
Writing objects: 100% (4/4), 403 bytes | 403.00 KiB/s, done.
Total 4 (delta 3), reused 0 (delta 0)
To ssh://git-codecommit.eu-west-2.amazonaws.com/v1/repos/go-lambda-example
   810720d..bc3bd21  main -> main
```

There's a little bit of a wrinkle here - the branch is called `main` because that's what GitHub now likes (and I do agree) but by default the default branch in CodeCommit is still `master` - you will need to jump into Code Commit and do a pull request into `master`, then if you jump back to Code Pipeline you will see the build-and-deploy executing.

You can also cross check in the S3 bucket to see the versioned zip files showing up:

```
aws --profile adm_rhook_cli s3 ls rahookbuild20201114111717192400000001/go-lambda-example/
                           PRE BuildArtif/
                           PRE SourceArti/
2020-11-14 18:29:54    5245477 go-lambda-example.2020-11-14_18-29-53.zip
2020-11-14 18:32:53    5245520 go-lambda-example.2020-11-14_18-32-52.zip
2020-11-14 21:00:30    5245515 go-lambda-example.2020-11-14_21-00-29.zip
2020-11-14 21:10:47    5245497 go-lambda-example.2020-11-14_21-10-46.zip
2020-11-14 21:39:34    5245730 go-lambda-example.2020-11-14_21-39-33.zip
2020-11-16 18:45:58    5245247 go-lambda-example.2020-11-16_18-45-57.zip
```

To tear down the assets:

```
$ terraform destroy
```
Note that this does not remove the contents of the build bucket, you might want to clean those up manually. You will also want to remove the additional remote from the Go lambda project.

## Notes
There's quite a lot built by this:

1. A CodeCommit repository for the lambda code
2. A CodeBuilder build - note that this uses the `buildspec.yml` in the example code to define the build steps.
3. The CodePipeline pipeline
4. A CloudWatch Event Rule to trigger the pipeline on commit
5. A CloudWatch log group for the build logs to go into
6. A number of roles and policies used by all of the above.

The strategy in place is to have dedicated roles and policies for the pipeline project - this makes it easier to restrict access to various bits and pieces to least required privileges.

## ToDo
There's a few things to make this a more interesting demonstration:

1. Pull the Lambda code from GitHub and push to AWS as part of the setup
2. Make the branch that is built from a configurable item
3. Push the generated Lambda ZIP into Lambda itself.
4. Turn this into a reusable module to allow spinning up multiple projects.
5. Tighten up the security.

## License
Copyright 2020 Little Dog Digital

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
