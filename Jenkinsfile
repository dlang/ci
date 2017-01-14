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
}
