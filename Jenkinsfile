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
    def repos = [
        dub: {
            dir ("dub") {
                withEnv(["PATH=${env.WORKSPACE}/dmd/src/dmd:${env.PATH}"]) {
                        sh "./build.sh"
                }
            }
        },
        tools: {
            dir ("tools") {
                withEnv(["PATH=${env.WORKSPACE}/dmd/src/dmd:${env.PATH}"]) {
                    build 'linux'
                }
            }
        }
    ]

    node {
        parallel repos
    }
}

stage("Package distribution") {
    node {
        sh "mkdir -p distribution/{bin,imports,libs}"

        sh "cp dmd/src/dmd distribution/bin/"
        writeFile file: 'distribution/bin/dmd.conf', text: '''[Environment]
DFLAGS=-I%@P%/../imports -L-L%@P%/../libs -L--export-dynamic -L--export-dynamic -fPIC'''
        sh "cp dub/bin/dub distribution/bin/"
        sh "cp tools/generated/linux/64/rdmd distribution/bin/"

        sh "cp -r phobos/{etc,std} distribution/imports/"
        sh "cp -r druntime/import/* distribution/imports/"
        sh "cp phobos/generated/linux/release/64/libphobos2.a distribution/libs"

        sh "tar -cf distribution.tar distribution"
        archiveArtifacts artifacts: 'distribution.tar', onlyIfSuccessful: true
    }
}

stage("Test downstream projects") {
    build "dlangci-downstream"
}
