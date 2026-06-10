const { watch } = require('gulp');
const { exec } = require('child_process');

function swaggerMerge(cb) {
  exec('npm run merge', (err, stdout, stderr) => {
    if (stdout?.length) process.stdout.write(stdout);
    if (stderr?.length) process.stderr.write(stderr);

    cb(err || undefined);
  });
}

exports.default = () => {
  watch(['./**/*.yaml', '!merged/*'], swaggerMerge);
};
