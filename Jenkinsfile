#!/bin/env groovy

def build (os) {
    // TODO: figure out OS from node label

    switch (os) {
        case "linux":
            sh "make -f posix.mak RELEASE=1 AUTO_BOOTSTRAP=1"
            break
        default:
            assert false
    }
}

def cleanCheckout (repo_url) {
    checkout poll: false, scm: [$class: 'GitSCM', branches: [[name:
        '*/master']], extensions: [[$class: 'CleanBeforeCheckout']],
        userRemoteConfigs: [[url: repo_url]]]
}

////////////////////////////////////////////////////////////////////////////////

stage('Clone') {
    def projects = [ 'dmd', 'druntime', 'phobos', 'dub', 'tools' ]
    def repos = [:]

    for (int i = 0; i < projects.size(); ++i) {
        def proj = projects[i]; // http://stackoverflow.com/a/35776133
        repos["$proj"] = {
            dir("$proj") {
                cleanCheckout "https://github.com/dlang/${proj}.git"
            }
        }
    }

    node {
        parallel repos
    }
}

stage('Build Compiler') {
    node {
        dir('dmd') {
            build 'linux'
        }
        dir('druntime') {
            build 'linux'
        }
        dir('phobos') {
            build 'linux'
        }
    }
}

stage('Test Compiler') {
    def repos = [
        dmd: {
            dir('dmd/test') {
                sh "make MODEL=64"
            }
        },
        druntime: {
            dir('druntime') {
                sh "make -f posix.mak unittest"
            }
        },
        phobos: {
            dir('phobos') {
                sh "make -f posix.mak unittest"
            }
        }
    ]

    node {
        parallel repos
    }
}

stage('Build Tools') {
    withEnv(["PATH=${env.WORKSPACE}/dmd/src/dmd:${env.PATH}"]) {
        sh "To be done"
    }
}

stage("Package distribution") {
    sh "To be done"
}

stage("Test downstream projects") {
    // TODO:
    sh "Runs job from ProjectsJenkinsfile"
}
