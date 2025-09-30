#!/usr/bin/python3

#  Copyright 2024 Cix Technology Group Co., Ltd.
#  All Rights Reserved.
#
#  The following programs are the sole property of Cix Technology Group Co., Ltd.,
#  and contain its proprietary and confidential information.
#

# Description: release the repo manifests to github
# Author: Xinjun
# Date: 2025-09-17
# Revision: original v1.0
#

import string
import os, sys
import requests
import base64
import json
import time
import subprocess
import random

###########################################################################################################

DEBUG = False

PATH_HOME = ''
PATH_WORKSPACE = ''

GITHUB_TOKEN = ''
GITHUB_USERNAME = ''
GITHUB_ORG_NAME = ''
GITHUB_OWNER = ''

CONFIG_FILE = ''
REPO_NAME = ''
BRANCH_NAME = ''

def loadJson(path):
    try:
        f = open(path, "r", encoding = "utf-8")
        txt = f.read()
        f.close()
        return json.loads(txt)
    except Exception as e:
        print('load json failed.')
    return json.loads('[]')

def saveJson(data, path):
    try:
        f = open(path, "w", encoding = "utf-8")
        f.write(json.dumps(data, indent=2, ensure_ascii=False))
        f.close()
    except Exception as e:
        print('save json failed.')

def getValue(str, key):
    keyLen = len(key)
    iStart = str.find(key+'="')
    if iStart > 0:
        iStart = iStart + keyLen + 2
        iEnd = str.find('"', iStart)
        if iEnd > iStart:
            return str[iStart: iEnd], iStart, iEnd
    return '', 0, 0

def runApp(cmd):
    result = ''
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, shell=True)
    try:
        lines = 0
        while True:
            line = proc.stdout.readline()
            if not line and proc.poll() != None:
                break
            result = result + line.decode('utf-8')
            lines = lines + 1
    except Exception:
        print(f'run [{cmd}] exception')
    finally:
        proc.stdout.close()
    return result

def loadConfig(file):
    content = ''
    projects = []
    try:
        ext = False
        remote = False
        ignore = False
        fIn = open(file, 'r', encoding='utf-8')
        for line in fIn.readlines():
            strip = line.strip()
            if ignore:
                if strip.endswith('/>'):
                    ignore = False
                continue
            if strip.startswith('<remote ') or strip.startswith('<default '):
                if not remote:
                    content += f'  <remote name="origin" fetch="https://github.com/{GITHUB_OWNER}" />\n'
                    content += f'  <default remote="origin" sync-j="4" sync-c="true" sync-tags="false" />\n'
                    remote = True
                if not strip.endswith('/>'):
                    ignore = True
                    continue
                else:
                    ignore = False
            elif strip.startswith('<project '):
                if not ext:
                    #content += f'  <project path="ext" name="ext" groups="cix" revision="{BRANCH_NAME}" />\n'
                    projects.append({'path': 'ext', 'name': f'ext', 'revision': BRANCH_NAME})
                    content += f'  <project path="ext_debs" name="ext_debs" groups="cix" revision="{BRANCH_NAME}" />\n'
                    projects.append({'path': 'ext_debs', 'name': f'ext_debs', 'revision': BRANCH_NAME})
                    ext = True
                path, iStart, iEnd = getValue(line, 'path')
                name, iStart, iEnd = getValue(line, 'name')
                revision, iStart, iEnd = getValue(line, 'revision')
                name = name.replace('/', '__')
                if strip.endswith('/>'):
                    content += f'  <project path="{path}" name="{name}" groups="cix" revision="{revision}" />\n'
                else:
                    content += f'  <project path="{path}" name="{name}" groups="cix" revision="{revision}">\n'
                projects.append({'name': name, 'path': path, 'revision': revision})
            else:
                content += line
        fIn.close()
    except Exception as e:
        print(f'error for {file}: {e}')
        exit(1)
    return content, projects

def gitExists(gitName):
    try:
        response = requests.get(f'https://api.github.com/repos/{GITHUB_OWNER}/{gitName}',
                                headers={
                                    'Authorization': f'Bearer {GITHUB_TOKEN}',
                                    'Accept': 'application/vnd.github.v3+json'
                                })
        if response.status_code in [200, 201]:
            print(f'{gitName} exists!')
            return True
        elif response.status_code == 404:
            print(f'{gitName} does not exist!')
            return False
        else:
            print(f'check {gitName} fail: {response.status_code}')
            return False
    except requests.exceptions.RequestException as e:
        print(f'Error: {e}')
        return False

