from aws_cdk import (
    aws_s3 as s3,
    aws_codecommit as codecommit,
    aws_events_targets as targets,
    aws_codebuild as codebuild
)
import aws_cdk as cdk
from constructs import Construct


class CodepipelineStack(cdk.Stack):
    def __init__(self, scope: Construct, construct_id: str, bucket: s3.Bucket, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)

        repo = codecommit.Repository(
            self,
            'Repository',
            repository_name='sbt-sample-repo',
            code=codecommit.Code.from_directory("./assets/sbt-sample")
        )
        project = codebuild.Project(
            self,
            'Project',
            project_name='sbt-sample-project',
            source=codebuild.Source.code_commit(
                repository=repo,
                branch_or_ref="refs/heads/main"
            ),
            artifacts=codebuild.Artifacts.s3(
                bucket=bucket,
                path="builds",
                package_zip=False,
                include_build_id=False
            )
        )
        # starts a CodeBuild project when a commit is pushed to the "master" branch of the repo
        repo.on_commit(
            'OnCommit',
            target=targets.CodeBuildProject(project),
            branches=["main"]
        )
