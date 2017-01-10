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

////////////////////////////////////////////////////////////////////////////////

stage('Clone') {
    def projects = [ 'dmd', 'druntime', 'phobos', 'dub', 'tools' ]
    def repos = [:]

    projects.each {
        repos[${it}] = {
            dir('dlang/${it}') {
                checkout poll: false, scm: [$class: 'GitSCM', branches: [[name: '*/master']], extensions: [[$class: 'CleanBeforeCheckout']], userRemoteConfigs: [[url: 'https://github.com/dlang/${it}.git']]]
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
            dir('dmd') {
                sh "make -f posix.mak unittest"
            }
        },
        druntime: {
            dir('druntime') {
                sh "make -f posix.mak test"
            }
        },
        phobos: {
            dir('phobos') {
                sh "make -f posix.mak test"
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