def revisionExists(gitName, revision):
    try:
        url = f'https://api.github.com/repos/{GITHUB_OWNER}/{gitName}/git/{revision}'
        response = requests.get(url=url,
                                headers={
                                    'Authorization': f'Bearer {GITHUB_TOKEN}',
                                    'Accept': 'application/vnd.github.v3+json'
                                })
        if response.status_code in [200, 201]:
            print(f'{revision} exists!')
            return True
        elif response.status_code == 404:
            print(f'{revision} does not exist!')
            return False
        else:
            print(f'check revision {revision} fail: {response.status_code}')
            return False
    except requests.exceptions.RequestException as e:
        print(f'Error: {e}')
        return False

def branchExists(gitName, branch):
    return revisionExists(gitName=gitName,revision=f'ref/heads/{branch}')

def tagExists(gitName, tag):
    return revisionExists(gitName=gitName,revision=f'ref/tags/{tag}')

def createGit(gitName, private = False):
    try:
        if len(GITHUB_ORG_NAME) > 0:
            url = f'https://api.github.com/orgs/{GITHUB_OWNER}/repos'
        else:
            url = f'https://api.github.com/user/repos'
        response = requests.post(url,
                                json={
                                    'name': gitName,
                                    'description': f'Create {gitName} via api',
                                    'private': private,
                                    'auto_init': True
                                    },
                                headers={
                                    'Authorization': f'Bearer {GITHUB_TOKEN}',
                                    'Accept': 'application/vnd.github.v3+json'
                                })
        if response.status_code in [200, 201]:
            print(f'create {gitName} success!')
            return True
        else:
            print(f'create {gitName} fail: {response.json()}')
            return False
    except requests.exceptions.RequestException as e:
        print(f'Error: {e}')
        return False

def getBranchSHA(gitName, branch = 'main'):
    try:
        response = requests.get(f'https://api.github.com/repos/{GITHUB_OWNER}/{gitName}/git/ref/heads/{branch}',
                                headers={
                                    'Authorization': f'Bearer {GITHUB_TOKEN}',
                                    'Accept': 'application/vnd.github.v3+json'
                                })
        if response.status_code in [200, 201]:
            return response.json()['object']['sha']
        else:
            return ''
    except requests.exceptions.RequestException as e:
        print(f'Error: {e}')
        return ''

def getFileSHA(gitName, remoteFile, branch = 'main'):
    try:
        response = requests.get(f'https://api.github.com/repos/{GITHUB_OWNER}/{gitName}/contents/{remoteFile}',
                                headers={
                                    'Authorization': f'Bearer {GITHUB_TOKEN}',
                                    'Accept': 'application/vnd.github.v3+json'
                                },
                                params={
                                    'ref': branch
                                })
        if response.status_code in [200, 201]:
            return response.json()['sha']
        else:
            return ''
    except requests.exceptions.RequestException as e:
        print(f'Error: {e}')
        return ''

def createRevision(gitName, revision, sha):
    try:
        response = requests.post(f'https://api.github.com/repos/{GITHUB_OWNER}/{gitName}/git/refs',
                                json={
                                    'ref': f'{revision}',
                                    'sha': sha
                                    },
                                headers={
                                    'Authorization': f'Bearer {GITHUB_TOKEN}',
                                    'Accept': 'application/vnd.github.v3+json'
                                })
        if response.status_code in [200, 201]:
            return True
        else:
            return False
    except requests.exceptions.RequestException as e:
        print(f'Error: {e}')
        return False

def createBranch(gitName, newBranch, baseBranch = 'main'):
    if branchExists(gitName, newBranch):
        return True
    sha = getBranchSHA(gitName, baseBranch)
    if len(sha) < 1:
        print(f'Cannot get the sha form the branch {baseBranch}')
        return False
    flag = createRevision(gitName=gitName, revision=f'refs/heads/{newBranch}', sha=sha)
    if flag:
        print(f'create branch {newBranch} success!')
    else:
        print(f'failed to create branch: {newBranch}')
    return flag

def createTag(gitName, newTag, baseBranch = 'main'):
    if tagExists(gitName, newTag):
        return True
    sha = getBranchSHA(gitName, baseBranch)
    if len(sha) < 1:
        print(f'Cannot get the sha form the branch {baseBranch}')
        return False
    flag = createRevision(gitName=gitName, revision=f"refs/tags/{newTag}", sha=sha)
    if flag:
        print(f'create tag {newTag} success!')
    else:
        print(f'failed to create tag: {newTag}')
    return flag

