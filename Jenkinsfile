#!/bin/env groovy

node {
    stage ("Trigger") {
        dir ("dlang/ci") {
            git "https://github.com/dlang/ci.git"
        }

        load "dlang/ci/pipeline.groovy"
    }
}
