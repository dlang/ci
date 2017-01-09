#!/bin/env groovy

def build (os) {
    // TODO: figure out OS from node label

    switch (os) {
        case "linux":
            sh "make -f posix.mak RELEASE=1"
            break
        default:
            assert false
    }
}

def reset () {
    sh "git reset --hard"
    sh "git clean -fdx"
}

////////////////////////////////////////////////////////////////////////////////

stage('Clone') {
    def repos = [
        dmd: {
            dir('dmd') {
                git url: 'https://github.com/dlang/dmd.git'
                reset()
            }
        },
        druntime: {
            dir('druntime') {
                git url: 'https://github.com/dlang/druntime.git'
                reset()
            }
        },
        phobos: {
            dir('phobos') {
                git url: 'https://github.com/dlang/phobos.git'
                reset()
            }
        },
        dub: {
            dir('dub') {
                git url: 'https://github.com/dlang/dub.git'
                reset()
            }
        },
        tools: {
            dir('tools') {
                git url: 'https://github.com/dlang/tools.git'
                reset()
            }
        }
    ]

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