def commitGitFile(content, gitName, remoteFile, branch = 'main'):
    sha = getFileSHA(gitName, remoteFile, branch)
    data = {'message': f'Commit the file {remoteFile} via api',
            'content': content,
            'branch': branch
            }
    if len(sha) > 0:
        data['sha'] = sha
    try:
        response = requests.put(f'https://api.github.com/repos/{GITHUB_OWNER}/{gitName}/contents/{remoteFile}',
                                json=data,
                                headers={
                                    'Authorization': f'Bearer {GITHUB_TOKEN}',
                                    'Accept': 'application/vnd.github.v3+json'
                                })
        if response.status_code in [200, 201]:
            print(f'commit {remoteFile} success!')
            return True
        else:
            print(f'commit {remoteFile} fail: {response.json()}')
            return False
    except requests.exceptions.RequestException as e:
        print(f'Error: {e}')
        return False

def doGitHub(content, projects, private = False):
    # create repo manifests
    if not gitExists(REPO_NAME):
        createGit(REPO_NAME, private)

    # create repo branch
    createBranch(REPO_NAME, BRANCH_NAME, 'main')

    # commit the default.xml
    content = base64.b64encode(content.encode()).decode()
    #print(content)
    commitGitFile(content, REPO_NAME, 'default.xml', BRANCH_NAME)

    time.sleep(0.2)
    # process all projects
    for project in projects:
        time.sleep(0.3)
        if not gitExists(project['name']):
            createGit(project['name'], private)

    # create rc_tag for cix_ext
    tmp = runApp(f'grep "EX_VERSION" {PATH_WORKSPACE}/build-scripts/build-all.sh')
    tag, iStart, iEnd = getValue(tmp, 'EX_VERSION')
    if len(tag) > 0:
        print(f'create the tag "{tag}" for ext')
        createTag('ext', tag)
    else:
        print('Error: cannot create the tag for ext')

def doDebs():
    dstPath = os.path.join(PATH_WORKSPACE, 'ext_debs')
    if not os.path.exists(dstPath):
        os.mkdir(dstPath)
    for entry in os.scandir(os.path.join(PATH_WORKSPACE, 'ext', 'output', 'cix_evb', 'debs')):
        if entry.is_file():
            if entry.path.endswith('.deb'): # and entry.name.startswith('cix'):
                path = os.path.join(dstPath, entry.name[0:len(entry.name)-4])
                runApp(f'dpkg-deb -R {entry.path} {path}')
                if doLargeFile(path, path, 100 * 1024 * 1024):
                    runApp(f'rm -rf {path}')
    os.chdir(dstPath)
    runApp(f'git init')
    runApp(f'git checkout -b "{BRANCH_NAME}"')
    runApp(f'git add .')
    runApp(f'git commit -m "update the ext_debs"')

def doLargeFile(root, path, maxSize, exist = False):
    for entry in os.scandir(path):
        if entry.is_file() and entry.stat().st_size > maxSize:
            file = entry.path[len(root):].lstrip('/').lstrip('\\')
            print(f'file {entry.path} size: {entry.stat().st_size} > {maxSize}')
            
            #check the file if exists in git 
            
            # os.chdir(root)
            # res = runApp(f'git lfs track "{file}"')
            # print(f'git lfs track "{file}": {res}')
            exist = True
        elif entry.is_dir() and entry.name != '.git':
            if doLargeFile(root, entry.path, maxSize, exist):
                exist = True
    return exist

