#!/bin/env groovy

def cloneUpstream () {
    checkout(scm: [
        $class: 'GitSCM',
        branches: scm.branches,
        extensions: scm.extensions + [[$class: 'CleanBeforeCheckout']],
        userRemoteConfigs: scm.userRemoteConfigs
    ])
}

def pipeline
node {
    dir('dlang/ci') {
        cloneUpstream()
    }
    pipeline = load 'dlang/ci/pipeline.groovy'
}
pipeline.runPipeline()
