#!/bin/env groovy

/*******************************************************************************

    Utilities and helpers

*******************************************************************************/

/**
    Standard function to be used to do a git checkout for arbitrary URL in
    current folder. Cleans the folder (using `git reset --hard` +
    `git clean -fdx`) in the process.
 **/
def cleanCheckout (repo_url, git_ref = "master") {
    git poll: false, branch: "master",
        extensions: [[$class: 'CleanBeforeCheckout']], url: repo_url
}

/**
    Utility to simplify repeating boilerplate of defining parallel steps
    over array of folders. Creates a map from @names array where each value
    is @action called with each name respectively while being wrapped in
    `dir(name)` statement.
 **/
def mapSteps (names, action) {
    def steps = [:]

    for (int i = 0; i < names.size(); ++i) {
        def name = names[i];
        steps[name] = { dir(name, { action(name) }) }
    }

    return steps
}

/*******************************************************************************

    Actions

    In Groovy it is not possible to define a "static" nested function and
    defining a closure wrongly captures a context, making it break `parallel`
    in weird ways.

    Because of that, all actions to be used with `mapSteps` are to be define
    here as global functions. Each function should be named in relation to stage
    is used in and take exactly one argument - directory name

*******************************************************************************/

def clone (name) {
    cleanCheckout "https://github.com/dlang/${name}.git"
}

def test (name) {
    if (name == 'dmd')
        sh "make -j 4 -f posix.mak test MODEL=64"
    else
        sh "make -f posix.mak unittest"
}

/*******************************************************************************

    Stages

*******************************************************************************/

node { // for now whole pipeline runs on one node because no slaves are present

    def projects = [ 'dmd', 'druntime', 'phobos', 'dub', 'tools' ]

    stage('Clone') {
        parallel mapSteps(projects, this.&clone)
    }

    stage('Build Compiler') {
        // main compilation process can't be parallel because each repo
        // expects previous one to be already built and present in parent
        // folder

        def action = { sh "make -f posix.mak RELEASE=1 AUTO_BOOTSTRAP=1" }

        dir('dmd',      action)
        dir('dmd/src', { sh 'make -f posix.mak AUTO_BOOTSTRAP=1 dmd.conf' })
        dir('druntime', action)
        dir('phobos',   action)
    }

    stage('Test Compiler') {
        // dmd own test execution time is the biggest lirability here
        // so it is run with additional internal parallelization (make -j 4)
        // finding ways to speed up tests would help this pipeline a lot

        parallel mapSteps([ 'dmd', 'druntime', 'phobos' ], this.&test)
    }

    stage('Build Tools') {
        def repos = [
            'dub': {
                withEnv(["PATH=${env.WORKSPACE}/dmd/src:${env.PATH}"]) {
                    dir ('dub') { sh "./build.sh" }
                }
            },
            'tools': {
                withEnv(["PATH=${env.WORKSPACE}/dmd/src:${env.PATH}"]) {
                    dir ('tools') { sh "make -f posix.mak RELEASE=1" }
                }
            }
        ]

        parallel repos
    }

    stage("Package distribution") {
        // ideally this step should be in sync with the release tars
        sh '''#!/usr/bin/env bash
            set -ueo pipefail

            rm -rf distribution
            mkdir -p distribution/{bin,imports,libs}
            cp --recursive --link dmd/src/dmd dub/bin/dub tools/generated/linux/64/rdmd distribution/bin/
            cp --recursive --link phobos/etc phobos/std druntime/import/* distribution/imports/
            cp --recursive --link phobos/generated/linux/release/64/libphobos2.a distribution/libs/
            echo '[Environment]
DFLAGS=-I%@P%/../imports -L-L%@P%/../libs -L--export-dynamic -L--export-dynamic -fPIC' > distribution/bin/dmd.conf
            tar -cf distribution.tar distribution
        '''
        archiveArtifacts artifacts: 'distribution.tar', onlyIfSuccessful: true
    }
}

stage("Test downstream projects") {
    build job: 'dlangci-downstream'
}
