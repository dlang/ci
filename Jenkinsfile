#!/bin/env groovy
// use legacy checkout SCM to fetch library, so we test changes froms PRs/branches
// https://github.com/jenkinsci/workflow-cps-global-lib-plugin/pull/37#issuecomment-311608135
library identifier: "dlang@master", retriever: legacySCM(scm)
runPipeline()
