#!/bin/env groovy

def Utils

stage('Initialization') {
    node {
        checkout scm
        sh "ls -lah"
        Utils = load "Utils.groovy"
        assert Utils
    }
}

void setBuildStatus(String message, String state) {
  step([
      $class: "GitHubCommitStatusSetter",
      reposSource: [$class: "ManuallyEnteredRepositorySource", url: "https://github.com/my-org/my-repo"],
      contextSource: [$class: "ManuallyEnteredCommitContextSource", context: "ci/jenkins/build-status"],
      errorHandlers: [[$class: "ChangingBuildStatusErrorHandler", result: "UNSTABLE"]],
      statusResultSource: [ $class: "ConditionalStatusResultSource", results: [[$class: "AnyBuildResult", message: message, state: state]] ]
  ]);
}

////////////////////////////////////////////////////////////////////////////////

stage('Clone') {
    def projects = [ 'dmd', 'druntime', 'phobos', 'dub', 'tools' ]
    def repos = [:]

    for (int i = 0; i < projects.size(); ++i) {
        def proj = projects[i]; // http://stackoverflow.com/a/35776133
        repos["$proj"] = {
            dir("$proj") {
                Utils.cleanCheckout "https://github.com/dlang/${proj}.git"
            }
        }
    }

    node {
        parallel repos
    }

//    setBuildStatus("Build complete", "SUCCESS");
}