if __name__ == '__main__':
    args = sys.argv
    count = len(args)
    i = 0
    while i < count:
        if args[i] == '-h':
            print(f'{args[0]} <options>')
            print(f'    -t <token>:               the access token of github')
            print(f'    -u <user name>:           the user name of github')
            print(f'    -c <config file>:         the config file (default.xml)')
            print(f'    -r <repo name>:           the repo name of github')
            print(f'    -b <branch name>:         the branch name of the repo')
            print(f'    -o <organization name>:   the organization name of the github api')
            sys.exit(0)
        elif args[i] == '-t':
            i = i + 1
            GITHUB_TOKEN = args[i]
        elif args[i] == '-u':
            i = i + 1
            GITHUB_USERNAME = args[i]
        elif args[i] == '-c':
            i = i + 1
            CONFIG_FILE = args[i]
        elif args[i] == '-r':
            i = i + 1
            REPO_NAME = args[i]
        elif args[i] == '-b':
            i = i + 1
            BRANCH_NAME = args[i]
        elif args[i] == '-o':
            i = i + 1
            GITHUB_ORG_NAME = args[i]
        elif args[i] == '--debug':
            DEBUG = True
        i = i + 1

    if len(GITHUB_TOKEN) < 1:
        print(f'Please input the github token with -t')
        sys.exit(0)
    if len(GITHUB_USERNAME) < 1:
        print(f'Please input the github username with -u')
        sys.exit(0)
    if len(REPO_NAME) < 1:
        print(f'Please input the repo name with -r')
        sys.exit(0)
    if len(REPO_NAME) < 1:
        print(f'Please input the repo name with -r')
        sys.exit(0)
    if len(BRANCH_NAME) < 1:
        print(f'Please input the branch name with -b')
        sys.exit(0)

    if len(GITHUB_ORG_NAME) > 0:
        GITHUB_OWNER = GITHUB_ORG_NAME
    else:
        GITHUB_OWNER = GITHUB_USERNAME

    if not os.path.exists(CONFIG_FILE):
        print(f'Config file {CONFIG_FILE} does not exist')
        sys.exit(0)

    PATH_HOME = os.path.realpath(os.path.join(__file__, '..'))
    PATH_WORKSPACE = os.path.realpath(os.path.join(CONFIG_FILE, '..', '..', '..'))
    print(f'PATH_HOME: {PATH_HOME}')
    print(f'PATH_WORKSPACE: {PATH_WORKSPACE}')

    content, projects = loadConfig(CONFIG_FILE)
    #print(content)
    #print(projects)

    doDebs()

    hasLargeFile = False
    for project in projects:
        if project['path'] != 'ext':
            path = os.path.join(PATH_WORKSPACE, project['path'])
            if os.path.exists(path):
                os.chdir(path)
                if doLargeFile(path, path, 100 * 1024 * 1024):
                    hasLargeFile = True
    if hasLargeFile:
        print('The large files cannot be supported (> 100M)')
        exit(0)

    if DEBUG:
        doGitHub(content, projects, private=True)
    else:
        doGitHub(content, projects, private=False)

    for project in projects:
        if project['path'] != 'ext':
            path = os.path.join(PATH_WORKSPACE, project['path'])
            if os.path.exists(path):
                os.chdir(path)
                print(f'-----{path}-----')
                res = runApp(f'git checkout {project["revision"]}')
                print(f'git checkout {project["revision"]} : {res}')
                #runApp(f'git lfs pull')
                # if doLargeFile(path, path, 100 * 1024 * 1024): # file which size is larger than 100M will use lfs
                #     os.chdir(path)
                #     res = runApp('git add .')
                #     print(f'git add . : {res}')
                #     res = runApp('git commit --amend -CHEAD')
                #     #print(f'git commit --amend -CHEAD : {res}')

                os.chdir(path)
                res = runApp(f'git remote | grep github')
                if len(res) > 0:
                    runApp(f'git remote remove github')
                res = runApp(f'git remote add github ssh://github.com/{GITHUB_OWNER}/{project["name"]}')
                print(f'git remote add github : {res}')
                if project['path'] == 'linux' and not branchExists(project['name'], project["revision"]):
                    commitID = runApp("git log -n1 HEAD~8000 | grep commit | head -1 | awk '{print $2}'")
                    if len(commitID) > 0:
                        temp = ''.join(random.choices(string.ascii_letters, k=8))
                        runApp(f'git checkout -b {temp} {commitID}')
                        res = runApp(f'git push -o skip-validation github {temp}:{project["revision"]}')
                        print(f'git push github 1 : {res}')

                        runApp(f'git checkout {project["revision"]}')
                        res = runApp(f'git push -o skip-validation github {project["revision"]}')
                        print(f'git push github 2 : {res}')
                    else:
                        res = runApp(f'git push -o skip-validation github {project["revision"]}')
                        print(f'git push github : {res}')
                else:
                    res = runApp(f'git push -o skip-validation github {project["revision"]}')
                    print(f'git push github : {res}')
            else:
                print(f'path {path} does not exist!')
        else:
            path = os.path.join(PATH_WORKSPACE, project['path'])
            if os.path.exists(path):
                path_7z = os.path.join(PATH_WORKSPACE, 'ext_7z') 
                if not os.path.exists(path_7z):
                    os.mkdir(path_7z)
                os.chdir(PATH_WORKSPACE)
                runApp(f'7z a -v1g {path_7z}/cix_ext.7z ext')

    os.chdir(PATH_WORKSPACE)
