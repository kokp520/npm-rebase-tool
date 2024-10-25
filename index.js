// index.js
const { execSync } = require('child_process');
const inquirer = require('inquirer');

async function main() {
    console.log("Checking differences with master branch...");

    const { master } = await inquirer.prompt([
        {
            type: 'list',
            name: 'master',
            message: '請選擇要git rebase -i的目標branch(master):',
            choices: ['master', 'main', 'dev', 'pre', 'develop', 'release'],
        },
    ]);

    const revert = execSync(`git cherry -v origin/${master}`).toString();
    const commits = (revert.match(/^\+/g) || []).length;

    if (commits < 2) {
        console.error("Warning: There are commits not merged with master branch.");
        console.error(`This branch cherry -v origin ${master}, commits = ${commits}.`);
        console.error("Please Check again.");
        process.exit(1);
    } else {
        console.log("Checking Done.");
        console.log(`Cherry -v commit number: ${commits}.`);
    }

    console.log(`WARNING: This script will squash all commits after ${master} branch.`);
    const { continueRebase } = await inquirer.prompt([
        {
            type: 'confirm',
            name: 'continueRebase',
            message: 'Are you sure you want to continue?',
            default: false,
        },
    ]);

    if (!continueRebase) {
        process.exit(1);
    }

    console.log(" ---- Start rebase master... -----");

    const currentBranch = execSync('git rev-parse --abbrev-ref HEAD').toString().trim();
    const originMasterCommitSha1 = execSync(`git rev-parse origin/${master}`).toString().trim();
    const afterMasterCommitSha1 = execSync(`git rev-list ${originMasterCommitSha1}..HEAD | tail -n 1`).toString().trim();
    let commitMsg = execSync(`git log ${afterMasterCommitSha1} -1 --format=%B`).toString().trim();

    execSync(`git fetch origin ${master}`);
    execSync(`git checkout ${master}`);
    execSync(`git pull origin ${master}`);
    execSync(`git checkout ${currentBranch}`);
    execSync(`git reset --soft ${afterMasterCommitSha1}`);

    console.log(`目前的Commit Msg是 ${commitMsg}`);

    const { updateMsg } = await inquirer.prompt([
        {
            type: 'confirm',
            name: 'updateMsg',
            message: '需要變更嗎?',
            default: false,
        },
    ]);

    if (updateMsg) {
        const { newCommitMsg } = await inquirer.prompt([
            {
                type: 'input',
                name: 'newCommitMsg',
                message: '輸入新的Commit Msg:',
            },
        ]);
        commitMsg = newCommitMsg;
    }

    execSync(`git commit --amend -m "${commitMsg}"`);
    console.log(' ---- Success! ---- ');
    console.log(`合併後的commit Msg: ${execSync("git log --name-status --pretty=format:'%h %s' -n 1").toString().trim()}`);
}

main().catch(err => {
    console.error(err);
    process.exit(1);
});