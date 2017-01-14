def dlang_make () {
    // TODO: windows support
    sh "make -f posix.mak RELEASE=1 AUTO_BOOTSTRAP=1"
}

def cleanCheckout (repo_url, gitref = "master") {
    git poll: false, branch: gitref,
        extensions: [[$class: 'CleanBeforeCheckout']], url: repo_url
}

def cleanCheckoutLatestTag (repo_url) {
    cleanCheckout()

    def LATEST = sh (
        script: 'git tag -l | egrep "^v[0-9]+\\.[0-9]+\\.[0-9]+.*$" | sort --version-sort | tail -n 1',
        returnStdout: true
    ).trim()

    // TODO: figure out how to do it via built-in git step
    sh "git checkout ${LATEST}"
}

return this
